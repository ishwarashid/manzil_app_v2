import 'package:flutter/material.dart';
import 'package:manzil_app_v2/screens/chats_screen.dart';
import 'package:manzil_app_v2/widgets/driver_card.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';

class FindDrivers extends StatefulWidget {
  const FindDrivers({super.key});

  @override
  State<FindDrivers> createState() => _FindDriversState();
}

class _FindDriversState extends State<FindDrivers> {
  final _availableDrivers = [
    {"driverName": "John Doe", "distance": "2 mins"},
    {"driverName": "Jane Smith", "distance": "3 mins"},
    {"driverName": "Jane Smith", "distance": "3 mins"},
  ];

  final _ridesBooked = [
    // {"pickup": "abc", "destination": "def"}
  ];

  // void _setScreen(String identifier) async {
  //   Navigator.of(context).pop();
  //   if (identifier == 'home') {
  //     Navigator.of(context).pop();
  //   } else if (identifier == 'chats') {
  //     Navigator.of(context).push(
  //       MaterialPageRoute(
  //         builder: (ctx) => const ChatsScreen(),
  //       ),
  //     );
  //   } else if (identifier == 'foundDrivers') {
  //     Navigator.of(context).push(
  //       MaterialPageRoute(
  //         builder: (ctx) => const FindDrivers(),
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final hasBookARide = _ridesBooked.isNotEmpty;

    Widget content =
    const Center(child: Text("You haven't booked a ride yet!"),);

    if (hasBookARide && _availableDrivers.isEmpty) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "No one accepted your request!",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: const Color.fromRGBO(30, 60, 87, 1),
                  fontWeight: FontWeight.w500
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10,),
            Text(
              "Please check status again after few mins",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: const Color.fromRGBO(30, 60, 87, 1),
              ),
            ),
          ],
        ),
      );
    }

    if (_availableDrivers.isNotEmpty) {
      content = ListView.builder(
        itemCount: _availableDrivers.length,
        itemBuilder: (context, index) => DriverCard(_availableDrivers[index]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Found Drivers"),
      ),
      // drawer: MainDrawer(onSelectScreen: _setScreen,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }
}
