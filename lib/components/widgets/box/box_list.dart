import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BoxList extends StatefulWidget {
  final double screenHgt;
  final double screenWdt;

  final List<dynamic> boxWidgetList;
  final List<dynamic> resultList;
  final List<dynamic> tempList;

  final VoidCallback onCompleteBox;
  final void Function (int boxIndex) onDuplicatePressed;
  final void Function(int boxIndex) onBoxTap;

  const BoxList({
    super.key,
    required this.boxWidgetList,
    required this.onBoxTap,
    required this.resultList,
    required this.tempList,
    required this.onCompleteBox,
    required this.onDuplicatePressed,
    required this.screenHgt,
    required this.screenWdt,
  });

  @override
  State<BoxList> createState() => _BoxListState();
}

class _BoxListState extends State<BoxList> {
  double labelSize = 0;
  double btnPadding = 0;
  double btnIconSize = 0;
  double btnFontSize = 0;
  double labelPadding = 0;
  double boxListHgt = 0;
  double topPadding = 0;
  double leftPadding = 0;
  double rightPadding = 0;
  double duplicateBtnSize = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.screenHgt > 900 && widget.screenWdt > 1700) {
      labelSize = 30;
      labelPadding = 15;
      btnPadding = 15;
      btnIconSize = 30;
      btnFontSize = 17;
      duplicateBtnSize = 25;
      boxListHgt = widget.screenHgt / 2 - 140;
      topPadding = 10;
      leftPadding = 10;
      rightPadding = 10;
    } else {
      labelSize = 20;
      labelPadding = 5;
      btnPadding = 8;
      btnIconSize = 20;
      btnFontSize = 12;
      duplicateBtnSize = 15;
      boxListHgt = widget.screenHgt / 2 - 100;
      topPadding = 2;
      leftPadding = 2;
      rightPadding = 2;
    }
    return Padding(
      padding: EdgeInsets.only(
        top: topPadding,
        left: leftPadding,
        right: rightPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Box List',
                style: GoogleFonts.bebasNeue(
                  fontSize: labelSize,
                  color: Colors.black,
                ),
              ),
              TextButton.icon(
                onPressed:
                    widget.tempList.isEmpty ? null : widget.onCompleteBox,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(
                    btnPadding,
                  ),
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey.shade400,
                  disabledIconColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                icon: Icon(
                  Icons.add_circle,
                  color: Colors.white,
                  size: btnIconSize,
                ),
                label: Text(
                  'Box',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: btnFontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (widget.boxWidgetList.isEmpty) ...[
            const Text(''),
          ] else ...[
            SizedBox(height: labelPadding),
            SizedBox(
              height: boxListHgt,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < widget.boxWidgetList.length; i++) ...[
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onBoxTap(i),
                              child: widget.boxWidgetList[i],
                            ),
                          ),
                          IconButton(
                            onPressed: () => widget.onDuplicatePressed(i),
                            icon: Icon(
                              Icons.add,
                              color: Colors.blue,
                              size: duplicateBtnSize,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
