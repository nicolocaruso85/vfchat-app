import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:infinite_grouped_list/infinite_grouped_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/database.dart';
import '../../../themes/colors.dart';
import '../../../themes/styles.dart';

class Notification {
  final String message;
  final DateTime time;

  Notification({
    required this.message,
    required this.time,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  InfiniteGroupedListController<Notification, DateTime, String> controller = InfiniteGroupedListController<Notification, DateTime, String>();

  DocumentSnapshot? lastDocument;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('notifications'),
          style: TextStyles.font18Black500Weight,
        ),
        iconTheme: IconThemeData(
          color: ColorsManager.redPrimary,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: InfiniteGroupedList(
          groupBy: (item) => item.time,
          controller: controller,
          itemBuilder: (item) => ListTile(
            contentPadding: const EdgeInsets.only(left: 5, right: 5),
            onTap: () {
            },
            title: Text(
              item.message,
              style: TextStyles.font12White500Weight,
            ),
            trailing: Text(
              DateFormat('kk:mm').format(item.time),
              style: TextStyles.font11MediumLightShadeOfGray400Weight,
            ),
          ),
          onLoadMore: (info) => onLoadMore(info.offset),
          groupTitleBuilder: (title, groupBy, isPinned, scrollPercentage) => Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 10),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          groupCreator: (dateTime) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final yesterday = today.subtract(const Duration(days: 1));
            final lastWeek = today.subtract(const Duration(days: 7));
            final lastMonth = DateTime(today.year, today.month - 1, today.day);

            if (today.day == dateTime.day &&
                today.month == dateTime.month &&
                today.year == dateTime.year) {
              return context.tr('today');
            } else if (yesterday.day == dateTime.day &&
                yesterday.month == dateTime.month &&
                yesterday.year == dateTime.year) {
              return context.tr('yesterday');
            } else if (lastWeek.isBefore(dateTime) &&
                dateTime.isBefore(yesterday)) {
              return context.tr('thisWeek');
            } else if (lastMonth.isBefore(dateTime) &&
                dateTime.isBefore(lastWeek)) {
              return context.tr('thisMonth');
            } else {
              return '${dateTime.day}-${dateTime.month}-${dateTime.year}';
            }
          },
        ),
      ),
    );
  }

  Future<List<Notification>> onLoadMore(int offset) async {
    if (offset == 0) {
      lastDocument = null;
    }

    QuerySnapshot snapshot = await DatabaseMethods.getUserNotifications(10, lastDocument);

    List docs = snapshot.docs;

    List<Notification> results = [];

    await Future.forEach(docs, (d) async {
      if (d['type'] == 'group_message') {
        DocumentSnapshot user = await d['senderID'].get();
        DocumentSnapshot group = await d['groupID'].get();

        results.add(Notification(
          message: context.tr('messageFromUser') + ' ' + user['name'] + ' ' + context.tr('withText') + ' ' + d['message'] + ' ' + context.tr('inGroup') + ' ' + group['name'],
          time: d['time'].toDate(),
        ));
      }
      else if (d['type'] == 'add_group') {
        DocumentSnapshot user = await d['senderID'].get();
        DocumentSnapshot group = await d['groupID'].get();

        results.add(Notification(
          message: user['name'] + ' ' + context.tr('addToGroup') + ' ' + group['name'],
          time: d['time'].toDate(),
        ));
      }
      else {
        DocumentSnapshot user = await d['senderID'].get();

        results.add(Notification(
          message: context.tr('messageFromUser') + ' ' + user['name'] + ' ' + context.tr('withText') + ' ' + d['message'],
          time: d['time'].toDate(),
        ));
      }
    });

    return results;
  }
}
