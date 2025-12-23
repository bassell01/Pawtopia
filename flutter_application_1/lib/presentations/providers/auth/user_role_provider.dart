import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state_provider.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Reads role from Firestore: users/{uid}.role
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) return null;

  final db = ref.watch(firestoreProvider);
  final doc = await db.collection('users').doc(user.uid).get();

  // لو doc مش موجود => null (وده معناه محتاج تعمل users doc)
  return doc.data()?['role'] as String?;
});
