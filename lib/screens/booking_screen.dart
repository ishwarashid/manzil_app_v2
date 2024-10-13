import 'package:flutter/material.dart';
import 'package:manzil_app_v2/widgets/map.dart';

class BookingScreen extends StatelessWidget {

  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
      return const Scaffold(
        body: FullMap(),
      );
  }
}