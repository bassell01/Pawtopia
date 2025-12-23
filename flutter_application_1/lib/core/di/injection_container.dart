import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../services/firebase_auth_service.dart';
import '../services/firebase_firestore_service.dart';
import '../services/firebase_storage_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Firebase SDK
  if (!sl.isRegistered<FirebaseAuth>()) {
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  }
  if (!sl.isRegistered<FirebaseStorage>()) {
    sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  }

  // Wrapper services
  if (!sl.isRegistered<FirebaseAuthService>()) {
    sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService(sl<FirebaseAuth>()));
  }
  if (!sl.isRegistered<FirebaseFirestoreService>()) {
    sl.registerLazySingleton<FirebaseFirestoreService>(() => FirebaseFirestoreService(sl<FirebaseFirestore>()));
  }
  if (!sl.isRegistered<FirebaseStorageService>()) {
    sl.registerLazySingleton<FirebaseStorageService>(() => FirebaseStorageService(sl<FirebaseStorage>()));
  }
}
