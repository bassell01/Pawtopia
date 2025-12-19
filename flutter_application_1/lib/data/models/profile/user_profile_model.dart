import '../../../domain/entities/profile/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.userId,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.phoneNumber,
    super.bio,
    super.address,
    super.city,
    super.state,
    super.zipCode,
    super.createdAt,
    super.updatedAt,
  });

factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  return UserProfileModel(
    userId: json['userId'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String?,
    photoUrl: json['photoUrl'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    bio: json['bio'] as String?,
    address: json['address'] as String?,
    city: json['city'] as String?,
    state: json['state'] as String?,
    zipCode: json['zipCode'] as String?,
    createdAt: _toDate(json['createdAt']),
    updatedAt: _toDate(json['updatedAt']),
  );
}


  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      userId: profile.userId,
      email: profile.email,
      displayName: profile.displayName,
      photoUrl: profile.photoUrl,
      phoneNumber: profile.phoneNumber,
      bio: profile.bio,
      address: profile.address,
      city: profile.city,
      state: profile.state,
      zipCode: profile.zipCode,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }
}
