import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_animated_list/auto_animated_list.dart';
import 'package:intl/intl.dart';

import '../../helpers/extensions.dart';
import '../../router/routes.dart';
import '../../themes/styles.dart';

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffdbdbdb), Colors.white],
          stops: [0.25, 1],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('groups')
            .where('users', arrayContains: FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid))
            .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(context.tr('somethingWentWrong'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var sortedGroups = snapshot.data!.docs;
            sortedGroups.sort((a, b) {
              if (a.data().toString().contains('lastMessage')) {
                if (b.data().toString().contains('lastMessage')) {
                  return b['lastMessage'].compareTo(a['lastMessage']);
                }
              }
              else {
                return 1;
              }
              return 0;
            });

            return AutoAnimatedList(
              items: sortedGroups,
              itemBuilder: (context, doc, index, animation) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                data['id'] = doc.id;

                return SizeFadeTransition(
                  animation: animation,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xffdedede),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 20,
                      ),
                      leading: data['groupPic'] != null && data['groupPic'] != ''
                          ? Hero(
                              tag: data['groupPic'],
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: data['groupPic'],
                                  placeholder: (context, url) =>
                                      Image.asset('assets/images/loading.gif'),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error_outline_rounded),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : Image.asset(
                              'assets/images/user.png',
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                      title: Text(
                        data['name'],
                        style: TextStyles.font18Black800Weight,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        data['users'].length.toString() + ' ' + context.tr('users'),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Color(0xff828282),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      trailing: Text(
                        data['lastMessage'] != null ? formatDate(data['lastMessage']!.toDate()) : '',
                        style: const TextStyle(
                          color: Color(0xff828282),
                        ),
                      ),
                      isThreeLine: true,
                      titleAlignment: ListTileTitleAlignment.center,
                      enableFeedback: true,
                      dense: false,
                      visualDensity: VisualDensity(vertical: 4),
                      titleTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                        height: 1.2.h,
                      ),
                      subtitleTextStyle: TextStyle(
                        height: 1.2.h,
                      ),
                      horizontalTitleGap: 2,
                      onTap: () {
                        context.pushNamed(Routes.groupScreen, arguments: data);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
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
}
