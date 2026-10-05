// lib/features/transport/transport_mission_detail_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// Écran de détail d'une mission transport.
// Affiche les infos + l'action à faire (scan QR, en route, retour).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/terrain_models.dart';
import '../../core/utils/navigation_launcher.dart';
import 'transport_mission_detail_controller.dart';
import 'transport_scan_screen.dart';

class TransportMissionDetailScreenWrapper extends StatelessWidget {
  final String missionId;
  const TransportMissionDetailScreenWrapper({super.key, required this.missionId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransportMissionDetailController()..loadMission(missionId),
      child: const TransportMissionDetailScreen(),
    );
  }
}

class TransportMissionDetailScreen extends StatelessWidget {
  const TransportMissionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TransportMissionDetailController>();
    const primary = Color(0xFFFF6B35);

    if (ctrl.isLoading && ctrl.mission == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }
    if (ctrl.mission == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mission')),
        body: Center(child: Text(ctrl.error ?? 'Mission introuvable')),
      );
    }

    final m = ctrl.mission!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.reference),
            Text(
              m.transportMode == 'tow' ? '🚛 Remorquage' : '🧑‍✈️ Chauffeur',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusCard(mission: m),
            const SizedBox(height: 16),
            _VehicleCard(mission: m),
            const SizedBox(height: 16),
            _ClientCard(mission: m),
            const SizedBox(height: 16),
            _CenterCard(mission: m),
            const SizedBox(height: 16),
            _TimelineCard(mission: m),
            const SizedBox(height: 16),
            _ActionButton(ctrl: ctrl, mission: m),
            if (ctrl.error != null) ...[
              const SizedBox(height: 12),
              Text(
                ctrl.error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cards
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final TransportMissionModel mission;
  const _StatusCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.stepLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mission.nextActionLabel,
                  style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _style() {
    switch (mission.transporterStatus) {
      case 'pending':
        return (Colors.grey, Icons.schedule);
      case 'en_route_to_client':
        return (Colors.blue, Icons.directions_car);
      case 'picked_up':
        return (Colors.orange, Icons.inventory_2_outlined);
      case 'delivered_to_center':
        return (Colors.green, Icons.check_circle_outline);
      case 'return_en_route':
        return (Colors.blue, Icons.undo);
      case 'delivered_to_client':
        return (Colors.green, Icons.check_circle);
      default:
        return (Colors.grey, Icons.info_outline);
    }
  }
}

class _VehicleCard extends StatelessWidget {
  final TransportMissionModel mission;
  const _VehicleCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return _Card(
      icon: Icons.directions_car,
      title: 'Véhicule',
      children: [
        _InfoRow(label: 'Immatriculation', value: mission.registrationNumber, bold: true),
        _InfoRow(label: 'Marque', value: mission.vehicleBrand),
        _InfoRow(label: 'Modèle', value: mission.vehicleModel),
        if (mission.vehicleColor != null) _InfoRow(label: 'Couleur', value: mission.vehicleColor!),
        if (mission.slotStartsAt != null)
          _InfoRow(label: 'Créneau', value: mission.slotTime),
      ],
    );
  }
}

class _ClientCard extends StatefulWidget {
  final TransportMissionModel mission;
  const _ClientCard({required this.mission});

  @override
  State<_ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<_ClientCard> {
  double? _distanceKm;
  bool _locating = false;
  bool _locationUnavailable = false;

  TransportMissionModel get mission => widget.mission;

  @override
  void initState() {
    super.initState();
    _computeDistance();
  }

  Future<void> _computeDistance() async {
    final lat = mission.clientLat;
    final lng = mission.clientLng;
    if (lat == null || lng == null) return;

    setState(() => _locating = true);
    final pos = await NavigationLauncher.getCurrentPositionSafe();
    if (!mounted) return;

    if (pos == null) {
      setState(() {
        _locating = false;
        _locationUnavailable = true;
      });
      return;
    }

    final km = NavigationLauncher.haversineKm(
      pos.latitude,
      pos.longitude,
      lat,
      lng,
    );
    setState(() {
      _distanceKm = km;
      _locating = false;
      _locationUnavailable = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasCoords = mission.clientLat != null && mission.clientLng != null;

    return _Card(
      icon: Icons.person_outline,
      title: 'Client',
      children: [
        if (mission.clientName != null)
          _InfoRow(label: 'Nom', value: mission.clientName!),
        if (mission.clientPhone != null)
          _InfoRow(label: 'Téléphone', value: mission.clientPhone!),
        if (mission.clientAddress != null)
          _InfoRow(label: 'Adresse', value: mission.clientAddress!),

        if (hasCoords) ...[
          const SizedBox(height: 10),
          _buildDistanceBanner(),
        ],

        if (mission.clientPhone != null || hasCoords) ...[
          const SizedBox(height: 10),
          if (mission.clientPhone != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _call(mission.clientPhone!),
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('Appeler'),
              ),
            ),
          if (hasCoords) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => NavigationLauncher.openGoogleMapsDirections(
                      destLat: mission.clientLat!,
                      destLng: mission.clientLng!,
                    ),
                    icon: const Icon(Icons.navigation, size: 16),
                    label: const Text('Maps'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => NavigationLauncher.openWaze(
                      destLat: mission.clientLat!,
                      destLng: mission.clientLng!,
                    ),
                    icon: const Icon(Icons.directions_car, size: 16),
                    label: const Text('Waze'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDistanceBanner() {
    if (_locating) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Calcul de la distance…',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
      );
    }

    if (_locationUnavailable) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Position actuelle indisponible',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _computeDistance,
              child: const Text('Réessayer', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (_distanceKm != null) {
      final txt = _distanceKm! < 1
          ? '${(_distanceKm! * 1000).round()} m'
          : '${_distanceKm!.toStringAsFixed(1)} km';
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.route, size: 16, color: Color(0xFFFF6B35)),
            const SizedBox(width: 8),
            Text(
              'À $txt de vous',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _CenterCard extends StatelessWidget {
  final TransportMissionModel mission;
  const _CenterCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return _Card(
      icon: Icons.business,
      title: 'Centre CT',
      children: [
        if (mission.centerName != null) _InfoRow(label: 'Nom', value: mission.centerName!),
        if (mission.centerAddress != null)
          _InfoRow(label: 'Adresse', value: mission.centerAddress!),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final TransportMissionModel mission;
  const _TimelineCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return _Card(
      icon: Icons.timeline,
      title: 'Progression',
      children: [
        _TimelineStep(
          label: 'En route',
          done: mission.transporterEnRouteAt != null,
          time: _fmt(mission.transporterEnRouteAt),
        ),
        _TimelineStep(
          label: 'Récupéré chez client',
          done: mission.transporterPickedUpAt != null,
          time: _fmt(mission.transporterPickedUpAt),
        ),
        _TimelineStep(
          label: 'Livré au centre',
          done: mission.transporterDeliveredAt != null,
          time: _fmt(mission.transporterDeliveredAt),
        ),
        _TimelineStep(
          label: 'Retour démarré',
          done: mission.transporterReturnStartedAt != null,
          time: _fmt(mission.transporterReturnStartedAt),
        ),
        _TimelineStep(
          label: 'Livré au client',
          done: mission.transporterReturnedAt != null,
          time: _fmt(mission.transporterReturnedAt),
          last: true,
        ),
      ],
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return '--:--';
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool done;
  final String time;
  final bool last;

  const _TimelineStep({
    required this.label,
    required this.done,
    required this.time,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? Colors.green : Colors.grey[300],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: done ? Colors.black87 : Colors.grey,
                fontWeight: done ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: done ? Colors.black54 : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final TransportMissionDetailController ctrl;
  final TransportMissionModel mission;

  const _ActionButton({required this.ctrl, required this.mission});

  @override
  Widget build(BuildContext context) {
    final action = _actionFor(mission);
    if (action == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: ctrl.isLoading ? null : () => _onPressed(context, action),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: ctrl.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(action.icon),
        label: Text(
          action.label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }

  _Action? _actionFor(TransportMissionModel m) {
    switch (m.transporterStatus) {
      case 'pending':
        return const _Action(
          label: 'Démarrer la mission',
          icon: Icons.play_arrow,
          type: 'en_route',
        );
      case 'en_route_to_client':
        return const _Action(
          label: 'Scanner QR chez client',
          icon: Icons.qr_code_scanner,
          type: 'scan_pickup',
        );
      case 'picked_up':
        return const _Action(
          label: 'Scanner QR au centre',
          icon: Icons.qr_code_scanner,
          type: 'scan_delivery',
        );
      case 'delivered_to_center':
        return const _Action(
          label: 'Démarrer le retour',
          icon: Icons.undo,
          type: 'return',
        );
      case 'return_en_route':
        return const _Action(
          label: 'Scanner QR chez client (retour)',
          icon: Icons.qr_code_scanner,
          type: 'scan_final',
        );
      default:
        return null;
    }
  }

  Future<void> _onPressed(BuildContext context, _Action action) async {
    switch (action.type) {
      case 'en_route':
        final ok = await ctrl.markEnRoute();
        if (ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mission démarrée'),
              backgroundColor: Color(0xFFFF6B35),
            ),
          );
        }
        break;

      case 'return':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransportScanScreen(
              missionId: mission.id,
              scanType: 'return',
              title: 'Scanner QR (retour)',
            ),
          ),
        ).then((_) => ctrl.loadMission(mission.id));
        break;

      case 'scan_pickup':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransportScanScreen(
              missionId: mission.id,
              scanType: 'pickup',
              title: 'Scanner QR chez client',
            ),
          ),
        ).then((_) => ctrl.loadMission(mission.id));
        break;

      case 'scan_delivery':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransportScanScreen(
              missionId: mission.id,
              scanType: 'delivery',
              title: 'Scanner QR au centre',
            ),
          ),
        ).then((_) => ctrl.loadMission(mission.id));
        break;

      case 'scan_final':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransportScanScreen(
              missionId: mission.id,
              scanType: 'final',
              title: 'Scanner QR chez client (retour)',
            ),
          ),
        ).then((_) => ctrl.loadMission(mission.id));
        break;
    }
  }
}

class _Action {
  final String label;
  final IconData icon;
  final String type;

  const _Action({
    required this.label,
    required this.icon,
    required this.type,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers UI
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Card({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFFF6B35), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _InfoRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}