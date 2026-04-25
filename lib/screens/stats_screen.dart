import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final roleColor = AppColors.roleColor(user.role);

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                _tabTitle(user.role),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.soil,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Muhtasari wa shughuli zako',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.mid,
                ),
              ),
              const SizedBox(height: 24),

              // 2×2 stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: _buildStats(user, roleColor),
              ),

              const SizedBox(height: 28),

              // Role-specific detailed section
              Text(
                'Maelezo Zaidi',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.soil,
                ),
              ),
              const SizedBox(height: 14),
              ..._buildDetailCards(user, roleColor),
            ],
          ),
        ),
      ),
    );
  }

  // Tab 3 title changes per role
  String _tabTitle(UserRole role) => switch (role) {
        UserRole.mkulima   => '🌿 Shamba Langu',
        UserRole.duka      => '🏪 Duka Langu',
        UserRole.muuzaji   => '📈 Biashara Yangu',
        UserRole.mwekezaji => '💼 Uwekezaji Wangu',
      };

  // Build 4 stat cards based on role
  List<Widget> _buildStats(UserModel user, Color color) =>
      switch (user.role) {
        UserRole.mkulima => [
            StatCard(
              value: '${user.farmSize?.toStringAsFixed(1) ?? "—"} Eka',
              label: 'Ukubwa wa Shamba',
              color: AppColors.leaf,
              icon: Icons.landscape,
            ),
            StatCard(
              value: '8 Wiki',
              label: 'Hadi Mavuno',
              color: AppColors.harvest,
              icon: Icons.timer_outlined,
            ),
            StatCard(
              value: 'TZS 850,000',
              label: 'Mapato Yanayotarajiwa',
              color: AppColors.sprout,
              icon: Icons.trending_up,
            ),
            StatCard(
              value: '3',
              label: 'Idadi ya Vipande',
              color: AppColors.mid,
              icon: Icons.grid_view,
            ),
          ],
        UserRole.duka => [
            StatCard(
              value: '${user.listingCount}',
              label: 'Bidhaa Orodhani',
              color: const Color(0xFF1565C0),
              icon: Icons.inventory_2_outlined,
            ),
            StatCard(
              value: 'TZS 320,000',
              label: 'Mauzo ya Wiki Hii',
              color: AppColors.harvest,
              icon: Icons.point_of_sale,
            ),
            StatCard(
              value: '7',
              label: 'Wateja Wapya',
              color: AppColors.sprout,
              icon: Icons.group_add_outlined,
            ),
            StatCard(
              value: '4.5 ⭐',
              label: 'Ukadiriaji Wako',
              color: AppColors.sun,
              icon: Icons.star_outline,
            ),
          ],
        UserRole.muuzaji => [
            StatCard(
              value: '${user.listingCount}',
              label: 'Orodha Zangu',
              color: const Color(0xFF6A1B9A),
              icon: Icons.format_list_bulleted,
            ),
            StatCard(
              value: 'TZS 2.5M',
              label: 'Mzunguko wa Wiki',
              color: AppColors.harvest,
              icon: Icons.currency_exchange,
            ),
            StatCard(
              value: '12',
              label: 'Miamala Kwa Siku',
              color: AppColors.sprout,
              icon: Icons.swap_horiz,
            ),
            StatCard(
              value: '4.3 ⭐',
              label: 'Ukadiriaji Wako',
              color: AppColors.sun,
              icon: Icons.star_outline,
            ),
          ],
        UserRole.mwekezaji => [
            StatCard(
              value: '2',
              label: 'Miradi Yangu',
              color: AppColors.harvest,
              icon: Icons.folder_outlined,
            ),
            StatCard(
              value: 'TZS 15M',
              label: 'Thamani ya Portfolio',
              color: AppColors.leaf,
              icon: Icons.account_balance_wallet_outlined,
            ),
            StatCard(
              value: '18%',
              label: 'Wastani wa ROI',
              color: AppColors.sprout,
              icon: Icons.show_chart,
            ),
            StatCard(
              value: '3',
              label: 'Mashamba',
              color: AppColors.mid,
              icon: Icons.landscape_outlined,
            ),
          ],
      };

  // Role-specific detail cards below the grid
  List<Widget> _buildDetailCards(UserModel user, Color color) =>
      switch (user.role) {
        UserRole.mkulima => [
            _DetailCard(
              icon: Icons.grass,
              title: 'Mazao Yangu',
              subtitle: user.mainCrops ?? 'Bado haujaweka mazao',
              color: color,
            ),
            _DetailCard(
              icon: Icons.water_drop_outlined,
              title: 'Hali ya Umwagiliaji',
              subtitle: 'Unahitaji lita 700 leo — ardhi ya tifutifu',
              color: color,
            ),
            _DetailCard(
              icon: Icons.warning_amber_outlined,
              title: 'Tahadhari',
              subtitle: 'Msimu wa viwavi vya jeshi — angalia mahindi',
              color: const Color(0xFFB71C1C),
            ),
          ],
        UserRole.duka => [
            _DetailCard(
              icon: Icons.inventory_2_outlined,
              title: 'Bidhaa Zinaishia',
              subtitle: 'Coragen SC — imebaki pakiti 3 tu',
              color: const Color(0xFFB71C1C),
            ),
            _DetailCard(
              icon: Icons.people_outline,
              title: 'Ombi Jipya',
              subtitle: 'Mkulima 2 wanauliza kuhusu mbegu za mahindi',
              color: color,
            ),
            _DetailCard(
              icon: Icons.store_outlined,
              title: 'Aina ya Bidhaa',
              subtitle: user.productType ?? 'Bidhaa zote',
              color: color,
            ),
          ],
        UserRole.muuzaji => [
            _DetailCard(
              icon: Icons.trending_up,
              title: 'Bei Imepanda',
              subtitle: 'Nyanya — TZS 1,200/kg (+15% wiki hii)',
              color: AppColors.leaf,
            ),
            _DetailCard(
              icon: Icons.local_shipping_outlined,
              title: 'Safari Inayokuja',
              subtitle: 'DSM → Morogoro — kesho saa 3 asubuhi',
              color: color,
            ),
            _DetailCard(
              icon: Icons.shopping_basket_outlined,
              title: 'Mazao Ninayonunua',
              subtitle: user.cropsTraded ?? 'Bado haujaweka',
              color: color,
            ),
          ],
        UserRole.mwekezaji => [
            _DetailCard(
              icon: Icons.landscape_outlined,
              title: 'Shamba Linalopatikana',
              subtitle: 'Ekari 10 — Chalinze, Pwani — TZS 180,000/mwezi',
              color: color,
            ),
            _DetailCard(
              icon: Icons.show_chart,
              title: 'Mradi Bora',
              subtitle: 'Alizeti Singida — ROI 22% — miaka 2',
              color: AppColors.sprout,
            ),
            _DetailCard(
              icon: Icons.handshake_outlined,
              title: 'Aina ya Uwekezaji',
              subtitle: user.investmentType ?? 'Haijawekwa',
              color: color,
            ),
          ],
      };
}

// Single detail card in the lower section
class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _DetailCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShambaCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              radius: 22,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.mid,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.mid.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
