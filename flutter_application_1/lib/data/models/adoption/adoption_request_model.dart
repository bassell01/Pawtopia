import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/adoption/adoption_request.dart';

class AdoptionRequestModel extends AdoptionRequest {
  const AdoptionRequestModel({
    required super.id,
    required super.petId,
    required super.ownerId,
    required super.requesterId,
    super.message,
    required super.status,
    super.createdAt,
    super.updatedAt,
    super.threadId,
  });

  AdoptionRequestModel copyWith({
    String? id,
    String? petId,
    String? ownerId,
    String? requesterId,
    String? message,
    AdoptionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? threadId,
  }) {
    return AdoptionRequestModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      ownerId: ownerId ?? this.ownerId,
      requesterId: requesterId ?? this.requesterId,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      threadId: threadId ?? this.threadId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      // (اختياري) تخزين id جوه الدوك
      'id': id,
      'petId': petId,
      'ownerId': ownerId,
      'requesterId': requesterId,
      'message': message,
      'status': status.name,
      'threadId': threadId,

  
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory AdoptionRequestModel.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    AdoptionStatus parseStatus(dynamic v) {
      final s = (v ?? 'pending').toString();
      return AdoptionStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => AdoptionStatus.pending,
      );
    }

    DateTime? parseTime(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return AdoptionRequestModel(
      id: id,
      petId: (json['petId'] ?? '') as String,
      ownerId: (json['ownerId'] ?? '') as String,
      requesterId: (json['requesterId'] ?? '') as String,
      message: json['message'] as String?,
      status: parseStatus(json['status']),
      createdAt: parseTime(json['createdAt']),
      updatedAt: parseTime(json['updatedAt']),
      threadId: json['threadId'] as String?,
    );
  }
}
