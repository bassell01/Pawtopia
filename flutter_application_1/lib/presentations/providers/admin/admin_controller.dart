import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../domain/entities/admin/dashboard_stats.dart';
import '../../../domain/usecases/admin/get_dashboard_stats.dart';
import '../../../domain/usecases/admin/update_user_role.dart';
import 'admin_providers.dart';

class AdminState {
  final bool loading;
  final Failure? failure;
  final DashboardStats? stats;
  final bool updatingRole;

  const AdminState({
    required this.loading,
    required this.failure,
    required this.stats,
    required this.updatingRole,
  });

  factory AdminState.initial() => const AdminState(
        loading: false,
        failure: null,
        stats: null,
        updatingRole: false,
      );

  AdminState copyWith({
    bool? loading,
    Failure? failure,
    DashboardStats? stats,
    bool? updatingRole,
    bool clearFailure = false,
  }) {
    return AdminState(
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
      stats: stats ?? this.stats,
      updatingRole: updatingRole ?? this.updatingRole,
    );
  }
}

class AdminController extends StateNotifier<AdminState> {
  final GetDashboardStats getDashboardStats;
  final UpdateUserRole updateUserRole;

  AdminController({
    required this.getDashboardStats,
    required this.updateUserRole,
  }) : super(AdminState.initial());

  Future<void> loadDashboard() async {
    state = state.copyWith(loading: true, clearFailure: true);

    final Either<Failure, DashboardStats> result = await getDashboardStats();

    result.fold(
      (f) => state = state.copyWith(loading: false, failure: f),
      (stats) => state = state.copyWith(loading: false, stats: stats),
    );
  }

  Future<void> refresh() => loadDashboard();

  Future<bool> changeUserRole({
    required String uid,
    required String role,
  }) async {
    state = state.copyWith(updatingRole: true, clearFailure: true);

    final Either<Failure, Unit> result =
        await updateUserRole(uid: uid, role: role);

    return result.fold(
      (f) {
        state = state.copyWith(updatingRole: false, failure: f);
        return false;
      },
      (_) {
        state = state.copyWith(updatingRole: false);
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearFailure: true);
  }
}

final adminControllerProvider =
    StateNotifierProvider.autoDispose<AdminController, AdminState>((ref) {
  final getStats = ref.read(getDashboardStatsProvider);
  final updateRole = ref.read(updateUserRoleProvider);

  return AdminController(
    getDashboardStats: getStats,
    updateUserRole: updateRole,
  );
});
