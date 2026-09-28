// lib/features/transport/transport_missions_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// Écran listant les missions transport CT du transporteur connecté.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/terrain_models.dart';
import 'transport_missions_controller.dart';
import 'transport_mission_detail_screen.dart';

class TransportMissionsScreenWrapper extends StatelessWidget {
  const TransportMissionsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransportMissionsController()..loadMissions(),
      child: const TransportMissionsScreen(),
    );
  }
}

class TransportMissionsScreen extends StatelessWidget {
  const TransportMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TransportMissionsController>();
    const primary = Color(0xFFFF6B35);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Missions transport'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: ctrl.refresh,
        child: _buildBody(ctrl),
      ),
    );
  }

  Widget _buildBody(TransportMissionsController ctrl) {
    if (ctrl.isLoading && ctrl.missions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    if (ctrl.error != null && ctrl.missions.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    ctrl.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: ctrl.refresh,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (ctrl.missions.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune mission en cours',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Vos missions de transport apparaîtront ici.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ctrl.missions.length,
      itemBuilder: (ctx, i) {
        final mission = ctrl.missions[i];
        return _MissionCard(
          mission: mission,
          onTap: () async {
            await Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => TransportMissionDetailScreenWrapper(
                  missionId: mission.id,
                ),
              ),
            );
            ctrl.refresh();
          },
        );
      },
    );
  }
}

class _MissionCard extends StatelessWidget {
  final TransportMissionModel mission;
  final VoidCallback onTap;

  const _MissionCard({required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusIcon) = _statusStyle(mission.providerStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : référence + badge transport
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: mission.transportMode == 'tow'
                          ? Colors.blue.withValues(alpha: 0.12)
                          : Colors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mission.transportMode == 'tow'
                              ? Icons.local_shipping
                              : Icons.person,
                          size: 14,
                          color: mission.transportMode == 'tow'
                              ? Colors.blue
                              : Colors.purple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mission.transportMode == 'tow'
                              ? 'Remorquage'
                              : 'Chauffeur',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: mission.transportMode == 'tow'
                                ? Colors.blue
                                : Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    mission.reference,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Véhicule
              Row(
                children: [
                  const Icon(Icons.directions_car,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${mission.registrationNumber} — ${mission.vehicleBrand} ${mission.vehicleModel}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Créneau
              if (mission.slotStartsAt != null) ...[
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      mission.slotTime,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Client
              if (mission.clientName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        mission.clientName!,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Statut + action
              Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    mission.stepLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      size: 12, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, IconData) _statusStyle(String? status) {
    switch (status) {
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
