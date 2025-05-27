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

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({
    super.key,
  });

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
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
        iconTheme: IconThemeData(
          color: ColorsManager.redPrimary,
        ),
        title: Text(
          context.tr('addUser'),
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
                nameField(),
                emailField(),
                telephoneField(),
                passwordField(),
                passwordConfirmationField(),
                rolesField(),
                groupsField(),
                Gap(20.h),
                addButton(context),
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
      });

    return MultiSelectDialogField(
      key: _multiSelectKeyGroups,
      items: _groups,
      initialValue: _userGroups,
      listType: MultiSelectListType.CHIP,
      searchable: true,
      title: Text(context.tr('groups')),
      cancelText: Text(context.tr('cancel')),
      selectedColor: ColorsManager.redPrimary,
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
    azienda!['ruoli']
      .forEach((ruolo) {
        Ruolo r = Ruolo(id: ruolo['id'], nome: ruolo['nome']);
        _roles.add(MultiSelectItem<Ruolo>(r, ruolo['nome']));
      });

    return Column(
      children: [
        MultiSelectDialogField(
          key: _multiSelectKeyRoles,
          items: _roles,
          listType: MultiSelectListType.CHIP,
          searchable: true,
          title: Text(context.tr('roles')),
          cancelText: Text(context.tr('cancel')),
          selectedColor: ColorsManager.redPrimary,
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
              _multiSelectKeyRoles.currentState!.validate();
            },
          ),
          onConfirm: (results) {
          },
        ),
        Gap(18.h),
      ],
    );
  }

  addButton(BuildContext context) {
    return AppButton(
      buttonText: context.tr('create'),
      textStyle: TextStyles.font20White600Weight,
      verticalPadding: 0,
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          DocumentSnapshot userDetails = await DatabaseMethods.getCurrentUserDetails();
          DocumentReference aziendaRef = await DatabaseMethods.getAziendaReference(userDetails['azienda'].id);

          UserRecord user = await FirebaseAdmin.instance.app()!.auth().createUser(
            email: emailController.text,
            password: passwordController.text,
          );

          var ruoli = [];
          _multiSelectKeyRoles.currentState!.value.forEach((ruolo) {
            ruoli.add({'id': ruolo.id});
          });

          var gruppi = [];
          _multiSelectKeyGroups.currentState!.value.forEach((gruppo) {
            gruppi.add({'id': gruppo.id});
          });

          await DatabaseMethods.addUserDetailsByUid(
            user.uid,
            {
              'name': nameController.text,
              'email': emailController.text,
              'telephone': telephoneController.text,
              'profilePic': '',
              'uid': user.uid,
              'isOnline': false,
              'isAdmin': false,
              'ruoli': ruoli,
              'gruppi': gruppi,
              'azienda': aziendaRef,
            },
          );

          await DatabaseMethods.addUserUpdatesByUid(
            user.uid,
            {
              'name': nameController.text,
              'email': emailController.text,
              'telephone': telephoneController.text,
              'profilePic': '',
              'uid': user.uid,
              'isOnline': false,
              'isAdmin': false,
              'ruoli': ruoli,
              'gruppi': gruppi,
              'azienda': aziendaRef,
            },
          );

          await AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: context.tr('addUserSuccess'),
            desc: context.tr('addUserSuccess'),
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
            if (value != passwordController.text) {
              return context.tr('passwordsDontMatch');
            }
            if (value == null ||
                value.isEmpty ||
                !AppRegex.isPasswordValid(value)) {
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
            if (value == null ||
                value.isEmpty ||
                !AppRegex.isPasswordValid(value)) {
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

  Future<void> _loadUserDetails() async {
    DocumentSnapshot details = await DatabaseMethods.getCurrentUserDetails();
    DocumentSnapshot a = await DatabaseMethods.getAzienda(details!['azienda'].id);

    setState(() {
      azienda = a;
    });
  }
}
