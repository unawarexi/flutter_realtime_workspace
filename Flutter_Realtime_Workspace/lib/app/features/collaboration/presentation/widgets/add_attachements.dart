import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/file_picker.dart';


class AddAttachmentsSection extends StatefulWidget {
  final List<String> attachments;
  final ValueChanged<List<String>> onChanged;
  final bool isDarkMode;

  const AddAttachmentsSection({
    super.key,
    required this.attachments,
    required this.onChanged,
    required this.isDarkMode,
  });

  @override
  State<AddAttachmentsSection> createState() => _AddAttachmentsSectionState();
}

class _AddAttachmentsSectionState extends State<AddAttachmentsSection> {
  List<String> get _attachments => widget.attachments;

  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      showDragHandle: false,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDarkMode = widget.isDarkMode;
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? TColors.cardColorDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? TColors.borderDark : TColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.insert_drive_file_outlined,
                      color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary),
                  title: Text(
                    'Choose from Files',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : TColors.backgroundDark,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await pickAnyFile();
                    if (file != null) {
                      setState(() {
                        widget.attachments.add(file.path.split('/').last);
                      });
                      widget.onChanged(List<String>.from(widget.attachments));
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined,
                      color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary),
                  title: Text(
                    'Take Photo',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : TColors.backgroundDark,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await pickImageFromGallery();
                    if (file != null) {
                      setState(() {
                        widget.attachments.add(file.path.split('/').last);
                      });
                      widget.onChanged(List<String>.from(widget.attachments));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: TColors.textTertiaryLight),
                  title: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDarkMode
                          ? TColors.textSecondaryDark
                          : TColors.textTertiaryLight,
                    ),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Column(
      children: [
        GestureDetector(
          onTap: _showAttachmentBottomSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? TColors.backgroundDarkAlt : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? TColors.borderDark : TColors.borderLight,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add Attachment',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : TColors.backgroundDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Column(
            children: _attachments.map((attachment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDarkMode
                          ? TColors.buttonPrimary
                          : TColors.buttonPrimaryLight)
                      .withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (isDarkMode
                            ? TColors.buttonPrimary
                            : TColors.buttonPrimaryLight)
                        .withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        attachment,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : TColors.backgroundDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.attachments.remove(attachment);
                        });
                        widget.onChanged(List<String>.from(widget.attachments));
                      },
                      child: Icon(
                        Icons.close_rounded,
                        color: isDarkMode
                            ? TColors.textSecondaryDark
                            : TColors.textTertiaryLight,
                        size: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
