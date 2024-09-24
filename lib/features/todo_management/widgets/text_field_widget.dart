import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({
    super.key,
    required this.hintText,
    required this.maxLine,
    this.errorText,
    required this.controller,
    required this.onFocusChange,
  });

  final String hintText;
  final int maxLine;
  final String? errorText; // Optional error text
  final TextEditingController controller; // Text editing controller
  final Function(bool) onFocusChange; // Callback for focus changes

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: onFocusChange, // Call the provided focus change function
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller, // Attach the controller
              decoration: InputDecoration(
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hintText,
                errorText: errorText, // Display error text if provided
              ),
              maxLines: maxLine,
            ),
            if (errorText != null) // Show error message below the text field
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  errorText!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
