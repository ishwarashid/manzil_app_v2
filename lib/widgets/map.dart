import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class FullMap extends StatefulWidget {
  const FullMap({super.key});

  @override
  State createState() => FullMapState();
}

class FullMapState extends State<FullMap> {
  MapboxMap? mapboxMap;

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
  }

  @override
  Widget build(BuildContext context) {
    String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
    MapboxOptions.setAccessToken(accessToken);

    Position position = Position(-98.0, 39.5);

     _determinePosition().then((value) {
      position = Position(value.longitude, value.latitude);
      print("${position.lat} ${position.lng}");

      CameraOptions camera = CameraOptions(
          center: Point(coordinates: position),
          zoom: 18,
          bearing: 0,
          pitch: 0);

      MapAnimationOptions mapAnimationOptions = MapAnimationOptions(duration: 1000);

      mapboxMap?.flyTo(camera, mapAnimationOptions);

      mapboxMap?.logo.updateSettings(LogoSettings(
        enabled: false
      ));

      mapboxMap?.location.updateSettings(LocationComponentSettings(
          puckBearing: PuckBearing.HEADING,
          puckBearingEnabled: true,
          enabled: true,
          locationPuck: LocationPuck(
              locationPuck2D: DefaultLocationPuck2D())));

    });

    return Scaffold(
        body: MapWidget(
          key: const ValueKey("mapWidget"),
          onMapCreated: _onMapCreated,
        ));
  }
}

Future<geolocator.Position> _determinePosition() async {
  geolocator.LocationPermission permission;

  // if (!serviceEnabled) {
  //   // Location services are not enabled don't continue
  //   // accessing the position and request users of the
  //   // App to enable the location services.
  //   return Future.error('Location services are disabled.');
  // }

  permission = await geolocator.Geolocator.checkPermission();
  if (permission == geolocator.LocationPermission.denied) {
    permission = await geolocator.Geolocator.requestPermission();
    if (permission == geolocator.LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == geolocator.LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await geolocator.Geolocator.getCurrentPosition();
}
