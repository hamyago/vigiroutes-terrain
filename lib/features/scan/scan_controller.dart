import 'package:flutter/foundation.dart';
import '../../core/models/terrain_models.dart';
import '../../core/services/api_error_helper.dart';
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

  /// Traite un token QR scanné.
  ///
  /// Retourne true si le scan a réussi, false sinon.
  /// En cas d'erreur, remet _isScanning = true pour autoriser un nouveau scan.
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
      _error = extractApiError(e, fallback: 'Erreur lors du scan. Réessayez.');
      _isLoading = false;
      _isScanning = true;
      notifyListeners();
      return false;
    }
  }

  /// Remet le scanner en état initial pour un nouveau scan.
  void reset() {
    _isScanning = true;
    _isLoading = false;
    _error = null;
    _scannedBooking = null;
    notifyListeners();
  }
}
