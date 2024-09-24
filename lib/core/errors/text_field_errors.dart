import 'package:flutter/material.dart';

class TextFieldError extends StatelessWidget {
  const TextFieldError({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.maxLine,
    required this.showError,
  }) : super(key: key);

  final TextEditingController controller;
  final String hintText;
  final int maxLine;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLine,
            decoration: InputDecoration(
              hintText: hintText,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorText: showError ? "This field is required" : null,
            ),
          ),
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              "This field is required",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
