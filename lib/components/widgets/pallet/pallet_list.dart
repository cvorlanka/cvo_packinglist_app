import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PalletList extends StatefulWidget {
  final double screenHgt;
  final double screenWdt;

  final List<dynamic> palletWidgetList;
  final List<dynamic> boxList;

  final VoidCallback onCompletePallet;
  final void Function(int palletIndex) onPalletTap;

  const PalletList({
    super.key,
    required this.palletWidgetList,
    required this.onPalletTap,
    required this.onCompletePallet,
    required this.boxList,
    required this.screenHgt,
    required this.screenWdt,
  });

  @override
  State<PalletList> createState() => _PalletListState();
}

class _PalletListState extends State<PalletList> {
  double labelSize = 0;
  double btnPadding = 0;
  double btnIconSize = 0;
  double btnFontSize = 0;
  double labelPadding = 0;
  double palletListHgt = 0;
  double topPadding = 0;
  double leftPadding = 0;
  double rightPadding = 0;
  double listLeftPadding = 0;
  double listRightPadding = 0;
  double listBottomPadding = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.screenHgt > 900 && widget.screenWdt > 1700) {
      labelSize = 30;
      labelPadding = 15;
      btnPadding = 15;
      btnIconSize = 30;
      btnFontSize = 17;
      palletListHgt = widget.screenHgt / 2 - 140;
      topPadding = 10;
      leftPadding = 10;
      rightPadding = 10;
      listLeftPadding = 5;
      listRightPadding = 5;
      listBottomPadding = 10;
    } else {
      labelSize = 20;
      labelPadding = 5;
      btnPadding = 8;
      btnIconSize = 20;
      btnFontSize = 12;
      palletListHgt = widget.screenHgt / 2 - 100;
      topPadding = 10;
      leftPadding = 0;
      rightPadding = 5;
      listLeftPadding = 2;
      listRightPadding = 2;
      listBottomPadding = 7;
    }
    return Padding(
      padding: EdgeInsets.only(
        top: topPadding,
        left: leftPadding,
        right: rightPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pallet List',
                style: GoogleFonts.bebasNeue(
                  fontSize: labelSize,
                  color: Colors.black,
                ),
              ),
              TextButton.icon(
                onPressed:
                    widget.boxList.isEmpty ? null : widget.onCompletePallet,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(
                    btnPadding,
                  ),
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey.shade400,
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
                  'Pallet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: btnFontSize,
                  ),
                ),
              ),
            ],
          ),
          if (widget.palletWidgetList.isEmpty) ...[
            const Text(''),
          ] else ...[
            SizedBox(height: labelPadding),
            SizedBox(
              height: palletListHgt,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      direction: Axis.horizontal,
                      children: [
                        for (var i = 0;
                            i < widget.palletWidgetList.length;
                            i++) ...[
                          Padding(
                            padding: EdgeInsets.only(
                              left: listLeftPadding,
                              right: listRightPadding,
                              bottom: listBottomPadding,
                            ),
                            child: GestureDetector(
                              onTap: () => widget.onPalletTap(i),
                              child: widget.palletWidgetList[i],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
