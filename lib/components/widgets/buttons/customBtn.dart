import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final void Function()? onPressed;
  final Color color;
  final double height;
  final double minWidth;
  final Widget child;

  const CustomButton({
    super.key,
    this.onPressed,
    required this.color,
    required this.height,
    required this.minWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: color,
      disabledColor: Colors.grey.shade400,
      disabledTextColor: Colors.grey.shade200,
      height: height,
      minWidth: minWidth,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}
