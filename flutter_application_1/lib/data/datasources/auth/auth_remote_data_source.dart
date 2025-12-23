import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/error/exceptions.dart';
import '../../../domain/entities/auth/user.dart' as domain;
import '../../models/auth/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    domain.UserRole role = domain.UserRole.user,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;

  Future<void> resetPassword({required String email});

  Future<void> sendEmailVerification();

  Future<bool> isEmailVerified();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
  });

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw ServerException('Sign in failed');
      }

      // ✅ refresh user (important)
      await user.reload();
      final refreshedUser = firebaseAuth.currentUser;

      // Update last login time
      await firestore.collection('users').doc(user.uid).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isEmailVerified': refreshedUser?.emailVerified ?? user.emailVerified,
      }, SetOptions(merge: true));

      // Ensure profile exists (safe for old users)
      await firestore.collection('profiles').doc(user.uid).set({
        'id': user.uid,
        'userId': user.uid,
        'email': refreshedUser?.email ?? user.email ?? email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return await _getUserModel(user.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_handleAuthError(e));
    } catch (e) {
      throw ServerException('An error occurred during sign in: $e');
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    domain.UserRole role = domain.UserRole.user,
  }) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw ServerException('Sign up failed');
      }

      final uid = user.uid;

      // Create user document in Firestore
      final userModel = UserModel(
        id: uid,
        email: email,
        role: role,
        isEmailVerified: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await firestore.collection('users').doc(uid).set(userModel.toJson());

      // Create user profile document
      await firestore.collection('profiles').doc(uid).set({
        'id': uid,
        'userId': uid,
        'email': email,
        'name': displayName,
        'displayName': displayName,
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Send verification email (optional)
      await user.sendEmailVerification();

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_handleAuthError(e));
    } catch (e) {
      throw ServerException('An error occurred during sign up: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw ServerException('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        throw ServerException('Google sign in failed');
      }

      final uid = user.uid;
      final email = user.email ?? googleUser.email;

      final userRef = firestore.collection('users').doc(uid);
      final profileRef = firestore.collection('profiles').doc(uid);

      final userDoc = await userRef.get();

      // ✅ if not exists -> create base user doc
      if (!userDoc.exists) {
        final userModel = UserModel(
          id: uid,
          email: email,
          role: domain.UserRole.user,
          isEmailVerified: user.emailVerified,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await userRef.set(userModel.toJson());

        await profileRef.set({
          'id': uid,
          'userId': uid,
          'email': email,
          'name': user.displayName ?? '',
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return userModel;
      }

      // ✅ user exists -> merge updates (avoid update() failures)
      await userRef.set({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isEmailVerified': user.emailVerified,
        // keep role as is (do NOT overwrite)
      }, SetOptions(merge: true));

      await profileRef.set({
        'id': uid,
        'userId': uid,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return await _getUserModel(uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_handleAuthError(e));
    } catch (e) {
      throw ServerException('An error occurred during Google sign in: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        firebaseAuth.signOut(),
        googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw ServerException('An error occurred during sign out: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) return null;

      return await _getUserModel(currentUser.uid);
    } catch (e) {
      throw ServerException('Failed to get current user: $e');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _getUserModel(firebaseUser.uid);
    });
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_handleAuthError(e));
    } catch (e) {
      throw ServerException('Failed to send password reset email: $e');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw ServerException('No user logged in');
      }
      await user.sendEmailVerification();
    } catch (e) {
      throw ServerException('Failed to send verification email: $e');
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return false;
      await user.reload();
      return firebaseAuth.currentUser?.emailVerified ?? false;
    } catch (e) {
      throw ServerException('Failed to check email verification status: $e');
    }
  }

  Future<UserModel> _getUserModel(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw ServerException('User data not found');
    }

    final data = doc.data()!;
    return UserModel.fromJson({
      ...data,
      'id': uid,
    });
  }

  String _handleAuthError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Email address is invalid';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      default:
        return e.message ?? 'An authentication error occurred';
    }
  }
}
