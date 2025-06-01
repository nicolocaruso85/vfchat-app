import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/already_have_account_text.dart';
import '../../../core/widgets/no_internet.dart';
import '../../../core/widgets/terms_and_conditions_text.dart';
import '../../../themes/colors.dart';
import '../../../themes/styles.dart';
import 'widgets/password_reset.dart';

class BuildForgetScreen extends StatelessWidget {
  const BuildForgetScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Luk',
                      style: TextStyles.font36Blue800Weight,
                    ),
                    Text(
                      'Up',
                      style: TextStyles.font36Red800Weight,
                    ),
                  ],
                ),
                Gap(20.h),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ColorsManager.purplePrimary, ColorsManager.redPrimary],
                        stops: [0.45, 1],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xffcccccc),
                          spreadRadius: 6,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(25),
                      child: Column(
                        children: [
                          Container(
                            width: 80.0,
                            height: 10.0,
                            child: Container(
                              decoration: new BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              ),
                            ),
                          ),
                          Gap(10.h),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Gap(40.h),
                                  Text(
                                    context.tr('reset'),
                                    style: TextStyles.font28White800Weight,
                                  ),
                                  Gap(10.h),
                                  Text(
                                    context.tr('enterEmailToResetPassword'),
                                    style: TextStyles.font14White400Weight,
                                  ),
                                  Gap(20.h),
                                  const PasswordReset(),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min, // Ensure minimum height
                                      children: [
                                        const TermsAndConditionsText(),
                                        Gap(24.h),
                                        const AlreadyHaveAccountText(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ForgetScreen extends StatelessWidget {
  const ForgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OfflineBuilder(
        connectivityBuilder: (
          BuildContext context,
          List<ConnectivityResult> connectivity,
          Widget child,
        ) {
          final bool connected =
              !connectivity.contains(ConnectivityResult.none);
          return connected
              ? const BuildForgetScreen()
              : const BuildNoInternet();
        },
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
