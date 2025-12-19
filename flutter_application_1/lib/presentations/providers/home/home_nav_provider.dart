import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeNavProvider =
    StateNotifierProvider<HomeNavController, int>(
  (ref) => HomeNavController(),
);

class HomeNavController extends StateNotifier<int> {
  HomeNavController() : super(0);

  void setIndex(int index) {
    state = index;
  }
}
