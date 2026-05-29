import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/feedback_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class SubmitFeedbackScreen extends ConsumerStatefulWidget {
  const SubmitFeedbackScreen({super.key});
  @override
  ConsumerState<SubmitFeedbackScreen> createState() => _State();
}

class _State extends ConsumerState<SubmitFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentCtrl = TextEditingController();
  String _type = 'general';
  int _rating = 0;
  bool _loading = false;

  @override
  void dispose() { _contentCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await FeedbackUseCase.submitFeedback(context: context, ref: ref, body: {
      'content': _contentCtrl.text.trim(), 'type': _type,
      if (_rating > 0) 'rating': _rating,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/feedback');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Submit Feedback', showBack: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.lg),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Type', style: TextStyle(fontSize: TResponsive.sp(context, 13), fontWeight: FontWeight.w500, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
          const SizedBox(height: TSizes.sm),
          Wrap(spacing: TSizes.sm, children: ['general', 'bug', 'feature', 'improvement', 'praise'].map((t) {
            final selected = t == _type;
            return ChoiceChip(
              label: Text(FeedbackUseCase.typeLabel(t)),
              selected: selected,
              onSelected: (_) => setState(() => _type = t),
              selectedColor: TColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: selected ? TColors.primary : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight), fontSize: TResponsive.sp(context, 12)),
              side: BorderSide(color: selected ? TColors.primary : (isDark ? TColors.darkBorder : TColors.lightBorder)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
            );
          }).toList()),
          const SizedBox(height: TSizes.lg),
          TInput(controller: _contentCtrl, label: 'Your Feedback', hint: 'Tell us what you think...', maxLines: 5, prefixIcon: Icons.edit_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
          const SizedBox(height: TSizes.lg),
          Text('Rating (optional)', style: TextStyle(fontSize: TResponsive.sp(context, 13), fontWeight: FontWeight.w500, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
          const SizedBox(height: TSizes.sm),
          Row(children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(i < _rating ? Icons.star_rounded : Icons.star_border_rounded, size: TResponsive.sp(context, 32), color: TColors.yellow),
            ),
          ))),
          const SizedBox(height: TSizes.xl),
          TButton(text: 'Submit', onPressed: _loading ? null : _submit, isLoading: _loading, prefixIcon: Icons.send_rounded),
        ])),
      ),
    );
  }
}
