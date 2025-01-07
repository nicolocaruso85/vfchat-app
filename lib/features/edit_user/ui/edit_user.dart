import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../themes/styles.dart';
import '../../../services/database.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/password_validations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../helpers/app_regex.dart';

class EditUserScreen extends StatefulWidget {
  final String uid;
  const EditUserScreen({
    super.key,
    required this.uid,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  DocumentSnapshot? userDetails;

  bool isObscureText = true;

  bool hasMinLength = false;

  late TextEditingController nameController = TextEditingController();
  late TextEditingController emailController = TextEditingController();
  late TextEditingController passwordController = TextEditingController();
  late TextEditingController passwordConfirmationController =
      TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('editUser')),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 18.h,
        ),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              nameField(),
              emailField(),
              passwordField(),
              passwordConfirmationField(),
              Gap(20.h),
              modifyButton(context),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _loadUserDetails();
  }

  modifyButton(BuildContext context) {
    return AppButton(
      buttonText: context.tr('edit'),
      textStyle: TextStyles.font15DarkBlue500Weight,
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          await DatabaseMethods.updateUserDetailsByUid(
            widget.uid,
            {
              'name': nameController.text,
              'email': emailController.text,
            },
          );

          await AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: context.tr('editUserSuccess'),
            desc: context.tr('editUserSuccess'),
          ).show();

          Navigator.pop(context);
        }
      },
    );
  }

  Column nameField() {
    return Column(
      children: [
        AppTextFormField(
          hint: context.tr('name'),
          validator: (value) {
            if (value == null || value.isEmpty || value.startsWith(' ')) {
              return context.tr('pleaseEnterValid', args: ['Name']);
            }
          },
          controller: nameController,
        ),
        Gap(18.h),
      ],
    );
  }

  Widget passwordConfirmationField() {
    return AppTextFormField(
      controller: passwordConfirmationController,
      hint: context.tr('confirmPassword'),
      isObscureText: isObscureText,
      suffixIcon: GestureDetector(
        onTap: () {
          setState(() {
            isObscureText = !isObscureText;
          });
        },
        child: Icon(
          isObscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.white,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return null;

        if (value != passwordController.text) {
          return context.tr('passwordsDontMatch');
        }
        if (value != null && !AppRegex.isPasswordValid(value)) {
          return context.tr('pleaseEnterValid', args: ['Password']);
        }
      },
    );
  }

  Column passwordField() {
    return Column(
      children: [
        AppTextFormField(
          controller: passwordController,
          hint: context.tr('password'),
          isObscureText: isObscureText,
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                isObscureText = !isObscureText;
              });
            },
            child: Icon(
              isObscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return null;

            if (value != null && !AppRegex.isPasswordValid(value)) {
              return context.tr('pleaseEnterValid', args: ['Password']);
            }
          },
        ),
        Gap(18.h),
      ],
    );
  }

  Column emailField() {
    return Column(
      children: [
        AppTextFormField(
          hint: context.tr('email'),
          validator: (value) {
            if (value == null ||
                value.isEmpty ||
                !AppRegex.isEmailValid(value)) {
              return context.tr('pleaseEnterValid', args: ['Email']);
            }
          },
          controller: emailController,
        ),
        Gap(18.h),
      ],
    );
  }

  Future<void> _loadUserDetails() async {
    DocumentSnapshot details = await DatabaseMethods.getUserDetails(widget.uid);
    setState(() {
      userDetails = details;
      nameController.text = userDetails?['name'];
      emailController.text = userDetails?['email'];
    });
  }
}
