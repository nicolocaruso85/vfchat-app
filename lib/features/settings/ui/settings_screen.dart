import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/modal_fit.dart';
import '../../../services/database.dart';
import '../../../themes/colors.dart';
import '../../../themes/styles.dart';
import '../../../router/routes.dart';

const bool keyAuthScreenDefaultValue = false;

const String keyAuthScreenEnabled = "auth_screen_enabled";

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAuthScreenEnabled = false;
  final LocalAuthentication auth = LocalAuthentication();
  late List<BiometricType> availableBiometric;

  DocumentSnapshot? currentUserDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('settings'),
          style: TextStyles.font18Black500Weight,
        ),
        iconTheme: IconThemeData(
          color: ColorsManager.redPrimary,
        ),
        forceMaterialTransparency: true,
        shape: Border(
          bottom: BorderSide(
            color: Color(0xffc2c2c2),
            width: 1.0,
          )
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            ListTile(
              title: Text(
                context.tr('userProfile'),
                style: TextStyles.font18Black600Weight,
              ),
              onTap: () {
                Navigator.pushNamed(context, Routes.userProfileScreen);
              },
            ),
            if (currentUserDetails != null && currentUserDetails?['isAdmin'])
              ListTile(
                title: Text(
                  context.tr('manageUsers'),
                  style: TextStyles.font18Black600Weight,
                ),
                onTap: () {
                  Navigator.pushNamed(context, Routes.manageUsersScreen);
                },
              ),
            /*ListTile(
              title: Text(
                context.tr('changeLanguage'),
                style: TextStyles.font18Black600Weight,
              ),
              onTap: () => showCupertinoModalBottomSheet(
                expand: false,
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => const ModalFit(),
              ),
            ),*/
            ListTile(
              title: Text(
                context.tr('unlockApp'),
                style: TextStyles.font18Black600Weight,
              ),
              subtitle: Text(
                context.tr('unlockAppDesc'),
                style: TextStyles.font14Grey400Weight,
              ),
              trailing: CupertinoSwitch(
                value: _isAuthScreenEnabled,
                onChanged: (value) {
                  setState(
                    () {
                      if (availableBiometric.isEmpty) {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.error,
                          animType: AnimType.topSlide,
                          showCloseIcon: true,
                          closeIcon: const Icon(Icons.close_rounded),
                          title: context.tr('warning'),
                          desc: context.tr('authNotSupported'),
                        ).show();
                      } else {
                        _isAuthScreenEnabled = value;
                        _setAuthScreenPreference(value);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await auth.getAvailableBiometrics().then((value) {
        availableBiometric = value;
      });
    });
    _loadAuthScreenPreference();
    _loadCurrentUserDetails();
  }

  Future<void> _loadAuthScreenPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isAuthScreenEnabled =
        prefs.getBool(keyAuthScreenEnabled) ?? keyAuthScreenDefaultValue;
    setState(() {});
  }

  Future<void> _setAuthScreenPreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAuthScreenEnabled, value);
  }

  Future<void> _loadCurrentUserDetails() async {
    DocumentSnapshot userDetails = await DatabaseMethods.getCurrentUserDetails();

    setState(() {
      currentUserDetails = userDetails;
    });
  }
}
