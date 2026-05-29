import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/team_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';

class AddTeamMemberScreen extends ConsumerStatefulWidget {
	const AddTeamMemberScreen({
		super.key,
		required this.teamId,
	});

	final String teamId;

	@override
	ConsumerState<AddTeamMemberScreen> createState() => _AddTeamMemberScreenState();
}

class _AddTeamMemberScreenState extends ConsumerState<AddTeamMemberScreen> {
	final _formKey = GlobalKey<FormState>();
	final _emailController = TextEditingController();
	String _role = 'member';
	bool _isSubmitting = false;

	static const _roles = ['member', 'lead', 'admin'];

	@override
	void dispose() {
		_emailController.dispose();
		super.dispose();
	}

	Future<void> _submit() async {
		if (!_formKey.currentState!.validate()) return;
		setState(() => _isSubmitting = true);
		await TeamUseCase.inviteMember(
			context: context,
			ref: ref,
			teamId: widget.teamId,
			body: {
				'email': _emailController.text.trim(),
				'role': _role,
			},
		);
		if (!mounted) return;
		setState(() => _isSubmitting = false);
		Navigator.of(context).pop();
	}

	@override
	Widget build(BuildContext context) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final hPad = TResponsive.pagePadding(context);
		final textPrimary = isDark ? TColors.textDark : TColors.textLight;

		return Scaffold(
			backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
			appBar: AppBar(
				title: const Text('Add Team Member'),
				backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
				elevation: 0,
			),
			body: Padding(
				padding: EdgeInsets.all(hPad),
				child: Form(
					key: _formKey,
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							TextFormField(
								controller: _emailController,
								keyboardType: TextInputType.emailAddress,
								style: TextStyle(color: textPrimary),
								decoration: InputDecoration(
									labelText: 'Member email',
									hintText: 'user@example.com',
									border: OutlineInputBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
								),
								validator: (value) {
									if (value == null || value.trim().isEmpty) return 'Email is required';
									if (!value.contains('@')) return 'Enter a valid email';
									return null;
								},
							),
							const SizedBox(height: TSizes.md),
							DropdownButtonFormField<String>(
								value: _role,
								decoration: InputDecoration(
									labelText: 'Role',
									border: OutlineInputBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
								),
								items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r.capitalize()))).toList(),
								onChanged: (v) => setState(() => _role = v ?? 'member'),
							),
							const SizedBox(height: TSizes.xl),
							FilledButton(
								onPressed: _isSubmitting ? null : _submit,
								style: FilledButton.styleFrom(
									backgroundColor: TColors.primary,
									padding: const EdgeInsets.symmetric(vertical: TSizes.md),
									shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
								),
								child: Text(_isSubmitting ? 'Sending...' : 'Send Invitation'),
							),
						],
					),
				),
			),
		);
	}
}

extension _StringExt on String {
	String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

