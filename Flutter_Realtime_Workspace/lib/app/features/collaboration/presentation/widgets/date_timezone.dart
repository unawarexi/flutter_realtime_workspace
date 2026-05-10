import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/utils/formatters.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';

class DateTimeTimezonePicker extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String selectedTimezone;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<String> onTimezoneChanged;
  final bool isDarkMode;

  const DateTimeTimezonePicker({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedTimezone,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onTimezoneChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final timezones = TFormatter.getAllTimeZoneNames();
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 340;
        final double tileWidth = isWide ? (constraints.maxWidth - 16) / 3 : constraints.maxWidth;

        return isWide
            ? Row(
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _buildDateTimeTile(
                      title: 'Date',
                      value: TFormatter.formatDateForUi(selectedDate),
                      icon: Icons.calendar_today_outlined,
                      isDarkMode: isDarkMode,
                      onTap: () async {
                        final picked = await _showThemedDatePicker(context, selectedDate, isDarkMode);
                        if (picked != null && picked != selectedDate) {
                          onDateChanged(picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: tileWidth,
                    child: _buildDateTimeTile(
                      title: 'Time',
                      value: TFormatter.formatTimeForUi(selectedTime),
                      icon: Icons.access_time_rounded,
                      isDarkMode: isDarkMode,
                      onTap: () async {
                        final picked = await _showThemedTimePicker(context, selectedTime, isDarkMode);
                        if (picked != null && picked != selectedTime) {
                          onTimeChanged(picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: tileWidth,
                    child: _buildDateTimeTile(
                      title: 'Timezone',
                      value: TFormatter.formatTimezone(selectedTimezone),
                      icon: Icons.public,
                      isDarkMode: isDarkMode,
                      onTap: () async {
                        final tz = await _showTimezonePicker(context, timezones, selectedTimezone, isDarkMode);
                        if (tz != null && tz != selectedTimezone) {
                          onTimezoneChanged(tz);
                        }
                      },
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDateTimeTile(
                    title: 'Date',
                    value: TFormatter.formatDateForUi(selectedDate),
                    icon: Icons.calendar_today_outlined,
                    isDarkMode: isDarkMode,
                    onTap: () async {
                      final picked = await _showThemedDatePicker(context, selectedDate, isDarkMode);
                      if (picked != null && picked != selectedDate) {
                        onDateChanged(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDateTimeTile(
                    title: 'Time',
                    value: TFormatter.formatTimeForUi(selectedTime),
                    icon: Icons.access_time_rounded,
                    isDarkMode: isDarkMode,
                    onTap: () async {
                      final picked = await _showThemedTimePicker(context, selectedTime, isDarkMode);
                      if (picked != null && picked != selectedTime) {
                        onTimeChanged(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDateTimeTile(
                    title: 'Timezone',
                    value: TFormatter.formatTimezone(selectedTimezone),
                    icon: Icons.public,
                    isDarkMode: isDarkMode,
                    onTap: () async {
                      final tz = await _showTimezonePicker(context, timezones, selectedTimezone, isDarkMode);
                      if (tz != null && tz != selectedTimezone) {
                        onTimezoneChanged(tz);
                      }
                    },
                  ),
                ],
              );
      },
    );
  }

  // Themed Date Picker
  Future<DateTime?> _showThemedDatePicker(BuildContext context, DateTime initialDate, bool isDarkMode) {
    final theme = Theme.of(context);
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.light(
              primary: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
              onPrimary: Colors.white,
              surface: isDarkMode ? TColors.cardColorDark : Colors.white,
              onSurface: isDarkMode ? Colors.white : TColors.backgroundDark,
              background: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
            ).copyWith(
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
            dialogBackgroundColor: isDarkMode ? TColors.cardColorDark : Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  // Themed Time Picker
  Future<TimeOfDay?> _showThemedTimePicker(BuildContext context, TimeOfDay initialTime, bool isDarkMode) {
    final theme = Theme.of(context);
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.light(
              primary: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
              onPrimary: Colors.white,
              surface: isDarkMode ? TColors.cardColorDark : Colors.white,
              onSurface: isDarkMode ? Colors.white : TColors.backgroundDark,
              background: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
            ).copyWith(
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
            dialogBackgroundColor: isDarkMode ? TColors.cardColorDark : Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  // Timezone Picker as Modal Bottom Sheet
  Future<String?> _showTimezonePicker(
    BuildContext context,
    List<String> timezones,
    String selectedTimezone,
    bool isDarkMode,
  ) async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDarkMode ? TColors.cardColorDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Select Timezone',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : TColors.backgroundDark,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: timezones.length,
                  separatorBuilder: (_, __) => Divider(
                    color: isDarkMode ? TColors.borderDark : TColors.borderLight,
                    height: 1,
                  ),
                  itemBuilder: (context, idx) {
                    final tz = timezones[idx];
                    return ListTile(
                      title: Text(
                        TFormatter.formatTimezone(tz),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : TColors.backgroundDark,
                          fontSize: 12,
                        ),
                      ),
                      trailing: tz == selectedTimezone
                          ? Icon(Icons.check, color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary, size: 18)
                          : null,
                      onTap: () => Navigator.pop(context, tz),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateTimeTile({
    required String title,
    required String value,
    required IconData icon,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isDarkMode ? TColors.backgroundDarkAlt : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? TColors.borderDark : TColors.borderLight,
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : TColors.backgroundDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
