import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../features/chat/ui/chat_page.dart';
import '../features/group/ui/group_page.dart';
import '../features/create_password/ui/create_password.dart';
import '../features/display_picture/ui/display_picture_screen.dart';
import '../features/display_picture/ui/display_group_picture_screen.dart';
import '../features/forget_password/ui/forget_screen.dart';
import '../features/home/ui/home_screen.dart';
import '../features/local_auth/auth.dart';
import '../features/login/ui/login_screen.dart';
import '../features/newgroup/ui/new_group_screen.dart';
import '../features/settings/ui/settings_screen.dart';
import '../features/signup/ui/sign_up_sceen.dart';
import '../features/update/ui/update.dart';
import '../features/manage_users/ui/manage_users.dart';
import '../features/add_user/ui/add_user.dart';
import '../features/edit_user/ui/edit_user.dart';
import 'routes.dart';

class AppRoute {
  Route? onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.authScreen:
        return MaterialPageRoute(
          builder: (context) => const Auth(),
        );

      case Routes.updateScreen:
        return MaterialPageRoute(
          builder: (context) => const UpdateScreen(),
        );

      case Routes.chatScreen:
        final arguments = routeSettings.arguments;
        if (arguments is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              receivedUserName: arguments['name'],
              receivedUserID: arguments['uid'],
              receivedMToken: arguments['mtoken'],
              active: (arguments['isOnline'] is String) ? bool.parse(arguments['isOnline']) : arguments['isOnline'],
              receivedUserProfilePic: arguments['profilePic'],
            ),
          );
        }

      case Routes.groupScreen:
        final arguments = routeSettings.arguments;
        if (arguments is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => GroupScreen(
              groupID: arguments['id'],
              groupName: arguments['name'],
              groupPic: arguments['groupPic'],
              users: arguments['users'],
            ),
          );
        }

      case Routes.forgetScreen:
        return MaterialPageRoute(
          builder: (context) => const ForgetScreen(),
        );

      case Routes.loginScreen:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );

      case Routes.signupScreen:
        return MaterialPageRoute(
          builder: (context) => const SignUpScreen(),
        );

      case Routes.createPassword:
        final arguments = routeSettings.arguments;
        if (arguments is List) {
          return MaterialPageRoute(
            builder: (_) => CreatePassword(
              googleUser: arguments[0],
              credential: arguments[1],
            ),
          );
        }

      case Routes.settingsScreen:
        return MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        );

      case Routes.manageUsersScreen:
        return MaterialPageRoute(
          builder: (context) => const ManageUsersScreen(),
        );

      case Routes.addUserScreen:
        return MaterialPageRoute(
          builder: (context) => const AddUserScreen(),
        );

      case Routes.editUserScreen:
        final arguments = routeSettings.arguments;
        if (arguments is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => EditUserScreen(
              uid: arguments['uid'],
            ),
          );
        }

      case Routes.newGroupScreen:
        return MaterialPageRoute(
          builder: (context) => const NewGroupScreen(),
        );

      case Routes.displayPictureScreen:
        final arguments = routeSettings.arguments;
        if (arguments is List) {
          return MaterialPageRoute(
            builder: (context) => DisplayPictureScreen(
              image: arguments[0] as XFile,
              token: arguments[1] as String,
              receivedMToken: arguments[2] as String,
              receivedUserID: arguments[3] as String,
            ),
          );
        }

      case Routes.displayGroupPictureScreen:
        final arguments = routeSettings.arguments;
        if (arguments is List) {
          return MaterialPageRoute(
            builder: (context) => DisplayGroupPictureScreen(
              image: arguments[0] as XFile,
              token: arguments[1] as String,
              groupID: arguments[2] as String,
            ),
          );
        }

      case Routes.homeScreen:
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
  
    }
    return null;
  }
}
