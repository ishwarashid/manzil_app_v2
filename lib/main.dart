import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manzil_app_v2/screens/splash_screen.dart';
import 'package:manzil_app_v2/screens/start_screen.dart';
import 'package:manzil_app_v2/services/chat/chat_services.dart';
import 'package:manzil_app_v2/services/notification/background_detector.dart';
import 'package:manzil_app_v2/services/notification/notification_plugin.dart';
import 'package:manzil_app_v2/services/socket_handler.dart';

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

  initializeService();

  runApp(
    const BackgroundDetector(
      child: ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

void startBackgroundService() {
  final service = FlutterBackgroundService();
  service.startService();
}

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      onStart: onStart,
      isForegroundMode: false,
      autoStartOnBoot: true,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final box = GetStorage();

  final ChatService chatService = ChatService();

  SocketHandler();

  chatService.getUsers().then((users) {
    for (var user in users) {
      if (box.read('phoneNumber') == user['phoneNumber']) {
        box.write("_id", user["_id"]);
      }

      if (box.read("_id") == user['_id']) {
        continue;
      }

      List<String> ids = [box.read("_id"), user['_id']];
      ids.sort();
      String eventId = ids.join("_");
      Map<String, dynamic> message;

      SocketHandler.socket.on(
          eventId,
          (data) => {
                message = List.from(data).first as Map<String, dynamic>,
                if (message['senderId'] != box.read("_id"))
                  {notificationPlugin.showNotification(message)}
              });
    }
  });

  service.on("stop");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();

    notificationPlugin.requestPermissions();

    return MaterialApp(
        title: 'Manzil',
        theme: theme,
        home: Builder(
          builder: (context) {
            if (box.read('phoneNumber') == '' ||
                box.read('phoneNumber') == null) {
              return const StartScreen();
            }
            return const SplashScreen();
          },
        )
        // home: const SplashScreen(),
        );
  }
}
