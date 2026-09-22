import 'package:flutter/foundation.dart';
import '../../core/models/terrain_models.dart';
import '../../core/services/terrain_service.dart';

class BookingDetailController extends ChangeNotifier {
  TerrainBookingModel? _booking;
  bool _isLoading = false;
  String? _error;

  TerrainBookingModel? get booking => _booking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final TerrainService _service = TerrainService.instance;

  // In-memory cache shared across controllers
  static final Map<String, TerrainBookingModel> _cache = {};

  static void populateCache(List<TerrainBookingModel> bookings) {
    for (final b in bookings) {
      _cache[b.id] = b;
    }
  }

  Future<void> loadBooking(String id) async {
    if (_cache.containsKey(id)) {
      _booking = _cache[id];
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final bookings = await _service.getTodayBookings();
      for (final b in bookings) {
        _cache[b.id] = b;
      }
      _booking = _cache[id];
      if (_booking == null) {
        _error = 'Réservation introuvable';
      }
    } catch (e) {
      _error = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startInspection() async {
    if (_booking == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.startInspection(_booking!.id);
      final updated = _booking!.copyWith(status: 'in_progress');
      _booking = updated;
      _cache[updated.id] = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitReport({
    required String result,
    String? nonConformity,
    String? recommendations,
    String? nextVtDate,
    required String pvNumber,
  }) async {
    if (_booking == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final reportData = {
        'result': result,
        if (nonConformity != null && nonConformity.isNotEmpty)
          'non_conformity_points': nonConformity,
        if (recommendations != null && recommendations.isNotEmpty)
          'recommendations': recommendations,
        if (nextVtDate != null && nextVtDate.isNotEmpty)
          'next_vt_date': nextVtDate,
        'pv_number': pvNumber,
      };
      await _service.submitReport(_booking!.id, reportData);
      final updated = _booking!.copyWith(status: 'completed');
      _booking = updated;
      _cache[updated.id] = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _extractError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Session expirée';
    if (msg.contains('422')) return 'Données invalides. Vérifiez les champs.';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Pas de connexion réseau';
    }
    return 'Une erreur est survenue';
  }
}
