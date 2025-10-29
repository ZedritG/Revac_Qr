import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:revec_qr/features/auth/presentation/screens/login_screen.dart';
import 'package:revec_qr/features/auth/presentation/screens/splash_screen.dart';
import 'package:revec_qr/features/visits/presentation/screens/visit_history_screen.dart';
import 'package:revec_qr/features/visits/presentation/screens/visit_scanner_screen.dart';

final initialRouteProvider = Provider<String>((ref) => AppRoutes.splash);

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String visitHistory = '/visits';
  static const String visitScanner = '/visits/scanner';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case visitHistory:
        return MaterialPageRoute<void>(
          builder: (_) => const VisitHistoryScreen(),
          settings: settings,
        );
      case visitScanner:
        return MaterialPageRoute<void>(
          builder: (_) => const VisitScannerScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }
}
