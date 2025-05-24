import 'package:flutter/material.dart';

///iMessage's chat bubble type
///
///chat bubble color can be customized using [color]
///chat bubble tail can be customized  using [tail]
///chat bubble display message can be changed using [text]
///[text] is the only required parameter
///message sender can be changed using [isSender]
///chat bubble [TextStyle] can be customized using [textStyle]

class BubbleSpecialThree extends StatelessWidget {
  final bool isSender;
  final String text;
  final String sendTime;
  final bool tail;
  final Color color;
  final TextAlign textAlign;
  final bool sent;
  final bool delivered;
  final bool seen;
  final TextStyle textStyle;
  final BoxConstraints? constraints;

  const BubbleSpecialThree({
    Key? key,
    this.isSender = true,
    this.constraints,
    required this.text,
    required this.sendTime,
    this.color = Colors.white70,
    this.tail = true,
    this.textAlign = TextAlign.left,
    this.sent = false,
    this.delivered = false,
    this.seen = false,
    this.textStyle = const TextStyle(
      color: Colors.black87,
      fontSize: 16,
    ),
  }) : super(key: key);

  ///chat bubble builder method
  @override
  Widget build(BuildContext context) {
    bool stateTick = false;
    Icon? stateIcon;
    if (sent) {
      stateTick = true;
      stateIcon = const Icon(
        Icons.done,
        size: 18,
        color: Color(0xFF97AD8E),
      );
    }
    if (delivered) {
      stateTick = true;
      stateIcon = const Icon(
        Icons.done_all,
        size: 18,
        color: Color(0xFF97AD8E),
      );
    }
    if (seen) {
      stateTick = true;
      stateIcon = const Icon(
        Icons.done_all,
        size: 18,
        color: Color(0xFF92DEDA),
      );
    }

    return Align(
      alignment: isSender ? Alignment.topRight : Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Column(
          crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            CustomPaint(
              painter: SpecialChatBubbleThree(
                color: color,
                alignment: isSender ? Alignment.topRight : Alignment.topLeft,
                tail: tail,
              ),
              child: Container(
                constraints: constraints ??
                  BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * .6,
                ),
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Stack(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: textAlign,
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Padding(
                            padding: stateTick
                              ? const EdgeInsets.only(right: 20)
                              : const EdgeInsets.only(right: 4),
                          ),
                        ],
                      ),
                    ),
                    stateIcon != null && stateTick
                        ? Positioned(
                            bottom: 0,
                            right: 0,
                            child: stateIcon,
                          )
                        : const SizedBox(
                            width: 1,
                          ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5),
            Text(
              sendTime,
              style: const TextStyle(
                color: Color(0xff828282),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///custom painter use to create the shape of the chat bubble
///
/// [color],[alignment] and [tail] can be changed

class SpecialChatBubbleThree extends CustomPainter {
  final Color color;
  final Alignment alignment;
  final bool tail;

  SpecialChatBubbleThree({
    required this.color,
    required this.alignment,
    required this.tail,
  });

  final double _radius = 15.0;

  @override
  void paint(Canvas canvas, Size size) {
    var h = size.height;
    var w = size.width;
    if (alignment == Alignment.topRight) {
      var path = Path();

      /// starting point
      path.moveTo(_radius, 0);

      /// top-left corner
      path.quadraticBezierTo(0, 0, 0, _radius);

      /// left line
      path.lineTo(0, h - _radius);

      /// bottom-left corner
      path.quadraticBezierTo(0, h, _radius, h);

      /// bottom line
      path.lineTo(w - _radius, h);

      /// bottom-right corner
      path.quadraticBezierTo(w, h, w, h - _radius);

      /// right line
      path.lineTo(w, 0);

      /// top-right curve
      //path.quadraticBezierTo(w - _radius, 0, w - _radius, 0);

      canvas.clipPath(path);
      canvas.drawRRect(
          RRect.fromLTRBR(0, 0, w, h, Radius.zero),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill);
    } else {
      var path = Path();

      /// starting point
      path.moveTo(0, 0);

      /// top-left corner
      //path.quadraticBezierTo(_radius, 0, _radius, _radius);

      /// left line
      path.lineTo(0, h - _radius);

      /// bottom-left bubble curve
      path.quadraticBezierTo(0, h, _radius, h);

      /// bottom line
      path.lineTo(w - _radius * 2, h);

      /// bottom-right curve
      path.quadraticBezierTo(w, h, w, h - _radius);

      /// right line
      path.lineTo(w, _radius);

      /// top-right curve
      path.quadraticBezierTo(w, 0, w - _radius, 0);
      canvas.clipPath(path);
      canvas.drawRRect(
          RRect.fromLTRBR(0, 0, w, h, Radius.zero),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
