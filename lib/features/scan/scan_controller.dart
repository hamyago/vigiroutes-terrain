import 'package:flutter/foundation.dart';
import '../../core/models/terrain_models.dart';
import '../../core/services/terrain_service.dart';

class ScanController extends ChangeNotifier {
  bool _isScanning = true;
  bool _isLoading = false;
  String? _error;
  TerrainBookingModel? _scannedBooking;

  bool get isScanning => _isScanning;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TerrainBookingModel? get scannedBooking => _scannedBooking;

  final TerrainService _service = TerrainService.instance;

  Future<bool> processScan(String qrToken) async {
    if (_isLoading) return false;
    _isLoading = true;
    _error = null;
    _isScanning = false;
    notifyListeners();
    try {
      final booking = await _service.scanQr(qrToken);
      _scannedBooking = booking;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      _isScanning = true;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _isScanning = true;
    _isLoading = false;
    _error = null;
    _scannedBooking = null;
    notifyListeners();
  }

  String _extractError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('404')) return 'QR code non reconnu ou réservation introuvable';
    if (msg.contains('409')) return 'Ce véhicule a déjà été scanné';
    if (msg.contains('401')) return 'Session expirée';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Pas de connexion réseau';
    }
    return 'Erreur lors du scan. Réessayez.';
  }
}
