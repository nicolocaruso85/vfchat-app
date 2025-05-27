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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl_mobile_field/intl_mobile_field.dart';
import 'package:intl_mobile_field/flags_drop_down.dart';

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
  late TextEditingController telephoneController =
      TextEditingController();
  late TextEditingController passwordController = TextEditingController();
  late TextEditingController passwordConfirmationController =
      TextEditingController();

  String? dialCode;

  final _multiSelectKey = GlobalKey<FormFieldState>();

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: ColorsManager.redPrimary,
        ),
        title: Text(
          context.tr('userProfile'),
          style: TextStyles.font18Black500Weight,
        ),
        forceMaterialTransparency: true,
        shape: Border(
          bottom: BorderSide(
            color: Color(0xffc2c2c2),
            width: 1.0,
          )
        ),
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
                telephoneField(),
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
      textStyle: TextStyles.font20White600Weight,
      verticalPadding: 0,
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          var name = nameController.text;
          var email = emailController.text;
          var telephone = telephoneController.text;
          var password = passwordController.text;

          if (name != userDetails?['name']) {
            _auth.currentUser!.updateProfile(
              displayName: name,
            );
          }
          if (email != userDetails?['email']) {
            _auth.currentUser!.updateEmail(email);
          }
          if (password != null && password != '') {
            _auth.currentUser!.updatePassword(password);
          }

          await DatabaseMethods.updateUserDetails(
            {
              'name': name,
              'email': email,
              'telephone': telephone,
            },
          );

          DocumentReference aziendaRef = await DatabaseMethods.getAziendaReference(azienda!.id);

          await DatabaseMethods.addUserUpdatesByUid(
            _auth.currentUser!.uid,
            {
              'name': nameController.text,
              'email': emailController.text,
              'telephone': telephone,
              'azienda': aziendaRef,
            },
            SetOptions(merge: true),
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
          maxLines: 1,
          isDark: true,
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
          isDark: true,
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
          isDark: true,
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
          maxLines: 1,
          isDark: true,
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
                color: Color(0x77000000),
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0x77000000),
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
          style: TextStyles.font18Black500Weight,
          favorite: const ['IT'],
          initialCountryCode: 'IT',
          languageCode: 'it',
          onCountryChanged: (country) {
            dialCode = country.dialCode;
          },
          disableLengthCounter: true,
          dropdownTextStyle: TextStyles.font18Black500Weight,
          onChanged: (phone) {
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

  Column aziendaField() {
    if (azienda != null) {
      return Column(
        children: [
          Text(
            context.tr('azienda'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            azienda?['name'],
            style: TextStyles.font16Black600Weight,
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
            style: TextStyles.font16Black600Weight,
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
            maxHeight: 600,
          ),
          onPickerChange: (file) async {
            Reference storageRef =
                FirebaseStorage.instance.ref('profile-images/${_auth.currentUser!.uid}');
            await storageRef!.putFile(File(file.path));

            String url = await storageRef!.getDownloadURL();
            print(url);

            await _auth.currentUser!.updatePhotoURL(url);

            await DatabaseMethods.updateUserDetails(
              {
                'profilePic': url,
              },
            );

            DocumentReference aziendaRef = await DatabaseMethods.getAziendaReference(userDetails!['azienda'].id);

            await DatabaseMethods.addUserUpdatesByUid(
              _auth.currentUser!.uid,
              {
                'profilePic': url,
                'azienda': aziendaRef,
              },
              SetOptions(merge: true),
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
      telephoneController.text = userDetails?['telephone'];
      print(userDetails);

      azienda = a;
    });
  }
}
