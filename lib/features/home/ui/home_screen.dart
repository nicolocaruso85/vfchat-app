import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:event/event.dart';
import 'package:gap/gap.dart';

import '../../../helpers/extensions.dart';
import '../../../router/routes.dart';
import '../../../services/database.dart';
import '../../../themes/colors.dart';
import '../../tabs/calls_tab.dart';
import '../../tabs/chat_tab.dart';
import '../../tabs/groups_tab.dart';
import '../../search/ui/search_groups.dart';
import '../../search/ui/search_users.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();

  TextEditingController? controller;

  var userSearchEvent = Event('userSearch');
  var groupSearchEvent = Event('groupSearch');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButton: SpeedDial(
          icon: Icons.grid_view_rounded,
          iconTheme: IconThemeData(color: Colors.black),
          renderOverlay: false,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.message),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              label: 'Nuovo Messaggio',
              onTap: () {

              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.group),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              label: 'Crea Gruppo',
              onTap: () {

              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.video_call_outlined),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              label: 'Avvia Chiamata',
              onTap: () {

              },
            ),
          ],
        ),
        appBar: AppBar(
          title: Text(context.tr('title')),
          bottom: TabBar(
            indicatorColor: ColorsManager.greenPrimary,
            indicatorWeight: 3.5,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: ColorsManager.greenPrimary,
            unselectedLabelColor: const Color(0xffffffff).withOpacity(0.5),
            tabs: [
              Tab(text: context.tr('chats')),
              Tab(text: context.tr('groups')),
              Tab(text: context.tr('calls')),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              color: Colors.white,
              onPressed: () async {
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);

                if (pickedFile != null) {
                  if (!context.mounted) return;
                  context.pushNamed(Routes.displayPictureScreen, arguments: [
                    pickedFile,
                    '',
                    '',
                    '',
                  ]);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              color: Colors.white,
              onPressed: () {
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
              },
            ),
            _buildPopMenu(),
          ],
        ),
        body: const TabBarView(
          children: [
            ChatsTab(),
            GroupsTab(),
            CallsTab(),
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
  }

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _goToNotificationChatPage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_goToNotificationChatPage);
  }

  PopupMenuButton _buildPopMenu() {
    return PopupMenuButton(
      color: const Color.fromARGB(255, 41, 52, 59),
      icon: const Icon(Icons.more_vert),
      elevation: 8,
      position: PopupMenuPosition.under,
      iconColor: Colors.white,
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () {
            context.pushNamed(Routes.newGroupScreen);
          },
          child: Text(
            context.tr('newGroup'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        PopupMenuItem(
          onTap: () {
            context.pushNamed(Routes.settingsScreen);
          },
          child: Text(
            context.tr('settings'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        PopupMenuItem(
          onTap: () async {
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
          child: Text(
            context.tr('signOut'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _goToNotificationChatPage(RemoteMessage message) async {
    if (message.data['type'] == 'chat') {
      context.pushNamed(Routes.chatScreen, arguments: message.data);
    } else if (message.data['type'] == 'group') {
      var group = await DatabaseMethods.getGroup(message.data['groupId']);
      context.pushNamed(Routes.groupScreen, arguments: {
        'id': message.data['groupId'],
        'name': group['name'],
        'groupPic': group['groupPic'],
        'users': group['users'],
      });
    } else {
      context.pushReplacementNamed(Routes.homeScreen);
    }
  }
}
