// lib/core/services/alert_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Service d'alerte sonore + vocale pour les missions transport CT.
//
// Comportement (inspiré du ProviderAlertService de l'app Pro) :
//   1. Joue alarm.wav en boucle (attire l'attention)
//   2. Énonce les détails de la mission en TTS
//   3. Répète une 2e fois après 4s
//
// Usage :
//   TerrainAlertService.instance.newMission(
//     missionId  : 'VT-XXXX',
//     reference  : 'VT-XXXX',
//     clientName : 'Yago Hamede',
//     address    : 'Yopougon, Abidjan',
//     transportMode: 'tow',
//   );
//   ...
//   TerrainAlertService.instance.stop();
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TerrainAlertService {
  TerrainAlertService._();
  static final instance = TerrainAlertService._();

  final _player = AudioPlayer();
  final _tts = FlutterTts();

  String? _ringingMissionId;
  bool _ttsReady = false;

  // ── Initialisation TTS (appelée une fois au démarrage) ─────────────────

  Future<void> init() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Warm-up silencieux (certains moteurs ont besoin de ça)
      await _tts.speak(' ');
      await _tts.stop();
    } catch (e) {
      debugPrint('[TerrainAlert] TTS init KO : $e');
    }

    // Précharger alarm.wav pour éviter 3-5s de latence au 1er dispatch
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setSource(AssetSource('raw/alarm.wav'));
      await _player.setVolume(1.0);
    } catch (e) {
      debugPrint('[TerrainAlert] Impossible de précharger alarm.wav : $e');
    }

    _ttsReady = true;
  }

  // ── Déclenchement alerte ───────────────────────────────────────────────

  /// Lance l'alarme sonore en boucle + annonce vocale de la mission.
  ///
  /// [missionId]    : identifiant unique de la mission (évite les doublons).
  /// [reference]    : référence lisible (VT-XXXX).
  /// [clientName]   : nom du client.
  /// [address]      : adresse de récupération du véhicule.
  /// [transportMode]: 'tow' ou 'driver'.
  Future<void> newMission({
    required String missionId,
    String? reference,
    String? clientName,
    String? address,
    String? transportMode,
  }) async {
    // Idempotent : on ne re-sonne pas pour la même mission.
    if (_ringingMissionId == missionId) return;
    _ringingMissionId = missionId;

    // ── 1. Alarme sonore en boucle ────────────────────────────────────────
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.resume(); // utilise la source préchargée
    } catch (_) {
      try {
        await _player.play(AssetSource('raw/alarm.wav'));
      } catch (_) {}
    }

    // ── 2. Annonce vocale ────────────────────────────────────────────────
    await Future.delayed(const Duration(milliseconds: 300));
    await _speakDetails(
      reference: reference,
      clientName: clientName,
      address: address,
      transportMode: transportMode,
    );
  }

  // ── Arrêt ──────────────────────────────────────────────────────────────

  Future<void> stop() async {
    _ringingMissionId = null;
    await _player.stop();
    await _tts.stop();
  }

  // ── Lecture vocale ─────────────────────────────────────────────────────

  Future<void> _speakDetails({
    String? reference,
    String? clientName,
    String? address,
    String? transportMode,
  }) async {
    if (!_ttsReady) {
      await init();
    }

    final parts = <String>['Nouvelle mission CT !'];

    if (reference != null && reference.trim().isNotEmpty) {
      parts.add('Référence : ${reference.trim()}.');
    }

    if (transportMode != null && transportMode.trim().isNotEmpty) {
      final mode = transportMode == 'tow' ? 'remorquage' : 'chauffeur';
      parts.add('Type : $mode.');
    }

    if (address != null && address.trim().isNotEmpty) {
      parts.add('Récupération à ${address.trim()}.');
    }

    if (clientName != null && clientName.trim().isNotEmpty) {
      parts.add('Client : ${clientName.trim()}.');
    }

    parts.add('Ouvrez l\'application pour accepter la mission.');

    final fullText = parts.join(' ');

    try {
      await _tts.speak(fullText);

      // Répète après 4s si toujours en cours
      await Future.delayed(const Duration(seconds: 4));
      if (_ringingMissionId != null) {
        await _tts.speak(fullText);
      }
    } catch (_) {
      // TTS non disponible → alarme seule suffit.
    }
  }
}
