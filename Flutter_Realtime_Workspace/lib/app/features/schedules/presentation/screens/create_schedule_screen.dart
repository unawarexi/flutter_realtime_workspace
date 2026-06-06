import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/schedule_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class CreateScheduleScreen extends ConsumerStatefulWidget {
  const CreateScheduleScreen({super.key});
  @override
  ConsumerState<CreateScheduleScreen> createState() => _State();
}

class _State extends ConsumerState<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;
  bool _loading = false;

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() { if (isStart) {
      _startTime = dt;
    } else {
      _endTime = dt;
    } });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null) return;
    setState(() => _loading = true);
    final s = await ScheduleUseCase.createSchedule(context: context, ref: ref, body: {
      'title': _titleCtrl.text.trim(), 'description': _descCtrl.text.trim(),
      'startTime': _startTime!.toIso8601String(),
      if (_endTime != null) 'endTime': _endTime!.toIso8601String(),
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (s != null) context.go('/schedule');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Create Schedule', showBack: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.lg),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TInput(controller: _titleCtrl, label: 'Title', hint: 'Event title', prefixIcon: Icons.event_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
          const SizedBox(height: TSizes.spaceBetweenInputFields),
          TInput(controller: _descCtrl, label: 'Description', hint: 'Details...', maxLines: 3, prefixIcon: Icons.description_outlined),
          const SizedBox(height: TSizes.lg),
          _dateField(context, 'Start Time *', _startTime, isDark, () => _pickDate(true)),
          const SizedBox(height: TSizes.sm),
          _dateField(context, 'End Time', _endTime, isDark, () => _pickDate(false)),
          const SizedBox(height: TSizes.xl),
          TButton(text: 'Create Event', onPressed: (_loading || _startTime == null) ? null : _submit, isLoading: _loading, prefixIcon: Icons.add_rounded),
        ])),
      ),
    );
  }

  Widget _dateField(BuildContext context, String label, DateTime? value, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkCard.withValues(alpha: 0.6) : TColors.lightElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 18, color: isDark ? TColors.darkMuted : TColors.lightMuted),
          const SizedBox(width: TSizes.sm),
          Text(
            value != null ? '${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}' : label,
            style: TextStyle(fontSize: 14, color: value != null ? (isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight) : (isDark ? TColors.darkMuted : TColors.lightMuted)),
          ),
        ]),
      ),
    );
  }
}
