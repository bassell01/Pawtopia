import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? bio;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.bio,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        userId,
        email,
        displayName,
        photoUrl,
        phoneNumber,
        bio,
        address,
        city,
        state,
        zipCode,
        createdAt,
        updatedAt,
      ];

  UserProfile copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullName => displayName ?? email.split('@').first;
}
