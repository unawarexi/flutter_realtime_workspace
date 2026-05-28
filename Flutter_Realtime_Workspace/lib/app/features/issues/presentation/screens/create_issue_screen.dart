import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/utils/formatters.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';
import 'package:flutter_realtime_workspace/app/features/issues/usecases/issue_usecase.dart';

class CreateIssueScreen extends ConsumerStatefulWidget {
  final String? projectId;
  const CreateIssueScreen({super.key, this.projectId});

  @override
  ConsumerState<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends ConsumerState<CreateIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController();
  final _expectedCtrl = TextEditingController();
  final _actualCtrl = TextEditingController();
  final _envCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();

  String _type = 'bug';
  String _priority = 'medium';
  String _severity = 'minor';
  String _status = 'open';
  DateTime? _dueDate;
  bool _isLoading = false;
  final List<String> _labels = [];

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _descCtrl,
      _stepsCtrl,
      _expectedCtrl,
      _actualCtrl,
      _envCtrl,
      _labelCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _workspaceId =>
      ref.read(activeWorkspaceProvider)?.id ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final bg = isDark ? TColors.backgroundDark : TColors.backgroundLight;
    final textPrimary = isDark ? TColors.textDark : TColors.textLight;
    final surface = isDark ? TColors.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Create Issue',
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
            _label('Title *', isDark),
            const SizedBox(height: 8),
            _textField(_titleCtrl, 'Enter issue title', isDark,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title required' : null),
            const SizedBox(height: 20),
            _label('Description', isDark),
            const SizedBox(height: 8),
            _textField(_descCtrl, 'Describe the issue...', isDark,
                maxLines: 3),
            const SizedBox(height: 20),
            // Type + Severity row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Type', isDark),
                      const SizedBox(height: 8),
                      _dropdown<String>(
                        value: _type,
                        isDark: isDark,
                        items: const {
                          'bug': 'Bug',
                          'feature': 'Feature',
                          'improvement': 'Improvement',
                          'task': 'Task',
                          'epic': 'Epic',
                          'story': 'Story',
                        },
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Severity', isDark),
                      const SizedBox(height: 8),
                      _dropdown<String>(
                        value: _severity,
                        isDark: isDark,
                        items: const {
                          'trivial': 'Trivial',
                          'minor': 'Minor',
                          'major': 'Major',
                          'blocker': 'Blocker',
                        },
                        onChanged: (v) => setState(() => _severity = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Priority row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Priority', isDark),
                      const SizedBox(height: 8),
                      _dropdown<String>(
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Status', isDark),
                      const SizedBox(height: 8),
                      _dropdown<String>(
                        value: _status,
                        isDark: isDark,
                        items: const {
                          'open': 'Open',
                          'in_progress': 'In Progress',
                        },
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Due date
            _label('Due Date', isDark),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? TColors.darkElevated
                      : TColors.lightElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark
                          ? TColors.darkBorder
                          : TColors.lightBorder),
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
                              ? (isDark
                                  ? TColors.textDark
                                  : TColors.textLight)
                              : (isDark
                                  ? TColors.textDarkSecondary
                                  : TColors.textLightSecondary)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Steps to reproduce (for bug type)
            if (_type == 'bug') ...[
              _label('Steps to Reproduce', isDark),
              const SizedBox(height: 8),
              _textField(
                  _stepsCtrl, '1. Go to...\n2. Click on...\n3. See error',
                  isDark,
                  maxLines: 4),
              const SizedBox(height: 20),
              _label('Expected Behavior', isDark),
              const SizedBox(height: 8),
              _textField(
                  _expectedCtrl, 'What should happen?', isDark,
                  maxLines: 3),
              const SizedBox(height: 20),
              _label('Actual Behavior', isDark),
              const SizedBox(height: 8),
              _textField(
                  _actualCtrl, 'What actually happens?', isDark,
                  maxLines: 3),
              const SizedBox(height: 20),
              _label('Environment', isDark),
              const SizedBox(height: 8),
              _textField(
                  _envCtrl, 'OS, browser, version, etc.', isDark),
              const SizedBox(height: 20),
            ],
            // Labels
            _label('Labels', isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _textField(
                        _labelCtrl, 'Add label...', isDark,
                        onSubmitted: (_) => _addLabel())),
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
            const SizedBox(height: 40),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await IssueUseCase.createIssue(ref, {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'type': _type,
        'priority': _priority,
        'severity': _severity,
        'status': _status,
        if (_workspaceId.isNotEmpty) 'workspaceId': _workspaceId,
        if (widget.projectId != null) 'projectId': widget.projectId,
        if (_dueDate != null) 'dueDate': _dueDate!.toIso8601String(),
        if (_labels.isNotEmpty) 'labels': _labels,
        if (_type == 'bug' && _stepsCtrl.text.isNotEmpty)
          'stepsToReproduce': _stepsCtrl.text.trim(),
        if (_type == 'bug' && _expectedCtrl.text.isNotEmpty)
          'expectedBehavior': _expectedCtrl.text.trim(),
        if (_type == 'bug' && _actualCtrl.text.isNotEmpty)
          'actualBehavior': _actualCtrl.text.trim(),
        if (_type == 'bug' && _envCtrl.text.isNotEmpty)
          'environment': _envCtrl.text.trim(),
      });
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create issue: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _label(String text, bool isDark) => Text(text,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark
              ? TColors.textDarkSecondary
              : TColors.textLightSecondary));

  Widget _textField(
    TextEditingController ctrl,
    String hint,
    bool isDark, {
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    final bg = isDark ? TColors.darkElevated : TColors.lightElevated;
    final border = isDark ? TColors.darkBorder : TColors.lightBorder;
    return TextFormField(
      controller: ctrl,
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
            color: isDark
                ? TColors.textDarkTertiary
                : TColors.textLightTertiary),
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

  Widget _dropdown<T>({
    required T value,
    required bool isDark,
    required Map<T, String> items,
    required void Function(T?) onChanged,
  }) {
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
