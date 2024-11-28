import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v2/main.dart';
import 'package:manzil_app_v2/providers/booking_inputs_provider.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';
import 'package:manzil_app_v2/providers/rides_filter_provider.dart';
import 'package:manzil_app_v2/providers/user_ride_providers.dart';
import 'package:manzil_app_v2/screens/tracking.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key, required this.onSelectScreen});

  final void Function(String identifier) onSelectScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = GetStorage();
    final currentUser = ref.watch(currentUserProvider);
    final userRideStatus =
        ref.watch(userRideStatusProvider(currentUser['uid']));

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
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 42,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          (currentUser['first_name'] as String).isEmpty
                              ? "Unknown"
                              : currentUser['first_name'] as String,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 24,
                          ),
                          softWrap: true,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
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
                    onSelectScreen('home');
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
                    onSelectScreen('chats');
                  },
                ),
              ),
              userRideStatus.when(
                data: (status) {
                  // Show Found Drivers only if user is a passenger and has pending ride
                  if (!status.isDriver &&
                      status.activeRides
                          .any((ride) => ride['status'] == 'pending')) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                      child: ListTile(
                        title: Text(
                          "Found Drivers",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 20),
                        ),
                        leading: Icon(
                          Icons.directions_car_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                        onTap: () {
                          onSelectScreen('foundDrivers');
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              userRideStatus.when(
                data: (status) {
                  final hasAcceptedRide = status.activeRides
                      .any((ride) => (ride['status'] == 'accepted' || ride['status'] == 'picked' || ride['status'] == 'paying'));
                  // Show Tracking if user has any accepted ride
                  // For driver, make sure they only have one accepted ride
                  if (hasAcceptedRide) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                      child: ListTile(
                        title: Text(
                          "Tracking",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 20),
                        ),
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                        onTap: () {
                          // onSelectScreen('tracking');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => TrackingScreen(status.isDriver),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
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
                ref.read(currentUserProvider.notifier).clearUser();
                ref.read(ridesFilterProvider.notifier).clearDestination();
                ref.read(bookingInputsProvider.notifier).resetBookingInputs();
                Navigator.of(context).pop();
                Navigator.pushReplacement(
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
