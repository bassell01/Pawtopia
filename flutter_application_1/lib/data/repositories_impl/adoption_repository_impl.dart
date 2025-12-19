import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/adoption/adoption_request.dart';
import '../../domain/repositories/adoption_repository.dart';
import '../datasources/adoption/adoption_remote_data_source.dart';
import '../models/adoption/adoption_request_model.dart';

class AdoptionRepositoryImpl implements AdoptionRepository {
  final AdoptionRemoteDataSource _remote;

  AdoptionRepositoryImpl(FirebaseFirestore db) : _remote = AdoptionRemoteDataSource(db);

  @override
  Future<void> submitRequest(AdoptionRequest request) {
    final model = AdoptionRequestModel(
      id: request.id,
      petId: request.petId,
      adopterId: request.adopterId,
      shelterId: request.shelterId,
      status: request.status,
      note: request.note,
      createdAt: request.createdAt,
    );
    return _remote.submit(model);
  }

  @override
  Future<List<AdoptionRequest>> getUserRequests(String adopterId) async {
    final list = await _remote.getByAdopter(adopterId);
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AdoptionRequest>> getShelterRequests(String shelterId) async {
    final list = await _remote.getByShelter(shelterId);
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateRequestStatus({required String requestId, required String status}) {
    return _remote.updateStatus(requestId: requestId, status: status);
  }

  @override
  Stream<List<AdoptionRequest>> trackUserRequestsStream(String adopterId) {
    return _remote
        .streamByAdopter(adopterId)
        .map((list) => list.map((m) => m.toEntity()).toList());
  }
}
