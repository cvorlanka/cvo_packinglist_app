// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditBoxWidget extends StatefulWidget {
  final boxNumber;
  final dims;
  List<dynamic> currentElement;
  List<dynamic> orderList;

  EditBoxWidget({
    super.key,
    this.boxNumber,
    required this.currentElement,
    required this.orderList,
    this.dims,
  });

  @override
  State<EditBoxWidget> createState() => _EditBoxWidgetState();
}

class _EditBoxWidgetState extends State<EditBoxWidget> {
  List<dynamic> fixedOrderList = [];
  // list of textEditingControllers
  late List<TextEditingController> controllersList;
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  // list of checkbox values
  late List<bool> isChecked;

  @override
  void initState() {
    super.initState();
    controllersList = List<TextEditingController>.generate(
      widget.currentElement.length,
      (index) => TextEditingController(),
    );
    isChecked = List<bool>.filled(
      widget.currentElement.length,
      false,
      growable: true,
    );
  }

  void getChanges() {
    int length = int.tryParse(lengthController.text) ?? widget.dims['LENGTH'];
    int width = int.tryParse(widthController.text) ?? widget.dims['WIDTH'];
    int height = int.tryParse(heightController.text) ?? widget.dims['HEIGHT'];
    int weight = int.tryParse(weightController.text) ?? widget.dims['WEIGHT'];

    // check that dimensions are > 0
    if (length > 0 && width > 0 && height > 0 && weight > 0) {
      widget.dims['LENGTH'] = length;
      widget.dims['WIDTH'] = width;
      widget.dims['HEIGHT'] = height;
      widget.dims['WEIGHT'] = weight;
      getQtyChanges();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error!'),
          content: Text("Dimensions have to be bigger than zero"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void getQtyChanges() {
    List<bool> checkIfAmountAreValid = [];
    // check every textfield value to make sure they're all less than the total amount
    for (var j = 0; j < controllersList.length; j++) {
      int inputValue = int.tryParse(controllersList[j].text) ??
          widget.currentElement[j]['user_input'];
      int totalQty = widget.currentElement[j]['pack_qty'] +
          widget.currentElement[j]['user_input'];
      if (inputValue == 0 || inputValue > totalQty) {
        checkIfAmountAreValid.add(false);
      } else {
        checkIfAmountAreValid.add(true);
      }
    }
    // print('BoolsList: $checkIfAmountAreValid');

    // throw error if amounts are too big
    if (checkIfAmountAreValid.contains(false)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(
            'Amounts must be greater than zero and smaller than original qty',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // if amounts are ok check for items that are checked off
      // and remove them from the list of items
      for (var k = isChecked.length - 1; k >= 0; k--) {
        if (isChecked[k]) {
          bool isFound = false;
          for (var i = 0; i < widget.orderList.length; i++) {
            if (isFound == false) {
              List<dynamic> currentOrder =
                  List.from(widget.orderList[i] as List);
              for (var j = 0; j < currentOrder.length; j++) {
                var currentItem = currentOrder[j];
                if (currentItem['order_no'] ==
                        widget.currentElement[k]['order_no'] &&
                    currentItem['part_no'] ==
                        widget.currentElement[k]['part_no']) {
                  currentItem['pack_qty'] +=
                      widget.currentElement[k]['user_input'];
                  currentItem['user_input'] -
                      widget.currentElement[k]['user_input'];
                  currentItem['user_input'] -=
                      widget.currentElement[k]['user_input'];
                  widget.currentElement.removeAt(k);
                  isFound = true;
                  break;
                }
              }
            } else {
              isFound = false;
              break;
            }
          }
        }
      }
      // print('CurrentElements: ${widget.currentElement}');
      // print('OrderList: ${widget.orderList}');
      // change amounts in orderList(original) for every item in currentElement list
      for (var i = 0; i < widget.currentElement.length; i++) {
        bool beenFound = false;
        int originalValue = widget.currentElement[i]['user_input'];
        int inputValue = int.tryParse(controllersList[i].text) ??
            widget.currentElement[i]['user_input'];
        int totalQty = widget.currentElement[i]['pack_qty'] +
            widget.currentElement[i]['user_input'];
        int remainder = totalQty - inputValue;
        widget.currentElement[i]['user_input'] = inputValue;
        widget.currentElement[i]['pack_qty'] = remainder;
        for (var e = 0; e < widget.orderList.length; e++) {
          if (beenFound == false) {
            List<dynamic> currentOrder = List.from(widget.orderList[e] as List);
            for (var f = 0; f < currentOrder.length; f++) {
              var currentItem = currentOrder[f];
              if (currentItem['order_no'] ==
                      widget.currentElement[i]['order_no'] &&
                  currentItem['part_no'] ==
                      widget.currentElement[i]['part_no']) {
                int orderOriginalValue =
                    currentItem['pack_qty'] + currentItem['user_input'];
                currentItem['pack_qty'] += originalValue - inputValue;
                currentItem['user_input'] =
                    orderOriginalValue - currentItem['pack_qty'];
                beenFound = true;
                break;
              }
            }
          } else {
            beenFound = false;
            break;
          }
        }
      }
      Navigator.pop(context, widget.orderList);
    }
    // print('ItemsList: ${widget.currentElement}');
    // print('OrderList: ${widget.orderList}');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Box ${widget.boxNumber}'),
          Icon(
            Icons.delete_forever_rounded,
            color: Colors.red,
            size: 30,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.currentElement.isEmpty) ...[
              Text('Box is Empty'),
            ] else ...[
              const SizedBox(height: 10),
              for (var i = 0; i < widget.currentElement.length; i++) ...[
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${widget.currentElement[i]['description']}'),
                        const SizedBox(width: 50),
                        Row(
                          children: [
                            SizedBox(
                              height: 45,
                              width: 70,
                              child: TextField(
                                controller: controllersList[i],
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.top,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp('[0-9]')),
                                ],
                                decoration: InputDecoration(
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Checkbox(
                              value: isChecked[i],
                              onChanged: (value) {
                                setState(() {
                                  isChecked[i] = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Row(children: [
                        Text('L: '),
                        SizedBox(
                          height: 45,
                          width: 55,
                          child: TextField(
                            controller: lengthController,
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.top,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp('[0-9]')),
                            ],
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black54,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(width: 10),
                      Row(children: [
                        Text('W: '),
                        SizedBox(
                          height: 45,
                          width: 55,
                          child: TextField(
                            controller: widthController,
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.top,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp('[0-9]')),
                            ],
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black54,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(width: 10),
                      Row(children: [
                        Text('H: '),
                        SizedBox(
                          height: 45,
                          width: 55,
                          child: TextField(
                            controller: heightController,
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.top,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp('[0-9]')),
                            ],
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black54,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Wgt: '),
                      SizedBox(
                        height: 45,
                        width: 55,
                        child: TextField(
                          controller: weightController,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.top,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                          ],
                          decoration: InputDecoration(
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black54,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            getChanges();
          },
          child: Text('Submit'),
        ),
      ],
    );
  }
}
