import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v2/screens/find_drivers.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';
import 'package:manzil_app_v2/widgets/map.dart';
import 'package:manzil_app_v2/widgets/ride_inputs.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:http/http.dart' as http;
import '../providers/booking_inputs_provider.dart';

class Booking extends ConsumerStatefulWidget {
  const Booking({super.key});

  @override
  ConsumerState<Booking> createState() => _BookingState();
}

void updateUserPoints(String id, dynamic payload) async {
  const url = "https://shrimp-select-vertically.ngrok-free.app";

  await http.patch(
    Uri.parse("$url/users/$id"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(payload)
  );
}

class _BookingState extends ConsumerState<Booking> {
  final box = GetStorage();

  void _goToFindDriversScreen() {
    Map<String, dynamic> payload = {
      "startPoint": box.read("pickup_coordinates"),
      "endPoint": box.read("destination_coordinates")
    };

    updateUserPoints(box.read("_id"), payload);
    box.write("hasRequested", true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const FindDrivers(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      drawer: const MainDrawer(),
      body: SafeArea(
        child: SlidingUpPanel(
          onPanelOpened: () async => ref.read(bookingInputsProvider.notifier).setPickup(await box.read("pickup")),
          minHeight: 50,
          backdropOpacity: 0,
          panel: Center(
            child: RideInputs(onFindDrivers: _goToFindDriversScreen),
          ),
          collapsed: Container(
            // color: Theme.of(context).colorScheme.primary,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Text(
                "Slide up to fill the ride details",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              const FullMap(),
              Positioned(
                top: 16,
                left: 16,
                child: Builder(
                  builder: (context) => CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
    );
  }
}
