import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/terrain_models.dart';
import 'dashboard_controller.dart';

class DashboardScreenWrapper extends StatelessWidget {
  const DashboardScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardController()..loadStats(),
      child: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();
    const primary = Color(0xFFFF6B35);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadStats,
          ),
        ],
      ),
      body: controller.isLoading && controller.stats == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : controller.error != null && controller.stats == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(controller.error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.loadStats,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              // FIX : guard null avant d'utiliser stats! — pendant un retry,
              // isLoading=true + stats==null + error==null → crash sans ce check.
              : controller.stats == null
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
                  : RefreshIndicator(
                      color: primary,
                      onRefresh: controller.loadStats,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: _DashboardContent(stats: controller.stats!),
                      ),
                    ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final TerrainStatsModel stats;
  const _DashboardContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vue d'ensemble",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _StatCard(
                title: "Aujourd'hui",
                mainValue: stats.todayTotal.toString(),
                mainLabel: 'total',
                secondaryItems: [
                  ('Terminés', stats.todayCompleted, Colors.green),
                  ('En attente', stats.todayPending, Colors.orange),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SimpleStatCard(
                title: 'Cette semaine',
                value: stats.weekTotal.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SimpleStatCard(
                title: 'Ce mois',
                value: stats.monthTotal.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stats.pendingNow.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En attente maintenant',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Véhicules non encore arrivés',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Résultats des contrôles',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DonutCard(
                label: 'Favorable',
                rate: stats.favorableRate,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DonutCard(
                label: 'Défavorable',
                rate: stats.defavorableRate,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DonutCard(
                label: 'Contre-visite',
                rate: stats.contreVisiteRate,
                color: Colors.amber[700]!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String mainValue;
  final String mainLabel;
  final List<(String, int, Color)> secondaryItems;

  const _StatCard({
    required this.title,
    required this.mainValue,
    required this.mainLabel,
    required this.secondaryItems,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mainValue,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    mainLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...secondaryItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.$3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.$1,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Spacer(),
                    Text(
                      item.$2.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.$3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleStatCard extends StatelessWidget {
  final String title;
  final String value;
  const _SimpleStatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  final String label;
  final double rate;
  final Color color;
  const _DonutCard({required this.label, required this.rate, required this.color});

  @override
  Widget build(BuildContext context) {
    final percent = (rate * 100).round();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: rate.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
