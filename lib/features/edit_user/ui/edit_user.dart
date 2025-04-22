import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:firebase_admin/firebase_admin.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:intl_mobile_field/intl_mobile_field.dart';
import 'package:intl_mobile_field/flags_drop_down.dart';

import '../../../themes/colors.dart';
import '../../../themes/styles.dart';
import '../../../services/database.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/password_validations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../helpers/app_regex.dart';

class Ruolo {
  final int id;
  final String nome;

  const Ruolo({
    required this.id,
    required this.nome,
  });
}

class Gruppo {
  final int id;
  final String nome;

  const Gruppo({
    required this.id,
    required this.nome,
  });
}

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

  final _multiSelectKeyRoles = GlobalKey<FormFieldState>();
  final _multiSelectKeyGroups = GlobalKey<FormFieldState>();

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
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                nameField(),
                emailField(),
                telephoneField(),
                passwordField(),
                passwordConfirmationField(),
                rolesField(),
                groupsField(),
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

  groupsField() {
    if (azienda == null) return Column();

    List<MultiSelectItem<Gruppo>> _groups = [];
    List<Gruppo> _userGroups = [];
    azienda!['gruppi']
      .forEach((gruppo) {
        Gruppo r = Gruppo(id: gruppo['id'], nome: gruppo['nome']);
        _groups.add(MultiSelectItem<Gruppo>(r, gruppo['nome']));

        var selected = userDetails!['gruppi'].firstWhere((group) => group['id'] == gruppo['id'], orElse: () => null);

        if (selected != null) {
          _userGroups.add(r);
        }
      });

    return MultiSelectDialogField(
      key: _multiSelectKeyGroups,
      items: _groups,
      initialValue: _userGroups,
      listType: MultiSelectListType.CHIP,
      searchable: true,
      title: Text(context.tr('groups')),
      cancelText: Text(context.tr('cancel')),
      selectedColor: ColorsManager.greenPrimary,
      selectedItemsTextStyle: TextStyle(
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.all(Radius.circular(40)),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      buttonIcon: Icon(
        Icons.groups,
        color: Colors.white,
      ),
      buttonText: Text(
        context.tr('groups'),
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      chipDisplay: MultiSelectChipDisplay(
        chipColor: Colors.blue,
        chipWidth: MediaQuery.of(context).size.width,
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        onTap: (item) {
          _multiSelectKeyGroups.currentState!.value.remove(item);
          return _multiSelectKeyGroups.currentState!.value;
        },
      ),
      onConfirm: (results) {
      },
    );
  }

  Column rolesField() {
    if (azienda == null) return Column();

    List<MultiSelectItem<Ruolo>> _roles = [];
    List<Ruolo> _userRoles = [];
    azienda!['ruoli']
      .forEach((ruolo) {
        Ruolo r = Ruolo(id: ruolo['id'], nome: ruolo['nome']);
        _roles.add(MultiSelectItem<Ruolo>(r, ruolo['nome']));

        var selected = userDetails!['ruoli'].firstWhere((role) => role['id'] == ruolo['id'], orElse: () => null);

        if (selected != null) {
          _userRoles.add(r);
        }
      });

    return Column(
      children: [
        MultiSelectDialogField(
          key: _multiSelectKeyRoles,
          items: _roles,
          initialValue: _userRoles,
          listType: MultiSelectListType.CHIP,
          searchable: true,
          title: Text(context.tr('roles')),
          cancelText: Text(context.tr('cancel')),
          selectedColor: ColorsManager.greenPrimary,
          selectedItemsTextStyle: TextStyle(
            color: Colors.white,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.all(Radius.circular(40)),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          buttonIcon: Icon(
            Icons.perm_contact_cal_outlined,
            color: Colors.white,
          ),
          buttonText: Text(
            context.tr('roles'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          chipDisplay: MultiSelectChipDisplay(
            chipColor: Colors.blue,
            chipWidth: MediaQuery.of(context).size.width,
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            onTap: (item) {
              _multiSelectKeyRoles.currentState!.value.remove(item);
              return _multiSelectKeyRoles.currentState!.value;
            },
          ),
          onConfirm: (results) {
          },
        ),
        Gap(18.h),
      ],
    );
  }

  modifyButton(BuildContext context) {
    return AppButton(
      buttonText: context.tr('edit'),
      textStyle: TextStyles.font15DarkBlue500Weight,
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          var name = nameController.text;
          var email = emailController.text;
          var telephone = telephoneController.text;
          var password = passwordController.text;

          if (name != userDetails?['name']) {
            await FirebaseAdmin.instance.app()!.auth().updateUser(
              widget.uid,
              displayName: name,
            );
          }
          if (email != userDetails?['email']) {
            await FirebaseAdmin.instance.app()!.auth().updateUser(
              widget.uid,
              email: email,
            );
          }
          if (password != null && password != '') {
            await FirebaseAdmin.instance.app()!.auth().updateUser(
              widget.uid,
              password: password,
            );
          }

          var ruoli = [];
          _multiSelectKeyRoles.currentState!.value.forEach((ruolo) {
            ruoli.add({'id': ruolo.id});
          });

          var gruppi = [];
          _multiSelectKeyGroups.currentState!.value.forEach((gruppo) {
            gruppi.add({'id': gruppo.id});
          });

          await DatabaseMethods.updateUserDetailsByUid(
            widget.uid,
            {
              'name': name,
              'email': email,
              'telephone': telephone,
              'ruoli': ruoli,
              'gruppi': gruppi,
            },
          );

          DocumentReference aziendaRef = await DatabaseMethods.getAziendaReference(azienda!.id);

          await DatabaseMethods.addUserUpdatesByUid(
            widget.uid,
            {
              'azienda': aziendaRef,
              'name': name,
              'email': email,
              'telephone': telephone,
              'ruoli': ruoli,
              'gruppi': gruppi,
            },
            SetOptions(merge: true),
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
          maxLines: 1,
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
        Gap(18.h),
      ],
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
            border: OutlineInputBorder(
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
          ),
          fillColor: const Color(0xff273443),
          style: TextStyles.font18White500Weight,
          prefixIcon: FlagsDropDown(
            favorite: const ['IT'],
            initialCountryCode: 'IT',
            languageCode: 'it',
            onCountryChanged: (country) {
              dialCode = country.dialCode;
            },
          ),
          disableLengthCounter: true,
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

  Future<void> _loadUserDetails() async {
    DocumentSnapshot details = await DatabaseMethods.getUserDetails(widget.uid);
    DocumentSnapshot a = await DatabaseMethods.getAzienda(details!['azienda'].id);

    setState(() {
      userDetails = details;
      nameController.text = userDetails?['name'];
      emailController.text = userDetails?['email'];
      telephoneController.text = userDetails?['telephone'];

      azienda = a;
    });
  }
}
