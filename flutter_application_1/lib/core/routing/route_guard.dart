
import '../constants/app_routes.dart';

class RouteGuard {
  const RouteGuard();

  /// Returns a path to redirect to, or null to allow navigation.
  String? redirect({
    required String location,
    required bool isLoggedIn,
    required String? role,
    required bool authLoading,
    required bool roleLoading,
  }) {
    // While loading (splash time), keep user on splash
    if (authLoading || (isLoggedIn && roleLoading)) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    final isAuthRoute = location == AppRoutes.login || location == AppRoutes.register;
    final isSplash = location == AppRoutes.splash;
    final isAdminRoute = location.startsWith(AppRoutes.adminDashboard);

    // Not logged in -> allow only auth routes (and splash)
    if (!isLoggedIn) {
      if (isAuthRoute || isSplash) return null;
      return AppRoutes.login;
    }

    // Logged in -> prevent going back to auth routes or splash
    if (isAuthRoute || isSplash) {
      // Admin users go to admin dashboard; others go home
      return (role == 'admin') ? AppRoutes.adminDashboard : AppRoutes.home;
    }

    // Admin-only area protection
    if (isAdminRoute && role != 'admin') {
      return AppRoutes.home;
    }

    // Allowed
    return null;
  }
}
