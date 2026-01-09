import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_matching_controller.dart';
import 'ai_matching_state.dart';

final aiImageMatchControllerProvider =
    StateNotifierProvider.autoDispose<AiImageMatchController, AiImageMatchState>(
  (ref) => AiImageMatchController(),
);
