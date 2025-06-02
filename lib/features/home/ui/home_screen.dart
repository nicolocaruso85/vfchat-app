import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:event/event.dart';
import 'package:gap/gap.dart';

import '../../../helpers/extensions.dart';
import '../../../router/routes.dart';
import '../../../services/database.dart';
import '../../../themes/colors.dart';
//import '../../tabs/calls_tab.dart';
import '../../tabs/chat_tab.dart';
import '../../tabs/groups_tab.dart';
import '../../search/ui/search_groups.dart';
import '../../search/ui/search_users.dart';
import '../../../themes/styles.dart';
import '../../../core/widgets/app_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();

  TextEditingController? controller;

  DocumentSnapshot? currentUserDetails;

  var userSearchEvent = Event('userSearch');
  var groupSearchEvent = Event('groupSearch');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: SpeedDial(
          icon: Icons.add,
          iconTheme: IconThemeData(color: Colors.white),
          renderOverlay: false,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.message),
              backgroundColor: ColorsManager.redPrimary,
              foregroundColor: Colors.white,
              label: context.tr('newMessage'),
              onTap: () {
                showSearchModal();
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.group),
              backgroundColor: ColorsManager.redPrimary,
              foregroundColor: Colors.white,
              label: context.tr('createGroup'),
              onTap: () {
                context.pushNamed(Routes.newGroupScreen);
              },
            ),
            /*SpeedDialChild(
              child: const Icon(Icons.video_call_outlined),
              backgroundColor: Color(0xffd93d5c),
              foregroundColor: Colors.white,
              label: context.tr('startCall'),
              onTap: () {

              },
            ),*/
          ],
        ),
        appBar: AppBar(
          title: Text(
            context.tr('title'),
            style: TextStyles.font24Red800Weight,
          ),
          bottom: TabBar(
            indicatorColor: ColorsManager.redPrimary,
            indicatorWeight: 3.5,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: ColorsManager.redPrimary,
            tabs: [
              Tab(text: context.tr('chats')),
              Tab(text: context.tr('groups')),
              //Tab(text: context.tr('calls')),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              color: ColorsManager.redPrimary,
              onPressed: () {
                showSearchModal();
              },
            ),
            _buildPopMenu(),
            Gap(10),
          ],
        ),
        body: const TabBarView(
          children: [
            ChatsTab(),
            GroupsTab(),
            //CallsTab(),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        await DatabaseMethods.updateUserDetails({'isOnline': true});

        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        await DatabaseMethods.updateUserDetails({'isOnline': false});

        break;
      default:
        await DatabaseMethods.updateUserDetails({'isOnline': false});

        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        await DatabaseMethods.updateUserDetails({'isOnline': true});
        await setupInteractedMessage();
      },
    );
    _loadCurrentUserDetails();
  }

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _goToNotificationChatPage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_goToNotificationChatPage);
  }

  Widget _buildPopMenu() {
    return GestureDetector(
      onTap: () {
        showDialog<String>(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) => Dialog.fullscreen(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xffdbdbdb), Colors.white],
                  stops: [0.25, 1],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                context.pop();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Transform.rotate(
                                        angle: -math.pi / 4,
                                        child: Container(
                                          width: 40,
                                          height: 2.5,
                                          color: ColorsManager.redPrimary,
                                        ),
                                      ),
                                      Transform.rotate(
                                        angle: math.pi / 4,
                                        child: Container(
                                          width: 40,
                                          height: 2.5,
                                          color: ColorsManager.purplePrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Gap(15.h),
                          Text(
                            context.tr('home').toUpperCase(),
                            style: TextStyles.font24Red800Weight,
                          ),
                          Gap(25.h),
                          GestureDetector(
                            onTap: () {
                              context.pop();
                              context.pushNamed(Routes.newGroupScreen);
                            },
                            child: Text(
                              context.tr('newGroup').toLowerCase(),
                              style: TextStyles.font20Black300Weight,
                            ),
                          ),
                          Gap(15.h),
                          if (currentUserDetails != null && currentUserDetails?['isAdmin'])
                            GestureDetector(
                              onTap: () {
                                context.pop();
                                context.pushNamed(Routes.manageUsersScreen);
                              },
                              child: Text(
                                context.tr('manageUsers').toLowerCase(),
                                style: TextStyles.font20Black300Weight,
                              ),
                            ),
                          if (currentUserDetails != null && currentUserDetails?['isAdmin'])
                            Gap(15.h),
                          GestureDetector(
                            onTap: () {
                              context.pop();
                              context.pushNamed(Routes.userProfileScreen);
                            },
                            child: Text(
                              context.tr('userProfile').toLowerCase(),
                              style: TextStyles.font20Black300Weight,
                            ),
                          ),
                          Gap(15.h),
                          GestureDetector(
                            onTap: () {
                              context.pop();
                              context.pushNamed(Routes.notificationsScreen);
                            },
                            child: Text(
                              context.tr('notifications').toLowerCase(),
                              style: TextStyles.font20Black300Weight,
                            ),
                          ),
                          Gap(15.h),
                          GestureDetector(
                            onTap: () {
                              context.pop();
                              context.pushNamed(Routes.settingsScreen);
                            },
                            child: Text(
                              context.tr('settings').toLowerCase(),
                              style: TextStyles.font20Black300Weight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.pushNamed(Routes.notificationsScreen);
                            },
                            child: Text(
                              context.tr('privacyPolicy').toLowerCase(),
                              style: TextStyles.font20Black300Weight,
                            ),
                          ),
                          Gap(15.h),
                          AppButton(
                            buttonText: context.tr('signOut'),
                            textStyle: TextStyles.font20White600Weight,
                            verticalPadding: 0,
                            onPressed: () async {
                              try {
                                await GoogleSignIn().disconnect();
                              } finally {
                                await DatabaseMethods.updateUserDetails({'isOnline': false});

                                SharedPreferences prefs = await SharedPreferences.getInstance();

                                if (prefs.getBool('auth_screen_enabled') != null) {
                                  await prefs.remove('auth_screen_enabled');
                                }

                                await _auth.signOut();

                                // ignore: control_flow_in_finally
                                if (!context.mounted) return;
                                context.pushNamedAndRemoveUntil(
                                  Routes.loginScreen,
                                  predicate: (route) => false,
                                );
                              }
                            },
                          ),
                          Gap(20.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 45,
        height: 45,
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              height: 2,
              color: ColorsManager.redPrimary,
            ),
            Container(
              height: 2,
              color: ColorsManager.purplePrimary,
            ),
          ],
        ),
      ),
    );
  }

  void _goToNotificationChatPage(RemoteMessage message) async {
    if (message.data['type'] == 'chat') {
      context.pushNamed(Routes.chatScreen, arguments: message.data);
    } else if (message.data['type'] == 'group') {
      var group = await DatabaseMethods.getGroup(message.data['groupId']);
      context.pushNamed(Routes.groupScreen, arguments: {
        'id': message.data['groupId'],
      });
    } else {
      context.pushReplacementNamed(Routes.homeScreen);
    }
  }

  showSearchModal() {
    showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      builder: (context) => Material(
        child: Scaffold(
          backgroundColor: ColorsManager.backgroundDefaultColor,
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchBar(
                  controller: controller,
                  autoFocus: true,
                  hintText: context.tr('search'),
                  textStyle: MaterialStateProperty.all(TextStyles.font20Black300Weight),
                  padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 16.0)),
                  onChanged: (value) {
                    userSearchEvent.broadcast(Value(value));
                    groupSearchEvent.broadcast(Value(value));
                  },
                  trailing: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        userSearchEvent.unsubscribeAll();
                        groupSearchEvent.unsubscribeAll();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                Gap(20),
                SearchUsers(userSearchEvent: userSearchEvent),
                SearchGroups(groupSearchEvent: groupSearchEvent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadCurrentUserDetails() async {
    DocumentSnapshot userDetails = await DatabaseMethods.getCurrentUserDetails();

    setState(() {
      currentUserDetails = userDetails;
    });
  }
}
