import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/networking/dio_factory.dart';
import '../helpers/access_token.dart';
import 'database.dart';

class NotificationService extends ChangeNotifier {
  Future<void> sendPushMessage(
    String receiverMToken,
    String senderMToken,
    String message,
    String senderName,
    String senderID,
    String? senderUserProfilePic,
  ) async {
    AccessToken accessToken = AccessToken();
    String token = await accessToken.getAccessToken();

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    var data = json.encode({
      "message": {
        "token": receiverMToken,
        "notification": {"body": message, "title": senderName},
        'data': {
          'name': senderName,
          'type': 'chat',
          'uid': senderID,
          'mtoken': senderMToken,
          'isOnline': 'true',
          'profilePic': senderUserProfilePic
        }
      }
    });

    Dio dio = DioFactory.getDio();
    await dio.request(
      'https://fcm.googleapis.com/v1/projects/vfchat-cba48/messages:send',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );
  }

  Future<void> sendGroupPushMessage(
    String groupId,
    String senderMToken,
    String message,
    String senderName,
    String senderID,
    String? senderUserProfilePic,
  ) async {
    final _auth = FirebaseAuth.instance;

    AccessToken accessToken = AccessToken();
    String token = await accessToken.getAccessToken();

    var group = await DatabaseMethods.getGroup(groupId);

    group['users'].forEach((user) async {
      var u = await user.get();

      if (u['uid'] != _auth.currentUser!.uid) {
        var headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        };
        var data = json.encode({
          "message": {
            "token": u['mtoken'],
            "notification": {"body": message, "title": senderName},
            'data': {
              'name': senderName,
              'type': 'group',
              'uid': senderID,
              'mtoken': senderMToken,
              'isOnline': 'true',
              'groupId': groupId,
              'profilePic': senderUserProfilePic
            }
          }
        });

        Dio dio = DioFactory.getDio();
        await dio.request(
          'https://fcm.googleapis.com/v1/projects/vfchat-cba48/messages:send',
          options: Options(
            method: 'POST',
            headers: headers,
          ),
          data: data,
        );
      }
    });
  }
}
