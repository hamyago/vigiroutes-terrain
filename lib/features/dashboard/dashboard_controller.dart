import 'package:flutter/foundation.dart';
import '../../core/models/terrain_models.dart';
import '../../core/services/terrain_service.dart';

class DashboardController extends ChangeNotifier {
  TerrainStatsModel? _stats;
  bool _isLoading = false;
  String? _error;

  TerrainStatsModel? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final TerrainService _service = TerrainService();

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getDashboardStats();
      final statsData = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data;
      _stats = TerrainStatsModel.fromJson(statsData);
    } catch (e) {
      _error = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Session expirée';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Pas de connexion réseau';
    }
    return 'Erreur lors du chargement des statistiques';
  }
}
