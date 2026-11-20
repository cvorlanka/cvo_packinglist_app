// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:packinglist_app/components/widgets/textfields/custom_textfield.dart';

class DynamicWidget extends StatefulWidget {
  double screenHgt;
  double screenWdt;
  final int index;
  String? textfieldValue;
  final TextEditingController? qtyController;
  final List<dynamic> list;

  DynamicWidget({
    super.key,
    required this.list,
    required this.index,
    this.qtyController,
    this.textfieldValue,
    required this.screenHgt,
    required this.screenWdt,
  });

  @override
  _DynamicWidgetState createState() => _DynamicWidgetState();
}

class _DynamicWidgetState extends State<DynamicWidget> {
  final TextEditingController qtyController = TextEditingController();
  double dynamicWidgetHeight = 0;
  double dynamicWidgetFontSize = 0;
  double dynamicWidgetPadding = 0;
  double textfieldSpacing = 0;
  double textfieldHgt = 0;
  double textfieldWth = 0;
  double textfieldFontSize = 0;

  @override
  void dispose() {
    //qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.screenHgt > 900 && widget.screenWdt > 1700) {
      dynamicWidgetHeight = 60;
      dynamicWidgetFontSize = 15;
      dynamicWidgetPadding = 8;
      textfieldSpacing = 13;
      textfieldHgt = 50;
      textfieldWth = 80;
      textfieldFontSize = 15;
    } else {
      dynamicWidgetHeight = 50;
      dynamicWidgetFontSize = 12;
      dynamicWidgetPadding = 4;
      textfieldSpacing = 5;
      textfieldHgt = 40;
      textfieldWth = 70;
      textfieldFontSize = 12;
    }
    return SizedBox(
      height: dynamicWidgetHeight,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.only(left: 5, right: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.list[widget.index]['part_no']}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: dynamicWidgetFontSize,
                ),
              ),
              Text(
                '${widget.list[widget.index]['description']}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: dynamicWidgetFontSize,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${widget.list[widget.index]['pack_qty']}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: dynamicWidgetFontSize,
                    ),
                  ),
                  SizedBox(width: textfieldSpacing),
                  CustomTextField(
                    height: textfieldHgt,
                    width: textfieldWth,
                    textfieldFontSize: textfieldFontSize,
                    controller: qtyController,
                    labelText: 'Qty',
                    onChanged: (value) {
                      setState(() {
                        if (value != '') {
                          widget.textfieldValue = value;
                        } else {
                          widget.textfieldValue = '0';
                        }
                      });
                    },
                    allowChars: '[0-9]',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
