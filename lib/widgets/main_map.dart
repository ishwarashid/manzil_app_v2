import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v2/providers/booking_inputs_provider.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';

class MainMap extends ConsumerWidget {
  const MainMap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final bookingInputs = ref.watch(bookingInputsProvider);

    // Get current location from CurrentUserProvider
    final userCoordinates = currentUser['coordinates'] as List?;
    LatLng? currentLocation;
    if (userCoordinates != null && userCoordinates.length == 2) {
      currentLocation = LatLng(
        userCoordinates[0].toDouble(),
        userCoordinates[1].toDouble(),
      );
    }

    // Get pickup location from BookingInputsProvider
    final pickupCoordinates = bookingInputs['pickupCoordinates'] as List?;
    LatLng? pickupLocation;
    if (pickupCoordinates != null && pickupCoordinates.length == 2) {
      pickupLocation = LatLng(
        pickupCoordinates[0].toDouble(),
        pickupCoordinates[1].toDouble(),
      );
    }

    // Get destination from BookingInputsProvider
    final destinationCoordinates = bookingInputs['destinationCoordinates'] as List?;
    LatLng? destinationLocation;
    if (destinationCoordinates != null && destinationCoordinates.length == 2) {
      destinationLocation = LatLng(
        destinationCoordinates[0].toDouble(),
        destinationCoordinates[1].toDouble(),
      );
    }

    return currentLocation == null
        ? const Center(child: CircularProgressIndicator())
        : FlutterMap(
      options: MapOptions(
        initialCenter: currentLocation,
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
            // Current location marker
            if (currentLocation != null)
              Marker(
                point: currentLocation,
                width: 80,
                height: 80,
                child: const Column(
                  children: [
                    Icon(
                      Icons.my_location,
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

            // Pickup location marker (only if different from current location)
            if (pickupLocation != null &&
                (pickupLocation.latitude != currentLocation.latitude ||
                    pickupLocation.longitude != currentLocation.longitude))
              Marker(
                point: pickupLocation,
                width: 80,
                height: 80,
                child: const Column(
                  children: [
                    Icon(
                      Icons.trip_origin,
                      color: Colors.green,
                      size: 30,
                    ),
                    Text(
                      'Pickup',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Destination marker
            if (destinationLocation != null)
              Marker(
                point: destinationLocation,
                width: 80,
                height: 80,
                child: const Column(
                  children: [
                    Icon(
                      Icons.location_on,
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