import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manzil_app_v2/screens/user_chat_screen.dart';

class ChatListItem extends StatefulWidget {
  const ChatListItem({super.key, required this.userData});

  final Map<String, dynamic> userData;

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {

  final _currentUser = FirebaseAuth.instance.currentUser;


  @override
  Widget build(BuildContext context) {

    if (widget.userData["id"] != _currentUser!.uid) {

      final fullName = widget.userData["first_name"] + " " + widget.userData["last_name"];

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserChatScreen(
                fullName: fullName,
                receiverId: widget.userData["id"],
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
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
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
      return Container();
    }
  }
}
