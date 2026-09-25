import 'package:dio/dio.dart';
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

      // FIX #4 : TerrainDashboardModel ne contient pas weekTotal / monthTotal /
      // contreVisiteRate car le backend ne les expose pas encore dans /terrain/stats.
      // On calcule ce qu'on peut depuis les champs disponibles, et on met 0 pour
      // les champs manquants plutôt que de laisser des valeurs incohérentes.
      //
      // À faire côté backend Laravel : ajouter week_total, month_total,
      // contre_visite dans la réponse de GET /terrain/stats.
      final total = dashboard.totalExpectedToday;
      final completed = dashboard.favorable + dashboard.defavorable;
      // On déduit contre_visite = arrived - favorable - defavorable (approximation
      // jusqu'à ce que le backend l'expose directement).
      final contreVisite = (dashboard.arrived - completed).clamp(0, total);

      _stats = TerrainStatsModel(
        todayTotal: total,
        todayCompleted: completed,
        todayPending: total - dashboard.arrived,
        weekTotal: dashboard.myScansToday,   // approximation temporaire
        monthTotal: dashboard.myReportsToday, // approximation temporaire
        pendingNow: (total - dashboard.arrived).clamp(0, total),
        favorableRate: total > 0 ? (dashboard.favorable / total).clamp(0.0, 1.0) : 0.0,
        defavorableRate: total > 0 ? (dashboard.defavorable / total).clamp(0.0, 1.0) : 0.0,
        contreVisiteRate: total > 0 ? (contreVisite / total).clamp(0.0, 1.0) : 0.0,
      );
    } catch (e) {
      _error = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
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
          return 'Erreur serveur ($code)';
        default:
          break;
      }
    }
    final msg = e.toString();
    if (msg.contains('401')) return 'Session expirée';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Pas de connexion réseau';
    }
    return 'Erreur lors du chargement des statistiques';
  }
}
