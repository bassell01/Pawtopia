import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_picker_service.dart';
import '../../../domain/entities/pets/pet.dart';
import '../../../core/services/mobilenet_embedding_service.dart';
import '../../../core/services/cosine_similarity.dart';
import 'ai_matching_state.dart';

class AiImageMatchController extends StateNotifier<AiImageMatchState> {
  AiImageMatchController() : super(AiImageMatchState.initial());

  void setQueryType(String type) {
    state = state.copyWith(queryType: type);
  }

  Future<void> pickQueryImage() async {
    try {
      final path = await ImagePickerService.pickImage();
      if (path == null) return;

      state = state.copyWith(
        queryImage: File(path),
        results: const [],
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Image pick failed: $e');
    }
  }

  void clear() {
    state = AiImageMatchState.initial();
  }

  Future<void> compareAgainstPets(List<Pet> pets) async {
    final query = state.queryImage;
    if (query == null) return;

    final queryType = state.queryType.trim().toLowerCase();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      results: const [],
    );

    try {
      final embedder = await MobileNetEmbeddingService.instance();

      // Query embedding from File
      final queryVec = await embedder.embeddingFromFile(query);

      final results = <AiPetMatchResult>[];

      for (final pet in pets) {
        if (pet.photoUrls.isEmpty) continue;

        double best = -1;

        for (final raw in pet.photoUrls) {
          final url = raw.trim();
          if (url.isEmpty) continue;

          final uri = Uri.tryParse(url);
          final ok = uri != null &&
              uri.hasScheme &&
              uri.hasAuthority &&
              (uri.scheme == 'http' || uri.scheme == 'https');
          if (!ok) continue;

          try {
            final petVec = await embedder.embeddingFromUrl(url);

            // Raw AI similarity (cosine)
            final rawSim = CosineSimilarity.compute(queryVec, petVec);

            // ✅ TYPE-AWARE BOOST / PENALTY
            double adjustedSim = rawSim;

            final petType = pet.type.trim().toLowerCase();

            if (petType == queryType) {
              adjustedSim += 0.20; // boost same type
            } else {
              adjustedSim -= 0.20; // penalize different type
            }

            adjustedSim = adjustedSim.clamp(0.0, 1.0);

            if (adjustedSim > best) best = adjustedSim;
          } catch (_) {
            continue;
          }
        }

        if (best >= 0) {
          results.add(AiPetMatchResult(pet: pet, similarity: best));
        }
      }

      results.sort((a, b) => b.similarity.compareTo(a.similarity));

      state = state.copyWith(
        isLoading: false,
        results: results.take(10).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Compare failed: $e',
      );
    }
  }
}
