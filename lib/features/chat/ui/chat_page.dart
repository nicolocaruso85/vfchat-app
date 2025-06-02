import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:king_cache/king_cache.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../../../core/networking/dio_factory.dart';
import '../../../helpers/extensions.dart';
import '../../../helpers/notifications.dart';
import '../../../router/routes.dart';
import '../../../services/database.dart';
import '../../../services/notification_service.dart';
import '../../../themes/colors.dart';
import '../../../themes/styles.dart';
import 'widgets/message_bar.dart';
import 'widgets/url_preview.dart';

class ChatScreen extends StatefulWidget {
  final String receivedUserName;
  final String receivedUserID;
  final String receivedMToken;
  final bool active;
  final String? receivedUserProfilePic;
  const ChatScreen({
    super.key,
    required this.receivedUserName,
    required this.receivedUserID,
    required this.receivedMToken,
    required this.active,
    required this.receivedUserProfilePic,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = NotificationService();
  final _auth = FirebaseAuth.instance;
  late String? token;
  TextAlign textAlign = TextAlign.start;

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final _picker = ImagePicker();

  DocumentSnapshot? azienda;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
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
          padding: EdgeInsets.only(left: 8.w, right: 8.w, bottom: 22),
          child: Column(
            children: [
              Expanded(
                child: _buildMessagesList(),
              ),
              CustomMessageBar(
                onSend: (message) async {
                  bool permission = false;
                  bool error = false;

                  await KingCache.cacheViaRest(
                    azienda!['api'] + 'check-permission/' + _auth.currentUser!.uid + '/' + widget.receivedUserID + '/messaggi',
                    method: HttpMethod.get,
                    onSuccess: (data) {
                      if (data != null && data.containsKey('success')) {
                        print(data['success']);

                        if (data['success'] == 1) {
                          permission = true;
                        }
                      }
                    },
                    onError: (data) {
                      print(data);
                      error = true;
                    },
                    apiResponse: (data) {
                      print(data);
                    },
                    isCacheHit: (isHit) => debugPrint('Is Cache Hit: $isHit'),
                    shouldUpdate: true,
                    expiryTime: DateTime.now().add(const Duration(minutes: 1)),
                  );

                  if (error == true) {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.error,
                      animType: AnimType.rightSlide,
                      title: context.tr('error'),
                      desc: context.tr('connectionErrorMessage'),
                    ).show();

                    return;
                  }
                  if (permission == false) {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.error,
                      animType: AnimType.rightSlide,
                      title: context.tr('error'),
                      desc: context.tr('noPermissionMessage'),
                    ).show();

                    return;
                  }

                  Map<String, dynamic> notification = {
                    'senderID': FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid),
                    'message': message,
                    'type': 'direct_message',
                    'time': FieldValue.serverTimestamp(),
                  };

                  await DatabaseMethods.sendMessage(
                    message,
                    widget.receivedUserID,
                  );
                  DatabaseMethods.sendNotification(
                    widget.receivedUserID,
                    notification,
                  );
                  await _chatService.sendPushMessage(
                    widget.receivedMToken,
                    token!,
                    message,
                    _auth.currentUser!.displayName!,
                    _auth.currentUser!.uid,
                    _auth.currentUser!.photoURL,
                  );
                },
                onShowOptions: showImageOptions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Image Picker function to get image from camera
  Future getImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      if (!mounted) return;

      context.pushNamed(Routes.displayPictureScreen, arguments: [
        pickedFile,
        token!,
        widget.receivedMToken,
        widget.receivedUserID,
      ]);
    }
  }

  //Image Picker function to get image from gallery
  Future getImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (!mounted) return;
      context.pushNamed(Routes.displayPictureScreen, arguments: [
        pickedFile,
        token!,
        widget.receivedMToken,
        widget.receivedUserID,
      ]);
    }
  }

  getToken() async {
    token = await FirebaseMessaging.instance.getToken();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _loadUserDetails();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await HelperNotification.initialize(flutterLocalNotificationsPlugin);
      await getToken();
    });

    // listen for messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        HelperNotification.showNotification(
          message.notification!.title!,
          message.notification!.body!,
          flutterLocalNotificationsPlugin,
        );
      },
    );
  }

  Future showImageOptions() async {
    bool permission = false;
    bool error = false;

    await KingCache.cacheViaRest(
      azienda!['api'] + 'check-permission/' + _auth.currentUser!.uid + '/' + widget.receivedUserID + '/immagini',
      method: HttpMethod.get,
      onSuccess: (data) {
        print(data);

        if (data != null && data.containsKey('success')) {
          print(data['success']);

          if (data['success'] == 1) {
            permission = true;
          }
        }
      },
      onError: (data) {
        print(data);
        error = true;
      },
      apiResponse: (data) {
        print(data);
      },
      isCacheHit: (isHit) => debugPrint('Is Cache Hit: $isHit'),
      shouldUpdate: true,
      expiryTime: DateTime.now().add(const Duration(minutes: 1)),
    );

    if (error == true) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: context.tr('error'),
        desc: context.tr('connectionErrorMessage'),
      ).show();

      return;
    }
    if (permission == false) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: context.tr('error'),
        desc: context.tr('noPermissionImage'),
      ).show();

      return;
    }

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: Text(context.tr('photoGallery')),
            onPressed: () {
              context.pop();
              getImageFromGallery();
            },
          ),
          CupertinoActionSheetAction(
            child: Text(context.tr('camera')),
            onPressed: () {
              context.pop();
              getImageFromCamera();
            },
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      forceMaterialTransparency: true,
      shape: Border(
        bottom: BorderSide(
          color: Color(0xffc2c2c2),
          width: 1.0,
        )
      ),
      leadingWidth: 95.w,
      leading: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => Navigator.pop(context),
        child: Row(
          children: [
            Gap(10.w),
            Icon(
              Icons.arrow_back_ios,
              size: 25.sp,
              color: ColorsManager.redPrimary,
            ),
            widget.receivedUserProfilePic != null &&
                    widget.receivedUserProfilePic != ''
                ? Hero(
                    tag: widget.receivedUserProfilePic!,
                    child: ClipOval(
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/images/loading.gif',
                        image: widget.receivedUserProfilePic!,
                        fit: BoxFit.cover,
                        width: 60.w,
                        height: 60.h,
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/images/user.png',
                    height: 60.h,
                    width: 60.w,
                    fit: BoxFit.cover,
                  ),
          ],
        ),
      ),
      toolbarHeight: 70.h,
      title: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, Routes.otherUserProfileScreen, arguments: {'uid': widget.receivedUserID});
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.receivedUserName,
              style: TextStyles.font18Black500Weight,
            ),
            Text(
              widget.active
                  ? context.tr('online')
                  : context.tr('offline'),
              style: TextStyle(
                fontSize: 13.sp,
                color: Color(0xff828282),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BubbleNormalImage _buildImagePreviewer(
      Map<String, dynamic> data, bool isNewSender, String message) {
    return BubbleNormalImage(
      onPressDownload: () async {
        await _downloadImageFromFirebase(
          FirebaseStorage.instance.refFromURL(message),
          message,
        );
      },
      id: data['timestamp'].toDate().toString(),
      tail: isNewSender,
      isSender: data['senderID'] == _auth.currentUser!.uid ? true : false,
      color: data['senderID'] == _auth.currentUser!.uid
          ? const Color.fromARGB(255, 0, 107, 84)
          : const Color(0xff273443),
      image: CachedNetworkImage(
        imageUrl: message,
        placeholder: (context, url) => Image.asset('assets/images/loading.gif'),
        errorWidget: (context, url, error) =>
            const Icon(Icons.error_outline_rounded),
      ),
    );
  }

  Align _buildLinkPreviewer(Map<String, dynamic> data, String message) {
    bool isNewSender = data['senderID'] == _auth.currentUser!.uid
        ? true
        : false;
    return Align(
      alignment: data['senderID'] == _auth.currentUser!.uid
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isNewSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topRight: isNewSender ? Radius.circular(0) : Radius.circular(15),
                bottomRight: Radius.circular(15),
                topLeft: isNewSender ? Radius.circular(15) : Radius.circular(0),
                bottomLeft: Radius.circular(15),
              ),
              color: data['senderID'] == _auth.currentUser!.uid
                  ? ColorsManager.redPrimary
                  : ColorsManager.purplePrimary,
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 22, right: 22, top: 12, bottom: 0),
              child: LinkPreviewWidget(
                message: message,
                onLinkPressed: (link) async {
                  await _launchURL(link);
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 8, left: 8),
            child: Text(
              DateFormat("H:mm").format(
                data['timestamp'].toDate(),
              ),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Color(0xff828282),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
      DocumentSnapshot snapshot,
      DocumentSnapshot? previousMessage,
      DocumentSnapshot? nextMessage,
      bool isNewDay) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    bool isNewSender =
        nextMessage == null || data['senderID'] != nextMessage['senderID'];
    String message = data['message'];
    return Column(
      children: [
        if (isNewDay)
          DateChip(
            date: data['timestamp'].toDate(),
            dateColor: Color(0xff828282),
            color: Colors.transparent,
          ),
        if (message.contains(message.isContainsLink) &&
            message.contains('firebasestorage'))
          _buildImagePreviewer(data, isNewSender, message),
        if (message.contains(message.isContainsLink) &&
            !message.contains('firebasestorage'))
          _buildLinkPreviewer(data, message),
        if (!message.contains(message.isContainsLink))
          _buildTextMessage(message, data, isNewSender),
      ],
    );
  }

  Widget _buildMessagesList() {
    late Stream<QuerySnapshot<Object?>> allMessages =
        DatabaseMethods.getMessages(
            widget.receivedUserID, _auth.currentUser!.uid);

    List<String> sortedIDs = [widget.receivedUserID, _auth.currentUser!.uid];
    sortedIDs.sort();
    String chatRoomID = sortedIDs.join('_');

    return StreamBuilder(
      stream: allMessages,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        List<DocumentSnapshot> messageDocs = snapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          itemCount: messageDocs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot currentMessage = messageDocs[index];
            DocumentSnapshot? previousMessage =
                index > 0 ? messageDocs[index - 1] : null;
            DocumentSnapshot? nextMessage =
                index < messageDocs.length - 1 ? messageDocs[index + 1] : null;

            // Determine if the current message is from a new day
            bool isNewDay = nextMessage == null ||
                !_isSameDay(currentMessage['timestamp'].toDate(),
                    nextMessage['timestamp'].toDate());

            if (currentMessage['receiverID'] == _auth.currentUser!.uid) {
              _setMessageAsViewed(chatRoomID, currentMessage.id);
            }

            return _buildMessageItem(
              currentMessage,
              previousMessage,
              nextMessage,
              isNewDay,
            );
          },
        );
      },
    );
  }

  BubbleSpecialThree _buildTextMessage(
      String message, Map<String, dynamic> data, bool isNewSender) {
    return BubbleSpecialThree(
      text: message,
      color: data['senderID'] == _auth.currentUser!.uid
          ? ColorsManager.redPrimary
          : ColorsManager.purplePrimary,
      textAlign: TextAlign.left,
      sendTime: DateFormat("H:mm").format(
        data['timestamp'].toDate(),
      ),
      tail: isNewSender,
      isSender: data['senderID'] == _auth.currentUser!.uid
          ? true
          : false,
      seen: (data['senderID'] == _auth.currentUser!.uid) && data['isViewed'],
    );
  }

  Future<void> _downloadImageFromFirebase(Reference ref, String url) async {
    _showLoadingDialog();
    // Define the path where you want to save the image
    final tempDir = Directory.systemTemp;
    final path = '${tempDir.path}/${ref.name}';

    // Download the image using Dio
    await DioFactory.getDio().download(url, path);

    // Save the file to the gallery
    await Gal.putImage(
      path,
      album: 'ChatChat',
    );
    if (!mounted) return;
    context.pop();

    // Show a snackbar to indicate the download is complete
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image Downloaded')),
    );
  }

  bool _isSameDay(DateTime timestamp1, DateTime timestamp2) {
    return timestamp1.year == timestamp2.year &&
        timestamp1.month == timestamp2.month &&
        timestamp1.day == timestamp2.day;
  }

  Future<void> _launchURL(String myUrl) async {
    if (!myUrl.startsWith('http://') && !myUrl.startsWith('https://')) {
      myUrl = 'https://$myUrl';
    }
    final Uri url = Uri.parse(myUrl);
    if (!await launchUrl(
      url,
      mode: LaunchMode.inAppBrowserView,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  void _setMessageAsViewed(chatRoomID, messageId) {
    DatabaseMethods.setMessageAsViewed(chatRoomID, messageId);
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(
              color: ColorsManager.redPrimary,
            ),
          ),
        );
      },
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
