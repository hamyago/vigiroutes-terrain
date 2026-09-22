import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/terrain_models.dart';
import 'booking_detail_controller.dart';

class BookingDetailScreenWrapper extends StatelessWidget {
  final String bookingId;
  const BookingDetailScreenWrapper({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingDetailController()..loadBooking(bookingId),
      child: const BookingDetailScreen(),
    );
  }
}

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingDetailController>();
    const primary = Color(0xFFFF6B35);

    if (controller.isLoading && controller.booking == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
      );
    }
    if (controller.booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail réservation')),
        body: Center(
          child: Text(controller.error ?? 'Réservation introuvable'),
        ),
      );
    }

    final booking = controller.booking!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.registrationNumber),
            Text(
              booking.reference,
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
            _VehicleInfoCard(booking: booking),
            const SizedBox(height: 16),
            _StatusTimeline(status: booking.status),
            const SizedBox(height: 16),
            _ActionSection(booking: booking, controller: controller),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  controller.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _VehicleInfoCard extends StatelessWidget {
  final TerrainBookingModel booking;
  const _VehicleInfoCard({required this.booking});

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
                const Icon(Icons.directions_car, color: Color(0xFFFF6B35), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Informations véhicule',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const Divider(height: 20),
            _Row(label: 'Immatriculation', value: booking.registrationNumber, bold: true),
            _Row(label: 'Marque', value: booking.vehicleBrand),
            _Row(label: 'Modèle', value: booking.vehicleModel),
            _Row(label: 'Couleur', value: booking.vehicleColor),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Client',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _Row(label: 'Nom', value: booking.clientName),
            _Row(label: 'Téléphone', value: booking.clientPhone),
            _Row(label: 'Heure de passage', value: booking.slotTime),
            _Row(label: 'Transport', value: _transportLabel(booking.transportMode ?? '')),
          ],
        ),
      ),
    );
  }

  String _transportLabel(String mode) => switch (mode) {
        'self' => 'Conduit par le client',
        'tow' => 'Remorquage',
        'driver' => 'Conducteur mandaté',
        _ => mode,
      };
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _Row({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Arrivé', 'arrived', Icons.where_to_vote),
      ('Contrôle', 'in_progress', Icons.build),
      ('Terminé', 'completed', Icons.check_circle),
    ];

    final currentIndex = switch (status) {
      'arrived' => 0,
      'in_progress' => 1,
      'favorable' || 'defavorable' || 'contre_visite' || 'completed' => 2,
      _ => -1,
    };

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progression',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stepIdx = i ~/ 2;
                  final active = currentIndex > stepIdx;
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: active ? const Color(0xFFFF6B35) : Colors.grey[300],
                    ),
                  );
                }
                final stepIdx = i ~/ 2;
                final (label, _, icon) = steps[stepIdx];
                final done = currentIndex >= stepIdx;
                final current = currentIndex == stepIdx;
                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? const Color(0xFFFF6B35)
                            : Colors.grey[200],
                        border: current
                            ? Border.all(color: const Color(0xFFFF6B35), width: 3)
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: done ? Colors.white : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            current ? FontWeight.bold : FontWeight.normal,
                        color: done ? const Color(0xFFFF6B35) : Colors.grey,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final TerrainBookingModel booking;
  final BookingDetailController controller;
  const _ActionSection({required this.booking, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (booking.status == 'arrived') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: controller.isLoading
              ? null
              : () async {
                  final ok = await controller.startInspection();
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contrôle démarré'),
                        backgroundColor: Color(0xFFFF6B35),
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: controller.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.play_arrow),
          label: const Text(
            'Démarrer le contrôle',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      );
    }

    if (booking.status == 'in_progress') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: controller.isLoading
              ? null
              : () => _showReportSheet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: controller.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.assignment),
          label: const Text(
            'Finaliser et saisir le rapport',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      );
    }

    if (booking.status == 'completed') {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Contrôle terminé',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    if (booking.status == 'cancelled') {
      return Card(
        color: Colors.red[50],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Réservation annulée',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.grey, size: 24),
            SizedBox(width: 12),
            Text(
              'En attente d\'arrivée du véhicule',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReportBottomSheet(
        controller: controller,
        onSuccess: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rapport soumis — Notification envoyée'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}

class _ReportBottomSheet extends StatefulWidget {
  final BookingDetailController controller;
  final VoidCallback onSuccess;
  const _ReportBottomSheet({required this.controller, required this.onSuccess});

  @override
  State<_ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<_ReportBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String _result = 'favorable';
  final _nonConformityCtrl = TextEditingController();
  final _recommendationsCtrl = TextEditingController();
  final _nextVtDateCtrl = TextEditingController();
  final _pvNumberCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _localError;

  @override
  void dispose() {
    _nonConformityCtrl.dispose();
    _recommendationsCtrl.dispose();
    _nextVtDateCtrl.dispose();
    _pvNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _localError = null;
    });
    final ok = await widget.controller.submitReport(
      result: _result,
      nonConformity: _nonConformityCtrl.text.trim().isEmpty
          ? null
          : _nonConformityCtrl.text.trim(),
      recommendations: _recommendationsCtrl.text.trim().isEmpty
          ? null
          : _recommendationsCtrl.text.trim(),
      nextVtDate: _nextVtDateCtrl.text.trim().isEmpty
          ? null
          : _nextVtDateCtrl.text.trim(),
      pvNumber: _pvNumberCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) {
      widget.onSuccess();
    } else {
      setState(() => _localError = widget.controller.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6B35);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment, color: Color(0xFFFF6B35)),
                  const SizedBox(width: 8),
                  const Text(
                    'Rapport de contrôle',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Résultat',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _result,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'favorable',
                    child: Text('Favorable'),
                  ),
                  DropdownMenuItem(
                    value: 'defavorable',
                    child: Text('Défavorable'),
                  ),
                  DropdownMenuItem(
                    value: 'contre_visite',
                    child: Text('Contre-visite requise'),
                  ),
                ],
                onChanged: (v) => setState(() => _result = v ?? 'favorable'),
              ),
              const SizedBox(height: 16),
              if (_result == 'defavorable' || _result == 'contre_visite') ...[
                const Text(
                  'Points de non-conformité',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nonConformityCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Décrivez les points de non-conformité...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) {
                    if (_result != 'favorable' &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Requis pour ce résultat';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_result == 'favorable') ...[
                const Text(
                  'Date prochaine VT (YYYY-MM-DD)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nextVtDateCtrl,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    hintText: 'ex: 2027-09-18',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) {
                    if (_result == 'favorable' &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Requis pour un résultat favorable';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Recommandations (optionnel)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _recommendationsCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Recommandations à transmettre au client...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Numéro de PV',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pvNumberCtrl,
                decoration: InputDecoration(
                  hintText: 'ex: PV-2024-00123',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Le numéro de PV est requis';
                  }
                  return null;
                },
              ),
              if (_localError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _localError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Valider le rapport',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
