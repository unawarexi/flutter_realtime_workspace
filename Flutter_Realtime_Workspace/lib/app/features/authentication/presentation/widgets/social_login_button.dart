import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
	const SocialLoginButton({
		super.key,
		required this.label,
		required this.onPressed,
		required this.icon,
		this.backgroundColor,
		this.foregroundColor,
	});

	final String label;
	final VoidCallback onPressed;
	final Widget icon;
	final Color? backgroundColor;
	final Color? foregroundColor;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);

		return SizedBox(
			width: double.infinity,
			child: FilledButton.icon(
				onPressed: onPressed,
				icon: icon,
				style: FilledButton.styleFrom(
					backgroundColor:
							backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
					foregroundColor: foregroundColor ?? theme.colorScheme.onSurface,
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(14),
					),
				),
				label: Text(label),
			),
		);
	}
}
