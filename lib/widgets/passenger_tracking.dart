import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';
import 'package:manzil_app_v2/providers/user_ride_providers.dart';
import 'package:manzil_app_v2/screens/chats_screen.dart';
import 'package:manzil_app_v2/screens/find_drivers.dart';
import 'package:manzil_app_v2/screens/home_screen.dart';
import 'package:manzil_app_v2/services/ride/ride_services.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';
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
    if (!mounted) return;

    try {
      setState(() => _isProcessing = true);
      await _updateRideStatus(rideId, 'cancelled');

      // Store context before navigation
      final navigatorContext = context;

      // Show success message
      ScaffoldMessenger.of(navigatorContext).showSnackBar(
        const SnackBar(
          content: Text('Ride cancelled successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Reset processing state before navigation
      if (mounted) {
        setState(() => _isProcessing = false);
      }

      // Navigate after resetting state
      if (mounted) {
        Navigator.of(navigatorContext).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel ride: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showPaymentDialog(BuildContext context, Map<String, dynamic> ride) async {
    print(ride['status']);
    print("payment dialog");
    final paymentMethod = ride['paymentMethod'] as String? ?? 'cash';
    final formattedPaymentMethod = paymentMethod[0].toUpperCase() + paymentMethod.substring(1);

    // First update the status to paying
    await _updateRideStatus(ride['id'], 'paying');

    // Show alert dialog
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          // Auto dismiss after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
            }
          });

          return AlertDialog(
            title: const Text('Make Payment'),
            content: Text(
              'Please pay Rs. ${ride['calculatedFare']} through $formattedPaymentMethod to your driver.',
            ),
          );
        },
      );
    }
  }

  Future<void> _handleRideCompletion(Map<String, dynamic> rideData) async {
    if (!mounted) return;

    // Store context reference
    final navigatorContext = context;

    // Show completion snackbar
    ScaffoldMessenger.of(navigatorContext).showSnackBar(
      const SnackBar(
        content: Text('Ride Completed Successfully!'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Show rating dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (ctx) => RideRatingDialog(
        driverName: rideData['driverName'],
      ),
    );

    // If user rated the ride
    if (result != null && mounted) {
      try {
        await _ridesService.addRatingAndUpdateDriver(
          rideId: rideData['id'],
          driverId: rideData['selectedDriverId'],
          rating: result['rating'],
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Theme.of(navigatorContext).colorScheme.error,
          ),
        );
      }
    }

    // Navigate to home screen
    if (!mounted) return;
    Navigator.of(navigatorContext).pushAndRemoveUntil(
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

  void _setScreen(String identifier, {bool? isDriver}) async {
    Navigator.of(context).pop();
    if (identifier == 'chats') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const ChatsScreen(),
        ),
      );
    } else if (identifier == 'foundDrivers') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const FindDrivers(),
        ),
      );
    } else if (identifier == 'home') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userRideStatus =
    ref.watch(userRideStatusProvider(currentUser['uid']));

    return Scaffold(
      drawer: MainDrawer(
        onSelectScreen: _setScreen,
      ),
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

            if (completedRides.isEmpty) {
              // Use a single navigation call
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                  );
                }
              });
              return const SizedBox(); // Return empty widget instead of loading
            }

            // Handle completed ride if exists
            final currentRide = completedRides.first;
            if (mounted) {
              Future.microtask(() {
                if (mounted) {
                  _handleRideCompletion(currentRide);
                }
              });
            }
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
                      if (rideStatus == 'paying') ...[
                        const Icon(
                          Icons.payments_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Payment in Progress',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please make the payment to complete your ride',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (rideStatus == 'accepted' || rideStatus == 'picked') ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _cancelRide(currentRide['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: _isProcessing
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Cancel Ride"),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                      if (rideStatus == 'accepted')
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _updateRideStatus(currentRide['id'], 'picked'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                              await _showPaymentDialog(context, currentRide);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 76, 175, 64),
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: _isProcessing
                                ? const CircularProgressIndicator(color: Colors.white)
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