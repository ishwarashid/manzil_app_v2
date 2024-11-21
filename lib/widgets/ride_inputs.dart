import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v2/widgets/input_destination.dart';
import 'package:manzil_app_v2/widgets/input_fare.dart';
import 'package:manzil_app_v2/widgets/input_pickup.dart';
import 'package:http/http.dart' as http;
import 'package:text_scroll/text_scroll.dart';
import '../providers/booking_inputs_provider.dart';
import '../widgets/input_seats.dart';

class RideInputs extends ConsumerStatefulWidget {
  const RideInputs({super.key, required this.onFindDrivers});

  final Function() onFindDrivers;

  @override
  ConsumerState<RideInputs> createState() => _RideInputsState();
}

class _RideInputsState extends ConsumerState<RideInputs> {
  void _openSeatsModalOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      context: context,
      builder: (ctx) => const InputSeats(),
    );
  }

  void _openPickupModalOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      context: context,
      builder: (ctx) => const InputPickup(),
    );
  }

  void _openDestinationModalOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      context: context,
      builder: (ctx) => const InputDestination(),
    );
  }

  void _openFareModalOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      context: context,
      builder: (ctx) => const InputFare(),
    );
  }


  void sendRequest(payload) async {
      const url = "https://shrimp-select-vertically.ngrok-free.app";

      await http.post(
          Uri.parse("$url/sendrequest"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(payload)
      );
  }

  void _bookRide() {
    final box = GetStorage();
    Map<String, Object> bookingInfo = ref.read(bookingInputsProvider);
    //////////////////////////////////////////////////////////////////
    /////////////// SAVE BOOKING INFO IN DB HERE BISH////////////////
    ////////////////////////////////////////////////////////////////
    Map<String, dynamic> payload = {
      'userId': box.read("_id"),
      'pickup': box.read("pickup").toString().trim(),
      'destination': box.read("destination").toString().trim(),
      'seats': bookingInfo['seats'].toString(),
      'fare': bookingInfo['fare'].toString()
    };

    sendRequest(payload);

    ref.read(bookingInputsProvider.notifier).resetBookingInputs();
    widget.onFindDrivers();
  }

  @override
  Widget build(BuildContext context) {
    final bookingInputs = ref.watch(bookingInputsProvider);
    final bookingInputsNotifier = ref.read(bookingInputsProvider.notifier);

    bool areAllFieldsFilled = bookingInputsNotifier.areAllFieldsFilled();

    final pickup =
        bookingInputs['pickup'] as String? ?? "No Pickup Location Specified";
    final destination = bookingInputs['destination'] as String? ?? "To";
    final seats = bookingInputs['seats'] as int? ?? 0;
    final fare = bookingInputs['fare'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 60, right: 30, left: 30),
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                InkWell(
                  // onTap: _openPickupModalOverlay,
                  onTap: () {
                    _openPickupModalOverlay();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color.fromARGB(255, 255, 107, 74),
                        size: 30,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextScroll(
                            pickup.isNotEmpty
                                ? pickup
                                : "No Pickup Location Specified",
                          style: const TextStyle(fontSize: 18),
                        // child: Text(
                        //   pickup.isNotEmpty
                        //       ? pickup
                        //       : "No Pickup Location Specified",
                        //   style: const TextStyle(fontSize: 18),
                        //   softWrap: true,
                        //   maxLines: 1,
                        //   overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openDestinationModalOverlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: destination.isNotEmpty
                          ? const Color.fromARGB(255, 76, 175, 64)
                          : Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 30,
                        ),
                        const SizedBox(
                          width: 25,
                        ),
                        Expanded(
                          child: Text(
                            destination.isNotEmpty ? destination : "To",
                            style: TextStyle(
                                color: destination.isNotEmpty
                                    ? const Color.fromARGB(255, 255, 255, 255)
                                    : const Color.fromARGB(160, 255, 255, 255),
                                fontSize: 20),
                            softWrap: true,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openSeatsModalOverlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: seats > 0
                          ? const Color.fromARGB(255, 76, 175, 64)
                          : Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.airline_seat_recline_extra_sharp,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 30,
                        ),
                        const SizedBox(
                          width: 25,
                        ),
                        Text(
                          seats > 0 ? '$seats Seats' : "Number of Seats",
                          style: TextStyle(
                              color: seats > 0
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : const Color.fromARGB(160, 255, 255, 255),
                              fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openFareModalOverlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fare > 0
                          ? const Color.fromARGB(255, 76, 175, 64)
                          : Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "PKR",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        Text(
                          fare > 0 ? '$fare' : "Offer Your Fare",
                          style: TextStyle(
                              color: fare > 0
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : const Color.fromARGB(160, 255, 255, 255),
                              fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: areAllFieldsFilled ? _bookRide : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 107, 74),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                textStyle:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              child: const Text("Find a driver"),
            ),
          )
        ],
      ),
    );
  }
}
