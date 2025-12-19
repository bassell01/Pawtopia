import 'package:flutter_riverpod/flutter_riverpod.dart';
final petSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
