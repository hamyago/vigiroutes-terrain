import 'package:dio/dio.dart';
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

  /// Traite un token QR scanné.
  ///
  /// Retourne true si le scan a réussi, false sinon.
  /// En cas d'erreur, remet _isScanning = true pour autoriser un nouveau scan.
  Future<bool> processScan(String qrToken) async {
    if (_isLoading) return false;
    _isLoading = true;
    _error = null;
    _isScanning = false; // pause le scanner pendant l'appel réseau
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
      // FIX #2 : après une erreur, on remet isScanning = true MAIS
      // le MobileScannerController doit aussi être relancé (géré dans scan_screen.dart).
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

  // FIX #2 : utiliser DioException typé pour avoir des messages précis.
  String _extractError(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode;
          if (code == 404) return 'QR code non reconnu ou réservation introuvable';
          if (code == 409) return 'Ce véhicule a déjà été scanné';
          if (code == 401 || code == 403) return 'Session expirée';
          return 'Erreur serveur ($code)';
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionError:
          return 'Pas de connexion réseau';
        default:
          break;
      }
    }
    final msg = e.toString();
    if (msg.contains('404')) return 'QR code non reconnu ou réservation introuvable';
    if (msg.contains('409')) return 'Ce véhicule a déjà été scanné';
    if (msg.contains('401') || msg.contains('403')) return 'Session expirée';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Pas de connexion réseau';
    }
    return 'Erreur lors du scan. Réessayez.';
  }
}
