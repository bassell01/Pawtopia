enum AdoptionStatus { pending, accepted, rejected, cancelled }

class AdoptionRequest {
  final String id;
  final String petId;
  final String? petName;
  final String? petType;
  final String? petLocation;
  final String? petPhotoUrl;
  final String ownerId;
  final String requesterId;
  final String? requesterName;
  final String? message;
  final AdoptionStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final String? threadId;


  const AdoptionRequest({
    required this.id,
    required this.petId,
    required this.ownerId,
    required this.requesterId,
    this.requesterName,
    this.message,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.expiresAt, 
    this.threadId,
    this.petName,
    this.petType,
    this.petLocation,
    this.petPhotoUrl,
  });

  bool get isPending => status == AdoptionStatus.pending;
  bool get isAccepted => status == AdoptionStatus.accepted;
  bool get isRejected => status == AdoptionStatus.rejected;
  bool get isCancelled => status == AdoptionStatus.cancelled;
}
