import 'package:flutter/material.dart';

class MoreAppsScreen extends StatelessWidget {
	const MoreAppsScreen({super.key});

	static const _apps = [
		(
			title: 'Teamspot Admin',
			subtitle: 'Workspace controls, analytics, and governance tools.',
			icon: Icons.admin_panel_settings_rounded,
			color: Color(0xFF1E40AF),
		),
		(
			title: 'Teamspot Meet',
			subtitle: 'Dedicated video rooms, recordings, and live collaboration.',
			icon: Icons.video_call_rounded,
			color: Color(0xFF0F766E),
		),
		(
			title: 'Teamspot Drive',
			subtitle: 'Shared files, approvals, and version history across teams.',
			icon: Icons.folder_shared_rounded,
			color: Color(0xFF7C3AED),
		),
	];

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('More Apps')),
			body: ListView.separated(
				padding: const EdgeInsets.all(16),
				itemBuilder: (context, index) {
					final app = _apps[index];
					return Container(
						padding: const EdgeInsets.all(16),
						decoration: BoxDecoration(
							borderRadius: BorderRadius.circular(18),
							color: Theme.of(context).colorScheme.surface,
							border: Border.all(
								color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
							),
						),
						child: Row(
							children: [
								CircleAvatar(
									radius: 24,
									backgroundColor: app.color.withValues(alpha: 0.12),
									child: Icon(app.icon, color: app.color),
								),
								const SizedBox(width: 14),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												app.title,
												style: Theme.of(context).textTheme.titleMedium?.copyWith(
															fontWeight: FontWeight.w700,
														),
											),
											const SizedBox(height: 4),
											Text(
												app.subtitle,
												style: Theme.of(context).textTheme.bodyMedium,
											),
										],
									),
								),
							],
						),
					);
				},
				separatorBuilder: (_, __) => const SizedBox(height: 12),
				itemCount: _apps.length,
			),
		);
	}
}
