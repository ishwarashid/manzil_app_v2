import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class PassengerTrackingMap extends ConsumerStatefulWidget {
  final Map<String, dynamic> ride;

  const PassengerTrackingMap({
    required this.ride,
    super.key,
  });

  @override
  ConsumerState<PassengerTrackingMap> createState() => _PassengerTrackingMapState();
}

class _PassengerTrackingMapState extends ConsumerState<PassengerTrackingMap> {
  final mapController = MapController();
  LatLng? currentLocation;
  StreamSubscription<Position>? _locationStreamSubscription;
  bool _isLoading = true;  // Add loading state

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          print('Location permissions denied');
          return;
        }
      }

      // Get initial position
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Start streaming location updates
      _startLocationStream();
    } catch (e) {
      print('Error initializing location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
          (Position position) {
        setState(() {
          currentLocation = LatLng(position.latitude, position.longitude);
          mapController.move(currentLocation!, mapController.camera.zoom);
        });
      },
      onError: (e) => print('Location stream error: $e'),
    );
  }

  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final rideStatus = widget.ride['status'] as String;
    final driverCoordinates = widget.ride['driverCoordinates'] as List?;
    final destinationCoordinates = widget.ride['destinationCoordinates'] as List;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentLocation!,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          tileProvider: CancellableNetworkTileProvider(),
          userAgentPackageName: 'com.example.manzil_app',
        ),
        MarkerLayer(
          markers: [
            // Passenger's current location
            Marker(
              point: currentLocation!,
              width: 80,
              height: 80,
              child: const Column(
                children: [
                  Icon(
                    Icons.person_pin_circle,
                    color: Colors.blue,
                    size: 30,
                  ),
                  Text(
                    'You',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Driver's location
            if (rideStatus != 'picked' &&
                driverCoordinates != null &&
                driverCoordinates.length >= 2)
              Marker(
                point: LatLng(driverCoordinates[0], driverCoordinates[1]),
                width: 80,
                height: 80,
                child: Column(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      color: Colors.green,
                      size: 30,
                    ),
                    Text(
                      widget.ride['driverName'] ?? 'Driver',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Destination marker
            Marker(
              point: LatLng(destinationCoordinates[0], destinationCoordinates[1]),
              width: 80,
              height: 80,
              child: const Column(
                children: [
                  Icon(
                    Icons.flag,
                    color: Colors.red,
                    size: 30,
                  ),
                  Text(
                    'Destination',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}