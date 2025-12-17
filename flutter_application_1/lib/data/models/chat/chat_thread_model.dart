import '../../../domain/entities/chat/chat_thread.dart';

class ChatThreadModel {
  final String id;
  final List<String> participantIds;
  final String? petId;
  final String? lastMessage;

  ChatThreadModel({
    required this.id,
    required this.participantIds,
    this.petId,
    this.lastMessage,
  });

  factory ChatThreadModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatThreadModel(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? const []),
      petId: map['petId'] as String?,
      lastMessage: map['lastMessage'] as String?,
    );
  }

  ChatThread toEntity() => ChatThread(
        id: id,
        participantIds: participantIds,
        petId: petId,
        lastMessage: lastMessage,
      );
}
