import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v2/models/message.dart';
import 'package:http/http.dart' as http;

class ChatService {
  final box = GetStorage();
  final url = "https://shrimp-select-vertically.ngrok-free.app";

  Future<List<dynamic>> getUsers() async {

    final response = await http.get(
      Uri.parse('$url/users'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    final usersData = jsonDecode(response.body) as Map<String, dynamic>;
    final users = List.castFrom(usersData['data']);
    return users;

  }

  Future<List<dynamic>> getRideUsers() async {
    String userId = box.read("_id");
    final response = await http.get(
      Uri.parse('$url/ride-users/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if(response.statusCode == 404){
      return [];
    }

    final usersData = jsonDecode(response.body) as Map<String, dynamic>;

    List<dynamic> users = [];

    if(userId != usersData['data']['driver']["_id"].toString()){
      users.add(usersData['data']['driver']);
      return users;
    }

    List.castFrom(usersData['data']['passengers']).forEach((passenger){
      users.add(passenger["passenger"]);
    });

    return users;

  }

  Future<Map<String, dynamic>> getRide() async {
    String userId = box.read("_id");
    final response = await http.get(
      Uri.parse('$url/ride-users/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if(response.statusCode == 404){
      return {};
    }

    final rideData = jsonDecode(response.body) as Map<String, dynamic>;

    final ride = rideData["data"];

    return ride;

  }

  // send message
  Future<void> sendMessage(String receiverId, message) async {
    final currentUserId = box.read("_id");

    final fullName = box.read("firstName") + " " + box.read("lastName");

    Message newMessage = Message(
        senderId: currentUserId,
        senderName: fullName,
        receiverId: receiverId,
        message: message);

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    addMessage(chatRoomId, newMessage);

  }

  // get messages
  Future<List<dynamic>> getMessages(String userId, otherUserId) async {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    final response = await http.get(
      Uri.parse('$url/chatrooms?id=$chatRoomId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if(response.statusCode == 404){
      return [];
    }

    final chatroom = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = List.castFrom(chatroom['data']['messages']).reversed.toList();
    return messages;

  }


  void addMessage(String chatRoomId, Message message) async {

    await http.post(
      Uri.parse('$url/chatrooms'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "_id": chatRoomId,
        "message": jsonEncode(message.toMap())
    }),
    );

    return null;
  }
}
