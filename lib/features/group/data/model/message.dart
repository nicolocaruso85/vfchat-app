import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessage {
  final String senderID;
  final String senderName;
  final String message;
  final Timestamp timestamp;

  GroupMessage(
      {required this.senderID,
      required this.senderName,
      required this.message,
      required this.timestamp});
  // convert to a map
  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp
    };
  }
}
