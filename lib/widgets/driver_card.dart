import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';
import 'package:manzil_app_v2/screens/chats_screen.dart';
import 'package:manzil_app_v2/screens/user_chat_screen.dart';

class DriverCard extends ConsumerWidget {
  final Map<String, dynamic> driverInfo;
  final VoidCallback onAccept;
  final bool isAccepting;

  const DriverCard({
    required this.driverInfo,
    required this.onAccept,
    this.isAccepting = false,
    super.key,
  });

  String _getEstimatedTime(double distanceInMeters) {
    // Average speed: 30 km/h = 8.33 m/s
    const averageSpeedInMetersPerSecond = 8.33;

    // Calculate time in seconds
    final timeInSeconds = distanceInMeters / averageSpeedInMetersPerSecond;

    // Convert to minutes
    final minutes = timeInSeconds / 60;

    if (minutes < 1) {
      return "Less than a minute away";
    } else if (minutes < 60) {
      final roundedMinutes = minutes.round();
      return "$roundedMinutes ${roundedMinutes == 1 ? 'minute' : 'minutes'} away";
    } else {
      final hours = minutes / 60;
      final roundedHours = hours.round();
      return "$roundedHours ${roundedHours == 1 ? 'hour' : 'hours'} away";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider);
    final distance = driverInfo["distanceFromPassenger"] as double;
    final estimatedTime = _getEstimatedTime(distance);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverInfo["driverName"] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 45, 45, 45),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            estimatedTime,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "Rs. ${driverInfo["calculatedFare"]}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 45, 45, 45),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.message,
                        color: Color.fromARGB(255, 255, 170, 42),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatsScreen(),
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserChatScreen(
                              currentUser: currentUser,
                              fullName: driverInfo["driverName"] as String,
                              receiverId: driverInfo["driverId"],
                              receiverNumber: driverInfo["driverNumber"],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: isAccepting ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: isAccepting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text("Book"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
