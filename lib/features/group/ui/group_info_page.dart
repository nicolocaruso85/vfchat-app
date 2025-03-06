import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../themes/colors.dart';
import '../../../themes/styles.dart';
import '../../../services/database.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupID;

  const GroupInfoScreen({
    super.key,
    required this.groupID,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  DocumentSnapshot? groupDetails;
  String? creatorName;
  String? creatorID;

  List membersList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (groupDetails != null) ? groupDetails!['name'] : ''
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 18.h,
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                nameField(),
                createdByField(),
                createdDateField(),
                membersField(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _loadGroupDetails();
  }

  SizedBox nameField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('name'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            (groupDetails != null) ? (groupDetails?['name']) : '',
            style: TextStyles.font16White600Weight,
          ),
          Gap(8.h),
        ],
      ),
    );
  }

  SizedBox createdByField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('createdBy'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            (creatorName != null) ? creatorName! : '',
            style: TextStyles.font16White600Weight,
          ),
          Gap(8.h),
        ],
      ),
    );
  }

  SizedBox createdDateField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('createdDate'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            (groupDetails != null) ? (formatDate(groupDetails?['createdDate'].toDate())) : '',
            style: TextStyles.font16White600Weight,
          ),
          Gap(8.h),
        ],
      ),
    );
  }

  SizedBox membersField() {
    if (membersList.length == 0) {
      return SizedBox();
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('members'),
            style: TextStyles.font15Green500Weight,
          ),
          ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: membersList.length,
            itemBuilder: (context, index) {
              var data = membersList[index];

              return ListTile(
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
                trailing: creatorID == data['uid'] ?
                  Text(
                    context.tr('admin'),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 179, 178, 178),
                    ),
                  ) : Text(''),
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
                  showUserOptions(context, data);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String formatDate(date) {
    return DateFormat(DateFormat.YEAR_MONTH_DAY, 'it_IT').format(date.toUtc()) + ' ' + DateFormat(DateFormat.HOUR24_MINUTE, 'it_IT').format(date.toUtc());
  }

  Future<void> _loadGroupDetails() async {
    membersList = [];

    DocumentSnapshot details = await DatabaseMethods.getGroup(widget.groupID);
    DocumentSnapshot creatorDetails = await details?['creatorId'].get();

    await details?['users'].forEach((user) async {
      var u = await user.get();

      setState(() {
        membersList.add(u);
      });
    });

    setState(() {
      groupDetails = details;
      creatorID = creatorDetails['uid'];
      creatorName = creatorDetails['name'];
    });
  }

  Future showUserOptions(context, data) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: Text(context.tr('delete')),
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);

              List uList = [];

              var users = membersList;
              users.forEach((u) {
                if (u['uid'] != data['uid']) {
                  uList.add(FirebaseFirestore.instance.collection('users').doc(u['uid']));
                }
              });

              DatabaseMethods.updateGroupDetails(widget.groupID, {'users': uList});

              _loadGroupDetails();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: (){
            Navigator.pop(context);
          }, 
          child: Text(context.tr('cancel')),
        ),
      ),
    );
  }
}
