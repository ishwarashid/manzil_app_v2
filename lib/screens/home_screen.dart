import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manzil_app_v2/main.dart';
import 'package:manzil_app_v2/screens/chats_screen.dart';
import 'package:manzil_app_v2/screens/user_chat_screen.dart';
import 'package:manzil_app_v2/widgets/chat_list.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: () {},
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
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
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
                          print("back from chat");

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

                          print("back from chat");
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
