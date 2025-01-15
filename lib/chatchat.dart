import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:firebase_admin/firebase_admin.dart';

import 'main.dart';
import 'router/app_routes.dart';
import 'themes/colors.dart';

class ChatChat extends StatefulWidget {
  final AppRoute appRoute;
  const ChatChat({
    super.key,
    required this.appRoute,
  });

  @override
  State<ChatChat> createState() => _ChatChatState();
}

class _ChatChatState extends State<ChatChat> {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      child: KeyboardDismisser(
        gestures: [
          GestureType.onTap,
          GestureType.onPanUpdateDownDirection,
        ],
        child: MaterialApp(
          title: 'Chat aziendale',
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: ColorsManager.greenPrimary,
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: ColorsManager.greenPrimary,
              selectionHandleColor: ColorsManager.greenPrimary,
              selectionColor: Color.fromARGB(209, 0, 168, 132),
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: ColorsManager.greenPrimary,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: ColorsManager.greenPrimary,
            ),
            scaffoldBackgroundColor: ColorsManager.backgroundDefaultColor,
            appBarTheme: const AppBarTheme(
              foregroundColor: Colors.white,
              backgroundColor: ColorsManager.appBarBackgroundColor,
            ),
          ),
          onGenerateRoute: widget.appRoute.onGenerateRoute,
          initialRoute: initialRoute,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();

    initializeFirebaseAdmin();
  }

  initializeFirebaseAdmin() async {
    var data = await rootBundle.load('assets/firebase/service-account.json');
    File file = File(Directory.systemTemp.path + '/service-account.json');
    file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));

    FirebaseAdmin.instance.initializeApp(AppOptions(
      credential: FirebaseAdmin.instance.certFromPath(Directory.systemTemp.path + '/service-account.json'),
    ));
  }
}
