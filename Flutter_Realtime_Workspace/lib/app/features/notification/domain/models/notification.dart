class AppNotification {
	const AppNotification({
		required this.id,
		required this.title,
		required this.body,
		required this.createdAt,
		this.category = 'general',
		this.isRead = false,
	});

	final String id;
	final String title;
	final String body;
	final DateTime createdAt;
	final String category;
	final bool isRead;

	factory AppNotification.fromJson(Map<String, dynamic> json) {
		return AppNotification(
			id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
			title: json['title']?.toString() ?? 'Notification',
			body: json['body']?.toString() ?? json['message']?.toString() ?? '',
			createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
					DateTime.now(),
			category: json['category']?.toString() ?? 'general',
			isRead: json['isRead'] as bool? ?? false,
		);
	}
}
