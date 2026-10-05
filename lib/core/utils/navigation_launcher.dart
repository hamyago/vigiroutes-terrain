// lib/core/utils/navigation_launcher.dart
// ─────────────────────────────────────────────────────────────────────────────
// Helpers de navigation externe (Google Maps / Waze) + calcul de distance.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationLauncher {
  NavigationLauncher._();

  /// Ouvre Google Maps en mode itinéraire (pas juste le point).
  static Future<bool> openGoogleMapsDirections({
    required double destLat,
    required double destLng,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destLat,$destLng'
      '&travelmode=driving',
    );
    return _launchExternal(uri);
  }

  /// Ouvre Waze en navigation vers (lat,lng).
  /// Fallback Play Store si Waze n'est pas installé.
  static Future<bool> openWaze({
    required double destLat,
    required double destLng,
  }) async {
    final wazeUri = Uri.parse(
      'https://waze.com/ul?ll=$destLat,$destLng&navigate=yes',
    );

    try {
      if (await canLaunchUrl(wazeUri)) {
        final ok = await launchUrl(
          wazeUri,
          mode: LaunchMode.externalApplication,
        );
        if (ok) return true;
      }
    } catch (e) {
      debugPrint('[NavigationLauncher] Waze launch error: $e');
    }

    final storeUri = Uri.parse('market://details?id=com.waze');
    try {
      if (await canLaunchUrl(storeUri)) {
        return await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      }
      final webStore = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.waze',
      );
      return await launchUrl(webStore, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[NavigationLauncher] PlayStore launch error: $e');
      return false;
    }
  }

  /// Distance Haversine en km entre 2 points.
  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Récupère la position actuelle, gère permissions + service GPS.
  /// Retourne null si indisponible / refusé.
  static Future<Position?> getCurrentPositionSafe() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('[NavigationLauncher] getCurrentPositionSafe error: $e');
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Internes
  // ───────────────────────────────────────────────────────────────────────────

  static Future<bool> _launchExternal(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('[NavigationLauncher] launch error: $e');
      return false;
    }
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}