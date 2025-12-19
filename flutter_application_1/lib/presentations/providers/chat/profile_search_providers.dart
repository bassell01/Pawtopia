import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profilesSearchProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, q) {
  final query = q.trim();
  if (query.isEmpty) return const Stream.empty();

  // Prefix search on displayName (requires orderBy)
  final stream = FirebaseFirestore.instance
      .collection('profiles')
      .orderBy('displayName')
      .startAt([query])
      .endAt(['$query\uf8ff'])
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());

  return stream;
});
