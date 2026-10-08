// lib/features/transport/vehicle_photos_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// Écran de prise de photos du véhicule (S16.1).
//
// Contexte : après scan QR (pickup ou livraison), le transporteur doit
// photographier 4 côtés du véhicule (avant, arrière, gauche, droite).
// Les photos sont obligatoires et immuables.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/terrain_service.dart';

/// Couleurs du projet Terrain (hardcodées, cohérent avec les autres écrans)
const _kPrimary    = Color(0xFFFF6B35);
const _kBackground = Color(0xFFF8F8F8);
const _kBorder     = Color(0xFFE0E0E0);
const _kTextMuted  = Color(0xFF9E9E9E);
const _kSuccess    = Color(0xFF43A047);
const _kWarning    = Color(0xFFF9A825);
const _kError      = Color(0xFFE53935);

class VehiclePhotosScreen extends StatefulWidget {
  final String missionId;

  /// 'pickup' (avant transport) | 'delivery' (après livraison)
  final String context;

  const VehiclePhotosScreen({
    super.key,
    required this.missionId,
    required this.context,
  });

  @override
  State<VehiclePhotosScreen> createState() => _VehiclePhotosScreenState();
}

class _VehiclePhotosScreenState extends State<VehiclePhotosScreen> {
  /// 4 slots → chemin de fichier local (null si pas encore pris)
  final Map<String, String?> _photos = {
    'front': null,
    'back': null,
    'left': null,
    'right': null,
  };

  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  String? _error;

  int get _photoCount => _photos.values.where((p) => p != null).length;
  bool get _allPhotosTaken => _photoCount == 4;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitWarning();
      },
      child: Scaffold(
        backgroundColor: _kBackground,
        appBar: AppBar(
          title: Text(
            widget.context == 'pickup'
                ? 'Photos avant transport'
                : 'Photos après livraison',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Fermer',
            onPressed: _uploading ? null : _showExitWarning,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _allPhotosTaken
                        ? _kSuccess.withValues(alpha: 0.15)
                        : _kWarning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_photoCount / 4',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _allPhotosTaken ? _kSuccess : _kWarning,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: _kPrimary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Photographiez les 4 côtés du véhicule. '
                          'Ces photos serviront de preuve en cas de litige.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildSlot('front', 'Avant', Icons.directions_car),
                    _buildSlot('back',  'Arrière', Icons.directions_car_filled),
                    _buildSlot('left',  'Gauche', Icons.arrow_back),
                    _buildSlot('right', 'Droite', Icons.arrow_forward),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kError.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: _kError),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_allPhotosTaken && !_uploading)
                        ? _onValidate
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _uploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _allPhotosTaken
                                ? 'Valider les photos'
                                : 'Prenez les 4 photos',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlot(String slot, String label, IconData icon) {
    final filePath = _photos[slot];
    final hasPhoto = filePath != null;

    return GestureDetector(
      onTap: _uploading ? null : () => _takePhoto(slot),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPhoto ? _kSuccess : _kBorder,
            width: hasPhoto ? 2 : 1,
          ),
        ),
        child: hasPhoto
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(filePath), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: _kSuccess,
                        size: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: _kTextMuted),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Appuyer pour prendre',
                    style: TextStyle(fontSize: 11, color: _kTextMuted),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _takePhoto(String slot) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (file == null) return;

      setState(() {
        _photos[slot] = file.path;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Erreur caméra : $e');
    }
  }

  Future<void> _onValidate() async {
    setState(() {
      _uploading = true;
      _error = null;
    });

    final service = TerrainService.instance;

    for (final entry in _photos.entries) {
      final slot = entry.key;
      final path = entry.value;
      if (path == null) continue;

      final ok = await service.uploadVehiclePhoto(
        missionId: widget.missionId,
        slot: slot,
        filePath: path,
      );

      if (!ok) {
        if (!mounted) return;
        setState(() {
          _uploading = false;
          _error = 'Échec de l\'upload de la photo "$slot". Réessayez.';
        });
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showExitWarning() {
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Photos obligatoires'),
        content: const Text(
          'Vous devez prendre les 4 photos du véhicule avant de continuer. '
          'Ces photos servent de preuve en cas de litige.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: const Text('Continuer les photos'),
          ),
        ],
      ),
    );
  }
}
