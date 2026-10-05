// lib/features/transport/transport_missions_controller.dart
// ─────────────────────────────────────────────────────────────────────────────
// Controller pour la liste des missions transport CT.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/terrain_models.dart';
import '../../core/services/terrain_service.dart';
import '../../core/utils/navigation_launcher.dart';

class TransportMissionsController extends ChangeNotifier {
  List<TransportMissionModel> _missions = [];
  bool _isLoading = false;
  String? _error;
  double? _currentLat;
  double? _currentLng;
  bool _sortByDistance = true;

  List<TransportMissionModel> get missions => _missions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get currentLat => _currentLat;
  double? get currentLng => _currentLng;
  bool get sortByDistance => _sortByDistance;

  final TerrainService _service = TerrainService.instance;

  Future<void> loadMissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // S14 : récupérer la position actuelle si tri par distance
      if (_sortByDistance && _currentLat == null) {
        await _refreshPosition();
      }

      final list = await _service.getTransportMissions(
        lat: _currentLat,
        lng: _currentLng,
        sort: _sortByDistance ? 'distance' : 'slot',
      );

      // Tri secondaire : slot si pas de distance
      if (!_sortByDistance) {
        list.sort((a, b) {
          if (a.slotStartsAt == null) return 1;
          if (b.slotStartsAt == null) return -1;
          return a.slotStartsAt!.compareTo(b.slotStartsAt!);
        });
      }
      _missions = list;
    } catch (e) {
      _error = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère la position GPS actuelle (silencieux si refus).
  Future<void> _refreshPosition() async {
    final pos = await NavigationLauncher.getCurrentPositionSafe();
    if (pos != null) {
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
    }
  }

  /// Force le rafraîchissement de la position + recharge.
  Future<void> refreshPosition() async {
    await _refreshPosition();
    await loadMissions();
  }

  /// Bascule le mode de tri.
  void toggleSortMode() {
    _sortByDistance = !_sortByDistance;
    notifyListeners();
    loadMissions();
  }

  Future<void> refresh() => loadMissions();

  /// Met à jour une mission dans la liste locale (après un scan).
  void updateMission(TransportMissionModel updated) {
    final idx = _missions.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      _missions = List.from(_missions)..[idx] = updated;
      notifyListeners();
    }
  }

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
          return 'Erreur serveur ($code)';
        default:
          break;
      }
    }
    return 'Erreur lors du chargement des missions';
  }
}
