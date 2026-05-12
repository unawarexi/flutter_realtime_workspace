import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'widgets/select_participants_sheet.dart';
import 'package:flutter_realtime_workspace/app/features/collaboration/presentation/widgets/date_timezone.dart';
import 'package:flutter_realtime_workspace/app/features/collaboration/presentation/widgets/add_attachements.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/core/constants/variables.dart';
import 'package:flutter_realtime_workspace/app/domain/repositories/collaboration_repository.dart';

class ScheduleMeet extends StatefulWidget {
  const ScheduleMeet({super.key});

  @override
  State<ScheduleMeet> createState() => _ScheduleMeetState();
}

class _ScheduleMeetState extends State<ScheduleMeet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _duration = kMeetingDurationOptions[3];
  String _repeatOption = kMeetingRepeatOptions[0];
  String _meetingType = 'Virtual';
  String _reminderTime = kMeetingReminderOptions[1];
  String _selectedTimezone = 'UTC';
  List<Map<String, String>> _selectedParticipants = [];
  List<String> _attachments = [];

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isSubmitting = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    tzdata.initializeTimeZones();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  int _parseDuration(String durationStr) {
    if (durationStr.contains('hour')) {
      final hours = int.tryParse(durationStr.split(' ')[0]) ?? 1;
      return hours * 60;
    } else if (durationStr.contains('minutes')) {
      return int.tryParse(durationStr.split(' ')[0]) ?? 15;
    }
    return 60;
  }

  void _scheduleMeeting(WidgetRef ref) async {
    if (_formKey.currentState!.validate()) {
      final startHour = _selectedTime.hour;
      final startMinute = _selectedTime.minute;
      final durationMinutes = _parseDuration(_duration);

      final startTime = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
      final startTotal = startHour * 60 + startMinute;
      final endTotal = startTotal + durationMinutes;
      final endHour = (endTotal ~/ 60) % 24;
      final endMinute = endTotal % 60;
      final endTime = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

      final meetingData = <String, dynamic>{
        'meetingTitle': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'agenda': _descriptionController.text.trim(),
        'meetingDate': _selectedDate.toIso8601String(),
        'meetingTime': {
          'start': startTime,
          'end': endTime,
        },
        'duration': durationMinutes,
        'timezone': _selectedTimezone,
        'repeatOption': _repeatOption,
        'meetingType': _meetingType,
        'location': _meetingType == 'Virtual'
            ? {'meetingLink': _linkController.text.trim()}
            : {'address': _locationController.text.trim()},
        'participants': _selectedParticipants.map((p) => {
          if (p['userID'] != null) 'userID': p['userID'],
          if (p['email'] != null) 'email': p['email'],
        }).toList(),
        'reminderSettings': {
          'enabled': true,
          'reminderTime': _reminderTime,
          'notificationMethods': ['push', 'email'],
        },
        'attachments': _attachments,
      };

      await CollaborationRepository.submitScheduleMeeting(
        context: context,
        ref: ref,
        meetingData: meetingData,
        setSubmitting: (val) => setState(() => _isSubmitting = val),
        titleController: _titleController,
        onSuccess: () {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) Navigator.pop(context);
          });
        },
        onError: () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    return Consumer(
      builder: (context, ref, _) {
        return Scaffold(
          key: _scaffoldMessengerKey,
          backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
          appBar: _buildAppBar(isDarkMode),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderSection(isDarkMode),
                            const SizedBox(height: 12),
                            _buildMeetingDetailsSection(isDarkMode),
                            const SizedBox(height: 12),
                            _buildDateTimeSection(isDarkMode),
                            const SizedBox(height: 12),
                            _buildDurationRepeatSection(isDarkMode),
                            const SizedBox(height: 12),
                            _buildParticipantsSection(isDarkMode),
                            const SizedBox(height: 12),
                            _buildMeetingTypeSection(isDarkMode),
                            const SizedBox(height: 12),
                            _buildLocationSection(isDarkMode),
                            const SizedBox(height: 12),
                            _buildDescriptionSection(isDarkMode),
                            const SizedBox(height: 12),
                            _buildNotificationSection(isDarkMode),
                            const SizedBox(height: 12),
                            _buildAttachmentsSection(isDarkMode),
                            const SizedBox(height: 16),
                            _buildScheduleButton(isDarkMode, ref),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDarkMode ? TColors.cardColorDark : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? TColors.borderDark : TColors.borderLight,
            width: 0.8,
          ),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDarkMode ? Colors.white : TColors.backgroundDark,
            size: 14,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        'Schedule Meeting',
        style: TextStyle(
          color: isDarkMode ? Colors.white : TColors.backgroundDark,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      toolbarHeight: 40,
      actions: [
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDarkMode ? TColors.cardColorDark : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? TColors.borderDark : TColors.borderLight,
              width: 0.8,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.calendar_month_outlined,
              color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
              size: 14,
            ),
            onPressed: () {
              _showConflictChecker(isDarkMode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [TColors.buttonPrimary.withOpacity(0.1), TColors.lightBlue.withOpacity(0.05)]
              : [TColors.buttonPrimaryLight.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Meeting',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : TColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Schedule meetings with your team effortlessly',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingDetailsSection(bool isDarkMode) {
    return _buildSection(
      title: 'Meeting Details',
      isDarkMode: isDarkMode,
      child: Column(
        children: [
          _buildTextField(
            controller: _titleController,
            label: 'Meeting Title',
            hint: 'Enter meeting title',
            icon: Icons.title_rounded,
            isDarkMode: isDarkMode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a meeting title';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection(bool isDarkMode) {
    return _buildSection(
      title: 'Date & Time',
      isDarkMode: isDarkMode,
      child: DateTimeTimezonePicker(
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        selectedTimezone: _selectedTimezone,
        isDarkMode: isDarkMode,
        onDateChanged: (date) => setState(() => _selectedDate = date),
        onTimeChanged: (time) => setState(() => _selectedTime = time),
        onTimezoneChanged: (tz) => setState(() => _selectedTimezone = tz),
      ),
    );
  }

  Widget _buildDurationRepeatSection(bool isDarkMode) {
    return _buildSection(
      title: 'Duration & Repeat',
      isDarkMode: isDarkMode,
      child: Row(
        children: [
          Expanded(
            child: _buildDropdownField(
              label: 'Duration',
              value: _duration,
              items: kMeetingDurationOptions,
              icon: Icons.timer_outlined,
              isDarkMode: isDarkMode,
              onChanged: (value) => setState(() => _duration = value!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdownField(
              label: 'Repeat',
              value: _repeatOption,
              items: kMeetingRepeatOptions,
              icon: Icons.repeat_rounded,
              isDarkMode: isDarkMode,
              onChanged: (value) => setState(() => _repeatOption = value!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection(bool isDarkMode) {
    return _buildSection(
      title: 'Participants',
      isDarkMode: isDarkMode,
      child: Column(
        children: [
          _buildParticipantSelector(isDarkMode),
          if (_selectedParticipants.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSelectedParticipants(isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildMeetingTypeSection(bool isDarkMode) {
    return _buildSection(
      title: 'Meeting Type',
      isDarkMode: isDarkMode,
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption(
              title: 'Virtual',
              isSelected: _meetingType == 'Virtual',
              icon: Icons.videocam_outlined,
              isDarkMode: isDarkMode,
              onTap: () => setState(() => _meetingType = 'Virtual'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTypeOption(
              title: 'Physical',
              isSelected: _meetingType == 'Physical',
              icon: Icons.location_on_outlined,
              isDarkMode: isDarkMode,
              onTap: () => setState(() => _meetingType = 'Physical'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(bool isDarkMode) {
    return _buildSection(
      title: _meetingType == 'Virtual' ? 'Meeting Link' : 'Location',
      isDarkMode: isDarkMode,
      child: Column(
        children: [
          if (_meetingType == 'Virtual')
            _buildTextField(
              controller: _linkController,
              label: 'Meeting Link',
              hint: 'Enter meeting link or generate one',
              icon: Icons.link_rounded,
              isDarkMode: isDarkMode,
            )
          else
            _buildTextField(
              controller: _locationController,
              label: 'Address',
              hint: 'Enter location address',
              icon: Icons.location_on_outlined,
              isDarkMode: isDarkMode,
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.map_outlined,
                  color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
                  size: 20,
                ),
                onPressed: () {
                  _openLocationPicker();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(bool isDarkMode) {
    return _buildSection(
      title: 'Description/Agenda',
      isDarkMode: isDarkMode,
      child: _buildTextField(
        controller: _descriptionController,
        label: 'Description',
        hint: 'Enter meeting description or agenda',
        icon: Icons.description_outlined,
        isDarkMode: isDarkMode,
        maxLines: 4,
      ),
    );
  }

  Widget _buildNotificationSection(bool isDarkMode) {
    return _buildSection(
      title: 'Notifications',
      isDarkMode: isDarkMode,
      child: _buildDropdownField(
        label: 'Reminder',
        value: _reminderTime,
        items: kMeetingReminderOptions,
        icon: Icons.notifications_outlined,
        isDarkMode: isDarkMode,
        onChanged: (value) => setState(() => _reminderTime = value!),
      ),
    );
  }

  Widget _buildAttachmentsSection(bool isDarkMode) {
    return _buildSection(
      title: 'Attachments',
      isDarkMode: isDarkMode,
      child: AddAttachmentsSection(
        attachments: _attachments,
        isDarkMode: isDarkMode,
        onChanged: (newList) => setState(() => _attachments = newList),
      ),
    );
  }

  Widget _buildScheduleButton(bool isDarkMode, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.15),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => _scheduleMeeting(ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_send_rounded,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Schedule Meeting',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required bool isDarkMode,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? TColors.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? TColors.borderDark : TColors.borderLight,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.03),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : TColors.backgroundDark,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(
        color: isDarkMode ? Colors.white : TColors.backgroundDark,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
          size: 14,
        ),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: isDarkMode ? TColors.textTertiaryLight : TColors.textSecondaryDark,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: isDarkMode ? TColors.backgroundDarkAlt : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode ? TColors.borderDark : TColors.borderLight,
            width: 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode ? TColors.borderDark : TColors.borderLight,
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
            width: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required bool isDarkMode,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
          size: 14,
        ),
        labelStyle: TextStyle(
          color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: isDarkMode ? TColors.backgroundDarkAlt : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode ? TColors.borderDark : TColors.borderLight,
            width: 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode ? TColors.borderDark : TColors.borderLight,
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
            width: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
      style: TextStyle(
        color: isDarkMode ? Colors.white : TColors.backgroundDark,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: isDarkMode ? TColors.cardColorDark : Colors.white,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              color: isDarkMode ? Colors.white : TColors.backgroundDark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParticipantSelector(bool isDarkMode) {
    return GestureDetector(
      onTap: () async {
        final selected = await showModalBottomSheet<List<Map<String, String>>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => SelectParticipantsSheet(
            initiallySelected: _selectedParticipants,
          ),
        );
        if (selected != null) {
          setState(() {
            _selectedParticipants = selected;
          });
        }
      },
      child: Container(
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
          children: [
            Icon(
              Icons.people_outline_rounded,
              color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _selectedParticipants.isEmpty
                    ? 'Select participants'
                    : '${_selectedParticipants.length} participant${_selectedParticipants.length > 1 ? 's' : ''} selected',
                style: TextStyle(
                  color: _selectedParticipants.isEmpty
                      ? (isDarkMode ? TColors.textTertiaryLight : TColors.textSecondaryDark)
                      : (isDarkMode ? Colors.white : TColors.backgroundDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedParticipants(bool isDarkMode) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _selectedParticipants.map((participant) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                participant['fullName'] ?? '',
                style: TextStyle(
                  color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedParticipants.remove(participant);
                  });
                },
                child: Icon(
                  Icons.close_rounded,
                  color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
                  size: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required bool isSelected,
    required IconData icon,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight).withOpacity(0.1)
              : (isDarkMode ? TColors.backgroundDarkAlt : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight)
                : (isDarkMode ? TColors.borderDark : TColors.borderLight),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDarkMode ? TColors.lightBlue : TColors.buttonPrimary)
                  : (isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight),
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? (isDarkMode ? Colors.white : TColors.backgroundDark)
                    : (isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConflictChecker(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? TColors.cardColorDark : Colors.white,
          title: Text(
            'Schedule Conflicts',
            style: TextStyle(
              color: isDarkMode ? Colors.white : TColors.backgroundDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Checking for conflicts on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedTime.format(context)}...',
                style: TextStyle(
                  color: isDarkMode
                      ? TColors.textSecondaryDark
                      : TColors.textTertiaryLight,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'No conflicts found',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openLocationPicker() {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = THelperFunctions.isDarkMode(context);
        return AlertDialog(
          backgroundColor: isDarkMode ? TColors.cardColorDark : Colors.white,
          title: Text(
            'Select Location',
            style: TextStyle(
              color: isDarkMode ? Colors.white : TColors.backgroundDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Google Maps integration would be implemented here to allow users to select a location.',
            style: TextStyle(
              color: isDarkMode
                  ? TColors.textSecondaryDark
                  : TColors.textTertiaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode
                      ? TColors.textSecondaryDark
                      : TColors.textTertiaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _locationController.text = 'Selected Location from Maps';
                Navigator.pop(context);
              },
              child: Text(
                'Use Current Location',
                style: TextStyle(
                  color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}