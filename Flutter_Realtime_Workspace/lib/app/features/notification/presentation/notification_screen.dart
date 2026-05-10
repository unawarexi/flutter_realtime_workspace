import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/app/features/notification/data/notification_repository.dart';
import 'package:flutter_realtime_workspace/app/features/notification/domain/models/notification.dart';
import 'package:flutter_realtime_workspace/app/features/notification/presentation/widgets/notification_card.dart';
import 'package:flutter_realtime_workspace/core/network/api_exception.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<ApiResult<List<AppNotification>>> _notificationsFuture;
  final NotificationRepository _repository = NotificationRepository();

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _repository.fetchNotifications();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchNotifications();
    setState(() {
      _notificationsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: FutureBuilder<ApiResult<List<AppNotification>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data;
          if (result is ApiFailure<List<AppNotification>>) {
            return _NotificationErrorState(
              message: result.exception.message,
              onRetry: _refresh,
            );
          }

          final notifications = result is ApiSuccess<List<AppNotification>>
              ? result.data
              : const <AppNotification>[];

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  _NotificationEmptyState(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) =>
                  NotificationCard(notification: notifications[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: notifications.length,
            ),
          );
        },
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.notifications_none_rounded,
          size: 54,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 12),
        Text(
          'No notifications yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'New alerts, assignments, and updates will show up here.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _NotificationErrorState extends StatelessWidget {
  const _NotificationErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
