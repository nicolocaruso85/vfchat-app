import 'dart:io';
import 'package:avatar_better/avatar_better.dart' show Avatar, ProfileImageViewerOptions, BottomSheetStyles, OptionsCrop;
import 'package:avatar_better/src/tools/gallery_buttom.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:firebase_admin/firebase_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:path/path.dart' show basename;
import 'package:image_cropper/image_cropper.dart';

import '../../../themes/colors.dart';
import '../../../themes/styles.dart';
import '../../../services/database.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/password_validations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../helpers/app_regex.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = FirebaseAuth.instance;

  DocumentSnapshot? userDetails;
  DocumentSnapshot? azienda;

  bool isObscureText = true;

  bool hasMinLength = false;

  late TextEditingController nameController = TextEditingController();
  late TextEditingController emailController = TextEditingController();
  late TextEditingController passwordController = TextEditingController();
  late TextEditingController passwordConfirmationController =
      TextEditingController();

  final _multiSelectKey = GlobalKey<FormFieldState>();

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('userProfile')),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 18.h,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                aziendaField(),
                ruoliField(),
                gruppiField(),
                profileImageField(),
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
          var name = nameController.text;
          var email = emailController.text;
          var password = passwordController.text;

          if (name != userDetails?['name']) {
            await FirebaseAdmin.instance.app()!.auth().updateUser(
              _auth.currentUser!.uid,
              displayName: name,
            );
          }
          if (email != userDetails?['email']) {
            await FirebaseAdmin.instance.app()!.auth().updateUser(
              _auth.currentUser!.uid,
              email: email,
            );
          }
          if (password != null && password != '') {
            await FirebaseAdmin.instance.app()!.auth().updateUser(
              _auth.currentUser!.uid,
              password: password,
            );
          }

          await DatabaseMethods.updateUserDetails(
            {
              'name': name,
              'email': email,
            },
          );

          await DatabaseMethods.updateUserDetails(
            {
              'name': nameController.text,
              'email': emailController.text,
            },
          );

          await DatabaseMethods.addUserUpdatesByUid(
            _auth.currentUser!.uid,
            {
              'name': nameController.text,
              'email': emailController.text,
            },
          );

          await AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: context.tr('editUserProfileSuccess'),
            desc: context.tr('editUserProfileSuccess'),
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
          textInputAction: TextInputAction.next,
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
    return Column(
      children: [
        AppTextFormField(
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
        ),
        Gap(6.h),
      ],
    );
  }

  Column passwordField() {
    return Column(
      children: [
        AppTextFormField(
          controller: passwordController,
          hint: context.tr('password'),
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
          textInputAction: TextInputAction.next,
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

  Column aziendaField() {
    if (azienda != null) {
      return Column(
        children: [
          Text(
            context.tr('azienda'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            azienda?['nome'],
            style: TextStyles.font16White600Weight,
          ),
          Gap(6.h),
        ],
      );
    }

    return Column();
  }

  Column ruoliField() {
    if (azienda != null && userDetails != null && userDetails?['ruoli'].isNotEmpty) {
      List<String> roles = [];

      userDetails?['ruoli'].forEach((ruolo) {
        roles.add(azienda?['ruoli'].where((el) => el['id'] == ruolo['id']).first['nome']);
      });

      return Column(
        children: [
          Text(
            context.tr('roles'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            roles.join(', '),
            style: TextStyles.font16White600Weight,
          ),
          Gap(6.h),
        ],
      );
    }

    return Column();
  }

  Column gruppiField() {
    if (azienda != null && userDetails != null && userDetails?['gruppi'].isNotEmpty) {
      List<String> groups = [];

      userDetails?['gruppi'].forEach((ruolo) {
        groups.add(azienda?['gruppi'].where((el) => el['id'] == ruolo['id']).first['nome']);
      });

      return Column(
        children: [
          Text(
            context.tr('groups'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            groups.join(', '),
            style: TextStyles.font16White600Weight,
          ),
          Gap(6.h),
        ],
      );
    }

    return Column();
  }

  Column profileImageField() {
    return Column(
      children: [
        Gap(4.h),
        Avatar.profile(
          text: '',
          radius: 75,
          isBorderAvatar: true,
          gradientWidthBorder: const LinearGradient(colors: [Colors.white, Colors.white]),
          gradientBackgroundColor: const LinearGradient(colors: [const Color(0xff273443), const Color(0xff273443)]),
          imageNetwork: userDetails?['profilePic'] != '' ? (userDetails?['profilePic']) : null,
          bottomSheetStyles: BottomSheetStyles(
            backgroundColor: const Color(0xff273443),
            elevation: 0,
            middleText: context.tr('or'),
            middleTextStyle: const TextStyle(color: Colors.white),
            galleryButton: GalleryBottom(
              text: context.tr('photoGallery'),
              style: TextStyles.font15DarkBlue500Weight,
              color: Colors.white,
              icon: null,
            ),
            cameraButton: CameraButton(
              text: context.tr('camera'),
              style: TextStyles.font15DarkBlue500Weight,
              color: Colors.white,
              icon: null,
            ),
          ),
          optionsCrop: OptionsCrop(
            aspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
            toolbarColorCrop: Colors.deepOrange,
            toolbarWidgetColorCrop: Colors.white,
            initAspectRatioCrop: CropAspectRatioPreset.square,
            webPresentStyle: WebPresentStyle.dialog,
          ),
          onPickerChange: (file) async {
            String filename = basename(file.path);

            Reference storageRef =
                FirebaseStorage.instance.ref('profile-images/${filename}');
            await storageRef!.putFile(File(file.path));

            String url = await storageRef!.getDownloadURL();
            print(url);

            await _auth.currentUser!.updatePhotoURL(url);

            await DatabaseMethods.updateUserDetails(
              {
                'profilePic': url,
              },
            );

            await DatabaseMethods.addUserUpdatesByUid(
              _auth.currentUser!.uid,
              {
                'profilePic': url,
              },
            );
          },
        ),
        Gap(20.h),
      ],
    );
  }

  Future<void> _loadUserDetails() async {
    DocumentSnapshot details = await DatabaseMethods.getCurrentUserDetails();
    DocumentSnapshot a = await DatabaseMethods.getAzienda(details!['azienda'].id);

    setState(() {
      userDetails = details;
      nameController.text = userDetails?['name'];
      emailController.text = userDetails?['email'];

      azienda = a;
    });
  }
}
