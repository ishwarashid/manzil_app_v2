import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';
import 'package:manzil_app_v2/providers/user_ride_providers.dart';
import 'package:manzil_app_v2/screens/home_screen.dart';
import 'package:manzil_app_v2/services/ride/ride_services.dart';
import 'package:manzil_app_v2/widgets/passenger_tracking_map.dart';
import 'package:manzil_app_v2/widgets/ride_rating_dialog.dart';

class PassengerTracking extends ConsumerStatefulWidget {
  const PassengerTracking({super.key});

  @override
  ConsumerState<PassengerTracking> createState() => _PassengerTrackingState();
}

class _PassengerTrackingState extends ConsumerState<PassengerTracking> {
  bool _isProcessing = false;
  bool _isPaying = false;

  final _ridesService = RidesService();

  Future<void> _sendEmergencyAlert(String rideId, String userId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('emergencies').add({
      'pushedBy': userId,
      'rideId': rideId,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> _updateRideStatus(String rideId, String newStatus) async {
    print(newStatus);
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('rides').doc(rideId).update({
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> _cancelRide(String rideId) async {
    try {
      setState(() => _isProcessing = true);
      await _updateRideStatus(rideId, 'cancelled');
      if (mounted) {
        Navigator.of(context).pop(); // Go back to home
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _showPaymentDialog(BuildContext context, String rideId) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.circle,
                color: Colors.amber,
              ),
              title: const Text('Cash'),
              onTap: _isPaying
                  ? null
                  : () async {
                      print("hi");
                      setState(() {
                        _isPaying = true;
                      });

                      await _updateRideStatus(rideId, 'paying');
                      Navigator.of(ctx).pop();

                      setState(() {
                        _isPaying = false;
                      });
                    },
            ),
            ListTile(
              leading: const Icon(
                Icons.circle,
                color: Colors.redAccent,
              ),
              title: const Text('JazzCash'),
              onTap: _isPaying
                  ? null
                  : () async {
                      setState(() {
                        _isPaying = true;
                      });
                      await _updateRideStatus(rideId, 'paying');
                      // Add JazzCash integration here
                      setState(() {
                        _isPaying = false;
                      });
                      Navigator.of(ctx).pop();
                    },
            ),
            ListTile(
              leading: const Icon(
                Icons.circle,
                color: Colors.green,
              ),
              title: const Text('EasyPaisa'),
              onTap: _isPaying
                  ? null
                  : () async {
                      setState(() {
                        _isPaying = true;
                      });
                      await _updateRideStatus(rideId, 'paying');
                      Navigator.of(ctx).pop();

                      // Add EasyPaisa integration here
                      setState(() {
                        _isPaying = false;
                      });
                    },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isPaying ? null : () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRideCompletion(Map<String, dynamic> rideData) async {
    // Show completion alert for 2 seconds
    // if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride Completed Successfully!'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    // if (!mounted) return;

    // Show rating dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RideRatingDialog(
        driverName: rideData['driverName'],
      ),
    );

    // If user didn't skip rating
    if (result != null) {
      try {
        await _ridesService.addRatingAndUpdateDriver(
          rideId: rideData['id'],
          driverId: rideData['selectedDriverId'],
          rating: result['rating'],
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    // Navigate to home screen
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _completeRide(String rideId) async {
    try {
      setState(() => _isProcessing = true);
      await _updateRideStatus(rideId, 'completed');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userRideStatus =
        ref.watch(userRideStatusProvider(currentUser['uid']));

    return Scaffold(
      body: userRideStatus.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (status) {
          final pendingRides = List<Map<String, dynamic>>.from(
              status.activeRidesWithCompleted.where((ride) => ride['status'] != 'completed'))
            ..sort((a, b) =>
                (a['distanceFromPassenger'] as num).compareTo(b['distanceFromPassenger'] as num));

          if (pendingRides.isEmpty) {
            final completedRides = status.activeRidesWithCompleted
                .where((ride) => ride['status'] == 'completed');

            // If there are no completed rides either, go home
            if (completedRides.isEmpty) {
              Future.microtask(() {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                );
              });
              return const Center(child: CircularProgressIndicator());
            }

            // Handle completed ride if exists
            final currentRide = completedRides.first;
            Future.microtask(() => _handleRideCompletion(currentRide));
            return const Center(child: CircularProgressIndicator());
          }

          // Only get here if there are pending rides
          if (!mounted) return const SizedBox();
          final currentRide = pendingRides.first;

          if (currentRide.isEmpty) {
            return const Center(child: Text('No active ride found'));
          }

          final rideStatus = currentRide['status'] as String;

          // When ride is completed, trigger the completion flow
          if (rideStatus == 'completed') {
            // Use Future.microtask to avoid calling setState during build
            Future.microtask(() => _handleRideCompletion(currentRide));
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // Background content or other widgets
              Positioned.fill(
                child: PassengerTrackingMap(
                  ride: currentRide,
                ),
              ),

              // Emergency Button (show only when ride is picked)
              if (rideStatus == 'picked')
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
                        onPressed: () async {
                          try {
                            await _sendEmergencyAlert(
                              currentRide['id'],
                              currentUser['uid'],
                            );
                            if (mounted) {
                              showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  Future.delayed(const Duration(seconds: 2),
                                      () {
                                    Navigator.of(context).pop(true);
                                  });
                                  return const AlertDialog(
                                    title: Text(
                                      "Emergency Alert Sent!",
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    icon: Icon(
                                      Icons.emergency_share_rounded,
                                      size: 30,
                                    ),
                                    iconColor: Colors.redAccent,
                                  );
                                },
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),

              // Bottom Buttons
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      topLeft: Radius.circular(20),
                    ),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _cancelRide(currentRide['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: _isProcessing
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Cancel Ride"),
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (rideStatus == 'accepted')
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () =>
                                _updateRideStatus(currentRide['id'], 'picked'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: const Text("Picked Up"),
                          ),
                        ),
                      if (rideStatus == 'picked')
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () async {
                                    await _showPaymentDialog(
                                        context, currentRide['id']);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 76, 175, 64),
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: _isProcessing
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Complete Ride"),
                          ),
                        ),
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
