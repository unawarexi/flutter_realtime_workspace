import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
// import 'package:timezone/timezone.dart' ;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

// Formatter class with static methods for various types of formatting
class TFormatter {
  TFormatter._(); // Private constructor to prevent instantiation

  // Formatter for Date
  static String formatDate(DateTime dateTime, {String format = 'dd-MM-yy'}) {
    final DateFormat dateFormat = DateFormat(format);
    return dateFormat.format(dateTime);
  }

  // Formatter for Currency
  static String formatCurrency(double amount,
      {String locale = 'en_US', String symbol = '\$'}) {
    final NumberFormat currencyFormat =
        NumberFormat.simpleCurrency(locale: locale, name: symbol);
    return currencyFormat.format(amount);
  }

  // Formatter for Phone Number
  static String formatPhoneNumber(String phoneNumber, {String locale = 'US'}) {
    final phoneNumberFormat = PhoneNumberFormat(locale: locale);
    return phoneNumberFormat.format(phoneNumber);
  }

  // Format Date for UI
  static String formatDateForUi(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format Time for UI
  static String formatTimeForUi(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  // Get all time zone names (requires timezone package)
  static List<String> getAllTimeZoneNames() {
    tzdata.initializeTimeZones();
    return tz.timeZoneDatabase.locations.keys.toList()..sort();
  }

  // Format timezone for display
  static String formatTimezone(String timezone) {
    try {
      final location = tz.getLocation(timezone);
      final offset = location.currentTimeZone.offset ~/ 3600;
      final sign = offset >= 0 ? '+' : '-';
      return '$timezone (UTC$sign${offset.abs().toString().padLeft(2, '0')}:00)';
    } catch (_) {
      return timezone;
    }
  }

  // Show date picker and return selected date
  static Future<DateTime?> pickDate(BuildContext context, DateTime initialDate) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  // Show time picker and return selected time
  static Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
  }
}

// Helper class for phone number formatting
class PhoneNumberFormat {
  final String locale;

  PhoneNumberFormat({required this.locale});

  // Basic formatting for phone numbers (example for US)
  String format(String phoneNumber) {
    if (locale == 'US') {
      final RegExp phoneRegExp = RegExp(r'(\d{3})(\d{3})(\d{4})');
      return phoneNumber.replaceAllMapped(
          phoneRegExp, (match) => '(${match[1]}) ${match[2]}-${match[3]}');
    }
    // Implement more formats for other locales as needed
    return phoneNumber;
  }
}
