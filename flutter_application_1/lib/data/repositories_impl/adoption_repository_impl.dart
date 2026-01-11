import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/adoption/adoption_request.dart';
import '../../domain/repositories/adoption_repository.dart';
import '../datasources/adoption/adoption_remote_data_source.dart';
import '../models/adoption/adoption_request_model.dart';


class AdoptionRepositoryImpl implements AdoptionRepository {
  // Remote datasource dependency (injected) used to access Firestore
  final AdoptionRemoteDataSource remote;


  AdoptionRepositoryImpl({required this.remote});


// Create a new adoption request:
  @override
  Future<Either<Failure, String>> createRequest(AdoptionRequest request) async {
    try {
      final model = AdoptionRequestModel.fromEntity(request);
      final id = await remote.createRequest(model);
      return Right(id);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<List<AdoptionRequest>> watchMyRequests(String requesterId) {
    return remote.watchMyRequests(requesterId);
  }

  @override
  Stream<List<AdoptionRequest>> watchIncomingRequests(String ownerId) {
    return remote.watchIncomingRequests(ownerId);
  }

  @override
  Stream<List<AdoptionRequest>> watchMyAcceptedRequests(String requesterId) {
    return remote.watchMyAcceptedRequests(requesterId);
  }

  @override
  Future<Either<Failure, void>> updateStatus({
    required String requestId,
    required AdoptionStatus status,
    String? threadId,
  }) async {
    try {
      await remote.updateStatus(
        requestId: requestId,
        status: status.name,
        threadId: threadId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
  ///////////////////////////////
  @override
  Future<List<AdoptionRequest>> getUserRequests(String adopterId) {
    // TODO: implement getUserRequests
    throw UnimplementedError();
  }
}
