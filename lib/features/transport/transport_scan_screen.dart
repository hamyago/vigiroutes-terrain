import 'package:dio/dio.dart';
// lib/features/transport/transport_scan_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// Écran de scan QR pour les missions transport (4 étapes).
// Utilise le même système que l'app Terrain (mobile_scanner).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/terrain_service.dart';
import '../../core/services/snackbar_helper.dart';
class TransportScanScreen extends StatefulWidget {
  final String missionId;
  final String scanType; // 'pickup' | 'delivery' | 'return' | 'final'
  final String title;

  const TransportScanScreen({
    super.key,
    required this.missionId,
    required this.scanType,
    required this.title,
  });

  @override
  State<TransportScanScreen> createState() => _TransportScanScreenState();
}

class _TransportScanScreenState extends State<TransportScanScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _cameraController;
  bool _permissionChecked = false;
  bool _permissionGranted = false;
  bool _isProcessing = false;

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
    if (status.isGranted) _initCamera();
  }

  void _initCamera() {
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
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
        if (!_isProcessing) ctrl.start();
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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final token = barcode.rawValue!.trim();
    if (token.isEmpty) return;

    _isProcessing = true;
    _cameraController?.stop();
    setState(() {});

    try {
      debugPrint('[Scan] Token scanné (longueur=${token.length}) : ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
      debugPrint('[Scan] Mission ID : ${widget.missionId}');
      debugPrint('[Scan] Scan type : ${widget.scanType}');

      await TerrainService.instance.scanTransport(
        widget.missionId,
        scanType: widget.scanType,
        token: token,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Extraire le message d'erreur le plus clair possible
      String message = 'Erreur lors du scan. Réessayez.';

      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          final backendMsg = data['message'] ?? data['error'];
          if (backendMsg != null && backendMsg.toString().trim().isNotEmpty) {
            message = backendMsg.toString();
          }
        } else if (e.response?.statusCode == 422) {
          message = 'QR code refusé. Vérifiez le véhicule scanné.';
        } else if (e.response?.statusCode == 404) {
          message = 'Mission introuvable. Actualisez la liste.';
        } else if (e.response?.statusCode == 500) {
          message = 'Problème technique côté serveur. Contactez le support.';
        } else if (e.type == DioExceptionType.connectionTimeout ||
                   e.type == DioExceptionType.receiveTimeout ||
                   e.type == DioExceptionType.connectionError) {
          message = 'Pas de connexion réseau. Vérifiez votre connexion.';
        }
      } else {
        message = 'Erreur : ${e.toString()}';
      }

      showAppSnackBar(
        context,
        message,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
      _cameraController?.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          if (_cameraController != null)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => _cameraController!.toggleTorch(),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_permissionChecked) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    if (!_permissionGranted) {
      return _PermissionWidget(
        onRetry: () async {
          final status = await Permission.camera.request();
          if (!mounted) return;
          if (status.isGranted) {
            setState(() => _permissionGranted = true);
            _initCamera();
          } else if (status.isPermanentlyDenied) {
            openAppSettings();
          }
        },
      );
    }

    if (_cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _cameraController!,
          onDetect: _onDetect,
        ),
        _ScanOverlay(),
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  SizedBox(height: 16),
                  Text(
                    'Traitement en cours…',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        if (!_isProcessing)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Placez le QR code dans le cadre',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PermissionWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                size: 72, color: Colors.white38),
            const SizedBox(height: 24),
            const Text(
              'Permission caméra requise',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Autoriser la caméra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    const cornerLen = 28.0;
    const cornerWidth = 3.5;
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
