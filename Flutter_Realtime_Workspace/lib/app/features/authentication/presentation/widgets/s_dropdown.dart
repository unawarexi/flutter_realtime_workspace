import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Styled dropdown that uses the same border / fill tokens as [TInput].
class SDropdown extends StatelessWidget {
  const SDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDarkMode,
  });

  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDarkMode ? TColors.darkBorder : TColors.lightBorder;
    final fillColor =
        isDarkMode ? TColors.darkSurface : TColors.lightElevated;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          borderSide: BorderSide(color: TColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: TSizes.inputPadding,
          horizontal: TSizes.md,
        ),
      ),
      dropdownColor:
          isDarkMode ? TColors.darkSurface : TColors.lightSurface,
      style: TextStyle(
        color: isDarkMode ? TColors.textDark : TColors.textLight,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: isDarkMode
              ? TColors.textSecondaryDark
              : TColors.textSecondaryLight),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
