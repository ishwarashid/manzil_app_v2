import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manzil_app_v2/screens/splash_screen.dart';
import 'package:manzil_app_v2/screens/start_screen.dart';
import 'package:manzil_app_v2/services/notification/background_detector.dart';
import 'package:manzil_app_v2/services/notification/notification_plugin.dart';
import 'dart:io';

final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 52, 59, 113),
  ),
  textTheme: GoogleFonts.latoTextTheme(),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  HttpOverrides.global = MyHttpOverrides();

  runApp(const BackgroundDetector(child: ProviderScope(child: MyApp())));

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();

    notificationPlugin.requestPermissions();

    return GetMaterialApp(
        title: 'Manzil',
        theme: theme,
        home: Builder(
          builder: (context) {
            String? phoneNumber = box.read('phoneNumber');
            if ( phoneNumber == null || phoneNumber.isEmpty) {
              return const StartScreen();
            }
            return const SplashScreen();
          },
        )
        );
  }
}

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}
