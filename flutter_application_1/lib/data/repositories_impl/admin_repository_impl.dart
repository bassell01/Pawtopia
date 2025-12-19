import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin/dashboard_stats.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin/admin_remote_data_source.dart';
import '../models/admin/dashboard_stats_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remote;

  AdminRepositoryImpl(FirebaseFirestore db) : _remote = AdminRemoteDataSource(db);

  @override
  Future<DashboardStats> getDashboardStats() async {
    final c = await _remote.getStatsCounts();
    return DashboardStatsModel.fromCounts(
      totalPets: c['pets'] ?? 0,
      totalUsers: c['users'] ?? 0,
      pendingRequests: c['pending'] ?? 0,
    ).toEntity();
  }

  @override
  Future<void> updateUserRole({required String uid, required String role}) {
    return _remote.updateUserRole(uid, role);
  }
}
