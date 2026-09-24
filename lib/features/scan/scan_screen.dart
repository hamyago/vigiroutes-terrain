import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/models/terrain_models.dart';
import 'scan_controller.dart';

// FIX : ScanScreenWrapper est un StatelessWidget qui possède le Provider.
// L'ancien code plaçait ChangeNotifierProvider dans build() de _ScanScreenState,
// ce qui recréait ScanController à chaque setState, réinitialisant les scans.
class ScanScreenWrapper extends StatelessWidget {
  const ScanScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScanController(),
      child: const ScanScreen(),
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  MobileScannerController? _cameraController;
  bool _bottomSheetShown = false;
  bool _permissionChecked = false;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndInit();
  }

  Future<void> _checkPermissionAndInit() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permissionChecked = true;
      _permissionGranted = status.isGranted;
    });
    if (status.isGranted) {
      _initCamera();
    }
  }

  void _initCamera() {
    // FIX Samsung A14 / camera2 : formats limités à QR uniquement
    // pour éviter le scan multi-format trop lent sur cet appareil.
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
    );
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        ctrl.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        ctrl.stop();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture, ScanController controller) {
    if (!controller.isScanning || controller.isLoading) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    _handleScan(barcode.rawValue!, controller);
  }

  Future<void> _handleScan(String value, ScanController controller) async {
    final success = await controller.processScan(value);
    if (!mounted) return;
    if (success && controller.scannedBooking != null && !_bottomSheetShown) {
      _bottomSheetShown = true;
      await _showSuccessSheet(controller.scannedBooking!);
    } else if (!success && controller.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.error!),
            backgroundColor: Colors.red,
          ),
        );
        controller.reset();
        _bottomSheetShown = false;
      }
    }
  }

  Future<void> _showSuccessSheet(TerrainBookingModel booking) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ScanSuccessSheet(
        booking: booking,
        onViewDetails: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, '/booking/${booking.id}');
        },
      ),
    );
    if (mounted) {
      final controller = context.read<ScanController>();
      controller.reset();
      _bottomSheetShown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX : le Provider est maintenant dans ScanScreenWrapper, pas ici.
    final controller = context.watch<ScanController>();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanner QR Code'),
        actions: [
          if (_cameraController != null)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => _cameraController!.toggleTorch(),
            ),
        ],
      ),
      body: _buildBody(controller),
    );
  }

  Widget _buildBody(ScanController controller) {
    // Pas encore vérifié la permission
    if (!_permissionChecked) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    // Permission refusée
    if (!_permissionGranted) {
      return _PermissionDeniedWidget(
        onRetry: () async {
          final status = await Permission.camera.request();
          if (!mounted) return;
          if (status.isGranted) {
            setState(() {
              _permissionGranted = true;
            });
            _initCamera();
          } else if (status.isPermanentlyDenied) {
            openAppSettings();
          }
        },
      );
    }

    // Contrôleur pas encore prêt
    if (_cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _cameraController!,
          errorBuilder: (context, error, child) {
            return _CameraErrorWidget(
              error: error,
              onRetry: () {
                setState(() {});
                _cameraController?.start();
              },
            );
          },
          onDetect: (capture) => _onDetect(capture, controller),
        ),
        _ScanOverlay(),
        if (controller.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  SizedBox(height: 16),
                  Text(
                    'Vérification en cours...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              'Placez le QR code dans le cadre',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widget permission refusée ─────────────────────────────────────────────────

class _PermissionDeniedWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionDeniedWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 72, color: Colors.white38),
            const SizedBox(height: 24),
            const Text(
              'Permission caméra refusée.\n\nAllez dans :\nParamètres → Applications → VigiRoutes Terrain → Permissions → Caméra → Autoriser',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Ouvrir les paramètres'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget d'erreur caméra ────────────────────────────────────────────────────

class _CameraErrorWidget extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onRetry;

  const _CameraErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final message = _message();
    final isPermission = error.errorCode == MobileScannerErrorCode.permissionDenied;

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermission ? Icons.no_photography_outlined : Icons.camera_alt_outlined,
              size: 72,
              color: Colors.white38,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: isPermission ? openAppSettings : onRetry,
              icon: Icon(isPermission ? Icons.settings_outlined : Icons.refresh),
              label: Text(isPermission ? 'Ouvrir les paramètres' : 'Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _message() {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Permission caméra refusée.\n\nAllez dans :\nParamètres → Applications → VigiRoutes Terrain → Permissions → Caméra → Autoriser';
      case MobileScannerErrorCode.unsupported:
        return "La caméra n'est pas supportée\nsur cet appareil.";
      default:
        return 'Impossible d\'accéder à la caméra.\n\n${error.errorDetails?.message ?? 'Code : ${error.errorCode.name}'}\n\nRedémarrez l\'application et réessayez.';
    }
  }
}

// ── Overlay du cadre QR ───────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const frameSize = 250.0;
    final top = (size.height - frameSize) / 2 - 40;
    final left = (size.width - frameSize) / 2;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                top: top,
                left: left,
                child: Container(
                  width: frameSize,
                  height: frameSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: top,
          left: left,
          child: _CornerFrame(size: frameSize),
        ),
      ],
    );
  }
}

class _CornerFrame extends StatelessWidget {
  final double size;
  const _CornerFrame({required this.size});

  @override
  Widget build(BuildContext context) {
    const cornerLen = 24.0;
    const cornerWidth = 3.0;
    const color = Color(0xFFFF6B35);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: Container(width: cornerLen, height: cornerWidth, color: color)),
          Positioned(top: 0, left: 0, child: Container(width: cornerWidth, height: cornerLen, color: color)),
          Positioned(top: 0, right: 0, child: Container(width: cornerLen, height: cornerWidth, color: color)),
          Positioned(top: 0, right: 0, child: Container(width: cornerWidth, height: cornerLen, color: color)),
          Positioned(bottom: 0, left: 0, child: Container(width: cornerLen, height: cornerWidth, color: color)),
          Positioned(bottom: 0, left: 0, child: Container(width: cornerWidth, height: cornerLen, color: color)),
          Positioned(bottom: 0, right: 0, child: Container(width: cornerLen, height: cornerWidth, color: color)),
          Positioned(bottom: 0, right: 0, child: Container(width: cornerWidth, height: cornerLen, color: color)),
        ],
      ),
    );
  }
}

// ── Bottom sheet succès ───────────────────────────────────────────────────────

class _ScanSuccessSheet extends StatelessWidget {
  final TerrainBookingModel booking;
  final VoidCallback onViewDetails;

  const _ScanSuccessSheet({
    required this.booking,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Véhicule identifié',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      Text(
                        'Notification envoyée au client ✓',
                        style: TextStyle(color: Colors.green, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _InfoRow(label: 'Immatriculation', value: booking.registrationNumber),
            _InfoRow(label: 'Véhicule', value: '${booking.vehicleBrand} ${booking.vehicleModel}'),
            _InfoRow(label: 'Client', value: booking.clientName),
            _InfoRow(label: 'Heure de passage', value: booking.slotTime),
            _InfoRow(label: 'Centre', value: booking.centerName ?? ''),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onViewDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Voir les détails',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
