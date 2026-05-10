// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static OverlayEntry? _currentOverlay;

  static void show(
    String message, {
    ToastType type = ToastType.info,
    ToastGravity gravity = ToastGravity.TOP,
    int durationSeconds = 10,
    String? title,
    required BuildContext context,
  }) {
    // Remove any existing toast
    _removeCurrentToast();

    final _ToastStyle style = _getStyle(type);

    // Create overlay entry
    _currentOverlay = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        title: title,
        style: style,
        gravity: gravity,
        duration: Duration(seconds: durationSeconds),
        onRemove: () => _removeCurrentToast(),
      ),
    );

    // Insert the overlay
    Overlay.of(context, rootOverlay: true).insert(_currentOverlay!);
  }

  static void _removeCurrentToast() {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }
  }

  static _ToastStyle _getStyle(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const _ToastStyle(
          color: Color(0xFF10B981),
          icon: Icons.check_circle_rounded,
        );
      case ToastType.error:
        return const _ToastStyle(
          color: Color(0xFFEF4444),
          icon: Icons.error_rounded,
        );
      case ToastType.warning:
        return const _ToastStyle(
          color: Color(0xFFF59E42), // Use a valid warning color
          icon: Icons.warning_amber_rounded,
        );
      case ToastType.info:
        return const _ToastStyle(
          color: Color(0xFF3B82F6),
          icon: Icons.info_rounded,
        );
    }
  }
}

enum ToastGravity { TOP, BOTTOM, CENTER }

class _ToastStyle {
  final Color color;
  final IconData icon;

  const _ToastStyle({
    required this.color,
    required this.icon,
  });
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final String? title;
  final _ToastStyle style;
  final ToastGravity gravity;
  final Duration duration;
  final VoidCallback onRemove;

  const _ToastOverlay({
    Key? key,
    required this.message,
    this.title,
    required this.style,
    required this.gravity,
    required this.duration,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Slide animation based on gravity
    Offset beginOffset;
    switch (widget.gravity) {
      case ToastGravity.TOP:
        beginOffset = const Offset(0, -1);
        break;
      case ToastGravity.BOTTOM:
        beginOffset = const Offset(0, 1);
        break;
      case ToastGravity.CENTER:
      beginOffset = const Offset(0, 0);
        break;
    }

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation
    _animationController.forward();

    // Auto remove after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _hideToast();
      }
    });
  }

  void _hideToast() async {
    await _animationController.reverse();
    widget.onRemove();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    // Position based on gravity
    double? top, bottom;
    switch (widget.gravity) {
      case ToastGravity.TOP:
        top = safePadding.top + 20;
        break;
      case ToastGravity.BOTTOM:
        bottom = safePadding.bottom + 20;
        break;
      case ToastGravity.CENTER:
        top = (screenSize.height - 100) / 2;
        break;
    }

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          Positioned(
            top: top,
            bottom: bottom,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: _hideToast,
                    child: _AdvancedToastWidget(
                      message: widget.message,
                      title: widget.title,
                      style: widget.style,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedToastWidget extends StatelessWidget {
  final String message;
  final String? title;
  final _ToastStyle style;

  const _AdvancedToastWidget({
    Key? key,
    required this.message,
    this.title,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double width =
        MediaQuery.of(context).size.width * 0.68; // reduced width for nav icons

    // Custom theme colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1E293B);
    // final subtitleColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(
          horizontal: 18, vertical: 4),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: style.color.withOpacity(0.13),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: style.color.withOpacity(0.11),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(5),
            child: Icon(
              style.icon,
              color: style.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null && title!.isNotEmpty) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: style.color,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to make usage easier
extension AppToastExtension on BuildContext {
  void showToast(
    String message, {
    ToastType type = ToastType.info,
    ToastGravity gravity = ToastGravity.TOP,
    int durationSeconds = 3,
    String? title,
  }) {
    AppToast.show(
      message,
      type: type,
      gravity: gravity,
      durationSeconds: durationSeconds,
      title: title,
      context: this,
    );
  }
}

// Utility methods for common toast types
extension AppToastUtils on AppToast {
  static void success(String message,
      {String? title, required BuildContext context}) {
    AppToast.show(message,
        type: ToastType.success, title: title, context: context);
  }

  static void error(String message,
      {String? title, required BuildContext context}) {
    AppToast.show(message,
        type: ToastType.error, title: title, context: context);
  }

  static void warning(String message,
      {String? title, required BuildContext context}) {
    AppToast.show(message,
        type: ToastType.warning, title: title, context: context);
  }

  static void info(String message,
      {String? title, required BuildContext context}) {
    AppToast.show(message,
        type: ToastType.info, title: title, context: context);
  }
}
