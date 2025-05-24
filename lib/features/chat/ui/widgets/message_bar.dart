import 'package:chat_bubbles/message_bars/message_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../themes/colors.dart';
import '../../../../themes/styles.dart';

class CustomMessageBar extends StatelessWidget {
  final Function(String) onSend;
  final VoidCallback onShowOptions;
  const CustomMessageBar(
      {super.key, required this.onSend, required this.onShowOptions});

  @override
  Widget build(BuildContext context) {
    return MessageBar(
      messageBarHintText: context.tr('message'),
      messageBarHintStyle: TextStyles.font14Grey400Weight,
      messageBarTextStyle: TextStyles.font16Black400Weight,
      messageBarColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 7.h,
      ),
      paddingTextAndSendButton: EdgeInsets.only(left: 4.w),
      onSend: (message) async {
        WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
        await onSend(message);
      },
      sendButtonColor: ColorsManager.purplePrimary,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 4.w),
          child: Container(
            decoration: const BoxDecoration(
              color: ColorsManager.purplePrimary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 28,
              ),
              onPressed: onShowOptions,
            ),
          ),
        )
      ],
    );
  }
}
