import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:manzil_app_v2/services/chat/chat_services.dart';
import 'package:manzil_app_v2/widgets/message_bubble.dart';

class MessageList extends StatelessWidget {
  MessageList({super.key, required this.receiverId});

  final String receiverId;
  final String senderId = FirebaseAuth.instance.currentUser!.uid;
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _chatService.getMessages(senderId, receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Something went wrong! Please try gain later."),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages found.'),
          );
        }

        final loadedMessages = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 20,
            // bottom: 40,
            left: 13,
            right: 13,
          ),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessages[index].data() as Map<String, dynamic>;
            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data() as Map<String, dynamic>
                : null;

            final currentMessageUserId = chatMessage['senderId'];
            final nextMessageUserId =
            nextChatMessage != null ? nextChatMessage['senderId'] : null;
            final nextUserIsSame = nextMessageUserId == currentMessageUserId;

            if (nextUserIsSame) {
              return MessageBubble.next(
                message: chatMessage['message'],
                isMe: FirebaseAuth.instance.currentUser!.uid == currentMessageUserId,
              );
            } else {
              return MessageBubble.first(
                name: currentMessageUserId == FirebaseAuth.instance.currentUser!.uid ? "You" : chatMessage['sender_name'],
                message: chatMessage['message'],
                isMe: FirebaseAuth.instance.currentUser!.uid == currentMessageUserId,
              );
            }
          },
        );
      },
    );
  }
}
