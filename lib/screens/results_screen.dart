import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'scan_screen.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> diagnosis;
  final String imagePath;
  final String cropName;

  const ResultsScreen({
    super.key,
    required this.diagnosis,
    required this.imagePath,
    required this.cropName,
  });

  // Map severity level to a colour
  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return const Color(0xFF2E8B57);
      case 'medium':
        return const Color(0xFFFF6F00);
      case 'high':
        return const Color(0xFFE65100);
      case 'critical':
        return const Color(0xFFB71C1C);
      default:
        return Colors.grey;
    }
  }

  // Map severity level to Swahili label
  String _severityLabel(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return 'Chini';
      case 'medium':
        return 'Wastani';
      case 'high':
        return 'Juu';
      case 'critical':
        return 'Hatari Sana';
      default:
        return severity;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if Claude returned an error or if the plant is healthy
    final hasError = diagnosis['error'] == true;
    final isHealthy = diagnosis['is_healthy'] == true;

    final diseaseSw =
        diagnosis['disease_name_sw'] ?? 'Ugonjwa haujulikani';
    final diseaseEn = diagnosis['disease_name_en'] ?? '';
    final confidence = (diagnosis['confidence'] ?? 0.0) as double;
    final severity = diagnosis['severity'] ?? 'low';
    final descriptionSw =
        diagnosis['description_sw'] ?? '';
    final actionSw = diagnosis['immediate_action_sw'] ?? '';
    final pest1Name = diagnosis['pesticide_1_name'] ?? '';
    final pest1Dose = diagnosis['pesticide_1_dose'] ?? '';
    final pest2Name = diagnosis['pesticide_2_name'] ?? '';
    final pest2Dose = diagnosis['pesticide_2_dose'] ?? '';
    final daysCritical = diagnosis['days_until_critical'] ?? 0;
    final preventionSw = diagnosis['prevention_sw'] as String? ?? '';
    final threatType = diagnosis['threat_type'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text('Matokeo ya Uchunguzi',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show the leaf photo
            if (imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(imagePath),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),

            // Error case
            if (hasError)
              _InfoCard(
                color: const Color(0xFFB71C1C),
                child: Text(
                  diagnosis['message'] ?? 'Hitilafu isiyojulikana.',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),

            // Healthy plant
            if (!hasError && isHealthy)
              _InfoCard(
                color: const Color(0xFF2E8B57),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Mmea Wako Unaonekana Mzima! 🌿',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            // Disease found
            if (!hasError && !isHealthy) ...[
              // Disease name card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ugonjwa Uliopatikana:',
                        style: TextStyle(
                            color: Color(0xFF9E9E9E), fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        diseaseSw,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (diseaseEn.isNotEmpty)
                        Text(
                          diseaseEn,
                          style: const TextStyle(
                              color: Color(0xFF9E9E9E), fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Confidence and severity row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Uhakika',
                              style: TextStyle(
                                  color: Color(0xFF9E9E9E), fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(confidence * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A5C2E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: confidence,
                              color: const Color(0xFF1A5C2E),
                              backgroundColor: const Color(0xFFE8F5E9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Ukali',
                              style: TextStyle(
                                  color: Color(0xFF9E9E9E), fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _severityColor(severity)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _severityLabel(severity),
                                style: TextStyle(
                                  color: _severityColor(severity),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (daysCritical > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                '$daysCritical siku',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9E9E9E)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              if (descriptionSw.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Maelezo:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A5C2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(descriptionSw,
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Immediate action
              if (actionSw.isNotEmpty)
                _InfoCard(
                  color: const Color(0xFFFF6F00),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Fanya Sasa Hivi:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        actionSw,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Pesticide recommendations
              if (pest1Name.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dawa Zinazopendekezwa:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A5C2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PesticideRow(
                          number: '1',
                          name: pest1Name,
                          dose: pest1Dose,
                        ),
                        if (pest2Name.isNotEmpty) ...[
                          const Divider(),
                          _PesticideRow(
                            number: '2',
                            name: pest2Name,
                            dose: pest2Dose,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Prevention (text diagnosis only)
              if (preventionSw.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield,
                                color: Color(0xFF2E7D32), size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Kinga na Uzuiaji:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(preventionSw,
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],

              // Threat type badge (text diagnosis)
              if (threatType.isNotEmpty) ...[
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5C2E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Aina: $threatType',
                      style: const TextStyle(
                          color: Color(0xFF1A5C2E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),

            // Action buttons at the bottom
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Piga Picha Nyingine'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Rudi Nyumbani'),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A5C2E),
                side: const BorderSide(color: Color(0xFF1A5C2E)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable coloured information card
class _InfoCard extends StatelessWidget {
  final Color color;
  final Widget child;

  const _InfoCard({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

// One row showing a pesticide name and its dose
class _PesticideRow extends StatelessWidget {
  final String number;
  final String name;
  final String dose;

  const _PesticideRow({
    required this.number,
    required this.name,
    required this.dose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFF1A5C2E),
          child: Text(
            number,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(dose,
                  style: const TextStyle(
                      color: Color(0xFF9E9E9E), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
