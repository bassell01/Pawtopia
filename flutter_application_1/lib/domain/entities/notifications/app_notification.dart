class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // chat | adoption | system | ai
  final Map<String, dynamic> data;
  final String? deepLink;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.deepLink,
  });
}
