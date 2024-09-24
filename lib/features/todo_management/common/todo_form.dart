import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/errors/text_field_errors.dart';
import 'package:flutter_realtime_workspace/features/todo_management/provider/date_time_provider.dart';
import 'package:flutter_realtime_workspace/features/todo_management/provider/radioProvider.dart';
import 'package:flutter_realtime_workspace/features/todo_management/widgets/date_time_widget.dart';
import 'package:flutter_realtime_workspace/features/todo_management/widgets/radio_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Make sure to import for date formatting
import 'package:flutter/cupertino.dart';

class AddNewTask extends ConsumerWidget {
  const AddNewTask({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController teamController = TextEditingController();
    final TextEditingController projectLeadController = TextEditingController();

    // Error tracking
    bool showError = false;

    // Providers for date and time
    String dateProv = ref.watch(dateProvider);
    String timeProv = ref.watch(timeProvider);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: double.infinity,
              child: Text(
                "New Task Todo",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(thickness: 1.2, color: Colors.grey.shade200),
            const SizedBox(height: 12),

            // Title Task
            const Text("Title Task"),
            const SizedBox(height: 6),
            TextFieldError(
              hintText: "Add Task Name",
              maxLine: 1,
              controller: titleController,
              showError: showError && titleController.text.isEmpty,
            ),

            // Description
            const Text("Description"),
            const SizedBox(height: 6),
            TextFieldError(
              hintText: "Add Description",
              maxLine: 4,
              controller: descriptionController,
              showError: showError && descriptionController.text.isEmpty,
            ),

            // Team Assignment
            const Text("Assign Team"),
            const SizedBox(height: 6),
            TextFieldError(
              hintText: "Team Name",
              maxLine: 1,
              controller: teamController,
              showError: showError && teamController.text.isEmpty,
            ),

            // Project Lead
            const Text("Project Lead"),
            const SizedBox(height: 6),
            TextFieldError(
              hintText: "Project Lead Name",
              maxLine: 1,
              controller: projectLeadController,
              showError: showError && projectLeadController.text.isEmpty,
            ),

            const SizedBox(height: 12),

            // Radio Buttons
            Row(
              children: [
                Expanded(
                  child: RadioWidget(
                    categColor: Colors.green,
                    titleRadio: "LNR",
                    valueInput: 1,
                    onChangedValue: () =>
                        ref.read(radioProvider.notifier).update((state) => 1),
                  ),
                ),
                Expanded(
                  child: RadioWidget(
                    categColor: Colors.blue.shade700,
                    titleRadio: "WRK",
                    valueInput: 2,
                    onChangedValue: () =>
                        ref.read(radioProvider.notifier).update((state) => 2),
                  ),
                ),
                Expanded(
                  child: RadioWidget(
                    categColor: Colors.amberAccent.shade700,
                    titleRadio: "GEN",
                    valueInput: 3,
                    onChangedValue: () =>
                        ref.read(radioProvider.notifier).update((state) => 3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date and Time Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DateTimeWidget(
                  titleText: "Date",
                  valueText: dateProv,
                  iconSection: CupertinoIcons.calendar,
                  onTap: () async {
                    final getValue = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2021),
                      lastDate: DateTime(2029),
                    );
                    if (getValue != null) {
                      final format = DateFormat.yMd();
                      ref
                          .read(dateProvider.notifier)
                          .update((state) => format.format(getValue));
                    }
                  },
                ),
                const SizedBox(width: 22),
                DateTimeWidget(
                  titleText: "Time",
                  valueText: timeProv,
                  iconSection: CupertinoIcons.clock,
                  onTap: () async {
                    final getTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (getTime != null) {
                      ref
                          .read(timeProvider.notifier)
                          .update((state) => getTime.format(context));
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Attachment Options Button
            ElevatedButton(
              onPressed: () => _showAttachmentOptions(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Add Attachments"),
            ),

            const SizedBox(height: 12),

            // Button Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Colors.blue.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // Set the error flag
                      showError = true;

                      // Check for empty fields and handle accordingly
                      if (titleController.text.isNotEmpty &&
                          descriptionController.text.isNotEmpty &&
                          teamController.text.isNotEmpty &&
                          projectLeadController.text.isNotEmpty) {
                        // Handle task creation logic here
                      } else {
                        // If any field is empty, trigger validation error
                      }
                    },
                    child: const Text("Create"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAttachmentOption(Icons.camera_alt, "Take Photo", context),
              _buildAttachmentOption(Icons.videocam, "Record Video", context),
              _buildAttachmentOption(
                  Icons.insert_drive_file, "Choose File", context),
              _buildAttachmentOption(
                  Icons.screen_share, "Record Screen", context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
      IconData icon, String label, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      onTap: () {
        // Handle attachment action here
        Navigator.pop(context);
      },
    );
  }
}
