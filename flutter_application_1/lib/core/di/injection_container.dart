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
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // Wrapper services
  sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService(sl()));
  sl.registerLazySingleton<FirebaseFirestoreService>(() => FirebaseFirestoreService(sl()));
  sl.registerLazySingleton<FirebaseStorageService>(() => FirebaseStorageService(sl()));
}
