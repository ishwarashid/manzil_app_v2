import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manzil_app_v2/main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/light_logo.png', width: 180,),
              const SizedBox(height: 20,),
              Text(
                "Making Miles Matter, Sharing the Road",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8)),
              )
            ],
          ),
        ));
  }
}
