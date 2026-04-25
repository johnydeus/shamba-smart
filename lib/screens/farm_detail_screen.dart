import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/farm_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'add_farm_screen.dart';
import 'soil_screen.dart';
import 'scan_screen.dart';
import 'irrigation_screen.dart';

class FarmDetailScreen extends StatelessWidget {
  final FarmModel farm;

  const FarmDetailScreen({super.key, required this.farm});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: Text(farm.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Hariri Shamba',
            onPressed: () {
              final userId =
                  context.read<AuthProvider>().currentUser?.id ?? '';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddFarmScreen(
                    farmerId: userId,
                    editFarm: farm,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            if (farm.crops.isNotEmpty) _buildCropsCard(),
            if (farm.crops.isNotEmpty) const SizedBox(height: 16),
            _buildActionsSection(context),
            if (farm.notes != null && farm.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNotesCard(),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────

  Widget _buildSummaryCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.leaf.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.landscape,
                        color: AppColors.leaf, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          farm.region,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              Row(
                children: [
                  _StatItem(
                    icon: Icons.straighten,
                    label: 'Ukubwa',
                    value: farm.acresDisplay,
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    icon: Icons.eco,
                    label: 'Mazao',
                    value: '${farm.crops.length} aina',
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    icon: farm.hasLocation
                        ? Icons.gps_fixed
                        : Icons.gps_not_fixed,
                    label: 'GPS',
                    value: farm.hasLocation ? 'Imewekwa' : 'Haijawekwa',
                    valueColor: farm.hasLocation
                        ? AppColors.leaf
                        : Colors.orange,
                  ),
                ],
              ),
              if (farm.hasLocation) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_pin,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${farm.gpsLat!.toStringAsFixed(5)}, '
                        '${farm.gpsLng!.toStringAsFixed(5)}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  // ── Crops card ────────────────────────────────────────────

  Widget _buildCropsCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.grass, color: AppColors.leaf, size: 20),
                  const SizedBox(width: 8),
                  Text('Mazao ya Shamba',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: farm.crops
                    .map((c) => Chip(
                          label: Text(c,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.leaf,
                                  fontWeight: FontWeight.w600)),
                          backgroundColor:
                              AppColors.leaf.withValues(alpha: 0.1),
                          side: BorderSide(
                              color: AppColors.leaf.withValues(alpha: 0.3)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      );

  // ── Actions section ───────────────────────────────────────

  Widget _buildActionsSection(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Vitendo vya Shamba',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.grey.shade700)),
          ),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.landscape,
                  emoji: '🌍',
                  label: 'Data za\nUdongo',
                  color: const Color(0xFF7A5C3A),
                  onTap: farm.hasLocation
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SoilScreen(
                                farmLat: farm.gpsLat,
                                farmLng: farm.gpsLng,
                                farmName: farm.name,
                              ),
                            ),
                          )
                      : () => _showNoGpsDialog(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.document_scanner_outlined,
                  emoji: '🔬',
                  label: 'Chunguza\nUgonjwa',
                  color: const Color(0xFF1A5C2E),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.water_drop_outlined,
                  emoji: '💧',
                  label: 'Mpango\nUmwagiliaji',
                  color: const Color(0xFF0277BD),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const IrrigationScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  // ── Notes card ────────────────────────────────────────────

  Widget _buildNotesCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notes, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  const Text('Maelezo',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                farm.notes!,
                style: const TextStyle(
                    color: Colors.black87, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      );

  void _showNoGpsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('GPS Haijawekwa'),
        content: const Text(
            'Shamba hili halina GPS. Hariri shamba na ongeza GPS '
            'ili kupata data sahihi za udongo kwa eneo hili.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sawa'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to SoilScreen without farm GPS (will use device GPS)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SoilScreen()),
              );
            },
            child: const Text('Tumia GPS ya Simu'),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      );
}
