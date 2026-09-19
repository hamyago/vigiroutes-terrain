import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/models/terrain_models.dart';
import 'scan_controller.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _bottomSheetShown = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture, ScanController controller) {
    if (!controller.isScanning || controller.isLoading) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    final value = barcode.rawValue!;
    _handleScan(value, controller);
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
    return ChangeNotifierProvider(
      create: (_) => ScanController(),
      child: Builder(
        builder: (context) {
          final controller = context.watch<ScanController>();
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text('Scanner QR Code'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.flash_on),
                  onPressed: () => _cameraController.toggleTorch(),
                ),
              ],
            ),
            body: Stack(
              children: [
                MobileScanner(
                  controller: _cameraController,
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
            ),
          );
        },
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
    const cornerLen = 24.0;
    const cornerWidth = 3.0;
    const color = Color(0xFFFF6B35);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Top-left
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: cornerLen,
              height: cornerWidth,
              color: color,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: cornerWidth,
              height: cornerLen,
              color: color,
            ),
          ),
          // Top-right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: cornerLen,
              height: cornerWidth,
              color: color,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: cornerWidth,
              height: cornerLen,
              color: color,
            ),
          ),
          // Bottom-left
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: cornerLen,
              height: cornerWidth,
              color: color,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: cornerWidth,
              height: cornerLen,
              color: color,
            ),
          ),
          // Bottom-right
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: cornerLen,
              height: cornerWidth,
              color: color,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: cornerWidth,
              height: cornerLen,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
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
            _InfoRow(label: 'Centre', value: booking.centerName),
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
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
