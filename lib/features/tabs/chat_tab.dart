import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:collection/collection.dart';
import 'package:auto_animated_list/auto_animated_list.dart';

import '../../../services/database.dart';
import '../../helpers/extensions.dart';
import '../../router/routes.dart';
import '../../themes/styles.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, int> unreadMessagesCount = {};
  Map<String, DateTime> lastMessageTime = {};

  Stream<QuerySnapshot>? _stream;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getIdAzienda(),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (snapshot.data == null) return Column();

        String idAzienda = snapshot.data!;

        _stream = FirebaseFirestore.instance.collection('users')
          .where('isApproved', isEqualTo: true)
          .where('azienda', isEqualTo: FirebaseFirestore.instance.collection('aziende').doc(idAzienda))
          .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(context.tr('somethingWentWrong'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var users = snapshot.data!.docs;
            Map<int, dynamic> tempUsers = {};
            users.forEachIndexed((index, user) {
              if (lastMessageTime[user['uid']] != null) {
                tempUsers[lastMessageTime[user['uid']]!.microsecondsSinceEpoch * -1] = user;
              }
              else {
                tempUsers[index * -1] = user;
              }
            });

            List sortedUsers = Map.fromEntries(tempUsers.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key))).values.toList();

            return AutoAnimatedList(
              items: sortedUsers,
              itemBuilder: (context, doc, index, animation) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                if (_auth.currentUser!.email != data['email']) {
                  getUnreadMessagesCount(_auth.currentUser!.uid, data['uid']);
                  getLastMessageTime(_auth.currentUser!.uid, data['uid']);

                  return SizeFadeTransition(
                    animation: animation,
                    child: ListTile(
                      leading: data['profilePic'] != null && data['profilePic'] != ''
                          ? Hero(
                              tag: data['profilePic'],
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: data['profilePic'],
                                  placeholder: (context, url) =>
                                      Image.asset('assets/images/loading.gif'),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error_outline_rounded),
                                  width: 50.w,
                                  height: 50.h,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : Image.asset(
                              'assets/images/user.png',
                              height: 50.h,
                              width: 50.w,
                              fit: BoxFit.cover,
                            ),
                      tileColor: const Color(0xff111B21),
                      title: Text(
                        data['name'],
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        data['isOnline']
                            ? context.tr('online')
                            : context.tr('offline'),
                        style: const TextStyle(
                          color: Color.fromARGB(255, 179, 178, 178),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      trailing: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          lastMessageTime[data['uid']] != null ?
                            Text(
                              formatDate(lastMessageTime[data['uid']]!),
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ) : Column(),
                          unreadMessagesCount[data['uid']] != null ?
                            Column(
                              children: [
                                Gap(5.h),
                                CircleAvatar(
                                  backgroundColor: Colors.red,
                                  maxRadius: 10,
                                  child: Center(
                                    child: Text(
                                      unreadMessagesCount[data['uid']].toString(),
                                      style: TextStyles.font12White500Weight,
                                    ),
                                  ),
                                ),
                              ],
                            ) : Column(),
                        ],
                      ),
                      isThreeLine: true,
                      titleAlignment: ListTileTitleAlignment.center,
                      enableFeedback: true,
                      dense: false,
                      titleTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                        height: 1.2.h,
                      ),
                      subtitleTextStyle: TextStyle(
                        height: 2.h,
                      ),
                      horizontalTitleGap: 15.w,
                      onTap: () {
                        context.pushNamed(Routes.chatScreen, arguments: data)
                          .then((_) {
                            setState(() {
                              lastMessageTime = {};
                              unreadMessagesCount = {};
                            });
                          });
                      },
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            );
          },
        );
      },
    );
  }

  getLastMessageTime(String userID, String otherUserID) async {
    var snapshot = await DatabaseMethods.getChat(userID, otherUserID);
    if (snapshot.data() != null) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      var lastMessage = data['lastMessage'].toDate();

      if (lastMessageTime[otherUserID] == null) {
        setState(() {
          lastMessageTime[otherUserID] = lastMessage;
        });
      }
    }
  }

  String formatDate(date) {
    var year = DateFormat(DateFormat.YEAR, 'it_IT').format(date.toUtc());
    var currentYear = DateFormat(DateFormat.YEAR, 'it_IT').format(DateTime.now());

    var monthDay = DateFormat(DateFormat.MONTH_DAY, 'it_IT').format(date.toUtc());
    var currentMonthDay = DateFormat(DateFormat.MONTH_DAY, 'it_IT').format(DateTime.now());

    String formatedDate = '';
    if (year == currentYear) {
      if (monthDay == currentMonthDay) {
        formatedDate = DateFormat(DateFormat.HOUR24_MINUTE, 'it_IT').format(date.toUtc());
      }
      else {
        formatedDate = DateFormat(DateFormat.MONTH_DAY, 'it_IT').format(date.toUtc()) + ' ' + DateFormat(DateFormat.HOUR24_MINUTE, 'it_IT').format(date.toUtc());
      }
    }
    else {
      formatedDate = DateFormat(DateFormat.YEAR_MONTH_DAY, 'it_IT').format(date.toUtc()) + ' ' + DateFormat(DateFormat.HOUR24_MINUTE, 'it_IT').format(date.toUtc());
    }

    return formatedDate;
  }

  getUnreadMessagesCount(String userID, String otherUserID) async {
    if (unreadMessagesCount[otherUserID] != null) return;

    var p = await DatabaseMethods.getUnreadMessagesCount(userID, otherUserID);
    if (p.count! > 0 && p.count! != unreadMessagesCount[otherUserID]) {
      setState(() {
        unreadMessagesCount[otherUserID] = p.count!;
      });
    }
    print(p.count!);
  }

  Future<String> getIdAzienda() async {
    DocumentSnapshot userDetails = await DatabaseMethods.getCurrentUserDetails();
    return userDetails['azienda'].id;
  }
}
