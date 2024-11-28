import 'package:flutter/material.dart';
import 'package:manzil_app_v2/widgets/driver_tracking.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';
import 'package:manzil_app_v2/widgets/passenger_tracking.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen(this.isDriver, {super.key});

  final bool isDriver;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  Widget build(BuildContext context) {

    Widget screen = const PassengerTracking();
    if (widget.isDriver) {
      screen = const DriverTracking();
    }
    return Scaffold(
      // drawer: MainDrawer(onSelectScreen: _setScreen,),
      body: screen
    );
  }
}
