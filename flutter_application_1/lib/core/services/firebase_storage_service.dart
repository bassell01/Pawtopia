import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  FirebaseStorageService(this._storage);
  final FirebaseStorage _storage;

  Future<String> uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }
}
