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
import 'package:king_cache/king_cache.dart';

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

  int loadedUnreadMessagesCount = -1;
  int loadedLastMessageTime = -1;
  int loadingCheckUsersPermissions = -1;

  List<dynamic> items = [];

  late final Future<DocumentSnapshot> azienda;

  @override
  void initState() {
    super.initState();

    azienda = getAzienda();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: FutureBuilder<DocumentSnapshot>(
        future: azienda,
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.data == null) return Column();

          DocumentSnapshot az = snapshot.data!;

          _stream = DatabaseMethods.getUsers(az.id);

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
              if (loadingCheckUsersPermissions == -1) {
                checkUserPermissions(users, az);
                loadingCheckUsersPermissions = 0;
              }

              if (loadingCheckUsersPermissions <= 0) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<int, dynamic> tempUsers = {};
              users.forEachIndexed((index, user) {
                if (lastMessageTime[user['uid']] != null) {
                  tempUsers[lastMessageTime[user['uid']]!.microsecondsSinceEpoch * -1] = user;
                }
                else if (items.contains(user['uid'])) {
                  tempUsers[index * -1] = user;
                }
              });

              List sortedUsers = Map.fromEntries(tempUsers.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key))).values.toList();

              if (loadedUnreadMessagesCount <= 0 || loadedLastMessageTime <= 0) {
                if (loadedUnreadMessagesCount == -1) {
                  loadedUnreadMessagesCount = 0;
                  getUnreadMessagesCount(users);
                }
                if (loadedLastMessageTime == -1) {
                  loadedLastMessageTime = 0;
                  getLastMessageTime(users);
                }

                return const Center(child: CircularProgressIndicator());
              }

              return AutoAnimatedList(
                items: sortedUsers,
                itemBuilder: (context, doc, index, animation) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                  if (_auth.currentUser!.email != data['email']) {
                    return SizeFadeTransition(
                      animation: animation,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
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
                        title: Text(
                          data['name'],
                          style: TextStyles.font18Black800Weight,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          data['isOnline']
                              ? context.tr('online')
                              : context.tr('offline'),
                          style: const TextStyle(
                            color: Color(0xff828282),
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
                        horizontalTitleGap: 5,
                        shape: Border(
                          bottom: BorderSide(
                            color: Color(0x0ffcdcdcd),
                            width: 1,
                          ),
                        ),
                        onTap: () {
                          context.pushNamed(Routes.chatScreen, arguments: data)
                            .then((_) {
                              setState(() {
                                loadedLastMessageTime = -1;
                                loadedUnreadMessagesCount = -1;
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
      ),
    );
  }

  getLastMessageTime(List users) async {
    Map<String, DateTime> lastMessTime = {};

    await Future.forEach(users, (user) async {
      String otherUserID = user['uid'];

      if (lastMessageTime[otherUserID] == null) {
        var snapshot = await DatabaseMethods.getChat(_auth.currentUser!.uid, otherUserID);
        if (snapshot.data() != null) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

          var lastMessage = data['lastMessage'].toDate();

          lastMessTime[otherUserID] = lastMessage;
        }
      }
    });

    setState(() {
      lastMessageTime = lastMessTime;
      loadedLastMessageTime = 1;
    });
  }

  String formatDate(date) {
    var year = DateFormat(DateFormat.YEAR, 'it_IT').format(date.toLocal());
    var currentYear = DateFormat(DateFormat.YEAR, 'it_IT').format(DateTime.now());

    var monthDay = DateFormat(DateFormat.MONTH_DAY, 'it_IT').format(date.toLocal());
    var currentMonthDay = DateFormat(DateFormat.MONTH_DAY, 'it_IT').format(DateTime.now());

    String formatedDate = '';
    if (year == currentYear) {
      if (monthDay == currentMonthDay) {
        formatedDate = DateFormat(DateFormat.HOUR24_MINUTE, 'it_IT').format(date.toLocal());
      }
      else {
        formatedDate = DateFormat(DateFormat.MONTH_DAY, 'it_IT').format(date.toLocal()) + ' ' + DateFormat(DateFormat.HOUR24_MINUTE, 'it_IT').format(date.toLocal());
      }
    }
    else {
      formatedDate = DateFormat(DateFormat.YEAR_MONTH_DAY, 'it_IT').format(date.toLocal()) + ' ' + DateFormat(DateFormat.HOUR24_MINUTE, 'it_IT').format(date.toLocal());
    }

    return formatedDate;
  }

  getUnreadMessagesCount(List users) async {
    Map<String, int> unreadMessCount = {};

    await Future.forEach(users, (user) async {
      String otherUserID = user['uid'];
      if (unreadMessagesCount[otherUserID] == null) {
        var p = await DatabaseMethods.getUnreadMessagesCount(_auth.currentUser!.uid, otherUserID);
        if (p.count! > 0 && p.count! != unreadMessagesCount[otherUserID]) {
          unreadMessCount[otherUserID] = p.count!;
        }
      }
    });

    setState(() {
      unreadMessagesCount = unreadMessCount;
      loadedUnreadMessagesCount = 1;
    });
  }

  Future<DocumentSnapshot> getAzienda() async {
    DocumentSnapshot userDetails = await DatabaseMethods.getCurrentUserDetails();
    return await DatabaseMethods.getAzienda(userDetails['azienda'].id);
  }

  checkUserPermissions(users, azienda) async {
    print(azienda!['api'] + 'check-permission/' + _auth.currentUser!.uid + '/gruppo');

    await KingCache.cacheViaRest(
      azienda!['api'] + 'check-permission/csrf_token',
      method: HttpMethod.get,
      onSuccess: (data) async {
        print(data);

        if (data != null && data.containsKey('csrf_token')) {
          print(data['csrf_token']);

          await KingCache.cacheViaRest(
            azienda!['api'] + 'check-permission/' + _auth.currentUser!.uid + '/gruppo',
            method: HttpMethod.post,
            headers: {
              'X-CSRF-TOKEN': data['csrf_token'],
              'Content-Type': 'application/json',
              'Cookie': 'exp_csrf_token=' + data['csrf_token'] + ';',
            },
            formData: {
              'user_ids': [],
            },
            onSuccess: (data) {
              print(data);

              if (data != null && data.containsKey('success')) {
                if (data['success'] == 1) {
                  setState(() {
                    items = data['user_ids'];

                    loadingCheckUsersPermissions = 1;
                  });
                }
              }
            },
            onError: (data) => debugPrint(data.message),
            apiResponse: (data) {
            },
            isCacheHit: (isHit) => debugPrint('Is Cache Hit: $isHit'),
            shouldUpdate: true,
            expiryTime: DateTime.now().add(const Duration(minutes: 1)),
          );
        }
      },
      onError: (data) => debugPrint(data.message),
      apiResponse: (data) {
      },
      isCacheHit: (isHit) => debugPrint('Is Cache Hit: $isHit'),
      expiryTime: DateTime.now().add(const Duration(minutes: 1)),
    );
  }
}
