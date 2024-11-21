import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:manzil_app_v2/screens/ride_requests.dart';
import 'package:manzil_app_v2/screens/user_activity.dart';
import 'package:manzil_app_v2/screens/user_chat_screen.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';

import '../services/chat/chat_services.dart';
import '../services/notification/notification_plugin.dart';
import '../services/socket_handler.dart';
import 'booking_screen.dart';
import 'get_started_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final box = GetStorage();

  Future<int> getUser() async {
    const url = "https://shrimp-select-vertically.ngrok-free.app";

    var box = GetStorage();
    var phoneNumber = Uri.encodeQueryComponent(box.read('phoneNumber'));

    final response = await http.get(
      Uri.parse('$url/users?phoneNumber=$phoneNumber'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 404) {
      return 404;
    }

    final user = jsonDecode(response.body) as Map<String, dynamic>;

    box.write('firstName', user['data']['firstName'] as String);
    box.write('lastName', user['data']['lastName'] as String);
    box.write('_id', user['data']['_id'] as String);

    return 200;
  }

  void getLocationForDriverPickup(String longitude, String latitude) async {
    final box = GetStorage();
    String url = "https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&accept-language=en-US";

    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    var geocodedData = jsonDecode(response.body) as Map<String, dynamic>;

    await box.write("driver_pickup_coordinates", {"lat": geocodedData["lat"], "lon": geocodedData["lon"]});
    await box.write("driver_pickup", geocodedData["display_name"]);
  }

  Future<geolocator.Position> _determinePosition() async {
    geolocator.LocationPermission permission;

    permission = await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await geolocator.Geolocator.getCurrentPosition();
  }

  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  void initState() {
    final ChatService chatService = ChatService();

    SocketHandler();
    var message;

    notificationPlugin.setOnNotificationClick((data) =>
    {
      message = jsonDecode(data.payload),
      Get.to(UserChatScreen(
          fullName: message['senderName'], receiverId: message['receiverId']))
    });

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

        SocketHandler.socket.on(
            eventId,
                (data) =>
            {
              if (data['senderId'] != box.read("_id") &&
                  !notificationPlugin.isForeground)
                {
                  notificationPlugin.showNotification(data)
                }
            });
      }
    });

    getUser().then((status) {
      if (status == 404) {
        Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GetStartedScreen(),
            ));
      }
    });

    _determinePosition().then((position) {
      getLocationForDriverPickup(
          position.longitude.toString(),
          position.latitude.toString());
    });


    SocketHandler.socket.on("Canceled Ride", (user) {
      if (user["passenger"]["_id"] == box.read("_id")) {
        return;
      }

      var msg = {
        "senderName": "${user["passenger"]["firstName"]} ${user["passenger"]["lastName"]}",
        "message": "Has canceled the ride."
      };
      notificationPlugin.showNotification(msg);
    });

    SocketHandler.socket.on("Booked Ride", (user) {
      if (user["_id"] == box.read("_id")) {
        return;
      }

      var msg = {
        "senderName": "${user["firstName"]} ${user["lastName"]}",
        "message": "Has booked the ride."
      };
      notificationPlugin.showNotification(msg);

      box.write("canNavigate", true);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage = const UserActivityScreen();
    if (_selectedPageIndex == 1) {
      activePage = const RideRequestsScreen();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Booking(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              icon: const ImageIcon(
                size: 24,
                color: Color.fromARGB(255, 255, 170, 42),
                ResizeImage(AssetImage('assets/icons/book_a_ride_icon.png'),
                    width: 48, height: 48),
              ),
              label: const Text("Book a Ride"),
            ),
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        currentIndex: _selectedPageIndex,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.backup_table), label: "Your Activity"),
          BottomNavigationBarItem(
              icon: Icon(Icons.drive_eta_outlined), label: "Accept Requests"),
        ],
      ),
    );
  }
}
