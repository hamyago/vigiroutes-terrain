import 'package:flutter/foundation.dart';
import '../../core/models/terrain_models.dart';
import '../../core/services/terrain_service.dart';

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
      // Populate in-memory cache for detail screens
      _bookings.sort((a, b) => a.slotTime.compareTo(b.slotTime));
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

  String _extractError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Session expirée. Veuillez vous reconnecter.';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Pas de connexion réseau';
    }
    return 'Erreur lors du chargement des réservations';
  }
}
