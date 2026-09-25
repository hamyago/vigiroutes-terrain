import 'package:dio/dio.dart';
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

  // Cache partagé entre tous les controllers (même session).
  static final Map<String, TerrainBookingModel> _cache = {};

  static void populateCache(List<TerrainBookingModel> bookings) {
    for (final b in bookings) {
      _cache[b.id] = b;
    }
  }

  // Permet la mise à jour du cache depuis l'extérieur (ex: après scan).
  static void updateCache(TerrainBookingModel booking) {
    _cache[booking.id] = booking;
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

      // FIX #3 : Si le booking n'est pas dans les réservations du jour
      // (notification tardive, booking d'hier), on essaie de le charger
      // directement depuis l'API plutôt que d'afficher une erreur muette.
      if (_booking == null) {
        try {
          // Cet endpoint est à créer côté backend : GET /terrain/bookings/{id}
          final single = await _service.getBookingById(id);
          _booking = single;
          _cache[id] = single;
        } catch (_) {
          // Si l'endpoint n'existe pas encore, on affiche le message d'erreur clair.
          _error = 'Réservation introuvable (hors planning du jour)';
        }
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
      // On met à jour avec le résultat réel (favorable / defavorable / contre_visite).
      final updated = _booking!.copyWith(status: result);
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

  // FIX : utiliser DioException typé.
  String _extractError(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionError:
          return 'Pas de connexion réseau';
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode;
          if (code == 401) return 'Session expirée';
          if (code == 422) return 'Données invalides. Vérifiez les champs.';
          if (code == 404) return 'Réservation introuvable';
          return 'Erreur serveur ($code)';
        default:
          break;
      }
    }
    final msg = e.toString();
    if (msg.contains('401')) return 'Session expirée';
    if (msg.contains('422')) return 'Données invalides. Vérifiez les champs.';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Pas de connexion réseau';
    }
    return 'Une erreur est survenue';
  }
}
