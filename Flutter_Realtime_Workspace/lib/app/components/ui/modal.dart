import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Premium modal dialog with iOS-style blur backdrop and Cupertino actions.
class TModal {
  TModal._();

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDanger = false,
    bool barrierDismissible = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: CupertinoAlertDialog(
            title: Text(
              title,
              style: TextStyle(
                color: isDark ? TColors.textDark : TColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: content ??
                (message != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: TSizes.sm),
                        child: Text(
                          message,
                          style: TextStyle(
                            color: isDark
                                ? TColors.textDarkSecondary
                                : TColors.textLightSecondary,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : null),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  onCancel?.call();
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  cancelText,
                  style: TextStyle(
                    color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary,
                  ),
                ),
              ),
              CupertinoDialogAction(
                isDestructiveAction: isDanger,
                onPressed: () {
                  onConfirm?.call();
                  Navigator.of(ctx).pop(true);
                },
                child: Text(
                  confirmText,
                  style: TextStyle(
                    color: isDanger ? TColors.error : TColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
