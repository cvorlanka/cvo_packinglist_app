// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:packinglist_app/components/colors/colors.dart';

class Header extends StatelessWidget {
  final String userName;
  final VoidCallback onSignOut;
  final VoidCallback onNewOrderClick;
  final double screenHgt;
  final double screenWdt;
  double containerHeight = 0;
  double containerPadding = 0;
  double logoFontSize = 0;
  double textFontSize = 0;
  double sizedBoxWidth = 0;
  double iconSize = 0;

  Header({
    super.key,
    required this.userName,
    required this.onSignOut,
    required this.onNewOrderClick,
    required this.screenHgt,
    required this.screenWdt,
  });

  @override
  Widget build(BuildContext context) {
    if (screenHgt > 900 && screenWdt > 1700) {
      containerHeight = 80;
      containerPadding = 30;
      logoFontSize = 60;
      textFontSize = 20;
      sizedBoxWidth = 30;
      iconSize = 30;
    } else {
      containerHeight = 50;
      containerPadding = 15;
      logoFontSize = 35;
      textFontSize = 15;
      sizedBoxWidth = 15;
      iconSize = 20;
    }
    return Container(
      height: containerHeight,
      width: double.infinity,
      decoration: const BoxDecoration(color: AppColor.secondary),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: containerPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CLEARVISION OPTICAL',
              style: GoogleFonts.bebasNeue(
                color: Colors.white,
                fontSize: logoFontSize,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: onNewOrderClick,
                  style: TextButton.styleFrom(
                    side: BorderSide(color: Colors.white, width: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'New Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textFontSize,
                    ),
                  ),
                ),
                SizedBox(width: sizedBoxWidth),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: textFontSize,
                  ),
                ),
                SizedBox(width: sizedBoxWidth),
                IconButton(
                  onPressed: onSignOut,
                  icon: Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
