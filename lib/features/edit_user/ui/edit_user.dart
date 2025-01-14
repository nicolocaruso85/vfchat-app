import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:firebase_admin/firebase_admin.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import '../../../themes/styles.dart';
import '../../../services/database.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/password_validations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../helpers/app_regex.dart';

class Ruolo {
  final int id;
  final String nome;

  Ruolo({
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
  late TextEditingController passwordController = TextEditingController();
  late TextEditingController passwordConfirmationController =
      TextEditingController();

  final _multiSelectKey = GlobalKey<FormFieldState>();

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
              rolesField(),
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

  rolesField() {
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

    return MultiSelectDialogField(
      key: _multiSelectKey,
      items: _roles,
      initialValue: _userRoles,
      listType: MultiSelectListType.CHIP,
      searchable: true,
      title: Text(context.tr('roles')),
      cancelText: Text(context.tr('cancel')),
      selectedColor: Colors.blue,
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
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        onTap: (item) {
          _multiSelectKey.currentState!.value.remove(item);
          _multiSelectKey.currentState!.validate();
        },
      ),
      onConfirm: (results) {
      },
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
          _multiSelectKey.currentState!.value.forEach((ruolo) {
            ruoli.add({'id': ruolo.id});
          });

          await DatabaseMethods.updateUserDetailsByUid(
            widget.uid,
            {
              'name': name,
              'email': email,
              'ruoli': ruoli,
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
    DocumentSnapshot a = await DatabaseMethods.getAzienda(details!['azienda'].id);

    setState(() {
      userDetails = details;
      nameController.text = userDetails?['name'];
      emailController.text = userDetails?['email'];

      azienda = a;
    });
  }
}
