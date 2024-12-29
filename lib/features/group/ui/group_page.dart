import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_scroll_text/auto_scroll_text.dart';

import '../../../core/networking/dio_factory.dart';
import '../../../themes/colors.dart';
import '../../../helpers/extensions.dart';
import '../../../helpers/notifications.dart';
import '../../../router/routes.dart';
import '../../../services/database.dart';
import '../../chat/ui/widgets/message_bar.dart';
import '../../chat/ui/widgets/url_preview.dart';

class GroupScreen extends StatefulWidget {
  final String groupID;
  final String groupName;
  final String groupPic;
  final List users;

  const GroupScreen({
    super.key,
    required this.groupID,
    required this.groupName,
    required this.groupPic,
    required this.users,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final _auth = FirebaseAuth.instance;

  late String? token;
  final _picker = ImagePicker();

  String? usersList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/chat_backgrond.png"),
            opacity: 0.1,
            fit: BoxFit.cover,
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
                  await DatabaseMethods.sendGroupMessage(
                    message,
                    widget.groupID,
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

  @override
  void initState() {
    super.initState();

    List uList = [];
    widget.users.forEach((user) async {
      var u = await user.get();
      uList.add(u['name']);

      setState(() {
        usersList = uList.join(', ');
      });
    });
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      leadingWidth: 85.w,
      leading: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => Navigator.pop(context),
        child: Row(
          children: [
            Gap(10.w),
            Icon(Icons.arrow_back_ios, size: 25.sp),
            widget.groupPic != null &&
                    widget.groupPic != ''
                ? Hero(
                    tag: widget.groupPic!,
                    child: ClipOval(
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/images/loading.gif',
                        image: widget.groupPic!,
                        fit: BoxFit.cover,
                        width: 50.w,
                        height: 50.h,
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/images/user.png',
                    height: 50.h,
                    width: 50.w,
                    fit: BoxFit.cover,
                  ),
          ],
        ),
      ),
      toolbarHeight: 70.h,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.groupName),
          AutoScrollText(
            (usersList != null) ? usersList! : '',
            mode: AutoScrollTextMode.bouncing,
            velocity: Velocity(pixelsPerSecond: Offset(25, 0)),
            delayBefore: Duration(milliseconds: 500),
            pauseBetween: Duration(milliseconds: 2000),
            padding: EdgeInsets.only(right: 30),
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color.fromARGB(255, 179, 178, 178),
            ),
          ),
        ],
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
      ]);
    }
  }

  Future showImageOptions() async {
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

  Future<void> _downloadImageFromFirebase(Reference ref, String url) async {
    _showLoadingDialog();
    // Define the path where you want to save the image
    final tempDir = await getTemporaryDirectory();
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

  Align _buildLinkPreviewer(Map<String, dynamic> data, String message) {
    bool isNewSender = data['senderID'] == _auth.currentUser!.uid
        ? true
        : false;
    return Align(
      alignment: data['senderID'] == _auth.currentUser!.uid
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: isNewSender
            ? const EdgeInsets.fromLTRB(7, 7, 17, 7)
            : const EdgeInsets.fromLTRB(17, 7, 7, 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(20.r),
          ),
          color: data['senderID'] == _auth.currentUser!.uid
              ? const Color.fromARGB(255, 0, 107, 84)
              : const Color(0xff273443),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.all(
            Radius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LinkPreviewWidget(
                message: message,
                onLinkPressed: (link) async {
                  await _launchURL(link);
                },
              ),
              Gap(3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 5.h),
                child: Text(
                  DateFormat("H:mm").format(
                    data['timestamp'].toDate(),
                  ),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            dateColor: ColorsManager.gray400,
            color: const Color(0xff273443),
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
        DatabaseMethods.getGroupMessages(widget.groupID);

    List<String> sortedIDs = [_auth.currentUser!.uid];
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
          ? const Color.fromARGB(255, 0, 107, 84)
          : const Color(0xff273443),
      textAlign: TextAlign.left,
      sendTime: DateFormat("H:mm").format(
        data['timestamp'].toDate(),
      ),
      tail: isNewSender,
      isSender: data['senderID'] == _auth.currentUser!.uid
          ? true
          : false,
    );
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

  bool _isSameDay(DateTime timestamp1, DateTime timestamp2) {
    return timestamp1.year == timestamp2.year &&
        timestamp1.month == timestamp2.month &&
        timestamp1.day == timestamp2.day;
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
              color: ColorsManager.greenPrimary,
            ),
          ),
        );
      },
    );
  }
}