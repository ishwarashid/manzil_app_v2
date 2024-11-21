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
import 'package:manzil_app_v2/services/socket_handler.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

class FullPassengerMap extends ConsumerStatefulWidget {
  const FullPassengerMap({super.key});

  @override
  ConsumerState createState() => FullPassengerMapState();
}

class FullPassengerMapState extends ConsumerState<FullPassengerMap> {
  MapboxMap? mapboxMap;

  bool isPickedUp = false;

  PointAnnotationManager? pointAnnotationManager;

  final box = GetStorage();
  Point _driverPoint = Point(coordinates: Position(0.0, 0.0));

  double _azimuth = 0.0;
  double _previousAzimuth = 0.0;
  final double _threshold = 5.0; // Set your threshold (in degrees)
  Timer? _debounceTimer;

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
    SocketHandler.socket.on("Driver_Location", (value) {
      if (box.read("_id") != value["id"] && !isPickedUp) {
        _driverPoint =  Point(
            coordinates:
            Position(value["lng"] as num, value["lat"] as num));

        _addDriverLocation(
            _driverPoint,
            value["rotation"] as double);
      }
    });

    gyroscopeEventStream().listen((GyroscopeEvent event) {
      setStateIfSignificantRotation(event);
    });

    super.initState();
    // Any additional initialization if needed
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

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
    });
  }

  void _addDriverLocation(Point point, double rotation) async {

    Uint8List imageData = await getImageData();

    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(
            coordinates: Position(point.coordinates.lng,
                point.coordinates.lat)), // Example coordinates

        image: imageData,
        iconSize: 1.5,
        iconRotate: rotation);
    await pointAnnotationManager?.deleteAll();
    await pointAnnotationManager?.create(pointAnnotationOptions);
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

    List.from(geocodedData["routes"][0]["geometry"]["coordinates"])
        .map((position) {
      coordinates.add(Position(position[0], position[1]));
    });

    return LineString(coordinates: coordinates);
  }

  Future<Uint8List> getImageData() async {
    final ByteData bytes = await rootBundle.load('assets/icons/driver.png');

    final Uint8List imageData = bytes.buffer.asUint8List();

    return imageData;
  }

  Future<dynamic> getUser() async {
    const url = "https://shrimp-select-vertically.ngrok-free.app";
    var phone = box.read("phoneNumber");
    String phoneEncoded = Uri.encodeQueryComponent(phone);
    final response = await http.get(
      Uri.parse('$url/users?phoneNumber=$phoneEncoded'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    final usersData = jsonDecode(response.body) as Map<String, dynamic>;
    final user = usersData['data'];
    return user;

  }

  void cancelRide() async {
    const url = "https://shrimp-select-vertically.ngrok-free.app";

    await http.post(
      Uri.parse('$url/cancel-ride'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "userId": box.read("_id")
      }),
    );
  }


  @override
  Widget build(BuildContext context) {
    LocationPuck2D locationPuck2D = DefaultLocationPuck2D();

    getImageData().then((image){
      locationPuck2D = isPickedUp ? LocationPuck2D(topImage: image, bearingImage: image)  : DefaultLocationPuck2D();
    });

    String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
    MapboxOptions.setAccessToken(accessToken);

    Position position = Position(-98.0, 39.5);

    _determinePosition().then((value) {
      position = Position(value.longitude, value.latitude);

      mapboxMap?.location.updateSettings(LocationComponentSettings(
        puckBearing: PuckBearing.HEADING,
        puckBearingEnabled: true,
        enabled: true,
        locationPuck: LocationPuck(locationPuck2D: locationPuck2D),
      ));

      SocketHandler.socket.emit("User_Location", {
        "id": box.read("_id"),
        "lat": value.latitude,
        "lng": value.longitude,
        "rotation": _azimuth
      });
    });

    getUser().then((user){
      if(user["isPickedUp"].toString() == "true"){
        setState(() {
          isPickedUp = true;
        });
      }
      else{
        setState(() {
          isPickedUp = true;
        });
      }
    });

    return Stack(
      children: [
        Scaffold(
          body: MapWidget(
            key: const ValueKey("mapWidget"),
            onMapCreated: _onMapCreated,
          ),
        ),
        if(_driverPoint.coordinates.every((coordinate){ return coordinate != 0; }))
          Positioned(
            bottom: 320,
            right: 20,
            child: Builder(
              builder: (context) =>
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                    child: IconButton(
                      icon: Icon(
                        Icons.directions_car,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .onPrimary,
                        size: 30,
                      ),
                      onPressed: () {
                        position = Position(_driverPoint.coordinates.lng,
                            _driverPoint.coordinates.lat);

                        CameraOptions camera = CameraOptions(
                          center: Point(coordinates: position),
                          zoom: 18,
                          bearing: 0,
                          pitch: 0,
                        );

                        MapAnimationOptions mapAnimationOptions =
                        MapAnimationOptions(duration: 1000);

                        mapboxMap?.flyTo(camera, mapAnimationOptions);
                      },
                    ),
                  ),
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
                    position = Position(value.longitude, value.latitude);

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
                   const Text("The driver is coming to pick you up",
                       style: TextStyle(fontSize: 18, color: Colors.white)
                   ),
                  const SizedBox(height: 10),
                  const Text("2 mins away",
                      style: TextStyle(fontSize: 14, color: Colors.white)
                  ),
                  const SizedBox(height: 10),

                  !isPickedUp ?
                  ElevatedButton(
                      onPressed: () {
                        _determinePosition().then((value) {
                          double distance = geolocator.Geolocator.distanceBetween(
                              value.latitude,
                              value.longitude,
                              _driverPoint.coordinates.lat as double,
                              _driverPoint.coordinates.lng as double);

                          if(distance <= 10000000){
                            setState(() {
                              isPickedUp = true;
                            });
                            SocketHandler.socket.emit("Picked Up", box.read("_id"));
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 107, 74),
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 80.0),
                        textStyle:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      child: const Text("Got picked up",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),)
                  ) :
                  ElevatedButton(
                      onPressed: () {
                        SocketHandler.socket.emit("Completed Ride", box.read("_id"));
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 107, 74),
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 80.0),
                        textStyle:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      child: const Text("Complete Ride",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),)
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: (){
                        cancelRide();
                        box.write("isBooked", false);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 107, 74),
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 80.0),
                        textStyle:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      child: const Text("Cancel Ride",
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
