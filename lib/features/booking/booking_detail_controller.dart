import 'package:flutter/foundation.dart';
import '../../core/models/terrain_models.dart';
import '../../core/services/api_error_helper.dart';
import '../../core/services/terrain_service.dart';

class BookingDetailController extends ChangeNotifier {
  TerrainBookingModel? _booking;
  bool _isLoading = false;
  String? _error;

  TerrainBookingModel? get booking => _booking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final TerrainService _service = TerrainService.instance;

  // Cache partagé entre tous les controllers (même session).
  static final Map<String, TerrainBookingModel> _cache = {};

  static void populateCache(List<TerrainBookingModel> bookings) {
    for (final b in bookings) {
      _cache[b.id] = b;
    }
  }

  static void updateCache(TerrainBookingModel booking) {
    _cache[booking.id] = booking;
  }

  /// ✅ Session 13.6 : invalide une entrée du cache.
  /// Utile après un scan QR pour forcer le rechargement du booking.
  static void invalidateCache(String id) {
    _cache.remove(id);
  }

  Future<void> loadBooking(String id) async {
    // 1. Cache hit → affichage immédiat, pas de loading.
    if (_cache.containsKey(id)) {
      _booking = _cache[id];
      notifyListeners();
      return;
    }

    // 2. Cache miss → on charge la liste du jour.
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final bookings = await _service.getTodayBookings();
      for (final b in bookings) {
        _cache[b.id] = b;
      }
      _booking = _cache[id];

      // 3. Si le booking n'est pas dans les réservations du jour, on essaie
      //    de le charger directement depuis l'API.
      if (_booking == null) {
        try {
          final single = await _service.getBookingById(id);
          _booking = single;
          _cache[id] = single;
        } catch (_) {
          _error = 'Réservation introuvable (hors planning du jour)';
        }
      }
    } catch (e) {
      _error = extractApiError(e,
          fallback: 'Erreur lors du chargement de la réservation');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Démarre l'inspection (statut backend : 'inspection_ongoing').
  ///
  /// ⚠️ Le statut envoyé au backend est déduit par le serveur lui-même,
  /// on ne fait que déclencher l'appel. Côté client, on met à jour
  /// localement avec le BON statut backend.
  Future<bool> startInspection() async {
    if (_booking == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.startInspection(_booking!.id);
      final updated = _booking!.copyWith(status: 'inspection_ongoing');
      _booking = updated;
      _cache[updated.id] = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = extractApiError(e,
          fallback: 'Erreur lors du démarrage du contrôle');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Soumet le rapport d'inspection final.
  ///
  /// Le backend renverra `status = 'completed'` + `vt_result = <resultat>`.
  /// Côté client, on met à jour localement avec status='completed'.
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
      // Le backend écrit status='completed' + vt_result=result.
      final updated = _booking!.copyWith(status: 'completed');
      _booking = updated;
      _cache[updated.id] = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = extractApiError(e,
          fallback: 'Erreur lors de la soumission du rapport');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
