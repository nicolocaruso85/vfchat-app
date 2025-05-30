import 'package:flutter/material.dart';

///Normal Message bar with more actions
///
/// following attributes can be modified
///
///
/// # BOOLEANS
/// [replying] is the additional reply widget top of the message bar
///
/// # STRINGS
/// [replyingTo] is the string to tag the replying message
/// [messageBarHintText] is the string to show as message bar hint
///
/// # WIDGETS
/// [actions] are the additional leading action buttons like camera
/// and file select
///
/// # COLORS
/// [replyWidgetColor] is the reply widget color
/// [replyIconColor] is the reply icon color on the left side of reply widget
/// [replyCloseColor] is the close icon color on the right side of the reply
/// widget
/// [messageBarColor] is the color of the message bar
/// [sendButtonColor] is the color of the send button
/// [messageBarHintStyle] is the style of the message bar hint
///
/// # METHODS
/// [onTextChanged] is the function which triggers after text every text change
/// [onSend] is the send button action
/// [onTapCloseReply] is the close button action of the close button on the
/// reply widget usually change [replying] attribute to `false`

class MessageBar extends StatelessWidget {
  final bool replying;
  final String replyingTo;
  final List<Widget> actions;
  final TextEditingController _textController = TextEditingController();
  final Color replyWidgetColor;
  final Color replyIconColor;
  final Color replyCloseColor;
  final Color messageBarColor;
  final EdgeInsetsGeometry paddingTextAndSendButton;
  final EdgeInsetsGeometry contentPadding;

  final String messageBarHintText;
  final TextStyle messageBarHintStyle;
  final TextStyle messageBarTextStyle;

  final Color sendButtonColor;
  final void Function(String)? onTextChanged;
  final void Function(String)? onSend;
  final void Function()? onTapCloseReply;

  /// [MessageBar] constructor
  ///
  ///
  MessageBar({
    Key? key,
    this.replying = false,
    this.replyingTo = "",
    this.paddingTextAndSendButton = const EdgeInsets.only(left: 16),
    this.actions = const [],
    this.replyWidgetColor = const Color(0xffF4F4F5),
    this.replyIconColor = Colors.blue,
    this.replyCloseColor = Colors.black12,
    this.messageBarColor = const Color(0xffF4F4F5),
    this.sendButtonColor = Colors.blue,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    this.messageBarHintText = "Type your message here",
    this.messageBarHintStyle = const TextStyle(fontSize: 16),
    this.messageBarTextStyle = const TextStyle(fontSize: 16),
    this.onTextChanged,
    this.onSend,
    this.onTapCloseReply,
  }) : super(key: key);

  /// [MessageBar] builder method
  ///
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          replying
              ? Container(
                  color: replyWidgetColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        color: replyIconColor,
                        size: 24,
                      ),
                      Expanded(
                        child: Text(
                          'Re : $replyingTo',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: onTapCloseReply,
                        child: Icon(
                          Icons.close,
                          color: replyCloseColor,
                          size: 24,
                        ),
                      ),
                    ],
                  ))
              : Container(),
          replying
              ? Container(
                  height: 1,
                  color: Colors.grey.shade300,
                )
              : Container(),
          Container(
            color: messageBarColor,
            padding: const EdgeInsets.only(
              bottom: 4,
              top: 8,
            ),
            child: Row(
              children: <Widget>[
                ...actions,
                Expanded(
                  child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    style: messageBarTextStyle,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 6,
                    onChanged: onTextChanged,
                    decoration: InputDecoration(
                      hintText: messageBarHintText,
                      hintMaxLines: 1,
                      hintStyle: messageBarHintStyle,
                      contentPadding: contentPadding,
                      fillColor: Colors.transparent,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(
                          color: Color(0xff858585),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(
                          color: Color(0xff858585),
                          width: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: paddingTextAndSendButton,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xff3d2985),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        if (_textController.text.trim() != '') {
                          if (onSend != null) {
                            onSend!(_textController.text.trim());
                          }
                          _textController.text = '';
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
