import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/admin/admin_remote_data_source.dart';
import '../../../data/repositories_impl/admin_repository_impl.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../../../domain/usecases/admin/get_dashboard_stats.dart';
import '../../../domain/usecases/admin/update_user_role.dart';

//Firestore instance provider
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

//DataSource
final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  final db = ref.read(firebaseFirestoreProvider);
  return AdminRemoteDataSource(db);
});

//Repo Impl provider (concrete type)
final adminRepositoryImplProvider = Provider<AdminRepositoryImpl>((ref) {
  final remote = ref.read(adminRemoteDataSourceProvider);
  return AdminRepositoryImpl(remote);
});

// Repo provider (interface type)
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return ref.read(adminRepositoryImplProvider);
});

// Usecases
final getDashboardStatsProvider = Provider<GetDashboardStats>((ref) {
  final repo = ref.read(adminRepositoryProvider);
  return GetDashboardStats(repo);
});

final updateUserRoleProvider = Provider<UpdateUserRole>((ref) {
  final repo = ref.read(adminRepositoryProvider);
  return UpdateUserRole(repo);
});
