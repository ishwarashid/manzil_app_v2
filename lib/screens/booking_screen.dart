import 'package:flutter/material.dart';
import 'package:manzil_app_v2/screens/find_drivers.dart';
import 'package:manzil_app_v2/screens/ride_requests.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';
import 'package:manzil_app_v2/widgets/map.dart';
import 'package:manzil_app_v2/widgets/ride_inputs.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class Booking extends StatefulWidget {
  const Booking({super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  void _goToFindDriversScreen() {
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
                  fontSize: 18,
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
