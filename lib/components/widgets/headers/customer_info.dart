import 'package:flutter/material.dart';

class CustomerInfo extends StatelessWidget {
  final String name;
  final String address;
  final String poNumber;
  final double screenHgt;
  final double screenWdt;

  const CustomerInfo({
    super.key,
    required this.screenHgt,
    required this.screenWdt,
    required this.name,
    required this.address,
    required this.poNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (screenHgt > 900 && screenWdt > 1700) ? 50 : 30,
      width: double.infinity,
      color: Colors.blue.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (screenHgt > 900 && screenWdt > 1700) ? 30 : 15,
            ),
            child: Text(
              'PO#: $poNumber   -   $name   -   $address',
              style: TextStyle(
                color: Colors.white,
                fontSize: (screenHgt > 900 && screenWdt > 1700) ? 20 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
