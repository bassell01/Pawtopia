import 'package:flutter_riverpod/legacy.dart';

final petSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
