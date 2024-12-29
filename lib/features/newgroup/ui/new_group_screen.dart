import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:selectable_search_list/selectable_search_list.dart';

import '../../../themes/styles.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../services/database.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _auth = FirebaseAuth.instance;

  late TextEditingController nameController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  var selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('newGroup')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              nameField(),
              selectUsersList(),
              createButton(context),
              Gap(18.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Widget selectUsersList() {
    return StreamBuilder(
      stream: DatabaseMethods.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<ListItem> items = [];
        snapshot.data!.docs.forEach((var user) {
          if (user['uid'] != _auth.currentUser!.uid) {
            items.add(new ListItem(id: user['uid'], title: user['name']));
          }
        });

        return Expanded(
          child: MultiSelectListWidget(
            searchHint: context.tr('search'),
            selectAllTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            itemTitleStyle:  const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            items: items,
            onItemsSelect: (selectedItems) {
              selectedUsers = selectedItems;
            },
          ),
        );
      },
    );
  }

  Column nameField() {
    return Column(
      children: [
        AppTextFormField(
          hint: context.tr('name'),
          validator: (value) {
            if (value == null || value.isEmpty || value.startsWith(' ')) {
              return context.tr('pleaseEnterValid', args: ['Nome']);
            }
          },
          controller: nameController,
        ),
        Gap(18.h),
      ],
    );
  }

  createButton(BuildContext context) {
    return AppButton(
      buttonText: context.tr('create'),
      textStyle: TextStyles.font15DarkBlue500Weight,
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          var users = [];
          users.add(FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid));
          selectedUsers.forEach((selectedUser) {
            users.add(FirebaseFirestore.instance.collection('users').doc(selectedUser.id));
          });

          await FirebaseFirestore.instance
            .collection('groups')
            .add({
              'name': nameController.text,
              'users': users,
              'groupPic': '',
            });

          AwesomeDialog(
            dismissOnBackKeyPress: false,
            dismissOnTouchOutside: false,
            context: context,
            dialogType: DialogType.info,
            animType: AnimType.rightSlide,
            title: context.tr('newGroup'),
            desc: context.tr('newGroupCreated'),
            btnOkOnPress: () async {
              Navigator.of(context).pop();
            }
          ).show();
        }
      },
    );
  }
}
