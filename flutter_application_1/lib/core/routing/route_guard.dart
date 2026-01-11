import '../constants/app_routes.dart';

class RouteGuard {

  // RouteGuard contains pure navigation protection logic
  const RouteGuard();

  /// Returns a path to redirect to, or null to allow navigation.
  String? redirect({
    required String location,
    required bool isLoggedIn,
    required String? role,
    required bool authLoading,
    required bool roleLoading,
  }) {

    // While loading (splash/gate time), keep user on gate only
    if (authLoading || (isLoggedIn && roleLoading)) {
      return (location == AppRoutes.splash) ? null : AppRoutes.splash;
    }

// Check if user is navigating to login or register pages
    final isAuthRoute =
        location == AppRoutes.login || location == AppRoutes.register;


    final isGate = location == AppRoutes.authGate;

    // Admin-only area protection: match "/admin" or "/admin/..."
    final isAdminRoute =
        location == AppRoutes.adminDashboard ||
        location.startsWith('${AppRoutes.adminDashboard}/');


    // Not logged in -> allow only auth routes (and gate)
    if (!isLoggedIn) {
      if (isAuthRoute || isGate) return null;
      return AppRoutes.login;
    }

    // Logged in -> prevent going back to auth routes or gate
    if (isAuthRoute || isGate) {
      return (role == 'admin') ? AppRoutes.adminDashboard : AppRoutes.home;
    }

    // Admin-only area protection
    if (isAdminRoute && role != 'admin') {
      return AppRoutes.home;
    }

    return null;
  }
}
