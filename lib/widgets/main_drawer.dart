import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v2/main.dart';
import 'package:manzil_app_v2/screens/chats_screen.dart';
import 'package:manzil_app_v2/screens/find_drivers.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();

    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              DrawerHeader(
                decoration:
                    BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 42,
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: Text(
                          "${box.read('firstName')} ${box.read('lastName')}",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 24),
                          softWrap: true,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                child: ListTile(
                  title: Text(
                    "Home",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 20),
                  ),
                  leading: Icon(
                    Icons.home_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                child: ListTile(
                  title: Text(
                    "Chats",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 20),
                  ),
                  leading: Icon(
                    Icons.message_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatsScreen(),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                child: ListTile(
                  title: Text(
                    "Found Drivers",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 20),
                  ),
                  leading: Icon(
                    Icons.home_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FindDrivers(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: ListTile(
              title: Text(
                "Logout",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary, fontSize: 20),
              ),
              leading: Icon(
                Icons.exit_to_app,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
              onTap: () {
                box.erase();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyApp(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
