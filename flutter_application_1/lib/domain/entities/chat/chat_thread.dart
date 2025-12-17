class ChatThread {
  final String id;
  final List<String> participantIds;
  final String? petId;
  final String? lastMessage;

  ChatThread({
    required this.id,
    required this.participantIds,
    this.petId,
    this.lastMessage,
  });
}
