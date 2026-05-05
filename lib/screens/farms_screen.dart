import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/farm_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/farm_provider.dart';
import '../theme/app_colors.dart';
import 'add_farm_screen.dart';
import 'farm_detail_screen.dart';
import 'scan_screen.dart';
import 'soil_screen.dart';
import 'irrigation_screen.dart';

class FarmsScreen extends StatelessWidget {
  const FarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final farms = context.watch<FarmProvider>().farms;
    final isMkulima = user?.role == UserRole.mkulima;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: const Text('Mashamba Yangu 🌿'),
        actions: [
          if (farms.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Ongeza Shamba',
              onPressed: () => _openAddFarm(context, user?.id),
            ),
        ],
      ),
      body: farms.isEmpty
          ? _buildEmptyState(context, user?.id, isMkulima)
          : _buildFarmList(context, farms, user?.id),
      floatingActionButton: farms.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openAddFarm(context, user?.id),
              backgroundColor: AppColors.leaf,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Ongeza Shamba',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, String? userId, bool isMkulima) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.leaf.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Text('🌾', style: TextStyle(fontSize: 60)),
              ),
              const SizedBox(height: 24),
              Text(
                'Bado Hujaongeza Shamba',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.soil,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ongeza shamba lako la kwanza kupata ushauri '
                'wa udongo, magonjwa ya mazao, na umwagiliaji '
                'ulioboreshwa kwa kila shamba.',
                style: GoogleFonts.dmSans(
                    color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openAddFarm(context, userId),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text(
                    'Ongeza Shamba la Kwanza',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unaweza kuongeza mashamba mengi',
                style: GoogleFonts.dmSans(
                    color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );

  Widget _buildFarmList(
      BuildContext context, List<FarmModel> farms, String? userId) =>
      ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: farms.length,
        separatorBuilder: (context, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _FarmCard(
          farm: farms[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FarmDetailScreen(farm: farms[i]),
            ),
          ),
          onDelete: () => _confirmDelete(context, farms[i]),
        ),
      );

  void _openAddFarm(BuildContext context, String? userId) {
    if (userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddFarmScreen(farmerId: userId)),
    );
  }

  void _confirmDelete(BuildContext context, FarmModel farm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Futa Shamba'),
        content: Text(
            'Una uhakika unataka kufuta "${farm.name}"? '
            'Hatua hii haiwezi kutenduliwa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hapana'),
          ),
          TextButton(
            onPressed: () {
              context.read<FarmProvider>().deleteFarm(farm.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  final FarmModel farm;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FarmCard({
    required this.farm,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // ── Coloured header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A1E), Color(0xFF2E6B35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Text('🌾', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(farm.name,
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: Colors.white60),
                            const SizedBox(width: 3),
                            Text(farm.region,
                                style: GoogleFonts.dmSans(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(width: 10),
                            const Icon(Icons.straighten,
                                size: 12, color: Colors.white60),
                            const SizedBox(width: 3),
                            Text(farm.acresDisplay,
                                style: GoogleFonts.dmSans(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline,
                          size: 16, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Row(
                    children: [
                      _Badge(
                        icon: farm.hasLocation
                            ? Icons.gps_fixed
                            : Icons.gps_not_fixed,
                        label: farm.hasLocation ? 'GPS Imewekwa' : 'Weka GPS',
                        color: farm.hasLocation
                            ? AppColors.leaf
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        icon: Icons.grass,
                        label: farm.crops.isEmpty
                            ? 'Mazao Hayajawekwa'
                            : '${farm.crops.length} Zao${farm.crops.length > 1 ? " (${farm.crops.take(2).join(", ")})" : " (${farm.crops.first})"}',
                        color: farm.crops.isEmpty
                            ? Colors.grey
                            : AppColors.harvest,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Quick action buttons
                  Row(
                    children: [
                      _MiniAction(
                        emoji: '🔬',
                        label: 'Chunguza',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const ScanScreen())),
                      ),
                      const SizedBox(width: 8),
                      _MiniAction(
                        emoji: '🧪',
                        label: 'Udongo',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => SoilScreen(
                                  farmLat: farm.gpsLat,
                                  farmLng: farm.gpsLng,
                                  farmName: farm.name,
                                ))),
                      ),
                      const SizedBox(width: 8),
                      _MiniAction(
                        emoji: '💧',
                        label: 'Umwagiliaji',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const IrrigationScreen())),
                      ),
                      const Spacer(),
                      // Open detail arrow
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.leaf,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Fungua',
                                style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios,
                                size: 11, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

class _MiniAction extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _MiniAction(
      {required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.mid.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.soil,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

