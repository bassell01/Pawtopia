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

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final doc = await firestore.collection('profiles').doc(userId).get();
      
      if (!doc.exists) {
        throw ServerException('Profile not found');
      }

      return UserProfileModel.fromJson({...doc.data()!, 'userId': userId});
    } catch (e) {
      throw ServerException('Failed to get user profile');
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

      await firestore.collection('profiles').doc(userId).update(updates);

      return await getUserProfile(userId);
    } catch (e) {
      throw ServerException('Failed to update user profile');
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

      // Update profile with new photo URL
      await firestore.collection('profiles').doc(userId).update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      throw ServerException('Failed to upload profile image');
    }
  }

  @override
  Stream<UserProfileModel> watchUserProfile(String userId) {
    return firestore
        .collection('profiles')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw ServerException('Profile not found');
      }
      return UserProfileModel.fromJson({...doc.data()!, 'userId': userId});
    });
  }
}
