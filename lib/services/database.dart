import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/chat/data/model/message.dart';
import '../features/group/data/model/message.dart';

class DatabaseMethods {
  static final _auth = FirebaseAuth.instance;
  static final _fireStore = FirebaseFirestore.instance;

  static Future<void> addUserDetails(Map<String, dynamic> data,
      [SetOptions? options]) async {
    await _fireStore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .set(data, options);
  }

  static Future<void> deleteUserDetails(userID) async {
    await _fireStore
        .collection('users')
        .doc(userID)
        .delete();
  }

  static Future<DocumentSnapshot> getCurrentUserDetails() async {
    return await _fireStore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();
  }

  static Future<DocumentSnapshot> getUserDetails(uid) async {
    return await _fireStore
        .collection('users')
        .doc(uid)
        .get();
  }

  static Future<DocumentSnapshot> getGroup(groupID) async {
    return await _fireStore
        .collection('groups')
        .doc(groupID)
        .get();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUsers() {
    return _fireStore
        .collection('users')
        .snapshots();
  }

  static Stream<QuerySnapshot> getGroupMessages(String groupID) {
    return _fireStore
        .collection('groups')
        .doc(groupID)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get Messages from firestore
  static Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    List<String> sortedIDs = [userID, otherUserID];
    sortedIDs.sort();
    String chatRoomID = sortedIDs.join('_');
    return _fireStore
        .collection('chats')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> sendGroupMessage(String message, String groupID) async {
    final currentUserID = _auth.currentUser!.uid;
    final currentUserName = _auth.currentUser!.displayName;
    final timestamp = Timestamp.now();
    // create a new message
    GroupMessage newMessage = GroupMessage(
      senderID: currentUserID,
      senderName: currentUserName!,
      message: message,
      timestamp: timestamp,
    );

    await _fireStore
        .collection('groups')
        .doc(groupID)
        .collection('messages')
        .add(
          newMessage.toMap(),
        );
  }

  // SEND MESSAGE
  static Future<void> sendMessage(String message, String receiverID) async {
    // get current user info
    final currentUserID = _auth.currentUser!.uid;
    final currentUserName = _auth.currentUser!.displayName;
    final timestamp = Timestamp.now();
    // create a new message
    Message newMessage = Message(
      senderID: currentUserID,
      senderName: currentUserName!,
      message: message,
      receiverID: receiverID,
      isViewed: false,
      timestamp: timestamp,
    );
    // construct chat room id from current user id and recvier id (Sorted to ensure uniqueness)
    List<String> sortedIDs = [currentUserID, receiverID];
    sortedIDs.sort();
    String chatRoomID = sortedIDs.join('_');

    // add message to database
    await _fireStore
        .collection('chats')
        .doc(chatRoomID)
        .collection('messages')
        .add(
          newMessage.toMap(),
        );
  }

  static Future<void> updateUserDetails(Map<String, dynamic> data,
      [SetOptions? options]) async {
    await _fireStore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update(data);
  }

  static Future<void> setMessageAsViewed(chatRoomID, messageId) async {
    await _fireStore
        .collection('chats')
        .doc(chatRoomID)
        .collection('messages')
        .doc(messageId)
        .update({'isViewed': true});
  }
}
