import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:manzil_app_v2/main.dart';
import 'package:manzil_app_v2/screens/chats_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    getUser().then((status){
      if(status == 404){
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GetStartedScreen(),
            ));
      }
    });

    startBackgroundService();

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
                    builder: (context) => const BookingScreen(),
                ));
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ride Requests Near You",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(30, 60, 87, 1),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              width: 165,
              height: 5,
              decoration: BoxDecoration(
                  color: const Color.fromRGBO(30, 60, 87, 1),
                  borderRadius: BorderRadius.circular(5)),
            ),
            const SizedBox(
              height: 30,
            ),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Azan Rashid",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 45, 45, 45),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.message,
                          color: Color.fromARGB(255, 255, 170, 42),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatsScreen(),
                            ),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserChatScreen(
                                fullName: "Azan Rashid",
                                receiverId: "egizs0ZIhiNGF6nZRaQnweF0chN2",
                              ),
                            ),
                          );

                        },
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: Color.fromARGB(255, 255, 107, 74),),
                      Text("Tariq Bin Ziad Colony")
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.navigation,
                                color: Color.fromARGB(255, 255, 170, 42),),
                            Text("COMSATS University"),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        child: const Text("Accept"),
                      )
                    ],
                  ),
                ]),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Faraz Usman",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 45, 45, 45),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.message,
                          color: Color.fromARGB(255, 255, 170, 42),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserChatScreen(
                                fullName: "Faraz Usman",
                                receiverId: "ooMvMYyqJqWmIxPmCQiMnz5nDQf1",
                              ),
                            ),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatsScreen(),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: Color.fromARGB(255, 255, 107, 74),),
                      Text("Tariq Bin Ziad Colony")
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.navigation,
                                color: Color.fromARGB(255, 255, 170, 42),),
                            Text("COMSATS University"),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        child: const Text("Accept"),
                      )
                    ],
                  ),
                ]),
              ),
            )
          ],
        ),
      ),
    );
  }
}
