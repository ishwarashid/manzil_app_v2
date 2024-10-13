class Message {

  Message({
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
  });

  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "sender_name": senderName,
      "receiverId": receiverId,
      "message": message,
    };
  }

}