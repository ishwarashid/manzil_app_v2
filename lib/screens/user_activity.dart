import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';
import 'package:intl/intl.dart';
import 'package:manzil_app_v2/providers/user_ride_providers.dart';



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
    final isAccepted = status == 'accepted' || status == 'picked' || ride['status'] == 'paying';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser['uid'] as String;
    final userRideStatus = ref.watch(userRideStatusProvider(userId));

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
            child: userRideStatus.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (status) {
                final rides = status.activeRides;

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
                          status.isDriver
                              ? 'No active rides'
                              : 'No ride requests',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
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
                    status.isDriver,
                  ),
                );
              },
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


