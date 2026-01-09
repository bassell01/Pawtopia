import 'dart:io';
import '../../../domain/entities/pets/pet.dart';

class AiPetMatchResult {
  final Pet pet;
  final double similarity; // 0..1
  const AiPetMatchResult({required this.pet, required this.similarity});
}

class AiImageMatchState {
  final File? queryImage;
  final bool isLoading;
  final String? errorMessage;
  final List<AiPetMatchResult> results;

  /// ✅ NEW: what the user selected in UI (cat/dog/bird/other)
  final String queryType;

  const AiImageMatchState({
    required this.queryImage,
    required this.isLoading,
    required this.errorMessage,
    required this.results,
    required this.queryType,
  });

  factory AiImageMatchState.initial() => const AiImageMatchState(
        queryImage: null,
        isLoading: false,
        errorMessage: null,
        results: [],
        queryType: 'cat', // default
      );

  AiImageMatchState copyWith({
    File? queryImage,
    bool? isLoading,
    String? errorMessage,
    List<AiPetMatchResult>? results,
    String? queryType,
    bool clearError = false,
  }) {
    return AiImageMatchState(
      queryImage: queryImage ?? this.queryImage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      results: results ?? this.results,
      queryType: queryType ?? this.queryType,
    );
  }
}
