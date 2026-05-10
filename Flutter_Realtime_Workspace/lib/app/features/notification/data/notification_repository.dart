import 'package:flutter_realtime_workspace/app/features/notification/domain/models/notification.dart';
import 'package:flutter_realtime_workspace/core/apis/endpoints.dart';
import 'package:flutter_realtime_workspace/core/network/api_client.dart';
import 'package:flutter_realtime_workspace/core/network/api_exception.dart';

class NotificationRepository {
	NotificationRepository({ApiClient? apiClient})
			: _apiClient = apiClient ?? ApiClient.instance;

	final ApiClient _apiClient;

	Future<ApiResult<List<AppNotification>>> fetchNotifications() {
		return _apiClient.get<List<AppNotification>>(
			ApiEndpoints.notifications,
			fromJson: (json) {
				if (json is List) {
					return json
							.whereType<Map>()
							.map(
								(item) => AppNotification.fromJson(
									Map<String, dynamic>.from(item),
								),
							)
							.toList();
				}

				if (json is Map<String, dynamic>) {
					final items = json['notifications'] ?? json['data'] ?? json['items'];
					if (items is List) {
						return items
								.whereType<Map>()
								.map(
									(item) => AppNotification.fromJson(
										Map<String, dynamic>.from(item),
									),
								)
								.toList();
					}
				}

				return const <AppNotification>[];
			},
		);
	}

	Future<ApiResult<dynamic>> markAllAsRead() {
		return _apiClient.patch<dynamic>(ApiEndpoints.markAllRead);
	}
}
