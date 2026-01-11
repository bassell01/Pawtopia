import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/admin/dashboard_stats.dart';
import '../../repositories/admin_repository.dart';

class GetDashboardStats {
  final AdminRepository repo;
  GetDashboardStats(this.repo);

  Future<Either<Failure, DashboardStats>> call() {
    return repo.getDashboardStats();
  }
}
