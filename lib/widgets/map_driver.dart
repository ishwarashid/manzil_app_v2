import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
  late PolylineAnnotation _annotation;
  late PolylineAnnotation _previousAnnotation;

  var userLocation;

  final box = GetStorage();

  List<dynamic> ridePassengers = [];
  List<dynamic> pickedUpPassengers = [];

  bool rideStarted = false;

  ChatService chatService = ChatService();

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
          SocketHandler.socket.emit("Mark Ride Complete");
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

  void addPath(String long1, String lat1, String long2, String lat2) {
    getLineString(long1, lat1, long2, lat2)
        .then((value){
      PolylineAnnotationOptions polylineAnnotationOptions = PolylineAnnotationOptions(
          geometry: value,
          lineWidth: 6,
          lineColor: Colors.deepOrange.value
      );
        polylineAnnotationManager?.create(polylineAnnotationOptions).then((annotation){
          try {
            _previousAnnotation = _annotation;
            _annotation = annotation;
          }catch(e){}
        });

      try {
        polylineAnnotationManager?.delete(_previousAnnotation);
      }
      catch(e){}

    });
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    chatService.getRideUsers().then((users){

      ridePassengers.addAll(users);
      for (var passenger in ridePassengers) {
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
      }

      if(pickedUpPassengers.isNotEmpty && rideStarted){
        String lat1 = value.latitude.toString();
        String lng1 = value.longitude.toString();
        String lat2 = pickedUpPassengers[0]["startPoint"][0]["lat"];
        String lng2 = pickedUpPassengers[0]["startPoint"][0]["lon"];

        addPath(lng1, lat1, lng2, lat2);
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
        // if(_driverPoint.coordinates.every((coordinate){ return coordinate != 0; }))
        //   Positioned(
        //     bottom: 320,
        //     right: 20,
        //     child: Builder(
        //       builder: (context) =>
        //           CircleAvatar(
        //             radius: 30,
        //             backgroundColor: Theme
        //                 .of(context)
        //                 .colorScheme
        //                 .primary,
        //             child: IconButton(
        //               icon: Icon(
        //                 Icons.directions_car,
        //                 color: Theme
        //                     .of(context)
        //                     .colorScheme
        //                     .onPrimary,
        //                 size: 30,
        //               ),
        //               onPressed: () {
        //                 position = Position(_driverPoint.coordinates.lng,
        //                     _driverPoint.coordinates.lat);
        //
        //                 CameraOptions camera = CameraOptions(
        //                   center: Point(coordinates: position),
        //                   zoom: 18,
        //                   bearing: 0,
        //                   pitch: 0,
        //                 );
        //
        //                 MapAnimationOptions mapAnimationOptions =
        //                 MapAnimationOptions(duration: 1000);
        //
        //                 mapboxMap?.flyTo(camera, mapAnimationOptions);
        //               },
        //             ),
        //           ),
        //     ),
        //   ),
        // Positioned(
        //   bottom: 220,
        //   right: 20,
        //   child: Builder(
        //     builder: (context) => CircleAvatar(
        //       radius: 30,
        //       backgroundColor: Theme.of(context).colorScheme.primary,
        //       child: IconButton(
        //         icon: Icon(
        //           Icons.compass_calibration,
        //           color: Theme.of(context).colorScheme.onPrimary,
        //           size: 30,
        //         ),
        //         onPressed: () {
        //           _determinePosition().then((value) {
        //             position = Position(value.longitude, value.latitude);
        //
        //             CameraOptions camera = CameraOptions(
        //               center: Point(coordinates: position),
        //               zoom: 18,
        //               bearing: 0,
        //               pitch: 0,
        //             );
        //
        //             MapAnimationOptions mapAnimationOptions =
        //                 MapAnimationOptions(duration: 1000);
        //
        //             mapboxMap?.flyTo(camera, mapAnimationOptions);
        //           });
        //         },
        //       ),
        //     ),
        //   ),
        // ),
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
                   ) : const Text("No passengers to pickup"),
                  const SizedBox(height: 10),
                  const Text("2 mins away",
                      style: TextStyle(fontSize: 14, color: Colors.white)
                  ),
                  const SizedBox(height: 10),

                  // !isPickedUp ?
                  // ElevatedButton(
                  //     onPressed: () {
                  //       _determinePosition().then((value) {
                  //         double distance = geolocator.Geolocator.distanceBetween(
                  //             value.latitude,
                  //             value.longitude,
                  //             _driverPoint.coordinates.lat as double,
                  //             _driverPoint.coordinates.lng as double);
                  //
                  //         if(distance <= 100){
                  //           setState(() {
                  //             isPickedUp = true;
                  //           });
                  //         }
                  //       });
                  //     },
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: const Color.fromARGB(255, 255, 107, 74),
                  //       foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  //       padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 80.0),
                  //       textStyle:
                  //       const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  //     ),
                  //     child: const Text("Got picked up",
                  //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),)
                  // ) :
                  // ElevatedButton(
                  //     onPressed: () {},
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: const Color.fromARGB(255, 255, 107, 74),
                  //       foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  //       textStyle:
                  //       const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  //     ),
                  //     child: const Text("Complete Ride",
                  //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),)
                  // ),
                  // const SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: (){
                        polylineAnnotationManager?.deleteAll();
                        pointAnnotationManager?.deleteAll();

                        for (var passenger in pickedUpPassengers) {
                          num lat = num.parse(passenger["startPoint"][0]["lat"]);
                          num lng = num.parse(passenger["startPoint"][0]["lon"]);

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
                  ),
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
