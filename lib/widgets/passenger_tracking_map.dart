import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
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
  MapController? mapController;  // Make nullable
  LatLng? currentLocation;
  StreamSubscription<Position>? _locationStreamSubscription;
  bool _isLoading = true;
  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;

  @override
  void initState() {
    super.initState();
    // Initialize controller after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        mapController = MapController();
      });
      _initializeLocation();
    });
    _alignPositionOnUpdate = AlignOnUpdate.always;
    _alignPositionStreamController = StreamController<double?>();
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
        if (mounted && mapController != null) {
          setState(() {
            currentLocation = LatLng(position.latitude, position.longitude);
            mapController?.move(currentLocation!, mapController!.camera.zoom);
          });
        }
      },
      onError: (e) => print('Location stream error: $e'),
    );
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


  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    _alignPositionStreamController.close();
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
        CurrentLocationLayer(
          rotateAnimationCurve: Curves.easeInOut,
          alignPositionStream: _alignPositionStreamController.stream,
          alignPositionOnUpdate: _alignPositionOnUpdate,
          style: LocationMarkerStyle(
            headingSectorColor: Theme.of(context).primaryColor,
            marker: DefaultLocationMarker(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        MarkerLayer(
          markers: [
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
        Positioned(
          top: 8,
          right: 20,
          width: 42,
          child: FloatingActionButton(
            shape: const CircleBorder(),
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () {
              // Align the location marker to the center of the map widget
              // on location update until user interact with the map.
              setState(
                    () => _alignPositionOnUpdate = AlignOnUpdate.always,
              );
              // Align the location marker to the center of the map widget
              // and zoom the map to level 18.
              _alignPositionStreamController.add(18);
            },
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}