import '../../../domain/entities/admin/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalPets,
    required super.totalUsers,
    required super.pendingRequests,
  });

  factory DashboardStatsModel.fromCounts({
    required int totalPets,
    required int totalUsers,
    required int pendingRequests,
  }) {
    return DashboardStatsModel(
      totalPets: totalPets,
      totalUsers: totalUsers,
      pendingRequests: pendingRequests,
    );
  }

  DashboardStats toEntity() => DashboardStats(
        totalPets: totalPets,
        totalUsers: totalUsers,
        pendingRequests: pendingRequests,
      );
}
