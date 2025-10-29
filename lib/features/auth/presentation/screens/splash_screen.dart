import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:revec_qr/app/router/app_routes.dart';
import 'package:revec_qr/features/auth/domain/entities/user_session.dart';
import 'package:revec_qr/features/auth/presentation/controllers/session_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;
  ProviderSubscription<AsyncValue<UserSession?>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<AsyncValue<UserSession?>>(
      sessionControllerProvider,
      _onSessionChange,
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  void _onSessionChange(
    AsyncValue<UserSession?>? previous,
    AsyncValue<UserSession?> next,
  ) {
    if (!mounted || _navigated) return;
    next.whenOrNull(
      data: (session) {
        _navigated = true;
        final target =
            session != null ? AppRoutes.visitHistory : AppRoutes.login;
        Navigator.of(context).pushReplacementNamed(target);
      },
      error: (error, stackTrace) {
        _navigated = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar: $error')),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Revec QR',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparando tu experiencia...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
