import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/features/team_management/domain/usecases/add_team_member_usecase.dart';
import 'package:flutter_realtime_workspace/core/network/api_exception.dart';

class AddTeamMemberScreen extends StatefulWidget {
	const AddTeamMemberScreen({
		super.key,
		required this.teamId,
	});

	final String teamId;

	@override
	State<AddTeamMemberScreen> createState() => _AddTeamMemberScreenState();
}

class _AddTeamMemberScreenState extends State<AddTeamMemberScreen> {
	final _formKey = GlobalKey<FormState>();
	final _emailController = TextEditingController();
	final _roleController = TextEditingController();
	final _useCase = AddTeamMemberUseCase();

	bool _isSubmitting = false;

	@override
	void dispose() {
		_emailController.dispose();
		_roleController.dispose();
		super.dispose();
	}

	Future<void> _submit() async {
		if (!_formKey.currentState!.validate()) {
			return;
		}

		setState(() {
			_isSubmitting = true;
		});

		final result = await _useCase(
			teamId: widget.teamId,
			email: _emailController.text.trim(),
			role: _roleController.text.trim(),
		);

		if (!mounted) {
			return;
		}

		setState(() {
			_isSubmitting = false;
		});

		switch (result) {
			case ApiSuccess<Map<String, dynamic>>():
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Team member added successfully.')),
				);
				Navigator.of(context).pop(result.data);
			case ApiFailure<Map<String, dynamic>>():
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text(result.exception.message)),
				);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Add Team Member')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Form(
					key: _formKey,
					child: Column(
						children: [
							TextFormField(
								controller: _emailController,
								keyboardType: TextInputType.emailAddress,
								decoration: const InputDecoration(
									labelText: 'Member email',
								),
								validator: (value) {
									if (value == null || value.trim().isEmpty) {
										return 'Email is required';
									}
									return null;
								},
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _roleController,
								decoration: const InputDecoration(
									labelText: 'Role',
									hintText: 'member, admin, lead',
								),
							),
							const SizedBox(height: 20),
							SizedBox(
								width: double.infinity,
								child: FilledButton(
									onPressed: _isSubmitting ? null : _submit,
									child: Text(_isSubmitting ? 'Adding...' : 'Add member'),
								),
							),
						],
					),
				),
			),
		);
	}
}
