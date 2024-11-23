import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class UserActivityScreen extends StatelessWidget {
  UserActivityScreen({super.key});

  ///////////////////////////////////
  // HAVE TO GET THESE DYNAMICALLY//
  /////////////////////////////////
  final hasBookedRide = true;
  final hasConfirmedDriver = true;
  final box = GetStorage();
  ////////////////////////////////////////
  // AND ALSO CURRENTLY BOOKED RIDE DATA//
  ///////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    Widget activity;

    if (box.read("canNavigate") == null && !box.read("canNavigate")) {
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
                    Text(
                      "You have ${box.read("hasRequested") ? "Requested" : "Booked"} a ride",
                      style: const TextStyle(
                          fontSize: 18,
                          color: Color.fromRGBO(30, 60, 87, 1),
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color.fromARGB(255, 255, 107, 74),
                        ),
                        const SizedBox(width: 5),
                        Text(
                            box.read("pickup") != null ? box.read("pickup").toString() : "No pickup location",
                          style: const TextStyle(fontSize: 16),
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
                        Text(
                          box.read("destination") != null ? box.read("destination").toString() : "No destination location",
                          style: const TextStyle(fontSize: 16),
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
                            box.read("driver_name") ?? "Yet to be confirmed",
                          style: TextStyle(
                              fontSize: 16,
                              color: hasConfirmedDriver
                                  ? const Color.fromRGBO(30, 60, 87, 1)
                                  : Theme.of(context).colorScheme.secondary,
                              fontWeight:
                                  hasConfirmedDriver ? FontWeight.w600 : null),
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
    else{
      activity = const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Center(
            child: Text("You have not requested or booked a ride yet!", style: TextStyle(fontSize: 18), textAlign: TextAlign.center)),
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
