import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemList extends StatefulWidget {
  final GlobalKey<_ItemListState> myItemListKey = GlobalKey<_ItemListState>();
  //final int loopIndex;
  final int boxNum;
  final double screenHgt;
  final double screenWdt;

  final List<dynamic> rowWidgetList;
  final List<dynamic> tempList;

  ItemList({
    super.key,
    required this.boxNum,
    required this.rowWidgetList,
    //required this.loopIndex,
    required this.tempList,
    required this.screenHgt,
    required this.screenWdt,
  });

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  double boxFontSize = 0;
  double boxSize = 0;
  double horizontalPadding = 0;
  double labelHorizontalPadding = 0;
  double labelVerticalPadding = 0;
  double labelFontSize = 0;
  double iconSize = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.screenHgt > 900 && widget.screenWdt > 1700) {
      boxFontSize = 35;
      boxSize = 15;
      horizontalPadding = 20;
      labelHorizontalPadding = 90;
      labelVerticalPadding = 20;
      labelFontSize = 20;
      iconSize = 30;
    } else {
      boxFontSize = 25;
      boxSize = 8;
      horizontalPadding = 10;
      labelHorizontalPadding = 45;
      labelVerticalPadding = 10;
      labelFontSize = 16;
      iconSize = 20;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Box ${widget.boxNum}',
          style: GoogleFonts.bebasNeue(fontSize: boxFontSize),
        ),
        SizedBox(height: boxSize),
        Container(
          height: MediaQuery.of(context).size.height / 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade300,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: labelHorizontalPadding,
                    vertical: labelVerticalPadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'SKU',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.black,
                              fontSize: labelFontSize),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'Description',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.black,
                              fontSize: labelFontSize),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'QTY',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.black,
                              fontSize: labelFontSize),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    key: _listKey,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            child: widget.rowWidgetList[index],
                          ),
                          IconButton(
                            onPressed: () {
                              widget.rowWidgetList.removeAt(index);
                              widget.tempList.removeAt(index);
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.red,
                              size: iconSize,
                            ),
                          ),
                        ],
                      );
                    },
                    itemCount: widget.rowWidgetList.length,
                  ),
                ),
                //   for (var index = 0;
                //       index < widget.rowWidgetList.length;
                //       index++) ...[
                //     Row(
                //       children: [
                //         Expanded(
                //           child: widget.rowWidgetList[index],
                //         ),
                //         IconButton(
                //           onPressed: () {
                //             widget.rowWidgetList.removeAt(index);
                //             widget.tempList.removeAt(index);
                //             setState(() {});
                //           },
                //           icon: Icon(
                //             Icons.delete_forever_rounded,
                //             color: Colors.red,
                //             size: iconSize,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ],
                // ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
