import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/file_picker.dart';

/// Circular avatar picker with pick / change / remove flow.
/// Calls [onImagePicked] with the [File] or null (when removed).
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.pickedFile,
    required this.networkUrl,
    required this.isDarkMode,
    required this.onImagePicked,
  });

  final File? pickedFile;
  final String networkUrl;
  final bool isDarkMode;
  final ValueChanged<File?> onImagePicked;

  ImageProvider? get _image {
    if (pickedFile != null) return FileImage(pickedFile!);
    if (networkUrl.isNotEmpty) return NetworkImage(networkUrl);
    return null;
  }

  Future<void> _pick(BuildContext context) async {
    final file = await pickImageFromGallery(imageQuality: 80);
    if (file != null) onImagePicked(file);
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDarkMode ? TColors.darkCard : TColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? TColors.darkBorder
                    : TColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: TColors.primary),
              title: Text('Select New Photo',
                  style: TextStyle(
                      color: isDarkMode
                          ? TColors.textDark
                          : TColors.textLight)),
              onTap: () async {
                Navigator.pop(context);
                await _pick(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Remove Photo',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                onImagePicked(null);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = pickedFile != null || networkUrl.isNotEmpty;

    return TWidgetAnimations.scaleIn(
      duration: const Duration(milliseconds: 320),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                hasImage ? _showOptions(context) : _pick(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode
                    ? TColors.darkElevated
                    : TColors.lightElevated,
                border: Border.all(
                  color: TColors.primary.withValues(alpha: 0.35),
                  width: 2,
                ),
                image: _image != null
                    ? DecorationImage(
                        image: _image!, fit: BoxFit.cover)
                    : null,
              ),
              child: _image == null
                  ? const Icon(Icons.person_outline,
                      color: TColors.primary, size: TSizes.iconLg)
                  : null,
            ),
          ),
          const SizedBox(width: TSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasImage ? 'Profile photo set' : 'Add a profile photo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDarkMode
                        ? TColors.textDark
                        : TColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () =>
                      hasImage ? _showOptions(context) : _pick(context),
                  child: Text(
                    hasImage ? 'Change or remove' : 'Tap to select',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
