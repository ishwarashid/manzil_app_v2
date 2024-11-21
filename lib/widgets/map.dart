import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../providers/booking_inputs_provider.dart';

class FullMap extends ConsumerStatefulWidget {
  const FullMap({super.key});

  @override
  ConsumerState createState() => FullMapState();
}

class FullMapState extends ConsumerState<FullMap> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;

  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    // Any additional initialization if needed
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    // Add a listener for map tap events
    mapboxMap.setOnMapTapListener(_onMapTapped);
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    box.listenKey("destination_coordinates", (value){

      _addMarker(Point(coordinates: Position(double.parse(value['lon']), double.parse(value['lat']))));

      Map<String, dynamic> pickupPoint = box.read("pickup_coordinates");

      getLineString(pickupPoint["lon"]!, pickupPoint["lat"]!, value["lon"]!, value["lat"]!)
          .then((value){
        PolylineAnnotationOptions polylineAnnotationOptions = PolylineAnnotationOptions(
            geometry: value,
            lineWidth: 6,
            lineColor: Colors.deepOrange.value
        );

        polylineAnnotationManager?.deleteAll();
        polylineAnnotationManager?.create(polylineAnnotationOptions);
      });

      CameraOptions camera = CameraOptions(
        center: Point(coordinates: Position(double.parse(value['lon']), double.parse(value['lat']))),
        zoom: 16,
        bearing: 0,
        pitch: 0,
      );

      MapAnimationOptions mapAnimationOptions = MapAnimationOptions(duration: 1000);
      mapboxMap.flyTo(camera, mapAnimationOptions);

    });
  }

  void _onMapTapped(MapContentGestureContext gestureContext) async {
    final coordinates = gestureContext.point.coordinates;

    getLocationForDestination(coordinates.lng.toString(), coordinates.lat.toString());
    _addMarker(gestureContext.point);

    Map<String, dynamic> pickupPoint = box.read("pickup_coordinates");

    getLineString(pickupPoint["lon"]!, pickupPoint["lat"]!, coordinates.lng.toString(), coordinates.lat.toString())
        .then((value){
      PolylineAnnotationOptions polylineAnnotationOptions = PolylineAnnotationOptions(
        geometry: value,
        lineWidth: 6,
        lineColor: Colors.deepOrange.value
      );

      polylineAnnotationManager?.deleteAll();
      polylineAnnotationManager?.create(polylineAnnotationOptions);

    });
  }

  void _addMarker(Point point) async {

    final ByteData bytes =

        await rootBundle.load('assets/icons/marker.png');

    final Uint8List imageData = bytes.buffer.asUint8List();

    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(

        geometry: Point(coordinates: Position(point.coordinates.lng, point.coordinates.lat)), // Example coordinates

        image: imageData,

        iconSize: 1.5

    );
    await pointAnnotationManager?.deleteAll();
    await pointAnnotationManager?.create(pointAnnotationOptions);
  }

  void getLocation(String longitude, String latitude) async {
    final box = GetStorage();
    String url = "https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&accept-language=en-US";

    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    var geocodedData = jsonDecode(response.body) as Map<String, dynamic>;

    await box.write("pickup_coordinates", {"lat": geocodedData["lat"], "lon": geocodedData["lon"]});
    await box.write("pickup", geocodedData["display_name"]);
  }

  void getLocationForDestination(String longitude, String latitude) async {
    final box = GetStorage();
    String url = "https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&accept-language=en-US";

    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    var geocodedData = jsonDecode(response.body) as Map<String, dynamic>;

    await box.write("destination_coordinates", {"lat": geocodedData["lat"], "lon": geocodedData["lon"]});
    await box.write("destination", geocodedData["display_name"]);
    ref.read(bookingInputsProvider.notifier).setDestination(geocodedData["display_name"]);
  }

  Future<LineString> getLineString(String long1, String lat1, String long2, String lat2) async {

    String url = "https://api.mapbox.com/directions/v5/mapbox/driving/$long1%2C$lat1%3B$long2%2C$lat2?alternatives=false&geometries=geojson&language=en&overview=full&steps=true&access_token=${const String.fromEnvironment("ACCESS_TOKEN")}";

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

  @override
  Widget build(BuildContext context) {
    String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
    MapboxOptions.setAccessToken(accessToken);

    Position position = Position(-98.0, 39.5);

    _determinePosition().then((value) {
      position = Position(value.longitude, value.latitude);
      getLocation(value.longitude.toString(), value.latitude.toString());

      CameraOptions camera = CameraOptions(
        center: Point(coordinates: position),
        zoom: 18,
        bearing: 0,
        pitch: 0,
      );

      MapAnimationOptions mapAnimationOptions = MapAnimationOptions(duration: 1000);

      mapboxMap?.flyTo(camera, mapAnimationOptions);
      mapboxMap?.logo.updateSettings(LogoSettings(
        enabled: false,
      ));
      mapboxMap?.location.updateSettings(LocationComponentSettings(
        puckBearing: PuckBearing.HEADING,
        puckBearingEnabled: true,
        enabled: true,
        locationPuck: LocationPuck(locationPuck2D: DefaultLocationPuck2D()),
      ));
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
          bottom: 100,
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
