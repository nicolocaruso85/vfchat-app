import 'dart:io';

import 'package:chatchat/helpers/extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/database.dart';
import '../../../services/notification_service.dart';
import '../../../themes/colors.dart';

class DisplayPictureScreen extends StatefulWidget {
  final XFile image;
  final String? token;
  final String? receivedMToken;
  final String? receivedUserID;

  const DisplayPictureScreen({
    super.key,
    required this.image,
    this.token,
    this.receivedMToken,
    this.receivedUserID,
  });

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  late String url;

  final _auth = FirebaseAuth.instance;
  Reference? storageRef;

  final _chatService = NotificationService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('displayPicture')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 22.0.sp, color: Colors.white),
        backgroundColor: ColorsManager.redPrimary,
        visible: true,
        curve: Curves.bounceIn,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.save_alt_rounded, color: Colors.white),
            backgroundColor: ColorsManager.redPrimary,
            onTap: () async {
              _showLoadingDialog();
              final String filename = widget.image.name;
              await widget.image
                  .saveTo('/storage/emulated/0/DCIM/Camera/$filename');
              if (!context.mounted) return;
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Immagine Salvata'),
                ),
              );
            },
            label: 'Salva',
            labelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontSize: 16.0.sp,
            ),
            labelBackgroundColor: const Color(0xff273443),
          ),
          if (widget.receivedUserID != '')
            SpeedDialChild(
              child: const Icon(Icons.send_rounded, color: Colors.white),
              backgroundColor: ColorsManager.redPrimary,
              onTap: () async {
                _showLoadingDialog();
                storageRef =
                    FirebaseStorage.instance.ref('images/${widget.image.name}');
                await storageRef!.putFile(File(widget.image.path));

                url = await storageRef!.getDownloadURL();
                await DatabaseMethods.sendMessage(
                  url,
                  widget.receivedUserID!,
                );
                await _chatService.sendPushMessage(
                  widget.receivedMToken!,
                  widget.token!,
                  '📷 Foto',
                  _auth.currentUser!.displayName!,
                  _auth.currentUser!.uid,
                  _auth.currentUser!.photoURL,
                );
                if (!context.mounted) return;
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Immagine inviata'),
                  ),
                );
              },
              label: 'Invia',
              labelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0.sp,
              ),
              labelBackgroundColor: const Color(0xff273443),
            )
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        child: Image.file(
          File(widget.image.path),
          filterQuality: FilterQuality.high,
          fit: BoxFit.cover,
        ),
      ),
    );
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
}
