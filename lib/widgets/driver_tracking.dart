import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';
import 'package:manzil_app_v2/screens/home_screen.dart';
import 'package:manzil_app_v2/widgets/driver_tracking_map.dart';

class DriverTracking extends ConsumerStatefulWidget {
  const DriverTracking({
    super.key,
  });

  @override
  ConsumerState<DriverTracking> createState() => _DriverTrackingState();
}

class _DriverTrackingState extends ConsumerState<DriverTracking> {
  bool _isProcessing = false;
  String? _processingRideId;

  Stream<List<Map<String, dynamic>>> getRidesStream(String driverId) {
    return FirebaseFirestore.instance
        .collection('rides')
        .where('selectedDriverId', isEqualTo: driverId)
        .where('status', whereIn: ['accepted', 'picked', 'paying'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  Future<void> _sendEmergencyAlert(String rideId, String driverId) async {
    await FirebaseFirestore.instance.collection('emergencies').add({
      'pushedBy': driverId,
      'rideId': rideId,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> _updateRideStatus(String rideId, String newStatus) async {
    try {
      setState(() {
        _isProcessing = true;
        _processingRideId = rideId;
      });

      await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingRideId = null;
        });
      }
    }
  }

  Future<void> _deleteChatRoom(String driverId, String passengerId) async {
    try {
      // Create chatRoomId using the same logic
      List<String> ids = [driverId, passengerId];
      ids.sort();
      String chatRoomId = ids.join("_");

      // Delete the chat room
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .delete();

      print('Chat room deleted: $chatRoomId');
    } catch (e) {
      print('Error deleting chat room: $e');
    }
  }

  Future<void> _showPaymentConfirmDialog(
      BuildContext context, Map<String, dynamic> ride) async {
    if (_processingRideId == ride['id']) return;

    print("Showing payment dialog for ride: ${ride['id']}");

    final paymentMethod = ride['paymentMethod'] as String? ?? 'cash';
    final formattedPaymentMethod = paymentMethod[0].toUpperCase() + paymentMethod.substring(1);

    // Store ScaffoldMessenger reference
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Future<void> reportFraud() async {
      try {
        // Create a local copy of all operations
        final Future<void> statusUpdate = _updateRideStatus(ride['id'], 'completed');
        final Future<void> fraudReport = FirebaseFirestore.instance.collection('frauds').add({
          'fraudUserId': ride['passengerID'],
          'rideId': ride['id'],
          'reason': 'payment',
          'timestamp': Timestamp.now(),
        });
        final Future<void> chatRoomDeletion = _deleteChatRoom(
          ride['selectedDriverId'],
          ride['passengerID'],
        );

        // Wait for all operations to complete
        await Future.wait([statusUpdate, fraudReport, chatRoomDeletion]);

        if (mounted) {
          Future.microtask(() {
            try {
              scaffoldMessenger.clearSnackBars();
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Fraud report submitted'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            } catch (e) {
              print('Error showing snackbar: $e');
            }
          });
        }
      } catch (e) {
        print('Error reporting fraud: $e');
        if (mounted) {
          Future.microtask(() {
            try {
              scaffoldMessenger.clearSnackBars();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Error reporting fraud: $e'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            } catch (e) {
              print('Error showing error snackbar: $e');
            }
          });
        }
      }
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Method: $formattedPaymentMethod'),
            const SizedBox(height: 16),
            const Text('Has the passenger paid the fare?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Future.microtask(() {
                if (mounted) {
                  reportFraud();
                }
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Future.microtask(() async {
                if (mounted) {
                  await _updateRideStatus(ride['id'], 'completed');
                  await _deleteChatRoom(
                    ride['selectedDriverId'], // Current driver's ID
                    ride['passengerID'], // Passenger's ID
                  );
                }
              });
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

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getRidesStream(currentUser['uid']),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rides = snapshot.data ?? [];
          print("All rides length: ${rides.length}");
          for (var ride in rides) {
            print(
                "Ride ${ride['id']}: ${ride['destination']} - ${ride['status']}");
          }

          // Sort rides by distance
          final pendingRides = List<Map<String, dynamic>>.from(rides)
            ..sort((a, b) => (a['distanceFromPassenger'] as num)
                .compareTo(b['distanceFromPassenger'] as num));

          if (pendingRides.isEmpty) {
            // Use microtask for navigation
            Future.microtask(() {
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          // Add this check before accessing first element
          if (!mounted || pendingRides.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentRide = pendingRides.first;
          final rideStatus = currentRide['status'];

          print(
              "Current ride: ${currentRide['id']} - ${currentRide['status']}");

          if (rideStatus == 'paying' && !_isProcessing) {
            print("Showing payment dialog for current ride");
            Future.microtask(() {
              if (!mounted) return;
              _showPaymentConfirmDialog(context, currentRide);
            });
          }

          return Stack(
            children: [
              Positioned.fill(
                child: DriverTrackingMap(
                  rides: pendingRides,
                  driverId: currentUser['uid'],
                ),
              ),
              Positioned(
                bottom: 220,
                left: 20,
                child: CircleAvatar(
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
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentRide['destination'],
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(color: Colors.white),
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
