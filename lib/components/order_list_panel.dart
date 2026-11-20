import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:packinglist_app/components/colors/colors.dart';
import 'package:packinglist_app/pages/login_page.dart';

class OrderListPanel extends StatefulWidget {
  final double screenHgt;
  final double screenWdt;

  final List<dynamic> orderList;
  final List<dynamic> orderQtyList;
  final List<dynamic> tempList;
  final void Function(
    int i,
    List<dynamic> orderList,
    List<dynamic> tempList,
  )? addToRowWidgetList;

  const OrderListPanel({
    super.key,
    required this.screenHgt,
    required this.screenWdt,
    required this.orderList,
    required this.orderQtyList,
    required this.tempList,
    required this.addToRowWidgetList,
  });

  @override
  State<OrderListPanel> createState() => _OrderListPanelState();
}

class _OrderListPanelState extends State<OrderListPanel> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 5),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical:
                  (widget.screenHgt > 900 && widget.screenWdt > 1700) ? 20 : 10,
            ),
            child: Text(
              'ORDER LIST',
              style: GoogleFonts.bebasNeue(
                color: Colors.black,
                fontSize: (widget.screenHgt > 900 && widget.screenWdt > 1700)
                    ? 30
                    : 20,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: widget.orderList.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      (widget.screenHgt > 900 && widget.screenWdt > 1700)
                          ? 20
                          : 10,
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.orderList[index][0]['order_no']}-${widget.orderList[index][0]['order_ext']}',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: (widget.screenHgt > 900 &&
                                    widget.screenWdt > 1700)
                                ? 20
                                : 15,
                          ),
                        ),
                        if (widget.orderQtyList.isNotEmpty) ...[
                          Text(
                            '${widget.orderQtyList[index]}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: (widget.screenHgt > 900 &&
                                      widget.screenWdt > 1700)
                                  ? 20
                                  : 15,
                            ),
                          ),
                        ],
                      ],
                    ),
                    backgroundColor: Colors.grey.shade300,
                    childrenPadding: EdgeInsets.symmetric(
                      horizontal:
                          (widget.screenHgt > 900 && widget.screenWdt > 1700)
                              ? 10
                              : 5,
                    ),
                    collapsedIconColor: Colors.black,
                    iconColor: Colors.black,
                    children: [
                      for (var i = 0;
                          i < (widget.orderList[index]).length;
                          i++) ...[
                        GestureDetector(
                          onDoubleTap: () {
                            widget.orderList[index][i]['pack_qty'] == 0
                                ? showAlertDialog(context, 'SKU is Completed')
                                : widget.addToRowWidgetList!(
                                    i,
                                    widget.orderList[index],
                                    widget.tempList,
                                  );
                          },
                          child: Card(
                            color: Colors.white,
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              tileColor: AppColor.primary,
                              leading: Text(
                                '${widget.orderList[index][i]['part_no']}',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: (widget.screenHgt > 900 &&
                                          widget.screenWdt > 1700)
                                      ? 18
                                      : 14,
                                ),
                              ),
                              trailing:
                                  widget.orderList[index][i]['pack_qty'] == 0
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.green,
                                          size: (widget.screenHgt > 900 &&
                                                  widget.screenWdt > 1700)
                                              ? 35
                                              : 25,
                                        )
                                      : Text(
                                          '${widget.orderList[index][i]['pack_qty']}',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: (widget.screenHgt > 900 &&
                                                    widget.screenWdt > 1700)
                                                ? 18
                                                : 14,
                                          ),
                                        ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
