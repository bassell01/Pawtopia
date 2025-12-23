import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/auth/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    super.isEmailVerified,
    super.createdAt,
    super.lastLoginAt,
  });

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == (json['role'] ?? 'user'),
        orElse: () => UserRole.user,
      ),
      isEmailVerified: (json['isEmailVerified'] as bool?) ?? false,
      createdAt: _toDate(json['createdAt']),
      lastLoginAt: _toDate(json['lastLoginAt']),
    );
  }

  /// ✅ خلي Firestore يخزن Timestamp (أفضل) بدل String
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'lastLoginAt': lastLoginAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(lastLoginAt!),
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      role: user.role,
      isEmailVerified: user.isEmailVerified,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );
  }
}
