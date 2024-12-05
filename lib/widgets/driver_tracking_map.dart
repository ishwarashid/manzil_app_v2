import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:manzil_app_v2/services/route/route_monitoring_service.dart';

class DriverTrackingMap extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> rides;
  final String driverId;

  const DriverTrackingMap({
    required this.rides,
    required this.driverId,
    super.key,
  });

  @override
  ConsumerState<DriverTrackingMap> createState() => _DriverTrackingMapState();
}

class _DriverTrackingMapState extends ConsumerState<DriverTrackingMap> {
  final mapController = MapController();
  LatLng? currentLocation;
  StreamSubscription<Position>? _locationStreamSubscription;
  Timer? _databaseUpdateTimer;

  @override
  void initState() {
    super.initState();
    ref.read(routeMonitoringProvider.notifier).setContext(context);
    _checkAndRequestPermissions();
  }

  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    _databaseUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(DriverTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Instead of directly calling startMonitoring, schedule it for the next frame
    if (currentLocation != null && widget.rides != oldWidget.rides) {
      // Use microtask to ensure we're not in a build phase
      Future.microtask(() {
        if (!mounted) return;
        final position = Position(
          latitude: currentLocation!.latitude,
          longitude: currentLocation!.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        ref.read(routeMonitoringProvider.notifier).startMonitoring(
          widget.rides,
          position,
        );
      });
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    _initializeLocation();
    _startLocationStream();
    _startDatabaseUpdates();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        mapController.move(currentLocation!, 15);
      });

      // Start monitoring only once during initialization
      if (widget.rides.isNotEmpty) {
        ref.read(routeMonitoringProvider.notifier).startMonitoring(
          widget.rides,
          position,
        );
      }
    } catch (e) {
      print('Error getting initial location: $e');
    }
  }

  // Update this in DriverTrackingMap
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
        });

        // Change this to startMonitoring
        if (widget.rides.isNotEmpty) {
          ref.read(routeMonitoringProvider.notifier).startMonitoring(
            widget.rides,
            position,
          );
        }
      },
      onError: (e) => print('Location stream error: $e'),
    );
  }

  void _startDatabaseUpdates() {
    _databaseUpdateTimer = Timer.periodic(
      const Duration(seconds: 10), // 2 mins after testing
          (_) => _updateDriverLocationInDatabase(),
    );
  }

  Future<void> _updateDriverLocationInDatabase() async {
    if (currentLocation == null) return;

    try {
      // Only proceed with updates if there are accepted rides
      final acceptedRides = widget.rides.where((ride) => ride['status'] == 'accepted').toList();
      if (acceptedRides.isEmpty) return;

      final locationText = await _getAddressFromCoordinates(
          currentLocation!.latitude,
          currentLocation!.longitude
      );

      final batch = FirebaseFirestore.instance.batch();

      for (final ride in acceptedRides) {
        final rideRef = FirebaseFirestore.instance
            .collection('rides')
            .doc(ride['id']);

        batch.update(rideRef, {
          'driverLocation': locationText,
          'driverCoordinates': [currentLocation!.latitude, currentLocation!.longitude],
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
      print('Successfully updated driver location for ${acceptedRides.length} rides');
    } catch (e) {
      print('Error updating location in database: $e');
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lon) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&accept-language=en-US&lat=$lat&lon=$lon&zoom=18&addressdetails=1'
    );

    final response = await http.get(
        url,
        headers: {'Accept': 'application/json'}
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'];
    } else {
      throw Exception('Failed to get address');
    }
  }


  @override
  Widget build(BuildContext context) {
    print('Building map with current location: $currentLocation');
    print('Number of rides: ${widget.rides.length}');

    final center = currentLocation ?? const LatLng(24.8607, 67.0011);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          tileProvider: CancellableNetworkTileProvider(),
          userAgentPackageName: 'com.example.manzil_app',
        ),
        if (currentLocation != null || widget.rides.isNotEmpty)
          MarkerLayer(
            markers: [
              if (currentLocation != null)
                Marker(
                  point: currentLocation!,
                  width: 80,
                  height: 80,
                  child: const Column(
                    children: [
                      Icon(
                        Icons.directions_car,
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
              ...widget.rides.expand((ride) {
                final markers = <Marker>[];
                print('Processing ride: ${ride['id']}');

                if (ride['status'] != 'picked' &&
                    ride['pickupCoordinates'] != null &&
                    (ride['pickupCoordinates'] as List).length >= 2) {
                  print(ride['status']);
                  final pickupCoords = ride['pickupCoordinates'] as List;
                  markers.add(
                    Marker(
                      point: LatLng(pickupCoords[0], pickupCoords[1]),
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 30,
                          ),
                          Text(
                            '${ride['passengerName']} Pickup',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (ride['destinationCoordinates'] != null &&
                    (ride['destinationCoordinates'] as List).length >= 2) {
                  final destCoords = ride['destinationCoordinates'] as List;
                  markers.add(
                    Marker(
                      point: LatLng(destCoords[0], destCoords[1]),
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.flag,
                            color: Colors.red,
                            size: 30,
                          ),
                          Text(
                            '${ride['passengerName']} Dest.',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return markers;
              }),
            ],
          ),
      ],
    );
  }
}


