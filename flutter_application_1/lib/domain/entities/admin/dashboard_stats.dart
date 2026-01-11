class DashboardStats {
  final int totalPets;   
  final int availablePets;
  final int adoptedPets;
  final int totalAdopters;
  final int totalShelters;
  final int totalAdmins;
  final int pendingRequests;
  final int approvedRequests;
  final int rejectedRequests;
  final int completedRequests;

  const DashboardStats({
    required this.totalPets,
    required this.availablePets,
    required this.adoptedPets,
    required this.totalAdopters,
    required this.totalShelters,
    required this.totalAdmins,
    required this.pendingRequests,
    required this.approvedRequests,
    required this.rejectedRequests,
    required this.completedRequests,
  });
}
