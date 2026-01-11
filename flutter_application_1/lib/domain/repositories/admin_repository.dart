import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../entities/admin/dashboard_stats.dart';

abstract class AdminRepository {
  Future<Either<Failure, DashboardStats>> getDashboardStats();

  Future<Either<Failure, Unit>> updateUserRole({
    required String uid,
    required String role, // user | shelter | admin
  });

  Future<Either<Failure, Unit>> updateUserInfo({
    required String uid,
    required Map<String, dynamic> data,
  });

  Future<Either<Failure, Unit>> deleteUser({
    required String uid,
  });
}
