import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../repositories/admin_repository.dart';

class UpdateUserRole {
  final AdminRepository repo;
  UpdateUserRole(this.repo);

  Future<Either<Failure, Unit>> call({
    required String uid,
    required String role,
  }) {
    return repo.updateUserRole(uid: uid, role: role);
  }
}
