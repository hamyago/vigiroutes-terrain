import 'package:vigiroutes_terrain/services/api_service.dart';
import 'package:vigiroutes_terrain/modules/ct/terrain_models_updated.dart';

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
  ///
  /// Returns a raw map with keys:
  ///   - `success` (bool)
  ///   - `booking` (Map?) — booking data when success is true
  ///   - `message` (String?) — error or info message
  Future<Map<String, dynamic>> scanQr(String token) async {
    final response = await ApiService.instance.post(
      '/v1/terrain/scan-qr',
      body: {'token': token},
    );
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  /// Submit the final inspection report for a booking.
  ///
  /// [result] must be one of: favorable, defavorable, contre_visite
  /// [reportNotes] optional free-text notes from the terrain agent.
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
  ///
  /// [date] optional date filter in YYYY-MM-DD format. Defaults to today
  ///   on the server when omitted.
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
