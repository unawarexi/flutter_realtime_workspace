import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/workflow_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class CreateWorkflowScreen extends ConsumerStatefulWidget {
  const CreateWorkflowScreen({super.key});
  @override
  ConsumerState<CreateWorkflowScreen> createState() => _State();
}

class _State extends ConsumerState<CreateWorkflowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _triggerType = 'manual';
  bool _loading = false;

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final wf = await WorkflowUseCase.createWorkflow(context: context, ref: ref, body: {
      'name': _nameCtrl.text.trim(), 'description': _descCtrl.text.trim(),
      'trigger': {'type': _triggerType},
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (wf != null) context.go('/workflows/${wf.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Create Workflow', showBack: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.lg),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TInput(controller: _nameCtrl, label: 'Workflow Name', hint: 'e.g. Auto-assign tasks', prefixIcon: Icons.account_tree_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
          const SizedBox(height: TSizes.spaceBetweenInputFields),
          TInput(controller: _descCtrl, label: 'Description', hint: 'What does this workflow do?', maxLines: 3, prefixIcon: Icons.description_outlined),
          const SizedBox(height: TSizes.lg),
          Text('Trigger Type', style: TextStyle(fontSize: TResponsive.sp(context, 13), fontWeight: FontWeight.w500, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
          const SizedBox(height: TSizes.sm),
          Wrap(spacing: TSizes.sm, children: ['manual', 'schedule', 'webhook', 'event'].map((t) {
            final selected = t == _triggerType;
            return ChoiceChip(
              label: Text(WorkflowUseCase.triggerLabel(t)),
              selected: selected,
              onSelected: (_) => setState(() => _triggerType = t),
              selectedColor: TColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: selected ? TColors.primary : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight), fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: TResponsive.sp(context, 12)),
              side: BorderSide(color: selected ? TColors.primary : (isDark ? TColors.darkBorder : TColors.lightBorder)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
            );
          }).toList()),
          const SizedBox(height: TSizes.xl),
          TButton(text: 'Create Workflow', onPressed: _loading ? null : _submit, isLoading: _loading, prefixIcon: Icons.add_rounded),
        ])),
      ),
    );
  }
}
