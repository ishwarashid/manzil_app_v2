import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';
import 'package:manzil_app_v2/screens/booking.dart';
import 'package:manzil_app_v2/screens/chats_screen.dart';
import 'package:manzil_app_v2/screens/find_drivers.dart';
import 'package:manzil_app_v2/screens/ride_requests.dart';
import 'package:manzil_app_v2/screens/user_activity.dart';
import 'package:manzil_app_v2/widgets/main_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedPageIndex = 0;

  String? phoneNumber;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    final box = GetStorage();
    phoneNumber = box.read('phoneNumber');
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final currentUser = ref.read(currentUserProvider);

    if (currentUser['first_name'] == '') {
      try {
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone_number', isEqualTo: phoneNumber)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;

          final userData = doc.data() as Map<String, dynamic>;

          userData['uid'] = doc.id;

          ref.read(currentUserProvider.notifier).setUser(userData);
        }
      } catch (e) {
        // Handle error
        print("Error fetching user data: $e");
      }
    }
  }

  void _setScreen(String identifier) async {
    Navigator.of(context).pop();
    if (identifier == 'chats') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const ChatsScreen(),
        ),
      );
    } else if (identifier == 'foundDrivers') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const FindDrivers(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage = const UserActivityScreen();

    final currentUser = ref.watch(currentUserProvider);
    // print(currentUser);

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
      drawer: MainDrawer(onSelectScreen: _setScreen),
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        currentIndex: _selectedPageIndex,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.backup_table), label: "Activity"),
          BottomNavigationBarItem(
              icon: Icon(Icons.drive_eta_outlined), label: "Accept Requests"),
        ],
      ),
    );
  }
}
