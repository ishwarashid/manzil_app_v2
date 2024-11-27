import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';
import 'package:manzil_app_v2/providers/rides_filter_provider.dart';
import 'package:manzil_app_v2/screens/chats_screen.dart';
import 'package:manzil_app_v2/screens/user_chat_screen.dart';
import 'package:manzil_app_v2/services/chat/chat_services.dart';
import 'package:manzil_app_v2/services/ride/ride_services.dart';
import 'package:manzil_app_v2/widgets/destination_alert_dialog.dart';

class RideRequestsScreen extends ConsumerStatefulWidget {
  const RideRequestsScreen({super.key});

  @override
  RideRequestsScreenState createState() => RideRequestsScreenState();
}

class RideRequestsScreenState extends ConsumerState<RideRequestsScreen> {
  final _ridesService = RidesService();
  final _chatService = ChatService();
  bool _isProcessing = false;

  void _showDestinationInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => const DestinationAlertDialog(),
    );
  }

  @override
  void initState() {
    super.initState();
    final enteredDestination = ref.read(ridesFilterProvider) ?? '';
    if (enteredDestination.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDestinationInputDialog();
      });
    }
  }

  Future<void> _initiateChat(Map<String, dynamic> request) async {
    final currentUser = ref.read(currentUserProvider);
    final receiverId = request["passengerID"];

    await _chatService.createChatRoom(currentUser, receiverId as String);

    if (!mounted) return;

    // Navigate to chat screens
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
          currentUser: currentUser,
          fullName: request["passengerName"] as String,
          receiverId: receiverId,
        ),
      ),
    );
  }

  // Future<void> _acceptRide(String rideId) async {
  //   if (_isProcessing) return;
  //
  //   try {
  //     setState(() {
  //       _isProcessing = true;
  //     });
  //
  //     final currentUser = ref.read(currentUserProvider);
  //     await _ridesService.acceptRide(rideId, currentUser);
  //
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Ride request accepted successfully')),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to accept ride: $e')),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isProcessing = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _acceptRide(String rideId) async {
    if (_isProcessing) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final currentUser = ref.read(currentUserProvider);

      await _ridesService.acceptRide(rideId, currentUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride request accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final enteredDestination = ref.watch(ridesFilterProvider) ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
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
                    const SizedBox(height: 6),
                    Container(
                      width: 165,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(30, 60, 87, 1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _showDestinationInputDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const ImageIcon(
                    ResizeImage(
                      AssetImage('assets/icons/filter_rides_icon.png'),
                      width: 48,
                      height: 48,
                    ),
                    size: 20,
                    color: Color.fromRGBO(30, 60, 87, 1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (enteredDestination.isEmpty)
            const EmptyStateWidget(
              identifier: 'setDes',
              message: "Please set a destination to view requests.",
            )
          else
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _ridesService.getRides(currentUser['uid']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final requests = snapshot.data ?? [];
                  final filteredRequests = requests.where((ride) {
                    final destination = ride['destination'] as String;
                    return destination
                        .toLowerCase()
                        .contains(enteredDestination.trim().toLowerCase());
                  }).toList();

                  if (filteredRequests.isEmpty) {
                    return const EmptyStateWidget(
                      identifier: 'changeFilter',
                      message:
                          "No ride requests found\nTry changing the filter",
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredRequests.length,
                    itemBuilder: (context, index) => RideRequestCard(
                      request: filteredRequests[index],
                      onAccept: () =>
                          _acceptRide(filteredRequests[index]['id']),
                      onChat: () => _initiateChat(filteredRequests[index]),
                      isProcessing: _isProcessing,
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

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String identifier;

  const EmptyStateWidget({
    required this.message,
    required this.identifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (identifier == 'setDes' ) {
      return Padding(
        padding: const EdgeInsets.only( top: 240),
        child: Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: const Color.fromRGBO(30, 60, 87, 1),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: const Color.fromRGBO(30, 60, 87, 1),
              fontWeight: FontWeight.w500,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class RideRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onChat;
  final bool isProcessing;

  const RideRequestCard({
    required this.request,
    required this.onAccept,
    required this.onChat,
    required this.isProcessing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = request['createdAt'] as Timestamp;
    final timeAgo = DateTime.now().difference(createdAt.toDate());
    String timeAgoStr;
    if (timeAgo.inMinutes < 60) {
      timeAgoStr = '${timeAgo.inMinutes}m ago';
    } else if (timeAgo.inHours < 24) {
      timeAgoStr = '${timeAgo.inHours}h ago';
    } else {
      timeAgoStr = '${timeAgo.inDays}d ago';
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
          bottom: 15,
          top: 5,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request["passengerName"] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(30, 60, 87, 1),
                        ),
                      ),
                      Text(
                        timeAgoStr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.message,
                    color: Color.fromARGB(255, 255, 170, 42),
                  ),
                  onPressed: onChat,
                )
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color.fromARGB(255, 255, 107, 74),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    request["pickupLocation"] as String,
                    style: const TextStyle(fontSize: 14),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.navigation,
                        color: Color.fromARGB(255, 255, 170, 42),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          request["destination"] as String,
                          style: const TextStyle(fontSize: 14),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${request["offeredFare"]}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(30, 60, 87, 1),
                      ),
                    ),
                    Text(
                      '${request["seats"]} seats',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromRGBO(30, 60, 87, 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isProcessing ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text("Accept"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
