import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Core services
import '../services/firebase_auth_service.dart';
import '../services/firebase_firestore_service.dart';
import '../services/firebase_storage_service.dart';

// ================== Adoption imports ==================

// Data
import '../../data/datasources/adoption/adoption_remote_data_source.dart';
import '../../data/repositories_impl/adoption_repository_impl.dart';
// Domain
import '../../domain/repositories/adoption_repository.dart';
import '../../domain/usecases/adoption/create_adoption_request.dart';
import '../../domain/usecases/adoption/watch_my_adoption_requests.dart';
import '../../domain/usecases/adoption/watch_incoming_adoption_requests.dart';
import '../../domain/usecases/adoption/update_adoption_status.dart';
import '../../domain/usecases/adoption/watch_my_accepted_adoption_requests.dart';



// Global service locator instance used across the app 
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ================== Firebase SDK ==================
  if (!sl.isRegistered<FirebaseAuth>()) {
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  }
  if (!sl.isRegistered<FirebaseStorage>()) {
    sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  }
    

  // ================== Wrapper services ==================
  if (!sl.isRegistered<FirebaseAuthService>()) {
    sl.registerLazySingleton<FirebaseAuthService>(
      () => FirebaseAuthService(sl<FirebaseAuth>()),
    );
  }
  if (!sl.isRegistered<FirebaseFirestoreService>()) {
    sl.registerLazySingleton<FirebaseFirestoreService>(
      () => FirebaseFirestoreService(sl<FirebaseFirestore>()),
    );
  }
  if (!sl.isRegistered<FirebaseStorageService>()) {
    sl.registerLazySingleton<FirebaseStorageService>(
      () => FirebaseStorageService(sl<FirebaseStorage>()),
    );
  }

  // ================== Adoption ================== //


// ================== Adoption DataSource ==================//
// Remote data source talks directly to Firestore (queries/streams/writes)
  if (!sl.isRegistered<AdoptionRemoteDataSource>()) {
    sl.registerLazySingleton<AdoptionRemoteDataSource>(
      () => AdoptionRemoteDataSourceImpl(firestore: sl<FirebaseFirestore>()),
    );
  }

// ================== Adoption Repository ==================//
// Repository implementation connects domain to data source and handles mapping/errors

  if (!sl.isRegistered<AdoptionRepository>()) {
    sl.registerLazySingleton<AdoptionRepository>(
      () => AdoptionRepositoryImpl(remote: sl<AdoptionRemoteDataSource>()),
    );
  }

// ================== Adoption UseCases ==================//
// Each usecase represents a single business action and depends on AdoptionRepository

  if (!sl.isRegistered<CreateAdoptionRequest>()) {
    sl.registerLazySingleton<CreateAdoptionRequest>(
      () => CreateAdoptionRequest(sl<AdoptionRepository>()),
    );
  }

  if (!sl.isRegistered<WatchMyAdoptionRequests>()) {
    sl.registerLazySingleton<WatchMyAdoptionRequests>(
      () => WatchMyAdoptionRequests(sl<AdoptionRepository>()),
    );
  }

  if (!sl.isRegistered<WatchMyAcceptedAdoptionRequests>()) {
    sl.registerLazySingleton<WatchMyAcceptedAdoptionRequests>(
      () => WatchMyAcceptedAdoptionRequests(sl<AdoptionRepository>()),
    );
  }

  if (!sl.isRegistered<WatchIncomingAdoptionRequests>()) {
    sl.registerLazySingleton<WatchIncomingAdoptionRequests>(
      () => WatchIncomingAdoptionRequests(sl<AdoptionRepository>()),
    );
  }

  if (!sl.isRegistered<UpdateAdoptionStatus>()) {
    sl.registerLazySingleton<UpdateAdoptionStatus>(
      () => UpdateAdoptionStatus(sl<AdoptionRepository>()),
    );
  }

}
