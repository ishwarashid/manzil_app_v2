import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';
import 'package:manzil_app_v2/widgets/map_driver.dart';

class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});

  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapState();
}

class _DriverMapState extends ConsumerState<DriverMapScreen> {
  final box = GetStorage();


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          const FullDriverMap(),
          Positioned(
            top: 50,
            left: 16,
            child: Builder(
              builder: (context) => CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
