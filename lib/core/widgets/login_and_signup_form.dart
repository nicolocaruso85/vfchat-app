import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_mobile_field/intl_mobile_field.dart';
import 'package:intl_mobile_field/flags_drop_down.dart';
import 'package:searchable_listview/searchable_listview.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../helpers/app_regex.dart';
import '../../../themes/styles.dart';
import '../../helpers/extensions.dart';
import '../../router/routes.dart';
import '../../services/database.dart';
import '../../themes/colors.dart';
import 'app_button.dart';
import 'app_text_form_field.dart';
import 'password_validations.dart';
import '../../features/login/ui/widgets/do_not_have_account.dart';

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

  bool chooseNegozio = false;

  late final _auth = FirebaseAuth.instance;

  late TextEditingController nameController = TextEditingController();
  late TextEditingController emailController = TextEditingController();
  late TextEditingController telephoneController =
      TextEditingController();
  late TextEditingController passwordController = TextEditingController();
  late TextEditingController passwordConfirmationController =
      TextEditingController();
  late TextEditingController codiceAziendaController = TextEditingController();

  String? telephone;
  String? dialCode;

  final formKey = GlobalKey<FormState>();

  DocumentSnapshot? azienda;

  int? selectedNegozio;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Gap(40.h),
          if (widget.isSignUpPage == null)
            Text(
              context.tr('welcome'),
              style: TextStyles.font28White800Weight,
            ),
          if (widget.isSignUpPage == true)
            Text(
              context.tr('joinUs'),
              style: TextStyles.font28White800Weight,
            ),
          Gap(30.h),
          if (chooseNegozio == true) negozioField(),
          if (widget.isSignUpPage == true && chooseNegozio == false) nameField(),
          if (widget.isPasswordPage == null && chooseNegozio == false) emailField(),
          if (widget.isSignUpPage == true && chooseNegozio == false) telephoneField(),
          if (chooseNegozio == false) passwordField(),
          if (widget.isSignUpPage == null && chooseNegozio == false) Gap(5.h),
          if (widget.isSignUpPage == true && chooseNegozio == false) Gap(18.h),
          if ((widget.isSignUpPage == true || widget.isPasswordPage == true) && chooseNegozio == false)
            passwordConfirmationField(),
          if ((widget.isSignUpPage == null && widget.isPasswordPage == null) && chooseNegozio == false)
            forgetPasswordTextButton(context),
          if (widget.isSignUpPage == null && chooseNegozio == false) Gap(10.h),
          if (widget.isSignUpPage == true && chooseNegozio == false) codiceAziendaField(),
          Gap(20.h),
          if (chooseNegozio == true) previousButton(context),
          if (widget.isSignUpPage == null && chooseNegozio == false) loginWithField(context),
          Gap(30.h),
          if (widget.isSignUpPage == null && chooseNegozio == false)
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DoNotHaveAccountText(),
                ],
              ),
            ),
          if (widget.isSignUpPage == null && chooseNegozio == false) Gap(15.h),
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
          textInputAction: TextInputAction.next,
          maxLines: 1,
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

  Column telephoneField() {
    return Column(
      children: [
        IntlMobileField(
          controller: telephoneController,
          decoration: InputDecoration(
            hintText: context.tr('telephone'),
            hintStyle: TextStyles.font18Grey400Weight,
            contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 17.h),
            border: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0x77ffffff),
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0x77ffffff),
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xddffffff),
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
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          fillColor: Colors.transparent,
          style: TextStyles.font18White500Weight,
          favorite: const ['IT'],
          initialCountryCode: 'IT',
          languageCode: 'it',
          onCountryChanged: (country) {
            dialCode = country.dialCode;
          },
          disableLengthCounter: true,
          dropdownTextStyle: TextStyles.font18White500Weight,
          onChanged: (phone) {
            telephone = phone.number;
          },
          validator: (value) {
            if (value == null) {
              return context.tr('pleaseEnterValid', args: ['Telefono']);
            }
          },
          invalidNumberMessage: context.tr('pleaseEnterValid', args: ['Telefono']),
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
          style: TextStyles.font16White600Weight,
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
      buttonText: context.tr('login2'),
      textStyle: TextStyles.font20White600Weight,
      verticalPadding: 0,
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          try {
            final c = await _auth.signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );
            if (c.user!.emailVerified) {
              DocumentSnapshot userDetails = await DatabaseMethods.getCurrentUserDetails();

              if (userDetails['isApproved'] == false) {
                _auth.signOut();

                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.info,
                  animType: AnimType.rightSlide,
                  title: context.tr('userNotApproved'),
                  desc: context.tr('userNotApprovedDesc'),
                ).show();

                return;
              }

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
    if (chooseNegozio == true) {
      return signUpButton(context);
    }
    if (widget.isSignUpPage == true) {
      return nextButton(context);
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
          maxLines: 1,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.tr('pleaseEnterValid', args: ['Codice Azienda']);
            }
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
          textInputAction: TextInputAction.next,
          maxLines: 1,
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
      textInputAction: TextInputAction.next,
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
      textInputAction: (widget.isSignUpPage == true) ? TextInputAction.next : TextInputAction.done,
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

  SizedBox negozioField() {
    List<dynamic> negozi = azienda!['negozi'];

    return SizedBox(
      height: MediaQuery.of(context).size.height - 510,
      child: Column(
        children: [
          Gap(5.h),
          Text(
            context.tr('chooseNegozio'),
            style: TextStyles.font16White600Weight,
          ),
          Gap(5.h),
          Expanded(
            child: SearchableList<dynamic>(
              inputDecoration: InputDecoration(
                labelText: context.tr('search'),
                fillColor: Colors.white,
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.blue,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              textStyle: TextStyles.font16White600Weight,
              filter: (search) {
                return negozi.where((negozio) => negozio['nome'].toLowerCase().contains(search.toLowerCase())).toList();
              },
              lazyLoadingEnabled: false,
              initialList: negozi,
              itemBuilder: (dynamic negozio) {
                return ListTile(
                  tileColor: const Color(0xff111B21),
                  title: Text(
                    negozio['nome'],
                    style: TextStyle(
                      color: selectedNegozio == negozio['id'] ? Colors.red : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                    height: 1.2.h,
                  ),
                  onTap: () {
                    setState(() {
                      selectedNegozio = negozio['id'];
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Column loginWithField(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                height: 2.0,
                child: Container(
                  decoration: new BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: Text(
                context.tr('loginWith'),
                style: TextStyles.font12White500Weight,
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                height: 2.0,
                child: Container(
                  decoration: new BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                  ),
                ),
              ),
            ),
          ],
        ),
        Gap(10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 60,
              child: SignInWithAppleButton(
                height: 80,
                text: '',
                style: SignInWithAppleButtonStyle.white,
                onPressed: () async {
                  final credential = await SignInWithApple.getAppleIDCredential(
                    scopes: [
                      AppleIDAuthorizationScopes.email,
                      AppleIDAuthorizationScopes.fullName,
                    ],
                  );

                  print(credential);

                  // Now send the credential (especially `credential.authorizationCode`) to your server to create a session
                  // after they have been validated with Apple (see `Integration` section for more information on how to do this)
                },
              ),
            ),
            Gap(15.w),
            SizedBox(
              width: 90,
              height: 60,
              child: CupertinoButton(
                padding: EdgeInsets.all(8),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                color: Colors.white,
                onPressed: () {
                },
                child: Image.asset(
                  'assets/images/google.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Column previousButton(BuildContext context) {
    return Column(
      children: [
        AppButton(
          buttonText: context.tr('previous'),
          backgroundColor: Colors.red.shade700,
          textStyle: TextStyles.font15DarkBlue500Weight,
          onPressed: () async {
            setState(() {
              chooseNegozio = false;
              selectedNegozio = null;
            });
          },
        ),
        Gap(10.h),
      ],
    );
  }

  AppButton nextButton(BuildContext context) {
    return AppButton(
      buttonText: context.tr('next'),
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

            return;
          }

          QuerySnapshot aziende = await DatabaseMethods.getAziendaByCodice(codiceAzienda);
          setState(() {
            azienda = aziende.docs[0];
            print(azienda);
          });
        }

        if (formKey.currentState!.validate()) {
          setState(() {
            chooseNegozio = true;
          });
        }
      },
    );
  }

  AppButton signUpButton(BuildContext context) {
    return AppButton(
      buttonText: context.tr('createAccount'),
      textStyle: TextStyles.font15DarkBlue500Weight,
      onPressed: () async {
        if (selectedNegozio == null) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            animType: AnimType.rightSlide,
            title: context.tr('error'),
            desc: context.tr('chooseNegozio'),
          ).show();
          return;
        }

        try {
          await _auth.createUserWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );
          await _auth.currentUser!.updateDisplayName(nameController.text);
          await _auth.currentUser!.sendEmailVerification();

          DocumentReference aziendaRef = await DatabaseMethods.getAziendaReference(azienda!.id);

          await DatabaseMethods.addUserDetails(
            {
              'name': nameController.text,
              'email': emailController.text,
              'telephone': telephone,
              'profilePic': '',
              'uid': _auth.currentUser!.uid,
              'mtoken': await getToken(),
              'isOnline': false,
              'isAdmin': false,
              'isApproved': false,
              'ruoli': [],
              'gruppi': [],
              'idSede': selectedNegozio,
              'codiceAzienda': codiceAziendaController.text.toUpperCase(),
              'azienda': aziendaRef,
            },
          );

          await DatabaseMethods.addUserUpdatesByUid(
            _auth.currentUser!.uid,
            {
              'name': nameController.text,
              'email': emailController.text,
              'telephone': telephone,
              'profilePic': '',
              'uid': _auth.currentUser!.uid,
              'mtoken': await getToken(),
              'isOnline': false,
              'isAdmin': false,
              'isApproved': false,
              'ruoli': [],
              'gruppi': [],
              'idSede': selectedNegozio,
              'codiceAzienda': codiceAziendaController.text.toUpperCase(),
              'azienda': aziendaRef,
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
      },
    );
  }
}
