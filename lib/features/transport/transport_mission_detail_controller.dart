// lib/features/transport/transport_mission_detail_controller.dart
// ─────────────────────────────────────────────────────────────────────────────
// Controller pour le détail d'une mission transport.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/terrain_models.dart';
import '../../core/services/terrain_service.dart';

class TransportMissionDetailController extends ChangeNotifier {
  TransportMissionModel? _mission;
  bool _isLoading = false;
  String? _error;

  TransportMissionModel? get mission => _mission;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final TerrainService _service = TerrainService.instance;

  Future<void> loadMission(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _mission = await _service.getTransportMissionById(id);
    } catch (e) {
      _error = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markEnRoute() async {
    if (_mission == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _mission = await _service.markEnRoute(_mission!.id);
      return true;
    } catch (e) {
      _error = _extractError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> scan({
    required String scanType,
    required String token,
  }) async {
    if (_mission == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _mission = await _service.scanTransport(
        _mission!.id,
        scanType: scanType,
        token: token,
      );
      return true;
    } catch (e) {
      _error = _extractError(e);
      return false;
    } finally {
      _isLoading = false;
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
          if (code == 404) return 'Mission introuvable';
          if (code == 409) return 'Étape déjà validée';
          if (code == 422) return 'QR code invalide ou étape incorrecte';
          return 'Erreur serveur ($code)';
        default:
          break;
      }
    }
    return 'Une erreur est survenue';
  }
}
