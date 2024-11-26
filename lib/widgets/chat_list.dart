import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v2/providers/current_user_provider.dart';

import 'package:manzil_app_v2/services/chat/chat_services.dart';
import 'package:manzil_app_v2/widgets/chat_list_item.dart';

class ChatList extends ConsumerWidget {
  ChatList({super.key});

  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    return StreamBuilder(
      stream: _chatService.getUsersStream(currentUser),
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

        return ListView(
          children: snapshot.data!
              .map<Widget>((userData) => ChatListItem(userData: userData))
              .toList(),
        );
      },
    );
    ;
  }
}
