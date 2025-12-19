import 'package:equatable/equatable.dart';

enum UserRole {
  user,
  shelter,
  admin;

  bool get isAdmin => this == UserRole.admin;
  bool get isShelter => this == UserRole.shelter;
  bool get isUser => this == UserRole.user;
  bool get canManagePets => isAdmin || isShelter;
}

class User extends Equatable {
  final String id;
  final String email;
  final UserRole role;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.email,
    required this.role,
    this.isEmailVerified = false,
    this.createdAt,
    this.lastLoginAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        role,
        isEmailVerified,
        createdAt,
        lastLoginAt,
      ];

  User copyWith({
    String? id,
    String? email,
    UserRole? role,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
