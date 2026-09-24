import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/terrain_models.dart';
import '../../core/services/terrain_service.dart';
import '../booking/booking_detail_controller.dart';

class HomeController extends ChangeNotifier {
  List<TerrainBookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<TerrainBookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final TerrainService _service = TerrainService.instance;

  Future<void> loadBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _service.getTodayBookings();
      _bookings = list;
      _bookings.sort((a, b) => a.slotTime.compareTo(b.slotTime));
      // FIX : remplir le cache partagé pour que les écrans de détail
      // n'aient pas à refaire un appel réseau.
      BookingDetailController.populateCache(_bookings);
    } catch (e) {
      _error = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadBookings();

  void updateBooking(TerrainBookingModel updated) {
    final idx = _bookings.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      _bookings = List.from(_bookings)..[idx] = updated;
      notifyListeners();
    }
  }

  // FIX : utiliser DioException typé au lieu de string-matching sur e.toString().
  String _extractError(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Pas de connexion réseau';
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 401) {
            return 'Session expirée. Veuillez vous reconnecter.';
          }
          return 'Erreur serveur (${e.response?.statusCode})';
        case DioExceptionType.connectionError:
          return 'Pas de connexion réseau';
        default:
          break;
      }
    }
    final msg = e.toString();
    if (msg.contains('401')) return 'Session expirée. Veuillez vous reconnecter.';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Pas de connexion réseau';
    }
    return 'Erreur lors du chargement des réservations';
  }
}
