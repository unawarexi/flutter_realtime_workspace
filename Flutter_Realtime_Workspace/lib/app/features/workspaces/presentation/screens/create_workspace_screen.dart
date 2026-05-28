import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/workspaces/usecases/workspace_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

/// Form screen for creating a new workspace.
class CreateWorkspaceScreen extends ConsumerStatefulWidget {
  const CreateWorkspaceScreen({super.key});

  @override
  ConsumerState<CreateWorkspaceScreen> createState() =>
      _CreateWorkspaceScreenState();
}

class _CreateWorkspaceScreenState extends ConsumerState<CreateWorkspaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _visibility = 'private';
  String _template = 'kanban';
  bool _allowGuests = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await WorkspaceUseCase.createWorkspace(
      context: context,
      ref: ref,
      body: {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'settings': {
          'visibility': _visibility,
          'defaultProjectTemplate': _template,
          'allowGuests': _allowGuests,
        },
      },
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) context.go('/workspaces');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor:
          isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Create Workspace', showBack: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name ──
              TInput(
                controller: _nameCtrl,
                label: 'Workspace Name',
                hint: 'e.g. Engineering, Marketing',
                prefixIcon: Icons.workspaces_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: TSizes.spaceBetweenInputFields),

              // ── Description ──
              TInput(
                controller: _descCtrl,
                label: 'Description',
                hint: 'What is this workspace for?',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: TSizes.lg),

              // ── Section: Settings ──
              Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: TResponsive.sp(context, 11),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: isDark
                      ? TColors.textSecondaryDark
                      : TColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: TSizes.sm),

              // Visibility
              _OptionTile(
                icon: Icons.visibility_outlined,
                title: 'Visibility',
                value: _visibility,
                options: const {'private': 'Private', 'public': 'Public', 'invite_only': 'Invite Only'},
                onChanged: (v) => setState(() => _visibility = v),
              ),
              const SizedBox(height: TSizes.sm),

              // Template
              _OptionTile(
                icon: Icons.dashboard_customize_outlined,
                title: 'Default Template',
                value: _template,
                options: const {'kanban': 'Kanban', 'scrum': 'Scrum', 'blank': 'Blank'},
                onChanged: (v) => setState(() => _template = v),
              ),
              const SizedBox(height: TSizes.md),

              // Allow guests
              SwitchListTile.adaptive(
                value: _allowGuests,
                onChanged: (v) => setState(() => _allowGuests = v),
                title: Text(
                  'Allow Guests',
                  style: TextStyle(
                    fontSize: TResponsive.sp(context, 14),
                    color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight,
                  ),
                ),
                subtitle: Text(
                  'External users can be invited as guests',
                  style: TextStyle(
                    fontSize: TResponsive.sp(context, 12),
                    color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
                  ),
                ),
                secondary: Icon(
                  Icons.person_add_alt_1_outlined,
                  color: isDark ? TColors.darkMuted : TColors.lightMuted,
                ),
                activeColor: TColors.primary,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: TSizes.xl),

              // ── Submit ──
              TButton(
                text: 'Create Workspace',
                onPressed: _loading ? null : _submit,
                isLoading: _loading,
                prefixIcon: Icons.add_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown-style option tile for settings.
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: TSizes.md, vertical: TSizes.sm),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : TColors.lightCard,
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        border: Border.all(
          color: isDark ? TColors.darkBorder : TColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? TColors.darkMuted : TColors.lightMuted),
          const SizedBox(width: TSizes.sm),
          Text(
            title,
            style: TextStyle(
              fontSize: TResponsive.sp(context, 14),
              color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight,
            ),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: value,
            isDense: true,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(TSizes.radiusMd),
            dropdownColor: isDark ? TColors.darkSurface : TColors.lightSurface,
            style: TextStyle(
              fontSize: TResponsive.sp(context, 13),
              color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
            ),
            items: options.entries
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
