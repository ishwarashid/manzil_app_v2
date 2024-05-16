import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:manzil_app_v2/screens/home_screen.dart';
import 'firebase_options.dart';

import 'package:manzil_app_v2/screens/splash_screen.dart';

import 'package:manzil_app_v2/screens/start_screen.dart';

// var kLightColorScheme = ColorScheme.fromSeed(
//   seedColor: const Color.fromARGB(255, 52, 59, 113),
// );

// Yellow Color
// color: Color.fromARGB(255, 255, 170, 42)

// Carrot Color
// color: Color.fromARGB(255, 255, 107, 74)

// black variant
// Color.fromARGB(255, 45, 45, 45)

// Input field Text
// color: Color.fromRGBO(30, 60, 87, 1)
final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 52, 59, 113),
  ),
  textTheme: GoogleFonts.latoTextTheme(),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Manzil',
      theme: theme,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const StartScreen();
        },
      ),
      // home: const SplashScreen(),
    );
  }
}
