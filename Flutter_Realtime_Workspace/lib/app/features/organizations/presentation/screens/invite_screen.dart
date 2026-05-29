import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/organization_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/organization_provider.dart';

/// Invite member form for the active organization.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});
  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  String _role = 'member';
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final org = ref.read(activeOrganizationProvider).valueOrNull;
    if (org == null) return;

    setState(() => _loading = true);
    await OrganizationUseCase.inviteMember(
      context: context,
      ref: ref,
      orgId: org.id,
      body: {'email': _emailCtrl.text.trim(), 'role': _role},
    );
    if (!mounted) return;
    setState(() => _loading = false);
    _emailCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Invite Member', showBack: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Illustration area
              Center(
                child: Container(
                  width: TResponsive.sp(context, 80),
                  height: TResponsive.sp(context, 80),
                  decoration: BoxDecoration(
                    color: TColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_add_alt_1_rounded,
                      size: TResponsive.sp(context, 36), color: TColors.primary),
                ),
              ),
              const SizedBox(height: TSizes.lg),
              Center(
                child: Text(
                  'Invite a team member',
                  style: TextStyle(
                    fontSize: TResponsive.sp(context, 18),
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(height: TSizes.xs),
              Center(
                child: Text(
                  'They\'ll receive an email invitation to join',
                  style: TextStyle(
                    fontSize: TResponsive.sp(context, 13),
                    color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(height: TSizes.xl),

              // Email
              TInput(
                controller: _emailCtrl,
                label: 'Email Address',
                hint: 'colleague@company.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: TSizes.spaceBetweenInputFields),

              // Role selector
              Text('Role', style: TextStyle(fontSize: TResponsive.sp(context, 13), fontWeight: FontWeight.w500, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
              const SizedBox(height: TSizes.sm),
              Wrap(
                spacing: TSizes.sm,
                children: ['member', 'manager', 'admin'].map((r) {
                  final selected = r == _role;
                  return ChoiceChip(
                    label: Text(r[0].toUpperCase() + r.substring(1)),
                    selected: selected,
                    onSelected: (_) => setState(() => _role = r),
                    selectedColor: TColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected ? TColors.primary : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: TResponsive.sp(context, 13),
                    ),
                    side: BorderSide(color: selected ? TColors.primary : (isDark ? TColors.darkBorder : TColors.lightBorder)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
                  );
                }).toList(),
              ),
              const SizedBox(height: TSizes.xl),

              TButton(
                text: 'Send Invitation',
                onPressed: _loading ? null : _submit,
                isLoading: _loading,
                prefixIcon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
