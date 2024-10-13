import 'package:flutter/material.dart';
import 'package:manzil_app_v2/services/chat/chat_services.dart';
import 'package:manzil_app_v2/widgets/message_list.dart';
import 'package:manzil_app_v2/widgets/new_message_input.dart';

class UserChatScreen extends StatelessWidget {
  UserChatScreen({super.key, required this.fullName, required this.receiverId});

  final String fullName;
  final String receiverId;

  final ChatService _chatService = ChatService();

  void _sendMessage(String enteredMessage) async {

    if (enteredMessage.trim().isNotEmpty) {
      await _chatService.sendMessage(receiverId, enteredMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fullName),
      ),
      body: Column(
        children: [
          Expanded(
            child: MessageList(receiverId: receiverId),
          ),
          NewMessageInput(onSendMessage: _sendMessage),
        ],
      ),
    );
  }
}
