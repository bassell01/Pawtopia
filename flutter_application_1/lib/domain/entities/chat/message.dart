class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime? sentAt;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });
}
