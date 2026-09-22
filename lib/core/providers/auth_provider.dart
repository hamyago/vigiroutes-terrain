import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/terrain_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = true;
  String? _error;
  bool _isAuthenticated = false;
  String? _agentName;
  String? _centerName;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String? get agentName => _agentName;
  String? get centerName => _centerName;

  final TerrainService _service = TerrainService.instance;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('sanctum_token');
      if (token != null && token.isNotEmpty) {
        _agentName = prefs.getString('agent_name');
        _centerName = prefs.getString('center_name');
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (_) {
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.login(email, password);
      final token = result['token']?.toString() ?? result['access_token']?.toString() ?? '';
      if (token.isEmpty) {
        _error = 'Token manquant dans la réponse';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sanctum_token', token);

      final agentData = result['agent'] as Map<String, dynamic>?;
      _agentName = agentData?['name']?.toString() ??
          agentData?['full_name']?.toString() ??
          result['name']?.toString() ?? '';
      final ctPartner = agentData?['ct_partner'] as Map<String, dynamic>?;
      _centerName = agentData?['center_name']?.toString() ??
          ctPartner?['name']?.toString() ??
          result['center_name']?.toString() ?? '';

      await prefs.setString('agent_name', _agentName ?? '');
      await prefs.setString('center_name', _centerName ?? '');

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sanctum_token');
    await prefs.remove('agent_name');
    await prefs.remove('center_name');
    _isAuthenticated = false;
    _agentName = null;
    _centerName = null;
    notifyListeners();
  }

  String _extractError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('Unauthorized')) {
      return 'Email ou mot de passe incorrect';
    }
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Impossible de se connecter au serveur';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
