import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:selectable_search_list/selectable_search_list.dart';
import 'package:king_cache/king_cache.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../themes/colors.dart';
import '../../../themes/styles.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../services/database.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _auth = FirebaseAuth.instance;

  late TextEditingController nameController = TextEditingController();
  late TextEditingController descriptionController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  List<ListItem> items = [];

  var selectedUsers = [];

  int userLoaded = -1;

  late final Future<DocumentSnapshot> azienda;

  Stream<QuerySnapshot>? _stream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: ColorsManager.redPrimary,
        ),
        title: Text(
          context.tr('newGroup'),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffdbdbdb), Colors.white],
            stops: [0.25, 1],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Gap(8.h),
                nameField(),
                descriptionField(),
                selectUsersList(),
                createButton(context),
                Gap(18.h),
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

    azienda = getAzienda();
  }

  Widget selectUsersList() {
    return FutureBuilder<DocumentSnapshot>(
      future: azienda,
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.data == null) return Column();

        DocumentSnapshot? az = snapshot.data;

        _stream = DatabaseMethods.getUsers(az!.id);

        return StreamBuilder(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Expanded(
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            print('userLoaded');
            print(userLoaded);

            if (userLoaded <= 0) {
              if (userLoaded == -1) {
                List<String> userIds = [];
                snapshot.data!.docs.forEach((var user) {
                  if (user['uid'] != _auth.currentUser!.uid) {
                    userIds.add(user['uid']);
                  }
                });
                checkUserPermissions(snapshot.data!.docs, userIds, az);

                userLoaded = 0;
              }

              return Expanded(
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            return Expanded(
              child: MultiSelectListWidget(
                searchHint: context.tr('search'),
                selectAllTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                itemTitleStyle:  const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                items: items,
                onItemsSelect: (selectedItems) {
                  selectedUsers = selectedItems;
                },
              ),
            );
          },
        );
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
              return context.tr('pleaseEnterValid', args: ['Nome']);
            }
          },
          controller: nameController,
        ),
        Gap(18.h),
      ],
    );
  }

  Column descriptionField() {
    return Column(
      children: [
        AppTextFormField(
          hint: context.tr('description'),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          isDark: true,
          validator: (value) {
          },
          controller: descriptionController,
        ),
        Gap(18.h),
      ],
    );
  }

  createButton(BuildContext context) {
    return AppButton(
      buttonText: context.tr('create'),
      textStyle: TextStyles.font20White600Weight,
      verticalPadding: 0,
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          var users = [];
          users.add(FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid));
          selectedUsers.forEach((selectedUser) {
            users.add(FirebaseFirestore.instance.collection('users').doc(selectedUser.id));
          });

          await FirebaseFirestore.instance
            .collection('groups')
            .add({
              'name': nameController.text,
              'description': descriptionController.text,
              'users': users,
              'groupPic': '',
              'creatorId': FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid),
              'createdDate': FieldValue.serverTimestamp(),
            }).then((group) {
              selectedUsers.forEach((selectedUser) {
                Map<String, dynamic> notification = {
                  'senderID': FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid),
                  'groupID': FirebaseFirestore.instance.collection('groups').doc(group.id),
                  'type': 'add_group',
                  'time': FieldValue.serverTimestamp(),
                };

                DatabaseMethods.sendNotification(
                  selectedUser.id,
                  notification,
                );
              });
            });

          AwesomeDialog(
            dismissOnBackKeyPress: false,
            dismissOnTouchOutside: false,
            context: context,
            dialogType: DialogType.info,
            animType: AnimType.rightSlide,
            title: context.tr('newGroup'),
            desc: context.tr('newGroupCreated'),
            btnOkOnPress: () async {
              Navigator.of(context).pop();
            }
          ).show();
        }
      },
    );
  }

  Future<DocumentSnapshot> getAzienda() async {
    DocumentSnapshot userDetails = await DatabaseMethods.getCurrentUserDetails();
    return await DatabaseMethods.getAzienda(userDetails['azienda'].id);
  }

  checkUserPermissions(users, userIDs, azienda) async {
    print(azienda!['api'] + 'check-permission/' + _auth.currentUser!.uid + '/gruppo');

    await KingCache.cacheViaRest(
      azienda!['api'] + 'check-permission/csrf_token',
      method: HttpMethod.get,
      onSuccess: (data) async {
        print(data);

        if (data != null && data.containsKey('csrf_token')) {
          print(data['csrf_token']);

          await KingCache.cacheViaRest(
            azienda!['api'] + 'check-permission/' + _auth.currentUser!.uid + '/gruppo',
            method: HttpMethod.post,
            headers: {
              'X-CSRF-TOKEN': data['csrf_token'],
              'Content-Type': 'application/json',
              'Cookie': 'exp_csrf_token=' + data['csrf_token'] + ';',
            },
            formData: {
              'user_ids': userIDs,
            },
            onSuccess: (data) {
              print(data);

              if (data != null && data.containsKey('success')) {
                if (data['success'] == 1) {
                  List<dynamic> ids = data['user_ids'];

                  items = [];
                  users.forEach((var user) {
                    if (ids.contains(user['uid'])) {
                      items.add(new ListItem(id: user['uid'], title: user['name']));
                    }
                  });

                  setState(() {
                    userLoaded = 1;
                  });
                }
              }
            },
            onError: (data) => debugPrint(data.message),
            apiResponse: (data) {
            },
            isCacheHit: (isHit) => debugPrint('Is Cache Hit: $isHit'),
            shouldUpdate: true,
            expiryTime: DateTime.now().add(const Duration(minutes: 1)),
          );
        }
      },
      onError: (data) => debugPrint(data.message),
      apiResponse: (data) {
      },
      isCacheHit: (isHit) => debugPrint('Is Cache Hit: $isHit'),
      shouldUpdate: true,
      expiryTime: DateTime.now().add(const Duration(minutes: 1)),
    );
  }
}
