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
        hintStyle: TextStyles.font14Grey400Weight,
        isDense: isDense ?? true,
        filled: true,
        fillColor: const Color(0xff273443),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 17.h),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.coralRed,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.coralRed,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        suffixIcon: suffixIcon,
      ),
      obscureText: isObscureText ?? false,
      style: TextStyles.font18White500Weight,
    );
  }
}
