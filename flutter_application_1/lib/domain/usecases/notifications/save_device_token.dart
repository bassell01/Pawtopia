import '../../repositories/notification_repository.dart';

class SaveDeviceToken {
  SaveDeviceToken(this.repo);
  final NotificationRepository repo;

  Future<void> call({required String uid, required String token}) {
    return repo.saveDeviceToken(uid: uid, token: token);
  }
}
