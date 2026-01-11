import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../domain/entities/admin/dashboard_stats.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remote;
  AdminRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats() async {
    try {
      final stats = await remote.getDashboardStats();
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateUserRole({
    required String uid,
    required String role,
  }) async {
    try {
      await remote.updateUserRole(uid: uid, role: role);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Unit>> deleteUser({required String uid}) {
    // TODO: implement deleteUser
    throw UnimplementedError();
  }
  
  @override
  Future<Either<Failure, Unit>> updateUserInfo({required String uid, required Map<String, dynamic> data}) {
    // TODO: implement updateUserInfo
    throw UnimplementedError();
  }
}
