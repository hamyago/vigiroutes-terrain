import 'package:vigiroutes_terrain/services/api_service.dart';
import '../../core/models/terrain_models.dart';

class TerrainService {
  static final TerrainService instance = TerrainService._();
  TerrainService._();

  /// Fetch all bookings scheduled for today at this agent's assigned center.
  Future<List<TerrainBookingModel>> getTodayBookings() async {
    final response = await ApiService.instance.get('/v1/terrain/today-bookings');
    final List data = response['data'] as List? ?? [];
    return data
        .map((e) => TerrainBookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Scan a client QR code token.
  /// Returns the booking on success, throws on error.
  Future<TerrainBookingModel> scanQr(String token) async {
    final response = await ApiService.instance.post(
      '/v1/terrain/scan-qr',
      body: {'token': token},
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      // Response peut contenir directement le booking ou un objet {booking: {...}}
      final bookingMap = data.containsKey('booking')
          ? data['booking'] as Map<String, dynamic>
          : data;
      return TerrainBookingModel.fromJson(bookingMap);
    }
    throw Exception('Réponse inattendue du serveur');
  }

  /// Submit the final inspection report for a booking.
  /// [result] must be one of: favorable, defavorable, contre_visite
  Future<void> submitFinalReport(
    String bookingId, {
    required String result,
    String? reportNotes,
  }) async {
    await ApiService.instance.post(
      '/v1/terrain/bookings/$bookingId/final-report',
      body: {
        'result': result,
        if (reportNotes != null) 'report_notes': reportNotes,
      },
    );
  }

  /// Fetch dashboard statistics for the terrain agent.
  Future<TerrainDashboardModel> getDashboard({String? date}) async {
    final response = await ApiService.instance.get(
      '/v1/terrain/dashboard',
      queryParams: date != null ? {'date': date} : null,
    );
    return TerrainDashboardModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }
}
