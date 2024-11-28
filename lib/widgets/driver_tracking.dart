import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';
import 'package:manzil_app_v2/providers/user_ride_providers.dart';
import 'package:manzil_app_v2/screens/home_screen.dart';

class DriverTracking extends ConsumerStatefulWidget {
  const DriverTracking({super.key});

  @override
  ConsumerState<DriverTracking> createState() => _DriverTrackingState();
}

class _DriverTrackingState extends ConsumerState<DriverTracking> {
  bool _isProcessing = false;

  Future<void> _sendEmergencyAlert(String rideId, String userId) async {
    await FirebaseFirestore.instance.collection('emergencies').add({
      'pushedBy': userId,
      'rideId': rideId,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> _updateRideStatus(String rideId, String newStatus) async {
    await FirebaseFirestore.instance.collection('rides')
        .doc(rideId)
        .update({
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> _showPaymentConfirmDialog(BuildContext context, String rideId) async {
    print("Inside Dialog");
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: const Text('Has the passenger paid the fare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop(true);
              await _updateRideStatus(rideId, 'completed');
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userRideStatus = ref.watch(userRideStatusProvider(currentUser['uid']));

    return Scaffold(
      body: userRideStatus.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (status) {

          // Sort rides by distance
          final pendingRides = List<Map<String, dynamic>>.from(
              status.activeRides.where((ride) =>
              ride['status'] != 'completed' &&
                  ride['status'] != 'cancelled'
              )
          )..sort((a, b) => (a['distance'] as num).compareTo(b['distance'] as num));

          if (pendingRides.isEmpty) {
            Future.microtask(() {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          final currentRide = pendingRides.first;
          final rideStatus = currentRide['status'];

          // Use Future.microtask for dialog
          if (rideStatus == 'paying') {
            Future.microtask(() {
              if (!mounted) return;
              _showPaymentConfirmDialog(context, currentRide['id']);
            });
          }

          return Stack(
            children: [
              const Positioned.fill(
                child: SizedBox(), // Replace with map widget
              ),
              Positioned(
                bottom: 220,
                left: 20,
                child: Builder(
                  builder: (context) => CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.redAccent,
                    child: IconButton(
                      icon: Icon(
                        Icons.emergency_share_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 30,
                      ),
                      onPressed: () => _sendEmergencyAlert(
                        currentRide['id'],
                        currentUser['uid'],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      topLeft: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentRide['passengerName'],
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Colors.white
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentRide['destination'],
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Colors.white
                        ),
                      ),
                      // const SizedBox(height: 20),
                      // if (rideStatus == 'accepted')
                      //   SizedBox(
                      //     width: double.infinity,
                      //     height: 50,
                      //     child: ElevatedButton(
                      //       onPressed: _isProcessing ? null : () =>
                      //           _updateRideStatus(currentRide['id'], 'picked'),
                      //       style: ElevatedButton.styleFrom(
                      //         backgroundColor: Colors.amber,
                      //         foregroundColor: Colors.white,
                      //       ),
                      //       child: const Text('Picked Up'),
                      //     ),
                      //   ),
                      // if (rideStatus == 'picked')
                      //   SizedBox(
                      //     width: double.infinity,
                      //     height: 50,
                      //     child: ElevatedButton(
                      //       onPressed: _isProcessing ? null : () =>
                      //           _updateRideStatus(currentRide['id'], 'paying'),
                      //       style: ElevatedButton.styleFrom(
                      //         backgroundColor: Colors.green,
                      //         foregroundColor: Colors.white,
                      //       ),
                      //       child: const Text('Complete Ride'),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}