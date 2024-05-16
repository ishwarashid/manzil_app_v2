import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:manzil_app_v2/models/message.dart';

class ChatService {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firebase.collection("users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        user["id"] = doc.id;
        return user;
      }).toList();
    });
  }

  // return FirebaseFirestore.instance.collection("chat_rooms").doc(chatRoomId)
  //     .collection("messages").orderBy("timestamp", descending: true)
  //     .snapshots();

  // Stream<List<Map<String, dynamic>>> getUsersStream(
  //     String userId, otherUserId) {
  //   List<String> ids = [userId, otherUserId];
  //   ids.sort();
  //   String chatRoomId = ids.join("_");
  //
  //   return _firebase
  //       .collection("chat_rooms")
  //       .doc(chatRoomId)
  //       .collection("messages")
  //       .where("senderId", whereIn: [userId, otherUserId])
  //       .where("receiverId", whereIn: [userId, otherUserId])
  //       .snapshots()
  //       .map((snapshot) {
  //         return snapshot.docs.map((doc) {
  //           final user = doc.data();
  //           user["id"] = doc.id;
  //           return user;
  //         }).toList();
  //       });
  // }

  // send message
  Future<void> sendMessage(String receiverId, message) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    print("inside sendMessage");

    CollectionReference users = FirebaseFirestore.instance.collection('users');
    DocumentSnapshot docSnapshot = await users.doc(currentUserId).get();

    final data = docSnapshot.data() as Map<String, dynamic>;

    final fullName = data["first_name"] + " " + data["last_name"];

    Message newMessage = Message(
        senderId: currentUserId,
        senderName: fullName,
        receiverId: receiverId,
        message: message,
        timestamp: timestamp);
    print("after message");

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");
    await FirebaseFirestore.instance
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .add(newMessage.toMap());

    print("after saving message");
  }

  // get messages
  Stream<QuerySnapshot> getMessages(String userId, otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return FirebaseFirestore.instance
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }
}
