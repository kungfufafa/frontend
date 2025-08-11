import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/routes/app_pages.dart';
import 'package:frontend/app/services/api_service.dart';

/// AuthGuard middleware untuk melindungi routes yang memerlukan autentikasi
class AuthGuard extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Cek apakah user sudah login
    final token = ApiService.getToken();
    final isAuthenticated = token != null && token.isNotEmpty;

    // Jika user sudah login dan mencoba akses login/register, redirect ke profile
    if (isAuthenticated && (route == Routes.LOGIN || route == Routes.REGISTER)) {
      return const RouteSettings(name: Routes.PROFILE);
    }

    // Jika user belum login dan mencoba akses protected routes, redirect ke login
    if (!isAuthenticated && _isProtectedRoute(route)) {
      return const RouteSettings(name: Routes.LOGIN);
    }

    return null; // Lanjutkan ke route yang diminta
  }

  /// Cek apakah route memerlukan autentikasi
  bool _isProtectedRoute(String? route) {
    const protectedRoutes = [
      Routes.PROFILE,
    ];
    
    return protectedRoutes.contains(route);
  }
}

/// LoginGuard khusus untuk halaman login - mencegah user yang sudah login mengakses login
class LoginGuard extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final token = ApiService.getToken();
    final isAuthenticated = token != null && token.isNotEmpty;

    // Jika user sudah login, redirect ke profile
    if (isAuthenticated) {
      return const RouteSettings(name: Routes.PROFILE);
    }

    return null;
  }
}

/// RegisterGuard khusus untuk halaman register - mencegah user yang sudah login mengakses register
class RegisterGuard extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final token = ApiService.getToken();
    final isAuthenticated = token != null && token.isNotEmpty;

    // Jika user sudah login, redirect ke profile
    if (isAuthenticated) {
      return const RouteSettings(name: Routes.PROFILE);
    }

    return null;
  }
}