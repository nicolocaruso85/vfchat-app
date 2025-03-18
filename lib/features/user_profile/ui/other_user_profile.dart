import 'dart:io';
import 'package:avatar_better/avatar_better.dart' show Avatar;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../themes/colors.dart';
import '../../../themes/styles.dart';
import '../../../services/database.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String uid;

  const OtherUserProfileScreen({
    super.key,
    required this.uid,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  DocumentSnapshot? userDetails;
  DocumentSnapshot? azienda;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (userDetails != null) ? userDetails!['name'] : ''
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
                profileImageField(),
                nameField(),
                emailField(),
                telephoneField(),
                aziendaField(),
                ruoliField(),
                gruppiField(),
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

    _loadUserDetails();
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
            (userDetails != null) ? (userDetails?['name']) : '',
            style: TextStyles.font16White600Weight,
          ),
          Gap(8.h),
        ],
      ),
    );
  }

  SizedBox emailField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('email'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            (userDetails != null) ? (userDetails?['email']) : '',
            style: TextStyles.font16White600Weight,
          ),
          Gap(8.h),
        ],
      ),
    );
  }

  SizedBox telephoneField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('telephone'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            (userDetails != null) ? (userDetails?['telephone']) : '',
            style: TextStyles.font16White600Weight,
          ),
          Gap(8.h),
        ],
      ),
    );
  }

  SizedBox aziendaField() {
    if (azienda != null) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('azienda'),
              style: TextStyles.font15Green500Weight,
            ),
            Text(
              azienda?['nome'],
              style: TextStyles.font16White600Weight,
            ),
            Gap(8.h),
          ],
        ),
      );
    }

    return SizedBox();
  }

  SizedBox ruoliField() {
    if (azienda != null && userDetails != null && userDetails?['ruoli'].isNotEmpty) {
      List<String> roles = [];

      userDetails?['ruoli'].forEach((ruolo) {
        roles.add(azienda?['ruoli'].where((el) => el['id'] == ruolo['id']).first['nome']);
      });

      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('roles'),
              style: TextStyles.font15Green500Weight,
            ),
            Text(
              roles.join(', '),
              style: TextStyles.font16White600Weight,
            ),
            Gap(8.h),
          ],
        ),
      );
    }

    return SizedBox();
  }

  SizedBox gruppiField() {
    if (azienda != null && userDetails != null && userDetails?['gruppi'].isNotEmpty) {
      List<String> groups = [];

      userDetails?['gruppi'].forEach((ruolo) {
        groups.add(azienda?['gruppi'].where((el) => el['id'] == ruolo['id']).first['nome']);
      });

      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('groups'),
              style: TextStyles.font15Green500Weight,
            ),
            Text(
              groups.join(', '),
              style: TextStyles.font16White600Weight,
            ),
            Gap(8.h),
          ],
        ),
      );
    }

    return SizedBox();
  }

  Column profileImageField() {
    return Column(
      children: [
        Gap(4.h),
        Avatar(
          text: '',
          radius: 50,
          gradientBackgroundColor: const LinearGradient(colors: [const Color(0xff273443), const Color(0xff273443)]),
          imageNetwork: userDetails?['profilePic'] != '' ? (userDetails?['profilePic']) : null,
          image: userDetails?['profilePic'] == '' ? 'assets/images/user.png' : null,
        ),
        Gap(20.h),
      ],
    );
  }

  Future<void> _loadUserDetails() async {
    DocumentSnapshot details = await DatabaseMethods.getUserDetails(widget.uid);
    DocumentSnapshot a = await DatabaseMethods.getAzienda(details!['azienda'].id);

    setState(() {
      userDetails = details;

      azienda = a;
    });
  }
}
