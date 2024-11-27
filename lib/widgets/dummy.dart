// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:manzil_app_v2/providers/current_user_provider.dart';
// import 'package:manzil_app_v2/screens/chats_screen.dart';
// import 'package:manzil_app_v2/screens/user_chat_screen.dart';
// import 'package:manzil_app_v2/services/driver/driver_passenger_service.dart';
// import 'package:manzil_app_v2/widgets/driver_card.dart';
//
// class FindDrivers extends ConsumerStatefulWidget {
//   const FindDrivers({super.key});
//
//   @override
//   ConsumerState<FindDrivers> createState() => _FindDriversState();
// }
//
// class _FindDriversState extends ConsumerState<FindDrivers> {
//   final _driverPassengerService = DriverPassengerService();
//   bool _isAccepting = false;
//
//   Future<void> _acceptDriver(String rideId, Map<String, dynamic> driverInfo) async {
//     if (_isAccepting) return;
//
//     try {
//       setState(() {
//         _isAccepting = true;
//       });
//
//       final currentUser = ref.read(currentUserProvider);
//
//       await _driverPassengerService.acceptDriver(
//         rideId: rideId,
//         currentUser: currentUser,
//         driverInfo: driverInfo,
//       );
//       // Navigate to the chat screen
//       if (mounted) {
//         // First push the chats screen
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => const ChatsScreen(),
//           ),
//         );
//
//         // Then push the specific chat screen
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => UserChatScreen(
//               currentUser: currentUser,
//               fullName: driverInfo['driverName'],
//               receiverId: driverInfo['driverId'],
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to accept driver: $e')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isAccepting = false;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUser = ref.watch(currentUserProvider);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Found Drivers"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: StreamBuilder<Map<String, dynamic>?>(
//           stream: _driverPassengerService.getCurrentRide(currentUser['uid']),
//           builder: (context, rideSnapshot) {
//             if (rideSnapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//
//             if (rideSnapshot.hasError) {
//               return Center(child: Text('Error: ${rideSnapshot.error}'));
//             }
//
//             final currentRide = rideSnapshot.data;
//
//             if (currentRide == null) {
//               return Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       "No active ride request found",
//                       style: Theme.of(context).textTheme.titleLarge!.copyWith(
//                           color: const Color.fromRGBO(30, 60, 87, 1),
//                           fontWeight: FontWeight.w500),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       "Please create a ride request first",
//                       style: Theme.of(context).textTheme.bodyLarge!.copyWith(
//                         color: const Color.fromRGBO(30, 60, 87, 1),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             return StreamBuilder<List<Map<String, dynamic>>>(
//               stream: _driverPassengerService.getAcceptedDrivers(currentRide['id']),
//               builder: (context, driversSnapshot) {
//                 if (driversSnapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 if (driversSnapshot.hasError) {
//                   return Center(child: Text('Error: ${driversSnapshot.error}'));
//                 }
//
//                 final drivers = driversSnapshot.data ?? [];
//
//                 if (drivers.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           "No drivers have accepted yet!",
//                           style: Theme.of(context).textTheme.titleLarge!.copyWith(
//                               color: const Color.fromRGBO(30, 60, 87, 1),
//                               fontWeight: FontWeight.w500),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           "Please check again in a few minutes",
//                           style: Theme.of(context).textTheme.bodyLarge!.copyWith(
//                             color: const Color.fromRGBO(30, 60, 87, 1),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 return ListView.builder(
//                   itemCount: drivers.length,
//                   itemBuilder: (context, index) => DriverCard(
//                     driverInfo: drivers[index],
//                     onAccept: () => _acceptDriver(currentRide['id'], drivers[index]),
//                     isAccepting: _isAccepting,
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }