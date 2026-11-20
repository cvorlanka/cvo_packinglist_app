import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final double height;
  final double width;
  final double textfieldFontSize;
  final ValueChanged<String>? onChanged;
  final String allowChars;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.height,
    required this.width,
    required this.textfieldFontSize,
    this.onChanged,
    required this.allowChars,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: TextField(
        controller: widget.controller,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(widget.allowChars)),
        ],
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: const TextStyle(
            color: Colors.black,
            fontSize: 17,
          ),
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
          fontSize: widget.textfieldFontSize,
        ),
      ),
    );
  }
}
