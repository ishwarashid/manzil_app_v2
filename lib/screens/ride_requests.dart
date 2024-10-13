import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v2/providers/rides_filter_provider.dart';
import 'package:manzil_app_v2/widgets/destination_alert_dialog.dart';

class RideRequestsScreen extends ConsumerStatefulWidget {
  const RideRequestsScreen({super.key});

  @override
  RideRequestsScreenState createState() => RideRequestsScreenState();
}

class RideRequestsScreenState extends ConsumerState<RideRequestsScreen> {
  ////////////////////////////////////////////
  ///////// GET THIS DYNAMICALLY TOO ////////
  //////////////////////////////////////////

  List<Map<String, Object>> getRidesData() {
    final List<Map<String, String>> ridesData = [
      {
        "passengerName": "John Doe",
        "pickupLocation": "Tariq Bin Ziad Colony",
        "destination": "COMSATS University, Sahiwal"
      },
      {
        "passengerName": "Jane Smith",
        "pickupLocation": "Tariq Bin Ziad Colony",
        "destination": "COMSATS University, Sahiwal"
      },
      {
        "passengerName": "Michael Lee",
        "pickupLocation": "Tariq Bin Ziad Colony",
        "destination": "COMSATS University, Sahiwal"
      },
      {
        "passengerName": "Emily Davis",
        "pickupLocation": "Tariq Bin Ziad Colony",
        "destination": "Farid Town, Sahiwal"
      },
    ];

    return ridesData;
  }

  void _showDestinationInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return const DestinationAlertDialog();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final enteredDestination = ref.read(ridesFilterProvider) ?? '';
    if (enteredDestination.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDestinationInputDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enteredDestination = ref.watch(ridesFilterProvider) ?? '';

    final rideRequests = getRidesData();

    final filteredRequests = enteredDestination.isEmpty
        ? rideRequests
        : rideRequests.where((ride) {
            final destination = ride['destination'] as String;
            return destination
                .toLowerCase()
                .contains(enteredDestination.toLowerCase());
          }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ride Requests Near You",
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
                ],
              ),

              const Spacer(),
              // Icon(Icons.filter_alt_outlined)
              InkWell(
                onTap: () {
                  _showDestinationInputDialog();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.only(
                      left: 6, right: 6, top: 6, bottom: 5),
                  decoration: BoxDecoration(
                    // color: const Color.fromARGB(255, 255, 107, 74),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const ImageIcon(
                    size: 20,
                    color: Color.fromRGBO(30, 60, 87, 1),
                    ResizeImage(
                        AssetImage('assets/icons/filter_rides_icon.png'),
                        width: 48,
                        height: 48),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final request = filteredRequests[index];
                return Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, bottom: 15, top: 5),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              (request["passengerName"] as String),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color.fromRGBO(30, 60, 87, 1),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.message,
                                color: Color.fromARGB(255, 255, 170, 42),
                              ),
                              onPressed: () {},
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Color.fromARGB(255, 255, 107, 74),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              (request["pickupLocation"] as String),
                              style: const TextStyle(fontSize: 14),
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.navigation,
                                    color: Color.fromARGB(255, 255, 170, 42),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Flexible(
                                    child: Text(
                                      (request["destination"] as String),
                                      style: const TextStyle(fontSize: 14),
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                textStyle: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              child: const Text("Accept"),
                            )
                          ],
                        ),
                      ],
                    ),
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
