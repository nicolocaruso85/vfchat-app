import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../../core/widgets/login_and_signup_form.dart';
import '../../../core/widgets/modal_fit.dart';
import '../../../core/widgets/no_internet.dart';
import '../../../core/widgets/terms_and_conditions_text.dart';
import '../../../services/google_sign_in.dart';
import '../../../themes/styles.dart';
import 'widgets/do_not_have_account.dart';

class BuildLoginScreen extends StatelessWidget {
  const BuildLoginScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(left: 30.w, right: 30.w, bottom: 15.h, top: 5.h),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('login'),
                      style: TextStyles.font24White600Weight,
                    ),
                    Gap(10.h),
                    Text(
                      context.tr('loginToContinue'),
                      style: TextStyles.font14Grey400Weight,
                    ),
                    Gap(10.h),
                    EmailAndPassword(),
                    Gap(10.h),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Ensure minimum height
                children: [
                  const TermsAndConditionsText(),
                  Gap(15.h),
                  const DoNotHaveAccountText(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool first = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OfflineBuilder(
        connectivityBuilder: (
          BuildContext context,
          List<ConnectivityResult> connectivity,
          Widget child,
        ) {
          if (first) {
            first = false;
            return BuildLoginScreen();
          }

          final bool connected =
              !connectivity.contains(ConnectivityResult.none);
          return (connected) ? const BuildLoginScreen() : const BuildNoInternet();
        },
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
