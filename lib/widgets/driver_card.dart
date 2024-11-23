import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:manzil_app_v2/screens/passenger_map_screen.dart';
import '../screens/user_chat_screen.dart';

class DriverCard extends StatelessWidget {
   DriverCard(this.driver, {super.key});

  final Map<String, dynamic> driver;

  final box = GetStorage();

  void bookRide() async {
    const url = "https://shrimp-select-vertically.ngrok-free.app";

    await http.post(
      Uri.parse('$url/book-ride'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "driverId": driver["driverId"],
        "destination": box.read("driver_destination"),
        "passengerId": box.read("_id")
      }),
    );
  }

   void deleteRequest() async {
     const url = "https://shrimp-select-vertically.ngrok-free.app";
     String userId = box.read("_id");

     await http.delete(
       Uri.parse('$url/accepted-requests/$userId'),
       headers: <String, String>{
         'Content-Type': 'application/json; charset=UTF-8',
       },
     );
   }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (driver["driverName"] as String),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 45, 45, 45),
                      ),
                    ),
                    Text(
                      "${num.parse(driver["distance"].toString()).round()} meters far",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Text(
                      "${num.parse(driver["duration"].toString()).round()} mins",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
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
                        builder: (context) => UserChatScreen(
                          fullName: driver["driverName"] as String,
                          receiverId: driver["driverId"] as String,
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                      bookRide();
                      deleteRequest();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PassengerMapScreen(),
                        ),
                      );
                      box.write("hasRequested", false);
                      box.write("isBooked", true);
                      box.write("driver_name", driver["driverName"]);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  child: const Text("Book"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
