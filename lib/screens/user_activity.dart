import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';
import 'package:intl/intl.dart';

// Provider to determine if user is a driver based on ride history
final isDriverProvider = FutureProvider.autoDispose((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser['uid'] as String;

  // Check if user has any accepted rides as a driver
  final driverRidesQuery = await FirebaseFirestore.instance
      .collection('rides')
      .where('selectedDriverId', isEqualTo: userId)
      .where('status', isEqualTo: 'accepted')
      .limit(1)
      .get();

  // If they have rides as a driver, they're a driver
  if (driverRidesQuery.docs.isNotEmpty) {
    return true;
  }

  // Check if user has any rides as a passenger
  final passengerRidesQuery = await FirebaseFirestore.instance
      .collection('rides')
      .where('passengerID', isEqualTo: userId)
      .where('status', whereIn: ['completed', 'cancelled'])
      .limit(1)
      .get();

  // If they have rides as a passenger, they're a passenger
  if (passengerRidesQuery.docs.isNotEmpty) {
    return false;
  }

  // If no history found, we'll consider them a passenger by default
  return false;
});

class UserActivityScreen extends ConsumerWidget {
  const UserActivityScreen({super.key});

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  Widget _buildRideCard(
      BuildContext context, Map<String, dynamic> ride, bool isDriver) {
    final status = ride['status'] as String;
    final isAccepted = status == 'accepted';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAccepted
                        ? "Ride booked ${_formatTimestamp(ride['acceptedAt'])}"
                        : "Ride booked ${_formatTimestamp(ride['createdAt'])}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color.fromRGBO(30, 60, 87, 1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAccepted
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.capitalize(),
                    style: TextStyle(
                      color: isAccepted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color.fromARGB(255, 255, 107, 74),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    ride["pickupLocation"] as String,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.navigation,
                  color: Color.fromARGB(255, 255, 170, 42),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    ride["destination"] as String,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  isDriver ? Icons.person : Icons.drive_eta_rounded,
                  color: isAccepted
                      ? const Color.fromRGBO(30, 60, 87, 1)
                      : Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    isDriver
                        ? (ride['passengerName'] ?? 'Unknown Passenger')
                        : (ride['selectedDriverName'] ?? 'Yet to be confirmed'),
                    style: TextStyle(
                      fontSize: 16,
                      color: isAccepted
                          ? const Color.fromRGBO(30, 60, 87, 1)
                          : Theme.of(context).colorScheme.secondary,
                      fontWeight: isAccepted ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                Text(
                  'Rs. ${ride['finalFare'] ?? ride['offeredFare']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(30, 60, 87, 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getRidesStream(
      String userId, bool isDriver) {
    if (isDriver) {
      // Get rides where user is the driver and status is 'accepted'
      return FirebaseFirestore.instance
          .collection('rides')
          .where('selectedDriverId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList());
    } else {
      // Get rides where user is the passenger and status is pending or accepted
      return FirebaseFirestore.instance
          .collection('rides')
          .where('passengerID', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted'])
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isDriverAsync = ref.watch(isDriverProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Current Activity",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color.fromRGBO(30, 60, 87, 1),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 165,
            height: 4,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(30, 60, 87, 1),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isDriverAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (isDriver) => StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getRidesStream(currentUser['uid'], isDriver),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final rides = snapshot.data ?? [];

                  if (rides.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 300,
                            child: Image.asset(
                              'assets/images/no_activity_illustration.png',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No activity yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                  color: const Color.fromRGBO(30, 60, 87, 1),
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: rides.length,
                    itemBuilder: (context, index) => _buildRideCard(
                      context,
                      rides[index],
                      isDriver,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
