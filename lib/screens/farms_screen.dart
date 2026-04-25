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
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Farm icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.leaf.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.landscape,
                      color: AppColors.leaf, size: 28),
                ),
                const SizedBox(width: 14),

                // Farm info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.straighten,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(farm.acresDisplay,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(farm.region,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      if (farm.crops.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: farm.crops
                              .take(3)
                              .map((c) => _CropChip(crop: c))
                              .toList()
                            ..addAll(farm.crops.length > 3
                                ? [_CropChip(crop: '+${farm.crops.length - 3}')]
                                : []),
                        ),
                      ],
                      if (!farm.hasLocation)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.gps_not_fixed,
                                  size: 12, color: Colors.orange),
                              SizedBox(width: 4),
                              Text('GPS haijawekwa',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.orange)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _CropChip extends StatelessWidget {
  final String crop;
  const _CropChip({required this.crop});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.leaf.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          crop,
          style: const TextStyle(
              fontSize: 10, color: AppColors.leaf, fontWeight: FontWeight.w600),
        ),
      );
}
