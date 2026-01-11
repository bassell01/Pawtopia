import '../../../domain/entities/admin/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalPets,
    required super.availablePets,
    required super.adoptedPets,
    required super.totalAdopters,
    required super.totalShelters,
    required super.totalAdmins,
    required super.pendingRequests,
    required super.approvedRequests,
    required super.rejectedRequests,
    required super.completedRequests,
  });
}
