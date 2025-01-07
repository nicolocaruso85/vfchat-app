import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_admin/firebase_admin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../firebase_options.dart';
import '../../../services/database.dart';
import '../../../themes/styles.dart';
import '../../../router/routes.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manageUsers')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Routes.addUserScreen);
        },
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(context.tr('somethingWentWrong'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                if (_auth.currentUser!.email != data['email']) {
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
                      data['email'],
                      style: const TextStyle(
                        color: Color.fromARGB(255, 179, 178, 178),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
                      showUserOptions(context, data);
                    },
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Future showUserOptions(context, data) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: Text(context.tr('edit')),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.editUserScreen, arguments: data);
            },
          ),
          CupertinoActionSheetAction(
            child: Text(context.tr('delete')),
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              DatabaseMethods.deleteUserDetails(data['uid']);

              await FirebaseAdmin.instance.app()!.auth().deleteUser(data['uid']);
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
