import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:manzil_app_v2/main.dart';
import 'package:manzil_app_v2/screens/chats_screen.dart';
import 'package:manzil_app_v2/screens/ride_requests.dart';
import 'package:manzil_app_v2/screens/user_activity.dart';
import 'package:manzil_app_v2/screens/user_chat_screen.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';
import 'booking_screen.dart';
import 'get_started_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

    return 200;
  }

  // @override
  // void dispose() {
  //   stopBackgroundService();
  //   super.dispose();
  // }

  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    getUser().then((status) {
      if (status == 404) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GetStartedScreen(),
            ));
      }
    });

    startBackgroundService();

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => const Booking(),
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
