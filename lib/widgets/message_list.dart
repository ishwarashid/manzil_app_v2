import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v2/services/chat/chat_services.dart';
import 'package:manzil_app_v2/widgets/message_bubble.dart';

import '../services/socket_handler.dart';

class MessageList extends StatefulWidget {
  const MessageList({super.key, required this.receiverId,});

  final String receiverId;

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {

  final box = GetStorage();

  final ChatService _chatService = ChatService();

  var isLoading = true;

  late var loadedMessages = [];


  void loadMessages(String senderId) async {
    loadedMessages = await _chatService.getMessages(senderId, widget.receiverId);

    if(mounted){
      setState(() {
        isLoading = false;
      });
    }

  }

  @override
  void initState() {
    List<String> ids = [box.read("_id"), widget.receiverId];
    ids.sort();
    String eventId = ids.join("_");

    SocketHandler.socket.on(eventId, (data) =>  {

    if(mounted){
        setState(() {
      loadedMessages = [List.from(data).first, ...loadedMessages];
        })
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    loadedMessages.clear();
    super.dispose();
  }

  final Map<int, String> daysOfWeek =
  {
    1: "Sunday",
    2: "Tuesday",
    3: "Wednesday",
    4: "Thursday",
    5: "Friday",
    6: "Saturday",
    7: "Sunday"
  };

  @override
  Widget build(BuildContext context) {
    final String senderId = box.read("_id");

          if(isLoading){
            loadMessages(senderId);
            return const Center(
              child: CircularProgressIndicator());
          }

          if(loadedMessages.isEmpty){
              return const Center(
                  child: Text('No messages found.'));
          }

        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 30,
            // bottom: 40,
            left: 13,
            right: 13,
          ),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessages[index] as Map<String, dynamic>;
            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1] as Map<String, dynamic>
                : null;

            final currentMessageUserId = chatMessage['senderId'];
            final nextMessageUserId =
                nextChatMessage != null ? nextChatMessage['senderId'] : null;
            final nextUserIsSame = nextMessageUserId == currentMessageUserId;
            final DateTime date = DateTime.parse(chatMessage['timestamp']).toLocal();
            String time = "${date.hour}:${date.minute.toString().length > 1 ? date.minute : "0${date.minute}"} ${DateTime.now().weekday != date.weekday ? daysOfWeek[date.weekday]!.substring(0, 3) : ""}";


            if (nextUserIsSame) {
              return MessageBubble.next(
                message: chatMessage['message'],
                isMe: box.read("_id") == currentMessageUserId,
                time: time
              );
            } else {
            return MessageBubble.first(
            name: currentMessageUserId == box.read("_id")
            ? "You"
                : chatMessage['senderName'],
            message: chatMessage['message'],
            isMe: box.read("_id") == currentMessageUserId,
                time: time
            );
            }
          },
        );
      }
    // );
  // }
}
