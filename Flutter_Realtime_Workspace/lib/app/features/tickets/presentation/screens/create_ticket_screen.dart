import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/tickets/usecases/ticket_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});
  @override
  ConsumerState<CreateTicketScreen> createState() => _State();
}

class _State extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';
  bool _loading = false;

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ticket = await TicketUseCase.createTicket(
      context: context, ref: ref,
      body: {'title': _titleCtrl.text.trim(), 'description': _descCtrl.text.trim(), 'priority': _priority},
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ticket != null) context.go('/tickets/${ticket.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Create Ticket', showBack: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TInput(controller: _titleCtrl, label: 'Title', hint: 'Describe the issue', prefixIcon: Icons.confirmation_number_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: TSizes.spaceBetweenInputFields),
              TInput(controller: _descCtrl, label: 'Description', hint: 'Provide details...', maxLines: 4, prefixIcon: Icons.description_outlined),
              const SizedBox(height: TSizes.lg),
              Text('Priority', style: TextStyle(fontSize: TResponsive.sp(context, 13), fontWeight: FontWeight.w500, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
              const SizedBox(height: TSizes.sm),
              Wrap(
                spacing: TSizes.sm,
                children: TicketUseCase.priorityOrder.map((p) {
                  final selected = p == _priority;
                  final color = _priorityColor(p);
                  return ChoiceChip(
                    label: Text(TicketUseCase.priorityLabel(p)),
                    selected: selected,
                    onSelected: (_) => setState(() => _priority = p),
                    selectedColor: color.withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: selected ? color : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight), fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: TResponsive.sp(context, 12)),
                    side: BorderSide(color: selected ? color : (isDark ? TColors.darkBorder : TColors.lightBorder)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
                  );
                }).toList(),
              ),
              const SizedBox(height: TSizes.xl),
              TButton(text: 'Create Ticket', onPressed: _loading ? null : _submit, isLoading: _loading, prefixIcon: Icons.add_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String p) => switch (p) { 'critical' => TColors.error, 'high' => TColors.warning, 'medium' => TColors.info, _ => TColors.neutralGray };
}
