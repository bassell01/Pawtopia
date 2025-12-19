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

      if (credential.user == null) {
        throw ServerException('Sign in failed');
      }

      // Update last login time
      await firestore.collection('users').doc(credential.user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return await _getUserModel(credential.user!.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_handleAuthError(e));
    } catch (e) {
      throw ServerException('An error occurred during sign in');
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

      if (credential.user == null) {
        throw ServerException('Sign up failed');
      }

      // Create user document in Firestore
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        role: role,
        isEmailVerified: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await firestore.collection('users').doc(credential.user!.uid).set(
            userModel.toJson(),
          );

      // Create user profile document
      await firestore.collection('profiles').doc(credential.user!.uid).set({
        'userId': credential.user!.uid,
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send verification email
      await credential.user!.sendEmailVerification();

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_handleAuthError(e));
    } catch (e) {
      throw ServerException('An error occurred during sign up');
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

      if (userCredential.user == null) {
        throw ServerException('Google sign in failed');
      }

      // Check if user document exists
      final userDoc = await firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Create user document for new Google sign in
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          role: domain.UserRole.user,
          isEmailVerified: userCredential.user!.emailVerified,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toJson());

        // Create profile document
        await firestore
            .collection('profiles')
            .doc(userCredential.user!.uid)
            .set({
          'userId': userCredential.user!.uid,
          'email': userCredential.user!.email!,
          'displayName': userCredential.user!.displayName,
          'photoUrl': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return userModel;
      } else {
        // Update last login time
        await firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        return await _getUserModel(userCredential.user!.uid);
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_handleAuthError(e));
    } catch (e) {
      throw ServerException('An error occurred during Google sign in');
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
      throw ServerException('An error occurred during sign out');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) return null;

      return await _getUserModel(currentUser.uid);
    } catch (e) {
      throw ServerException('Failed to get current user');
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
      throw ServerException('Failed to send password reset email');
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
      throw ServerException('Failed to send verification email');
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return false;
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      throw ServerException('Failed to check email verification status');
    }
  }

  Future<UserModel> _getUserModel(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw ServerException('User data not found');
    }
    return UserModel.fromJson({...doc.data()!, 'id': uid});
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
