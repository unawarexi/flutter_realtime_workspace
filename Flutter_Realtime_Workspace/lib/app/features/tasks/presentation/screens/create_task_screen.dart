import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/utils/formatters.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';
import 'package:flutter_realtime_workspace/app/features/tasks/usecases/task_usecase.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  /// Optional pre-filled project ID.
  final String? projectId;
  const CreateTaskScreen({super.key, this.projectId});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _status = 'todo';
  String _priority = 'medium';
  DateTime? _dueDate;
  String? _selectedProjectId;
  bool _isLoading = false;
  final List<String> _labels = [];
  final _labelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.projectId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  String get _workspaceId =>
      ref.read(activeWorkspaceProvider)?.id ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final bg = isDark ? TColors.backgroundDark : TColors.backgroundLight;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final textSec =
        isDark ? TColors.textDarkSecondary : TColors.textLightSecondary;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? TColors.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Create Task',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton(
                    onPressed: _submit,
                    child: Text('Create',
                        style: TextStyle(
                            color: TColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            _FieldLabel(text: 'Title *', isDark: isDark),
            const SizedBox(height: 8),
            _InputField(
              controller: _titleCtrl,
              hint: 'Enter task title',
              isDark: isDark,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),
            // Description
            _FieldLabel(text: 'Description', isDark: isDark),
            const SizedBox(height: 8),
            _InputField(
              controller: _descCtrl,
              hint: 'Add a description...',
              isDark: isDark,
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            // Status + Priority row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(text: 'Status', isDark: isDark),
                      const SizedBox(height: 8),
                      _DropdownField<String>(
                        value: _status,
                        isDark: isDark,
                        items: const {
                          'backlog': 'Backlog',
                          'todo': 'To Do',
                          'in_progress': 'In Progress',
                          'in_review': 'In Review',
                          'done': 'Done',
                          'blocked': 'Blocked',
                        },
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(text: 'Priority', isDark: isDark),
                      const SizedBox(height: 8),
                      _DropdownField<String>(
                        value: _priority,
                        isDark: isDark,
                        items: const {
                          'lowest': 'Lowest',
                          'low': 'Low',
                          'medium': 'Medium',
                          'high': 'High',
                          'critical': 'Critical',
                        },
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Due Date
            _FieldLabel(text: 'Due Date', isDark: isDark),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? TColors.darkElevated : TColors.lightElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.calendar_1,
                        size: 18,
                        color: isDark
                            ? TColors.textDarkSecondary
                            : TColors.textLightSecondary),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? TFormatter.formatDate(_dueDate!)
                          : 'Select due date',
                      style: TextStyle(
                          fontSize: 14,
                          color: _dueDate != null
                              ? textPrimary
                              : textSec),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(Icons.close, size: 16, color: textSec),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Labels
            _FieldLabel(text: 'Labels', isDark: isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _InputField(
                    controller: _labelCtrl,
                    hint: 'Add label and press enter',
                    isDark: isDark,
                    onSubmitted: (_) => _addLabel(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addLabel,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: TColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (_labels.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _labels
                    .map((l) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: TColors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: TColors.purple.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: TColors.purple,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _labels.remove(l)),
                                child: Icon(Icons.close,
                                    size: 14, color: TColors.purple),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addLabel() {
    final text = _labelCtrl.text.trim();
    if (text.isNotEmpty && !_labels.contains(text)) {
      setState(() => _labels.add(text));
      _labelCtrl.clear();
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await TaskUseCase.createTask(context: context, ref: ref, body: {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'status': _status,
        'priority': _priority,
        if (_dueDate != null) 'dueDate': _dueDate!.toIso8601String(),
        if (_selectedProjectId != null) 'projectId': _selectedProjectId,
        if (_workspaceId.isNotEmpty) 'workspaceId': _workspaceId,
        if (_labels.isNotEmpty) 'labels': _labels,
      });
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── Shared form widgets ─────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? TColors.textDarkSecondary : TColors.textLightSecondary));
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.maxLines = 1,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? TColors.darkElevated : TColors.lightElevated;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(
          fontSize: 14,
          color: isDark ? TColors.textDark : TColors.textLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? TColors.textDarkTertiary : TColors.textLightTertiary),
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final bool isDark;
  final Map<T, String> items;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.value,
    required this.isDark,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? TColors.darkElevated : TColors.lightElevated;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? TColors.darkSurface : Colors.white,
          style: TextStyle(
              fontSize: 13,
              color: isDark ? TColors.textDark : TColors.textLight),
          onChanged: onChanged,
          items: items.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? TColors.textDark
                                : TColors.textLight)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
