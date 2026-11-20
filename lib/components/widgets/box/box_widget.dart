// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class BoxWidget extends StatefulWidget {
  int boxNumber;
  final double availHeight;
  final double availWidth;

  BoxWidget({
    super.key,
    required this.boxNumber,
    required this.availHeight,
    required this.availWidth,
  });

  @override
  State<BoxWidget> createState() => _BoxWidgetState();
}

class _BoxWidgetState extends State<BoxWidget> {
  double containerTopPadding = 0;
  double containerBottomPadding = 0;
  double boxTitleFontSize = 0;
  double boxSubtitleFontSize = 0;
  double boxHorizontalPadding = 0;
  double boxHeight = 0;

  int get getBoxNumber {
    return widget.boxNumber;
  }

  set setBoxNumber(int boxNumber) {
    widget.boxNumber = boxNumber;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availHeight > 900 && widget.availWidth > 1700) {
      containerBottomPadding = 10;
      boxTitleFontSize = 15;
      boxSubtitleFontSize = 12;
      boxHorizontalPadding = 10;
      boxHeight = 60;
    } else {
      containerBottomPadding = 5;
      boxTitleFontSize = 14;
      boxSubtitleFontSize = 11;
      boxHorizontalPadding = 5;
      boxHeight = 40;
    }
    return Padding(
      padding: EdgeInsets.only(bottom: containerBottomPadding),
      child: Container(
        height: boxHeight,
        padding: EdgeInsets.symmetric(horizontal: boxHorizontalPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BOX ${widget.boxNumber}',
              style: TextStyle(color: Colors.black, fontSize: boxTitleFontSize),
            ),
            Text(
              'Tap to view details',
              style:
                  TextStyle(color: Colors.black, fontSize: boxSubtitleFontSize),
            ),
          ],
        ),
      ),
    );
  }
}
