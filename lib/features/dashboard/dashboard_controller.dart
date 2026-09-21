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

  final TerrainService _service = TerrainService.instance;

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final dashboard = await _service.getDashboard();
      _stats = TerrainStatsModel(
        todayTotal: dashboard.totalExpectedToday,
        todayCompleted: dashboard.arrived,
        todayPending: dashboard.totalExpectedToday - dashboard.arrived,
        weekTotal: 0,
        monthTotal: 0,
        pendingNow: dashboard.totalExpectedToday - dashboard.arrived,
        favorableRate: dashboard.totalExpectedToday > 0
            ? dashboard.favorable / dashboard.totalExpectedToday
            : 0.0,
        defavorableRate: dashboard.totalExpectedToday > 0
            ? dashboard.defavorable / dashboard.totalExpectedToday
            : 0.0,
        contreVisiteRate: 0.0,
      );
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
