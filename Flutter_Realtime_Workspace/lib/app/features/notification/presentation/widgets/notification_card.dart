import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/domain/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
	const NotificationCard({super.key, required this.notification});

	final AppNotification notification;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final createdAt = TimeOfDay.fromDateTime(notification.createdAt).format(context);

		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: notification.isRead
						? theme.colorScheme.surface
						: theme.colorScheme.primary.withValues(alpha: 0.06),
				borderRadius: BorderRadius.circular(16),
				border: Border.all(
					color: notification.isRead
							? theme.dividerColor.withValues(alpha: 0.4)
							: theme.colorScheme.primary.withValues(alpha: 0.18),
				),
			),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					CircleAvatar(
						radius: 18,
						backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
						child: Icon(
							notification.isRead
									? Icons.notifications_none_rounded
									: Icons.notifications_active_rounded,
							size: 18,
							color: theme.colorScheme.primary,
						),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									notification.title,
									style: theme.textTheme.titleMedium?.copyWith(
										fontWeight: FontWeight.w700,
									),
								),
								const SizedBox(height: 6),
								Text(
									notification.body,
									style: theme.textTheme.bodyMedium,
								),
								const SizedBox(height: 10),
								Row(
									children: [
										Container(
											padding: const EdgeInsets.symmetric(
												horizontal: 8,
												vertical: 4,
											),
											decoration: BoxDecoration(
												color: theme.colorScheme.secondary.withValues(alpha: 0.12),
												borderRadius: BorderRadius.circular(999),
											),
											child: Text(
												notification.category,
												style: theme.textTheme.labelSmall?.copyWith(
													color: theme.colorScheme.secondary,
												),
											),
										),
										const Spacer(),
										Text(
											createdAt,
											style: theme.textTheme.labelMedium,
										),
									],
								),
							],
						),
					),
				],
			),
		);
	}
}
