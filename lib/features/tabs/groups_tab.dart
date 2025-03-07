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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('groups')
        .where('users', arrayContains: FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid))
        .orderBy('lastMessage', descending: true)
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(context.tr('somethingWentWrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var sortedGroups = snapshot.data!.docs;

        return AutoAnimatedList(
          items: sortedGroups,
          itemBuilder: (context, doc, index, animation) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            return SizeFadeTransition(
              animation: animation,
              child: ListTile(
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
                  data['users'].length.toString() + ' ' + context.tr('users'),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 179, 178, 178),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                trailing: Text(
                  data['lastMessage'] != null ? formatDate(data['lastMessage']!.toDate()) : '',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
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
                  context.pushNamed(Routes.groupScreen, arguments: data);
                },
              ),
            );
          },
        );
      },
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
