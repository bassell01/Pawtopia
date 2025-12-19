import '../entities/admin/dashboard_stats.dart';

abstract class AdminRepository {
  Future<DashboardStats> getDashboardStats();

  Future<void> updateUserRole({
    required String uid,
    required String role, // adopter | shelter | admin
  });
}
