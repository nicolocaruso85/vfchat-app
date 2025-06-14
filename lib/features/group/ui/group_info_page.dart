import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:avatar_better/avatar_better.dart' show Avatar, ProfileImageViewerOptions, BottomSheetStyles, OptionsCrop;
import 'package:avatar_better/src/tools/gallery_buttom.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:king_cache/king_cache.dart';
import 'package:selectable_search_list/selectable_search_list.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../themes/colors.dart';
import '../../../themes/styles.dart';
import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../services/database.dart';
import '../../../router/routes.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupID;

  const GroupInfoScreen({
    super.key,
    required this.groupID,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final _auth = FirebaseAuth.instance;

  DocumentSnapshot? groupDetails;
  String? creatorName;
  String? creatorID;

  List<DocumentSnapshot> membersList = [];
  List<String> membersUidList = [];

  late TextEditingController nameController = TextEditingController();
  late TextEditingController descriptionController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  List<ListItem> items = [];

  var selectedUsers = [];

  ValueNotifier<bool> userLoaded = ValueNotifier(false);

  late final Future<DocumentSnapshot> azienda;

  bool shouldUpdate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: ColorsManager.redPrimary,
        ),
        forceMaterialTransparency: true,
        shape: Border(
          bottom: BorderSide(
            color: Color(0xffc2c2c2),
            width: 1.0,
          )
        ),
        title: Text(
          (groupDetails != null) ? groupDetails!['name'] : '',
          style: TextStyles.font18Black500Weight,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showCupertinoModalBottomSheet(
                context: context,
                builder: (context) => Material(
                  child: Scaffold(
                    appBar: AppBar(
                      iconTheme: IconThemeData(
                        color: ColorsManager.redPrimary,
                      ),
                      title: Text(
                        context.tr('editGroup'),
                        style: TextStyles.font18Black500Weight,
                      ),
                      automaticallyImplyLeading: false,
                    ),
                    backgroundColor: ColorsManager.backgroundDefaultColor,
                    body: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 12),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            nameEditField(),
                            descriptionEditField(),
                            modifyButton(),
                            cancelButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 18.h,
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                groupImageField(),
                nameField(),
                descriptionField(),
                createdByField(),
                createdDateField(),
                membersField(),
                if (creatorID == _auth.currentUser!.uid) addUsersButton(),
                if (creatorID != _auth.currentUser!.uid) leaveGroupButton(),
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

    _loadGroupDetails();
  }

  Column groupImageField() {
    return Column(
      children: [
        Gap(4.h),
        Avatar.profile(
          text: '',
          radius: 50,
          isBorderAvatar: true,
          gradientWidthBorder: const LinearGradient(colors: [Colors.white, Colors.white]),
          gradientBackgroundColor: const LinearGradient(colors: [const Color(0xff273443), const Color(0xff273443)]),
          imageNetwork: groupDetails?['groupPic'] != '' ? (groupDetails?['groupPic']) : null,
          bottomSheetStyles: BottomSheetStyles(
            backgroundColor: Colors.white,
            elevation: 0,
            middleText: context.tr('or'),
            middleTextStyle: const TextStyle(color: Colors.white),
            galleryButton: GalleryBottom(
              text: context.tr('photoGallery'),
              style: TextStyles.font15White500Weight,
              color: ColorsManager.redPrimary,
              icon: null,
            ),
            cameraButton: CameraButton(
              text: context.tr('camera'),
              style: TextStyles.font15White500Weight,
              color: ColorsManager.redPrimary,
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
                FirebaseStorage.instance.ref('group-images/${groupDetails!.id}');
            await storageRef!.putFile(File(file.path));

            String url = await storageRef!.getDownloadURL();

            await DatabaseMethods.updateGroupDetails(
              groupDetails!.id,
              {
                'groupPic': url,
              },
            );

            _loadGroupDetails();
          },
        ),
        Gap(20.h),
      ],
    );
  }

  SizedBox nameField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('name'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            (groupDetails != null) ? (groupDetails?['name']) : '',
            style: TextStyles.font16Black600Weight,
          ),
          Gap(8.h),
        ],
      ),
    );
  }

  SizedBox descriptionField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('description'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            (groupDetails != null) ? (groupDetails?['description']) : '',
            style: TextStyles.font16Black600Weight,
          ),
          Gap(8.h),
        ],
      ),
    );
  }

  SizedBox createdByField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('createdBy'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            (creatorName != null) ? creatorName! : '',
            style: TextStyles.font16Black600Weight,
          ),
          Gap(8.h),
        ],
      ),
    );
  }

  SizedBox createdDateField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('createdDate'),
            style: TextStyles.font15Green500Weight,
          ),
          Text(
            (groupDetails != null) ? (formatDate(groupDetails?['createdDate'].toDate())) : '',
            style: TextStyles.font16Black600Weight,
          ),
          Gap(8.h),
        ],
      ),
    );
  }

  SizedBox membersField() {
    if (membersList.length == 0) {
      return SizedBox();
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('members'),
            style: TextStyles.font15Green500Weight,
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: membersList.length,
            itemBuilder: (context, index) {
              var data = membersList[index];

              return ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 8,
                ),
                leading: data['profilePic'] != null && data['profilePic'] != ''
                    ? Hero(
                        tag: data['profilePic'],
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: data['profilePic'],
                            placeholder: (context, url) =>
                                Image.asset('assets/images/loading.gif'),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error_outline_rounded),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Image.asset(
                        'assets/images/user.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      ),
                title: Text(
                  data['name'],
                  style: const TextStyle(
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  data['isOnline']
                      ? context.tr('online')
                      : context.tr('offline'),
                  style: const TextStyle(
                    color: Color(0xff828282),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                trailing: creatorID == data['uid'] ?
                  Text(
                    context.tr('admin'),
                    style: const TextStyle(
                      color: Color(0xff828282),
                    ),
                  ) : Text(''),
                isThreeLine: true,
                titleAlignment: ListTileTitleAlignment.center,
                enableFeedback: true,
                dense: false,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                  height: 1.2,
                ),
                subtitleTextStyle: TextStyle(
                  height: 1.2,
                ),
                horizontalTitleGap: 8,
                onTap: () {
                  showUserOptions(context, data);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Column nameEditField() {
    return Column(
      children: [
        AppTextFormField(
          hint: context.tr('name'),
          textInputAction: TextInputAction.next,
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

  Column descriptionEditField() {
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

  Column modifyButton() {
    return Column(
      children: [
        AppButton(
          buttonText: context.tr('edit'),
          textStyle: TextStyles.font20White600Weight,
          verticalPadding: 0,
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              await DatabaseMethods.updateGroupDetails(
                widget.groupID,
                {
                  'name': nameController.text,
                  'description': descriptionController.text,
                }
              );

              _loadGroupDetails();

              AwesomeDialog(
                dismissOnBackKeyPress: false,
                dismissOnTouchOutside: false,
                context: context,
                dialogType: DialogType.info,
                animType: AnimType.rightSlide,
                title: context.tr('editGroup'),
                desc: context.tr('editGroupDone'),
                btnOkOnPress: () async {
                  Navigator.of(context).pop();
                }
              ).show();
            }
          },
        ),
        Gap(18.h),
      ],
    );
  }

  cancelButton() {
    return AppButton(
      buttonText: context.tr('cancel'),
      textStyle: TextStyles.font20White600Weight,
      verticalPadding: 0,
      backgroundColor: Colors.red.shade700,
      onPressed: () async {
        Navigator.of(context).pop();
      },
    );
  }

  Column leaveGroupButton() {
    return Column(
      children: [
        AppButton(
          buttonText: context.tr('leaveGroup'),
          backgroundColor: Colors.red.shade700,
          textStyle: TextStyles.font20White600Weight,
          verticalPadding: 0,
          onPressed: () async {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.question,
              animType: AnimType.rightSlide,
              title: context.tr('leaveGroup'),
              desc: context.tr('confirmLeaveGroup'),
              btnOkText: context.tr('yes'),
              btnOkOnPress: () async {
                List uList = [];

                var users = membersList;
                users.forEach((u) {
                  if (u['uid'] != _auth.currentUser!.uid) {
                    uList.add(FirebaseFirestore.instance.collection('users').doc(u['uid']));
                  }
                });

                await DatabaseMethods.updateGroupDetails(widget.groupID, {'users': uList});

                Navigator.pushNamedAndRemoveUntil(context, Routes.homeScreen, (route) => false);
              },
              btnCancelText: context.tr('no'),
              btnCancelOnPress: () {
                Navigator.pop(context);
              },
            ).show();
          },
        ),
      ],
    );
  }

  Column addUsersButton() {
    return Column(
      children: [
        AppButton(
          buttonText: context.tr('addGroupUsers'),
          textStyle: TextStyles.font20White600Weight,
          verticalPadding: 0,
          onPressed: () async {
            showCupertinoModalBottomSheet(
              context: context,
              builder: (context) => Material(
                child: Scaffold(
                  appBar: AppBar(
                    iconTheme: IconThemeData(
                      color: ColorsManager.redPrimary,
                    ),
                    title: Text(
                      context.tr('addGroupUsers'),
                      style: TextStyles.font18Black500Weight,
                    ),
                    leading: BackButton(
                      onPressed: () {
                        selectedUsers = [];
                        userLoaded.value = false;
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  backgroundColor: ColorsManager.backgroundDefaultColor,
                  body: Padding(
                    padding: EdgeInsets.only(left: 5, right: 5, top: 12, bottom: 22),
                    child: Column(
                      children: [
                        selectUsersList(),
                        confirmAddUsersButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        ),
        Gap(10.h),
      ],
    );
  }

  Widget selectUsersList() {
    return FutureBuilder<DocumentSnapshot>(
      future: azienda,
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        DocumentSnapshot? az = snapshot.data;

        return StreamBuilder(
          stream: DatabaseMethods.getUsers(az!.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Expanded(
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (!userLoaded.value) {
              List<String> userIds = [];
              snapshot.data!.docs.forEach((var user) {
                if (user['uid'] != _auth.currentUser!.uid && !membersUidList.contains(user['uid'])) {
                  userIds.add(user['uid']);
                }
              });
              checkUserPermissions(snapshot.data!.docs, userIds, az);
            }

            return Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: userLoaded,
                builder: (context, value, _) {
                  if (!userLoaded.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return MultiSelectListWidget(
                    key: ValueKey(userLoaded.value),
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
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  confirmAddUsersButton(BuildContext context) {
    return AppButton(
      buttonText: context.tr('add'),
      textStyle: TextStyles.font20White600Weight,
      verticalPadding: 0,
      onPressed: () async {
        var users = [];
        membersList.forEach((member) {
          users.add(FirebaseFirestore.instance.collection('users').doc(member.id));
        });
        selectedUsers.forEach((selectedUser) {
          users.add(FirebaseFirestore.instance.collection('users').doc(selectedUser.id));

          Map<String, dynamic> notification = {
            'senderID': FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid),
            'groupID': FirebaseFirestore.instance.collection('groups').doc(widget.groupID),
            'type': 'add_group',
            'time': FieldValue.serverTimestamp(),
          };

          DatabaseMethods.sendNotification(
            selectedUser.id,
            notification,
          );
        });

        await DatabaseMethods.updateGroupDetails(widget.groupID, {'users': users});

        _loadGroupDetails();

        AwesomeDialog(
          dismissOnBackKeyPress: false,
          dismissOnTouchOutside: false,
          context: context,
          dialogType: DialogType.info,
          animType: AnimType.rightSlide,
          title: context.tr('addGroupUsers'),
          desc: context.tr('addGroupUsersDone'),
          btnOkOnPress: () async {
            setState(() {
              userLoaded.value = false;
            });

            shouldUpdate = true;

            Navigator.of(context).pop();
          }
        ).show();
      },
    );
  }

  String formatDate(date) {
    return DateFormat(DateFormat.YEAR_MONTH_DAY, 'it_IT').format(date.toUtc()) + ' ' + DateFormat(DateFormat.HOUR24_MINUTE, 'it_IT').format(date.toUtc());
  }

  Future<void> _loadGroupDetails() async {
    membersList = [];
    membersUidList = [];

    DocumentSnapshot details = await DatabaseMethods.getGroup(widget.groupID);
    DocumentSnapshot creatorDetails = await details?['creatorId'].get();

    await details?['users'].forEach((user) async {
      var u = await user.get();

      setState(() {
        membersList.add(u);
        membersUidList.add(u['uid']);
      });
    });

    setState(() {
      groupDetails = details;
      creatorID = creatorDetails['uid'];
      creatorName = creatorDetails['name'];

      nameController.text = groupDetails?['name'];
      descriptionController.text = groupDetails?['description'];
    });
  }

  Future showUserOptions(context, data) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: Text(context.tr('delete')),
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);

              List uList = [];

              var users = membersList;
              users.forEach((u) {
                if (u['uid'] != data['uid']) {
                  uList.add(FirebaseFirestore.instance.collection('users').doc(u['uid']));
                }
              });

              await DatabaseMethods.updateGroupDetails(widget.groupID, {'users': uList});

              setState(() {
                userLoaded.value = false;
              });

              shouldUpdate = true;

              _loadGroupDetails();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: (){
            Navigator.pop(context);
          }, 
          child: Text(context.tr('cancel')),
        ),
      ),
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
                    userLoaded.value = true;
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
