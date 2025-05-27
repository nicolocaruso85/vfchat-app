import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../themes/colors.dart';
import '../../themes/styles.dart';

class AppTextFormField extends StatelessWidget {
  final String hint;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final bool? isObscureText;
  final bool? isDark;
  final bool? isDense;
  final TextInputType? keyboardType;
  final int? maxLines;
  final TextEditingController? controller;
  final Function(String?) validator;
  final TextInputAction? textInputAction;
  const AppTextFormField({
    super.key,
    required this.hint,
    this.suffixIcon,
    this.isObscureText,
    this.isDark,
    this.isDense,
    this.controller,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.keyboardType,
    this.maxLines,
    required this.validator,
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textInputAction: textInputAction,
      focusNode: focusNode,
      validator: (value) {
        return validator(value);
      },
      onChanged: onChanged,
      controller: controller,
      maxLines: (isObscureText == true) ? 1 : maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintFadeDuration: const Duration(milliseconds: 500),
        hintStyle: TextStyles.font18Grey400Weight,
        isDense: isDense ?? true,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 17.h),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: (isDark == true) ? Color(0x77000000) : Color(0x77ffffff),
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: (isDark == true) ? Color(0xdd000000) : Color(0xddffffff),
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.coralRed,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.coralRed,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        suffixIcon: suffixIcon,
        errorStyle: TextStyle(color: Colors.white),
      ),
      obscureText: isObscureText ?? false,
      style: (isDark == true) ? TextStyles.font18Black500Weight : TextStyles.font18White500Weight,
    );
  }
}
