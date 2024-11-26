import 'package:flutter/material.dart';

class UserActivityScreen extends StatelessWidget {
  const UserActivityScreen({super.key});

  final hasBookedRide = true;
  final hasConfirmedDriver = true;

  @override
  Widget build(BuildContext context) {
    Widget activity = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            child: Image.asset(
              'assets/images/no_activity_illustration.png',
            ),
          ),
        ],
      ),
    );

    if (hasBookedRide) {
      activity = SingleChildScrollView(
        child: Column(
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "You booked a ride at 2pm today",
                      style: TextStyle(
                          fontSize: 18,
                          color: Color.fromRGBO(30, 60, 87, 1),
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Color.fromARGB(255, 255, 107, 74),
                        ),
                        SizedBox(width: 5),
                        Text(
                          "Tariq Bin Ziad Colony",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(
                          Icons.navigation,
                          color: Color.fromARGB(255, 255, 170, 42),
                        ),
                        SizedBox(width: 5),
                        Text(
                          "Comsats University Sahiwal",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.drive_eta_rounded,
                          color: hasConfirmedDriver
                              ? const Color.fromRGBO(30, 60, 87, 1)
                              : Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasConfirmedDriver
                              ? "Haider Ali"
                              : "Yet to be confirmed",
                          style: TextStyle(
                              fontSize: 16,
                              color: hasConfirmedDriver
                                  ? const Color.fromRGBO(30, 60, 87, 1)
                                  : Theme.of(context).colorScheme.secondary,
                              fontWeight: hasConfirmedDriver
                                  ? FontWeight.w600
                                  : null),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

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
          const SizedBox(
            height: 6,
          ),
          Container(
            width: 165,
            height: 4,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(30, 60, 87, 1),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(child: activity),
          // Use Expanded to center activity in the remaining space
        ],
      ),
    );
  }
}
