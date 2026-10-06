// lib/features/transport/client_signature_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// Écran de signature client à la livraison du véhicule.
// Session 15 - Phase 4.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../core/services/terrain_service.dart';

class ClientSignatureScreen extends StatefulWidget {
  final String missionId;
  final String missionReference;

  const ClientSignatureScreen({
    super.key,
    required this.missionId,
    required this.missionReference,
  });

  @override
  State<ClientSignatureScreen> createState() => _ClientSignatureScreenState();
}

class _ClientSignatureScreenState extends State<ClientSignatureScreen> {
  late final SignatureController _signatureController;
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    _signatureController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _hasSignature => _signatureController.isNotEmpty;

  Future<void> _submitSignature() async {
    if (!_hasSignature) {
      setState(() => _error = 'Veuillez faire signer le client.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Uint8List? bytes = await _signatureController.toPngBytes();
      if (bytes == null) {
        setState(() {
          _isLoading = false;
          _error = 'Erreur lors de la génération de la signature.';
        });
        return;
      }

      final base64Png = 'data:image/png;base64,${base64Encode(bytes)}';

      await TerrainService.instance.validateDelivery(
        widget.missionId,
        validationType: 'signed',
        signature: base64Png,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur : ${e.toString()}';
      });
    }
  }

  Future<void> _submitBypass(String type) async {
    // type : 'refused' | 'absent'
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      setState(() => _error = 'Veuillez saisir un motif.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Signature placeholder pour le bypass (le backend accepte quand même)
      await TerrainService.instance.validateDelivery(
        widget.missionId,
        validationType: type,
        signature: 'data:image/png;base64,',  // vide
        note: note,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur : ${e.toString()}';
      });
    }
  }

  void _clearSignature() {
    _signatureController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6B35);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Signature client'),
            Text(
              widget.missionReference,
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
            const Text(
              'Faites signer le client dans le cadre ci-dessous pour valider la livraison du véhicule.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Pad de signature
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                  height: 280,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Bouton effacer
            Row(
              children: [
                TextButton.icon(
                  onPressed: _hasSignature ? _clearSignature : null,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Effacer'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                if (!_hasSignature)
                  Text(
                    'Aucune signature',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Note optionnelle
            TextField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Note (optionnel)',
                hintText: 'Remarque, observation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],

            const SizedBox(height: 16),

            // Bouton Valider signature
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || !_hasSignature) ? null : _submitSignature,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text(
                  'Valider la signature',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            const Text(
              'Cas particuliers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),

            // Bypass : client absent
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _submitBypass('absent'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange[800],
                  side: BorderSide(color: Colors.orange[800]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.person_off, size: 16),
                label: const Text('Client absent'),
              ),
            ),
            const SizedBox(height: 8),

            // Bypass : client refuse
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _submitBypass('refused'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[700]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.block, size: 16),
                label: const Text('Client refuse de signer'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}