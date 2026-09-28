// lib/features/transport/transport_missions_controller.dart
// ─────────────────────────────────────────────────────────────────────────────
// Controller pour la liste des missions transport CT.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/terrain_models.dart';
import '../../core/services/terrain_service.dart';

class TransportMissionsController extends ChangeNotifier {
  List<TransportMissionModel> _missions = [];
  bool _isLoading = false;
  String? _error;

  List<TransportMissionModel> get missions => _missions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final TerrainService _service = TerrainService.instance;

  Future<void> loadMissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _service.getTransportMissions();
      // Tri par date de créneau (les plus proches en premier)
      list.sort((a, b) {
        if (a.slotStartsAt == null) return 1;
        if (b.slotStartsAt == null) return -1;
        return a.slotStartsAt!.compareTo(b.slotStartsAt!);
      });
      _missions = list;
    } catch (e) {
      _error = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
