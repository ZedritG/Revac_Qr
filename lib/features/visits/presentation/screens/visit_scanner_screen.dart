import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:revec_qr/core/constants/team_catalog.dart';
import 'package:revec_qr/core/services/permission_service.dart';
import 'package:revec_qr/features/auth/domain/entities/user_role.dart';
import 'package:revec_qr/features/auth/presentation/controllers/session_controller.dart';
import 'package:revec_qr/features/visits/presentation/controllers/visit_registration_controller.dart';
import 'package:revec_qr/shared/providers/service_providers.dart';

class VisitScannerScreen extends ConsumerStatefulWidget {
  const VisitScannerScreen({super.key});

  @override
  ConsumerState<VisitScannerScreen> createState() => _VisitScannerScreenState();
}

class _VisitScannerScreenState extends ConsumerState<VisitScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
  );
  bool _isProcessing = false;
  bool _hasCameraPermission = false;
  bool _scannerStarted = false;
  bool _isEnsuringPermissions = false;
  bool _isStartingScanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePermissions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _scannerStarted = false;
    }
    if (state == AppLifecycleState.resumed) {
      _ensurePermissions();
    }
  }

  Future<void> _ensurePermissions() async {
    if (_isEnsuringPermissions) return;
    _isEnsuringPermissions = true;

    final permissionService = ref.read(permissionServiceProvider);
    try {
      bool cameraGranted = await permissionService.hasPermission(
        AppPermission.camera,
      );
      if (!cameraGranted) {
        cameraGranted = await permissionService.request(AppPermission.camera);
        if (!cameraGranted && mounted) {
          await _showPermissionDeniedDialog();
        }
      }

      if (!cameraGranted) {
        await _scannerController.stop();
        _scannerStarted = false;
      }

      if (!mounted) return;

      setState(() {
        _hasCameraPermission = cameraGranted;
      });

      if (!cameraGranted) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startScannerIfNeeded();
      });
    } finally {
      _isEnsuringPermissions = false;
    }
  }

  Future<void> _startScannerIfNeeded() async {
    if (!_hasCameraPermission) return;
    if (_scannerStarted || _isStartingScanner) return;

    _isStartingScanner = true;
    try {
      await _scannerController.start();
      _scannerStarted = true;
    } catch (error) {
      // The controller might already be starting; swallow to avoid crashing.
      debugPrint('visit_scanner: failed to start scanner - $error');
    } finally {
      _isStartingScanner = false;
    }
  }

  Future<void> _showPermissionDeniedDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de camara requerido'),
        content: const Text(
          'Necesitamos acceso a la camara para escanear el codigo del equipo de trabajo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final code = _extractCode(capture);
    if (code == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    await _scannerController.stop();
    _scannerStarted = false;

    final team = TeamCatalog.infoFor(code);
    final confirmation = await _showConfirmationSheet(
      code: code,
      teamName: team.name,
      description: team.description,
      locationHint: team.locationHint,
    );

    if (confirmation == null || !confirmation.confirmed) {
      await _resumeScanner();
      return;
    }

    await _registerVisit(code, team.name, confirmation.note);
  }

  String? _extractCode(BarcodeCapture capture) {
    for (final candidate in capture.barcodes) {
      final value = candidate.rawValue;
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    if (capture.barcodes.isNotEmpty) {
      return capture.barcodes.first.rawValue;
    }
    return null;
  }

  Future<void> _registerVisit(
    String scannedCode,
    String teamName,
    String? note,
  ) async {
    final session = ref.read(currentSessionProvider);
    if (session == null || session.role != UserRole.technician) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo los tecnicos pueden registrar visitas.'),
        ),
      );
      await _resumeScanner();
      return;
    }

    final notifier = ref.read(visitRegistrationProvider.notifier);

    try {
      final record = await notifier.registerVisit(
        scannedCode: scannedCode,
        note: note,
      );

      if (!mounted) return;
      final usedFallback =
          record.note?.contains(
            VisitRegistrationController.fallbackLocationNote,
          ) ??
          false;
      final message = usedFallback
          ? 'Visita registrada sin ubicacion precisa. Revisa permisos de ubicacion.'
          : 'Visita registrada para $teamName.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(record);
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      await _resumeScanner();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar la visita: $error')),
      );
      await _resumeScanner();
    }
  }

  Future<_ConfirmationResult?> _showConfirmationSheet({
    required String code,
    required String teamName,
    String? description,
    String? locationHint,
  }) {
    final noteController = TextEditingController();
    return showModalBottomSheet<_ConfirmationResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    teamName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Codigo escaneado: $code',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (locationHint != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Ubicacion sugerida: $locationHint',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notas u observaciones',
                      hintText: 'Ej. Ajuste realizado, piezas reemplazadas...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final note = noteController.text.trim();
                      Navigator.of(context).pop(
                        _ConfirmationResult(
                          confirmed: true,
                          note: note.isEmpty ? null : note,
                        ),
                      );
                    },
                    child: const Text('Registrar visita'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              );
            },
          ),
        );
      },
    ).whenComplete(noteController.dispose);
  }

  Future<void> _resumeScanner() async {
    if (!_hasCameraPermission) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }
    await _startScannerIfNeeded();
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear equipo de trabajo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _scannerController.toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _scannerController.switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasCameraPermission)
            MobileScanner(
              controller: _scannerController,
              onDetect: _handleDetection,
            ),
          if (_hasCameraPermission)
            Align(
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          if (_hasCameraPermission)
            Positioned(
              top: 32,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Escanea el codigo del equipo de trabajo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Alinea el codigo dentro del marco para capturarlo automaticamente.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          if (!_hasCameraPermission)
            const Center(child: CircularProgressIndicator()),
          if (_isProcessing)
            const ColoredBox(
              color: Color.fromARGB(120, 0, 0, 0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _ConfirmationResult {
  const _ConfirmationResult({required this.confirmed, this.note});

  final bool confirmed;
  final String? note;
}
