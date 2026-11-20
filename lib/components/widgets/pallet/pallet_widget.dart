import 'package:flutter/material.dart';

class PalletWidget extends StatelessWidget {
  final int palletNumber;

  const PalletWidget({
    super.key,
    required this.palletNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PALLET $palletNumber',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
            const Text(
              'Tap to view details',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}