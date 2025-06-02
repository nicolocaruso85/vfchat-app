import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LinkPreviewWidget extends StatefulWidget {
  final String message;
  final Function(String) onLinkPressed;

  const LinkPreviewWidget({
    super.key,
    required this.message,
    required this.onLinkPressed,
  });
  @override
  State<LinkPreviewWidget> createState() => _LinkPreviewWidgetState();
}

class _LinkPreviewWidgetState extends State<LinkPreviewWidget> {
  Map<String, PreviewData> datas = {};

  @override
  Widget build(BuildContext context) {
    return LinkPreview(
      imageWidth: double.infinity,
      width: MediaQuery.of(context).size.width * 0.7,
      padding: EdgeInsets.all(0),
      onLinkPressed: widget.onLinkPressed,
      enableAnimation: true,
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      openOnPreviewImageTap: true,
      openOnPreviewTitleTap: true,
      onPreviewDataFetched: (previewData) {
        setState(() {
          datas = {
            ...datas,
            widget.message: previewData,
          };
        });
      },
      metadataTitleStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      metadataTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 13,
      ),
      previewData: datas[widget.message],
      text: widget.message,
      linkStyle: TextStyle(
        decorationColor: Colors.white,
        color: Colors.white,
        fontSize: 16,
      ),
    );
  }
}
