import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/adoption/adoption_request.dart';

class AdoptionRequestModel extends AdoptionRequest {
  const AdoptionRequestModel({
    required super.id,
    required super.petId,
    super.petName,
    super.petType,
    super.petLocation,
    super.petPhotoUrl,
    required super.ownerId,
    required super.requesterId,
    super.requesterName,
    super.message,
    required super.status,
    super.createdAt,
    super.updatedAt,
    super.expiresAt, 
    super.threadId,
  });

  factory AdoptionRequestModel.fromEntity(AdoptionRequest e) {
    return AdoptionRequestModel(
      id: e.id,
      petId: e.petId,
      petName: e.petName,
      petType: e.petType,
      petLocation: e.petLocation,
      petPhotoUrl: e.petPhotoUrl,
      ownerId: e.ownerId,
      requesterId: e.requesterId,
      requesterName: e.requesterName,
      message: e.message,
      status: e.status,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      expiresAt: e.expiresAt,
      threadId: e.threadId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'petId': petId,

      'ownerId': ownerId,
      'requesterId': requesterId,

      if (requesterName != null) 'requesterName': requesterName,

      if (message != null) 'message': message,

      'status': status.name,

      if (threadId != null) 'threadId': threadId,

      if (petName != null) 'petName': petName,
      if (petType != null) 'petType': petType,
      if (petLocation != null) 'petLocation': petLocation,
      if (petPhotoUrl != null) 'petPhotoUrl': petPhotoUrl,

      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),

    };
  }

  factory AdoptionRequestModel.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    AdoptionStatus parseStatus(dynamic v) {
      final s = (v ?? 'pending').toString().trim().toLowerCase();
      return AdoptionStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => AdoptionStatus.pending,
      );
    }

    DateTime? parseTime(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return AdoptionRequestModel(
      id: id,
      petId: (json['petId'] ?? '') as String,

      ownerId: (json['ownerId'] ?? '') as String,
      requesterId: (json['requesterId'] ?? '') as String,
      requesterName: json['requesterName'] as String?,

      message: json['message'] as String?,
      status: parseStatus(json['status']),
      createdAt: parseTime(json['createdAt']),
      updatedAt: parseTime(json['updatedAt']),
      expiresAt: parseTime(json['expiresAt']), 

      threadId: json['threadId'] as String?,

      petName: json['petName'] as String?,
      petType: json['petType'] as String?,
      petLocation: json['petLocation'] as String?,
      petPhotoUrl: json['petPhotoUrl'] as String?,
    );
  }
}
