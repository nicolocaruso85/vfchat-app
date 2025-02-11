import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../helpers/app_regex.dart';
import '../../../themes/styles.dart';
import '../../helpers/extensions.dart';
import '../../router/routes.dart';
import '../../services/database.dart';
import '../../themes/colors.dart';
import 'app_button.dart';
import 'app_text_form_field.dart';
import 'password_validations.dart';

// ignore: must_be_immutable
class EmailAndPassword extends StatefulWidget {
  final bool? isSignUpPage;
  final bool? isPasswordPage;
  late GoogleSignInAccount? googleUser;
  late OAuthCredential? credential;
  EmailAndPassword({
    super.key,
    this.isSignUpPage,
    this.isPasswordPage,
    this.googleUser,
    this.credential,
  });

  @override
  State<EmailAndPassword> createState() => _EmailAndPasswordState();
}

class _EmailAndPasswordState extends State<EmailAndPassword> {
  bool isObscureText = true;

  bool hasMinLength = false;

  late final _auth = FirebaseAuth.instance;

  late TextEditingController nameController = TextEditingController();
  late TextEditingController emailController = TextEditingController();
  late TextEditingController passwordController = TextEditingController();
  late TextEditingController passwordConfirmationController =
      TextEditingController();
  late TextEditingController codiceAziendaController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          if (widget.isSignUpPage == true) nameField(),
          if (widget.isPasswordPage == null) emailField(),
          passwordField(),
          Gap(18.h),
          if (widget.isSignUpPage == true || widget.isPasswordPage == true)
            passwordConfirmationField(),
          if (widget.isSignUpPage == null && widget.isPasswordPage == null)
            forgetPasswordTextButton(context),
          Gap(10.h),
          PasswordValidations(
            hasMinLength: hasMinLength,
          ),
          if (widget.isSignUpPage == true) codiceAziendaField(),
          Gap(20.h),
          loginOrSignUpOrPasswordButton(context),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();

    passwordConfirmationController.dispose();

    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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

  Widget forgetPasswordTextButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        context.pushNamed(Routes.forgetScreen);
      },
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          context.tr('forgetPassword'),
          style: TextStyles.font15Green500Weight,
        ),
      ),
    );
  }

  getToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    return fcmToken;
  }

  @override
  void initState() {
    super.initState();
    setupPasswordControllerListener();
  }

  AppButton loginButton(BuildContext context) {
    return AppButton(
      buttonText: context.tr('login'),
      textStyle: TextStyles.font15DarkBlue500Weight,
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          try {
            final c = await _auth.signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );
            if (c.user!.emailVerified) {
              await DatabaseMethods.addUserDetails(
                {
                  'name': _auth.currentUser!.displayName,
                  'email': _auth.currentUser!.email,
                  'profilePic': _auth.currentUser!.photoURL,
                  'uid': _auth.currentUser!.uid,
                  'mtoken': await getToken(),
                  'isOnline': true,
                  'isAdmin': false,
                  'ruoli': [],
                  'gruppi': [],
                },
                SetOptions(mergeFields: ['name', 'email', 'profilePic', 'uid', 'mtoken', 'isOnline']),
              );

              if (!context.mounted) return;
              context.pushNamedAndRemoveUntil(
                Routes.homeScreen,
                predicate: (route) => false,
              );
            } else {
              await _auth.signOut();
              if (!context.mounted) return;

              AwesomeDialog(
                context: context,
                dialogType: DialogType.info,
                animType: AnimType.rightSlide,
                title: context.tr('emailNotVerified'),
                desc: context.tr('emailNotVerifiedDesc'),
              ).show();
            }
          } on FirebaseAuthException catch (e) {
            if (e.code == 'user-not-found') {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.error,
                animType: AnimType.rightSlide,
                title: context.tr('error'),
                desc: context.tr('userNotFound'),
              ).show();
            } else if (e.code == 'wrong-password') {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.error,
                animType: AnimType.rightSlide,
                title: context.tr('error'),
                desc: context.tr('wrongPassword'),
              ).show();
            } else {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.error,
                animType: AnimType.rightSlide,
                title: context.tr('error'),
                desc: e.code,
              ).show();
            }
          }
        }
      },
    );
  }

  loginOrSignUpOrPasswordButton(BuildContext context) {
    if (widget.isSignUpPage == true) {
      return signUpButton(context);
    }
    if (widget.isSignUpPage == null && widget.isPasswordPage == null) {
      return loginButton(context);
    }
    if (widget.isPasswordPage!) {
      return passwordButton(context);
    }
  }

  Column codiceAziendaField() {
    return Column(
      children: [
        Gap(18.h),
        AppTextFormField(
          hint: context.tr('codiceAzienda'),
          validator: (value) {
          },
          controller: codiceAziendaController,
        ),
        Gap(10.h),
        Text(
          context.tr('codiceAziendaDesc'),
          style: TextStyles.font14DarkBlue500Weight.copyWith(
            color: ColorsManager.lightShadeOfGray,
          ),
        ),
      ],
    );
  }

  Column nameField() {
    return Column(
      children: [
        AppTextFormField(
          hint: context.tr('name'),
          validator: (value) {
            if (value == null || value.isEmpty || value.startsWith(' ')) {
              return context.tr('pleaseEnterValid', args: ['Nome']);
            }
          },
          controller: nameController,
        ),
        Gap(18.h),
      ],
    );
  }

  AppButton passwordButton(BuildContext context) {
    return AppButton(
      buttonText: context.tr('createPassword'),
      textStyle: TextStyles.font15DarkBlue500Weight,
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          try {
            await _auth.createUserWithEmailAndPassword(
              email: widget.googleUser!.email,
              password: passwordController.text,
            );

            await _auth.currentUser!.linkWithCredential(widget.credential!);
            await _auth.currentUser!
                .updateDisplayName(widget.googleUser!.displayName);
            await _auth.currentUser!
                .updatePhotoURL(widget.googleUser!.photoUrl);

            await DatabaseMethods.addUserDetails(
              {
                'name': widget.googleUser!.displayName,
                'profilePic': widget.googleUser!.photoUrl,
                'email': widget.googleUser!.email,
                'uid': _auth.currentUser!.uid,
                'mtoken': await getToken(),
                'isOnline': true,
                'isAdmin': false,
              },
            );
            if (!context.mounted) return;
            await AwesomeDialog(
              context: context,
              dialogType: DialogType.success,
              animType: AnimType.rightSlide,
              title: context.tr('success'),
              desc: context.tr('accountCreated'),
            ).show();

            if (!context.mounted) return;

            context.pushNamedAndRemoveUntil(
              Routes.homeScreen,
              predicate: (route) => false,
            );
          } on FirebaseAuthException catch (e) {
            if (e.code == 'email-already-in-use') {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.error,
                animType: AnimType.rightSlide,
                title: context.tr('error'),
                desc: context.tr('emailAlreadyExists'),
              ).show();
            } else {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.error,
                animType: AnimType.rightSlide,
                title: context.tr('error'),
                desc: e.message,
              ).show();
            }
          } catch (e) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              animType: AnimType.rightSlide,
              title: context.tr('error'),
              desc: e.toString(),
            ).show();
          }
        }
      },
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
        if (value != passwordController.text) {
          return context.tr('passwordsDontMatch');
        }
        if (value == null ||
            value.isEmpty ||
            !AppRegex.isPasswordValid(value)) {
          return context.tr('pleaseEnterValid', args: ['Password']);
        }
      },
    );
  }

  AppTextFormField passwordField() {
    return AppTextFormField(
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
        if (value == null ||
            value.isEmpty ||
            !AppRegex.isPasswordValid(value)) {
          return context.tr('pleaseEnterValid', args: ['Password']);
        }
      },
    );
  }

  void setupPasswordControllerListener() {
    passwordController.addListener(() {
      setState(() {
        hasMinLength = AppRegex.isPasswordValid(passwordController.text);
      });
    });
  }

  AppButton signUpButton(BuildContext context) {
    return AppButton(
      buttonText: context.tr('createAccount'),
      textStyle: TextStyles.font15DarkBlue500Weight,
      onPressed: () async {
        String codiceAzienda = codiceAziendaController.text;
        if (codiceAzienda != '') {
          AggregateQuerySnapshot numberAziende = await DatabaseMethods.getNumberAziendeByCodice(codiceAzienda);
          if (numberAziende.count == 0) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              animType: AnimType.rightSlide,
              title: context.tr('error'),
              desc: context.tr('codiceAziendaNotFound'),
            ).show();
          }
        }
        return;

        if (formKey.currentState!.validate()) {
          try {
            await _auth.createUserWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );
            await _auth.currentUser!.updateDisplayName(nameController.text);
            await _auth.currentUser!.sendEmailVerification();
            await DatabaseMethods.addUserDetails(
              {
                'name': nameController.text,
                'email': emailController.text,
                'profilePic': '',
                'uid': _auth.currentUser!.uid,
                'mtoken': await getToken(),
                'isOnline': false,
                'isAdmin': false,
                'ruoli': [],
                'gruppi': [],
                'codiceAzienda': codiceAziendaController.text,
              },
            );

            await _auth.signOut();
            if (!context.mounted) return;
            await AwesomeDialog(
              context: context,
              dialogType: DialogType.success,
              animType: AnimType.rightSlide,
              title: context.tr('success'),
              desc: context.tr('verifyYourEmail'),
            ).show();

            if (!context.mounted) return;

            context.pushNamedAndRemoveUntil(
              Routes.loginScreen,
              predicate: (route) => false,
            );
          } on FirebaseAuthException catch (e) {
            if (e.code == 'email-already-in-use') {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.error,
                animType: AnimType.rightSlide,
                title: context.tr('error'),
                desc: context.tr('emailAlreadyExists'),
              ).show();
            } else {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.error,
                animType: AnimType.rightSlide,
                title: context.tr('error'),
                desc: e.message,
              ).show();
            }
          } catch (e) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              animType: AnimType.rightSlide,
              title: context.tr('error'),
              desc: e.toString(),
            ).show();
          }
        }
      },
    );
  }
}
