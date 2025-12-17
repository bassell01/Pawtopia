import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/chat/message.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime? sentAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['sentAt'];
    return MessageModel(
      id: id,
      senderId: (map['senderId'] ?? '') as String,
      text: (map['text'] ?? '') as String,
      sentAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Message toEntity() => Message(
        id: id,
        senderId: senderId,
        text: text,
        sentAt: sentAt,
      );
}
