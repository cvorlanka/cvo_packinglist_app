import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class MyTextField extends StatelessWidget {
  TextEditingController controller = TextEditingController();
  final String labelText;
  final String allowChars;
  final bool obscureText;

  MyTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.obscureText,
    required this.allowChars,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextField(
        controller: controller,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(allowChars)),
        ],
        decoration: InputDecoration(
          fillColor: Colors.grey.shade100,
          filled: true,
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
          ),
        ),
        obscureText: obscureText,
      ),
    );
  }
}