import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/error/exceptions.dart';
import '../../models/profile/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile(String userId);

  Future<UserProfileModel> updateUserProfile({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  });

  Future<String> uploadProfileImage({
    required String userId,
    required String imagePath,
  });

  Stream<UserProfileModel> watchUserProfile(String userId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ProfileRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      firestore.collection('profiles').doc(uid);

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      firestore.collection('users').doc(uid);

  Future<String?> _getEmailFromUsers(String uid) async {
    final u = await _userRef(uid).get();
    return u.data()?['email'] as String?;
  }

  Future<void> _ensureProfileHasEmail({
    required String uid,
    Map<String, dynamic>? profileData,
  }) async {
    final existingEmail = profileData?['email'];
    if (existingEmail is String && existingEmail.trim().isNotEmpty) return;

    // try users/{uid}.email
    final email = await _getEmailFromUsers(uid);

    if (email != null && email.trim().isNotEmpty) {
      await _profileRef(uid).set({
        'id': uid,
        'userId': uid,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    // still missing -> leave it but don't crash here
    // (UI can show "No email" or you can force throw)
  }

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final doc = await _profileRef(userId).get();

      // لو مش موجود اعمله create defaults (اختياري)
      if (!doc.exists) {
        final email = await _getEmailFromUsers(userId);

        await _profileRef(userId).set({
          'id': userId,
          'userId': userId,
          'email': email ?? '',
          'displayName': '',
          'photoUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final created = await _profileRef(userId).get();
        final data = created.data() ?? {};

        // لو لسه email فاضي هنسيبه بس مش هنكراش هنا
        return UserProfileModel.fromJson({
          ...data,
          'userId': userId,
          'email': (data['email'] ?? '') as String,
        });
      }

      final data = doc.data() ?? {};
      await _ensureProfileHasEmail(uid: userId, profileData: data);

      // اقرأ تاني بعد الـ heal (علشان email يبان)
      final fixedDoc = await _profileRef(userId).get();
      final fixed = fixedDoc.data() ?? {};

      return UserProfileModel.fromJson({
        ...fixed,
        'userId': userId,
        'email': (fixed['email'] ?? '') as String,
      });
    } catch (e) {
      throw ServerException('Failed to get user profile: $e');
    }
  }

  @override
  Future<UserProfileModel> updateUserProfile({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updates['displayName'] = displayName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (bio != null) updates['bio'] = bio;
      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;
      if (state != null) updates['state'] = state;
      if (zipCode != null) updates['zipCode'] = zipCode;

      // ✅ set merge بدل update (عشان لو doc مش موجود مايبقاش error)
      await _profileRef(userId).set(updates, SetOptions(merge: true));

      return await getUserProfile(userId);
    } catch (e) {
      throw ServerException('Failed to update user profile: $e');
    }
  }

  @override
  Future<String> uploadProfileImage({
    required String userId,
    required String imagePath,
  }) async {
    try {
      final file = File(imagePath);
      final fileName = 'profile_$userId.jpg';
      final ref = storage.ref().child('profile_images').child(fileName);

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      await _profileRef(userId).set({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return downloadUrl;
    } catch (e) {
      throw ServerException('Failed to upload profile image: $e');
    }
  }

  @override
  Stream<UserProfileModel> watchUserProfile(String userId) {
    // ✅ asyncMap عشان نقدر نعمل ensure email
    return _profileRef(userId).snapshots().asyncMap((doc) async {
      if (!doc.exists) {
        // اعمله create بسرعة
        await getUserProfile(userId);
        final created = await _profileRef(userId).get();
        final data = created.data() ?? {};
        return UserProfileModel.fromJson({
          ...data,
          'userId': userId,
          'email': (data['email'] ?? '') as String,
        });
      }

      final data = doc.data() ?? {};
      await _ensureProfileHasEmail(uid: userId, profileData: data);

      final fixedDoc = await _profileRef(userId).get();
      final fixed = fixedDoc.data() ?? {};

      return UserProfileModel.fromJson({
        ...fixed,
        'userId': userId,
        'email': (fixed['email'] ?? '') as String,
      });
    });
  }
}
