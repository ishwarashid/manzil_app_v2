import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';
import 'package:manzil_app_v2/screens/user_chat_screen.dart';

class ChatListItem extends ConsumerStatefulWidget {
  const ChatListItem({super.key, required this.userData});

  final Map<String, dynamic> userData;

  @override
  ConsumerState<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends ConsumerState<ChatListItem> {
  @override
  Widget build(BuildContext context) {
    // Watch the current user from Riverpod
    final currentUser = ref.watch(currentUserProvider);

    // Check if the user in the list is not the current user
    if (widget.userData["id"] != currentUser['uid']) {
      // Combine first and last name of the user
      final fullName = widget.userData["first_name"] + " " + widget.userData["last_name"];

      return GestureDetector(
        onTap: () {
          // Navigate to the chat screen with the selected user
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserChatScreen(
                currentUser: currentUser,  // Pass current user data
                fullName: fullName,         // Pass the full name of the selected user
                receiverId: widget.userData["id"], // Pass receiverId (user's ID)
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // User's profile avatar (default for now)
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                // User's full name displayed in the list item
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 45, 45, 45),
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Return an empty container if the user is the current user
      return Container();
    }
  }
}
