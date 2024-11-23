import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:manzil_app_v2/screens/home_screen.dart';
import 'package:manzil_app_v2/services/chat/chat_services.dart';
import 'package:manzil_app_v2/services/socket_handler.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

class FullDriverMap extends ConsumerStatefulWidget {
  const FullDriverMap({super.key});

  @override
  ConsumerState createState() => FullDriverMapState();
}

class FullDriverMapState extends ConsumerState<FullDriverMap> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;

  var userLocation;

  ChatService chatService = ChatService();

  final box = GetStorage();

  List<dynamic> ridePassengers = [];
  List<dynamic> pickedUpPassengers = [];
  var distanceToPoint = 0.0;
  var lastDistance;
  bool isIncreasing = false;

  bool rideStarted = false;

  Timer? timer;

  double _azimuth = 0.0;
  double _previousAzimuth = 0.0;
  final double _threshold = 5.0; // Set your threshold (in degrees)
  Timer? _debounceTimer;

  void _addMarker(Point point) async {

    final ByteData bytes =

    await rootBundle.load('assets/icons/marker.png');

    final Uint8List imageData = bytes.buffer.asUint8List();

    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(

        geometry: Point(coordinates: Position(point.coordinates.lng, point.coordinates.lat)), // Example coordinates

        image: imageData,

        iconSize: 1.5,

    );
    await pointAnnotationManager?.create(pointAnnotationOptions);
  }

  void setStateIfSignificantRotation(GyroscopeEvent event) {
    // Calculate azimuth (compass direction) from raw gyroscope data
    double currentAzimuth = atan2(event.y, event.x) * (180 / pi);

    // Ensure the azimuth is within the 0 to 360 degree range
    if (currentAzimuth < 0) {
      currentAzimuth = 360 + currentAzimuth;
    }

    // Only update the state if the change in azimuth exceeds the threshold
    if ((currentAzimuth - _previousAzimuth).abs() >= _threshold) {
      // Cancel any previous debounce timer
      _debounceTimer?.cancel();

      // Set a new debounce timer to update the state after 100 milliseconds
      _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
        setState(() {
          _previousAzimuth = _azimuth;
          _azimuth = currentAzimuth;
        });
      });
    }
  }


  @override
  void initState() {
    gyroscopeEventStream().listen((GyroscopeEvent event) {
      setStateIfSignificantRotation(event);
    });

    SocketHandler.socket.on("Booked Ride", (passenger){
      ridePassengers.add(passenger);
      num lat = num.parse(passenger["startPoint"][0]["lat"]);
      num lng = num.parse(passenger["startPoint"][0]["lon"]);

      _addMarker(Point(coordinates: Position(lng, lat)));
    });

    SocketHandler.socket.on("Canceled Ride", (passenger){
      ridePassengers.remove(passenger);

      if(ridePassengers.isEmpty && pickedUpPassengers.isEmpty){
        box.write("canNavigate", false);
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(
            builder: (context) => const HomeScreen()));
      }
    });

    SocketHandler.socket.on("Picked Up", (passenger) {
      ridePassengers.remove(passenger);
      pickedUpPassengers.add(passenger);

      if (ridePassengers.isEmpty && pickedUpPassengers.isEmpty) {
        box.write("canNavigate", false);
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const HomeScreen()));
      }
    });


      SocketHandler.socket.on("Completed Ride", (passenger) {
        pickedUpPassengers.remove(passenger);

        if (ridePassengers.isEmpty && pickedUpPassengers.isEmpty) {
          box.write("canNavigate", false);
          completeRide();
          showCupertinoDialog(
              barrierDismissible: false,
              context: context,
              builder: (_) {
                Future.delayed(const Duration(milliseconds: 800), () {
                  Navigator.of(context).pop(true);
                });

                return const AlertDialog(
                  title: Text("Ride has been completed!"),
                  icon: Icon(Icons.check_circle_outline_rounded),
                  iconColor: Colors.green,
                );
              }
          );
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => const HomeScreen()));
        }
    });

    super.initState();
    // Any additional initialization if needed
  }

  Future<Uint8List> getImageData() async {
    final ByteData bytes = await rootBundle.load('assets/icons/driver.png');

    final Uint8List imageData = bytes.buffer.asUint8List();

    return imageData;
  }

  Future<LineString> getLineString(
      String long1, String lat1, String long2, String lat2) async {
    String url =
        "https://api.mapbox.com/directions/v5/mapbox/driving/$long1%2C$lat1%3B$long2%2C$lat2?alternatives=false&geometries=geojson&language=en&overview=full&steps=true&access_token=${const String.fromEnvironment("ACCESS_TOKEN")}";

    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    var geocodedData = jsonDecode(response.body) as Map<String, dynamic>;

    List<Position> coordinates = [];

    for (var position in List.from(geocodedData["routes"][0]["geometry"]["coordinates"])) {
      coordinates.add(Position(position[0], position[1]));
    }
    return LineString(coordinates: coordinates);
  }

  void completeRide() async {
    const url = "https://shrimp-select-vertically.ngrok-free.app";
    var driverId = box.read("_id");

    await http.patch(
      Uri.parse("$url/complete-ride/$driverId"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
  }

// Ensure only one update is active at a time
  bool _isUpdating = false;

// Store the previous path's geometry
  List<List<double>> _previousCoordinates = [];

  void addPath(String long1, String lat1, String long2, String lat2) async {
    // Skip if an update is already in progress
    if (_isUpdating) return;

    _isUpdating = true; // Mark as updating

    // Create the new path as a list of [longitude, latitude] pairs
    List<List<double>> newCoordinates = [
      [double.parse(long1), double.parse(lat1)], // First point [longitude, latitude]
      [double.parse(long2), double.parse(lat2)], // Second point [longitude, latitude]
    ];

    // Compare with the previous coordinates
    if (_previousCoordinates.isNotEmpty && _isSamePath(newCoordinates, _previousCoordinates)) {
      _isUpdating = false; // Mark update as complete
      return;  // Skip creating a new polyline if the path is the same
    }

    _previousCoordinates = newCoordinates; // Update the previous coordinates

    try {
      // Get the new geometry for the path
      var value = await getLineString(long1, lat1, long2, lat2);

      // Remove all annotations before adding the new one
      await polylineAnnotationManager?.deleteAll();

      // Create the new polyline with rounded corners and ends
      PolylineAnnotationOptions polylineAnnotationOptions = PolylineAnnotationOptions(
        geometry: value,
        lineWidth: 6,
        lineColor: Colors.deepOrange.value,
        lineJoin: LineJoin.ROUND,
        lineBlur: 2
      );

      // Optional small delay to avoid blinking
      await Future.delayed(const Duration(milliseconds: 200));

      await polylineAnnotationManager?.create(polylineAnnotationOptions);
    } catch (e) {
      print("Error updating polyline: $e");
    } finally {
      _isUpdating = false; // Mark update as complete
    }
  }

// Compare two paths (List of List<double>) to see if they are the same
  bool _isSamePath(List<List<double>> newCoordinates, List<List<double>> oldCoordinates) {
    if (newCoordinates.length != oldCoordinates.length) {
      return false;
    }

    for (int i = 0; i < newCoordinates.length; i++) {
      if (newCoordinates[i][0] != oldCoordinates[i][0] ||  // Compare longitude
          newCoordinates[i][1] != oldCoordinates[i][1]) { // Compare latitude
        return false;
      }
    }
    return true;
  }



  Future<Map<String, dynamic>> getDistance(String long1, String lat1, String long2, String lat2) async {

    String url = "https://api.mapbox.com/directions/v5/mapbox/driving/$long1%2C$lat1%3B$long2%2C$lat2?alternatives=false&geometries=geojson&language=en&overview=full&steps=true&access_token=${const String.fromEnvironment("ACCESS_TOKEN")}";

    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    var geocodedData = jsonDecode(response.body) as Map<String, dynamic>;

    return {
      "distance": geocodedData["routes"][0]["distance"],
      "duration": geocodedData["routes"][0]["duration"]
    };
  }


  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    chatService.getRideUsers().then((users){

      ridePassengers.addAll(users);
      for (var passenger in ridePassengers) {
        if(passenger["isPickedUp"]){
          pickedUpPassengers.add(passenger);
          ridePassengers.remove(passenger);
        }

        num lat = num.parse(passenger["startPoint"][0]["lat"]);
        num lng = num.parse(passenger["startPoint"][0]["lon"]);

        _addMarker(Point(coordinates: Position(lng, lat)));
      }
    });

    LocationPuck2D locationPuck2D = DefaultLocationPuck2D();

    getImageData().then((image){
      locationPuck2D = box.read("canNavigate") ? LocationPuck2D(topImage: image, bearingImage: image)  : DefaultLocationPuck2D();
    });

    String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
    MapboxOptions.setAccessToken(accessToken);

    Position position = Position(-98.0, 39.5);

    _determinePosition().then((value) {
      position = Position(value.longitude, value.latitude);

      CameraOptions camera = CameraOptions(
        center: Point(coordinates: position),
        zoom: 18,
        bearing: 0,
        pitch: 0,
      );

      MapAnimationOptions mapAnimationOptions =
      MapAnimationOptions(duration: 1000);

      mapboxMap.flyTo(camera, mapAnimationOptions);
      mapboxMap.logo.updateSettings(LogoSettings(
        enabled: false,
      ));
      mapboxMap.location.updateSettings(LocationComponentSettings(
        puckBearing: PuckBearing.HEADING,
        puckBearingEnabled: true,
        enabled: true,
        locationPuck: LocationPuck(locationPuck2D: locationPuck2D),
      ));
  });
  }

  void _showDialog() {
    if (isIncreasing) {

      chatService.getRide().then((ride){
        SocketHandler.socket.emit("Ride Moving Away", ride);
      });

      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              icon: const Icon(Icons.warning_rounded),
              iconColor: Colors.red,
              title: const Text("Warning"),
              content: const Text(
                  "You have been moving away from your destination for 10 minutes."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    _determinePosition().then((value) {

      if(mounted) {
        setState(() {
        userLocation = value;
      });
      }

      if(ridePassengers.isNotEmpty && !rideStarted){
        String lat1 = value.latitude.toString();
        String lng1 = value.longitude.toString();
        String lat2 = ridePassengers[0]["startPoint"][0]["lat"];
        String lng2 = ridePassengers[0]["startPoint"][0]["lon"];

        addPath(lng1, lat1, lng2, lat2);
        getDistance(lng1, lat1, lng2, lat2).then((response){
          distanceToPoint = response["distance"];
        });
      }

      if(pickedUpPassengers.isNotEmpty && rideStarted){
        String lat1 = value.latitude.toString();
        String lng1 = value.longitude.toString();
        String lat2 = pickedUpPassengers[0]["endPoint"][0]["lat"];
        String lng2 = pickedUpPassengers[0]["endPoint"][0]["lon"];

        addPath(lng1, lat1, lng2, lat2);
        getDistance(lng1, lat1, lng2, lat2).then((response) {
          distanceToPoint = response["distance"];

          if (lastDistance != null) {
            if (distanceToPoint > lastDistance!) {
              // Distance is increasing
              if (!isIncreasing) {
                isIncreasing = true;

                // Start the 10-minute timer
                timer = Timer(const Duration(seconds: 5), _showDialog);
              }
            } else {
              // Distance is decreasing or stable
              if (isIncreasing) {
                isIncreasing = false;
                timer
                    ?.cancel(); // Cancel the timer if the distance stops increasing
              }
            }
          }
          lastDistance = distanceToPoint;
        });

      }

      SocketHandler.socket.emit("User_Location", {
        "id": box.read("_id"),
        "lat": value.latitude,
        "lng": value.longitude,
        "rotation": _azimuth
      });
    });

    return Stack(
      children: [
        Scaffold(
          body: MapWidget(
            key: const ValueKey("mapWidget"),
            onMapCreated: _onMapCreated,
          ),
        ),
        Positioned(
          bottom: 220,
          right: 20,
          child: Builder(
            builder: (context) => CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                icon: Icon(
                  Icons.compass_calibration,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 30,
                ),
                onPressed: () {
                  _determinePosition().then((value) {
                    Position position = Position(value.longitude, value.latitude);

                    CameraOptions camera = CameraOptions(
                      center: Point(coordinates: position),
                      zoom: 18,
                      bearing: 0,
                      pitch: 0,
                    );

                    MapAnimationOptions mapAnimationOptions =
                    MapAnimationOptions(duration: 1000);

                    mapboxMap?.flyTo(camera, mapAnimationOptions);
                  });
                },
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          left: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration:  BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0)),
                      boxShadow: const [BoxShadow(color: Colors.black26,
                                  offset: Offset(1, 1),
                                  blurRadius: 2.0)]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ridePassengers.isNotEmpty ?
                   Text("Going to pickup ${ridePassengers[0]["firstName"]} ${ridePassengers[0]["lastName"]}",
                       style: const TextStyle(fontSize: 18, color: Colors.white)
                   ) : pickedUpPassengers.isNotEmpty ?
                  Text("Going to drop ${pickedUpPassengers[0]["firstName"]} ${pickedUpPassengers[0]["lastName"]}",
                      style: const TextStyle(fontSize: 18, color: Colors.white)
                  ) : const Text("No passengers to pickup"),
                  const SizedBox(height: 10),
                  Text("${distanceToPoint.round()} meters far",
                      style: const TextStyle(fontSize: 14, color: Colors.white)
                  ),
                  const SizedBox(height: 10),

                  !rideStarted ?
                  ElevatedButton(
                      onPressed: (){

                        if(ridePassengers.isNotEmpty){
                          showCupertinoDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (_) {
                                Future.delayed(const Duration(milliseconds: 800), () {
                                  Navigator.of(context).pop(true);
                                });

                                return const AlertDialog(
                                  title: Text("Pickup the remaining passengers first!"),
                                  icon: Icon(Icons.warning),
                                  iconColor: Colors.red,
                                );
                              }
                          );
                          return;
                        }

                        polylineAnnotationManager?.deleteAll();
                        pointAnnotationManager?.deleteAll();

                        for (var passenger in pickedUpPassengers) {
                          num lat = num.parse(passenger["endPoint"][0]["lat"]);
                          num lng = num.parse(passenger["endPoint"][0]["lon"]);
                          _addMarker(Point(coordinates: Position(lng, lat)));
                        }
                        setState(() {
                          rideStarted = true;
                        });

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 107, 74),
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 80.0),
                        textStyle:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      child: const Text("Start Ride",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),)
                  ) : ElevatedButton(
                      onPressed: (){
                        chatService.getRide().then((ride){
                          SocketHandler.socket.emit("Emergency", ride);
                        });

                        showCupertinoDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (_) {
                              Future.delayed(const Duration(seconds: 2), () {
                                Navigator.of(context).pop(true);
                              });

                              return const AlertDialog(
                                title: Text("Emergency Alert Sent!"),
                                icon: Icon(Icons.emergency_share_rounded),
                                iconColor: Colors.red,
                              );
                            }
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 215, 0, 0),
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 80.0),
                        textStyle:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      child: const Text("Emergency",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),)
                  )
              ]),
            ),
          ),
        )
      ],
    );
  }
}

Future<geolocator.Position> _determinePosition() async {
  geolocator.LocationPermission permission;

  permission = await geolocator.Geolocator.checkPermission();
  if (permission == geolocator.LocationPermission.denied) {
    permission = await geolocator.Geolocator.requestPermission();
    if (permission == geolocator.LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == geolocator.LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied');
  }

  return await geolocator.Geolocator.getCurrentPosition();
}
