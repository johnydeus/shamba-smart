import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';
import 'market_screen.dart';
import 'forum_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final roleColor = AppColors.roleColor(user.role);

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Profile header ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.soil, roleColor.withValues(alpha: 0.85)],
                  ),
                ),
                child: Column(
                  children: [
                    UserAvatarCircle(
                        name: user.displayName, role: user.role, size: 72),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RoleChip(user.role, fontSize: 12),
                    const SizedBox(height: 8),
                    Text(
                      user.region,
                      style: GoogleFonts.dmSans(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats row under header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _HeaderStat(
                            value: '${user.listingCount}', label: 'Orodha'),
                        Container(
                            height: 30,
                            width: 1,
                            color: Colors.white24),
                        _HeaderStat(
                            value: '${user.salesCount}', label: 'Mauzo'),
                        Container(
                            height: 30,
                            width: 1,
                            color: Colors.white24),
                        _HeaderStat(
                            value: _joinedLabel(user.joinedAt),
                            label: 'Mwanachama'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Role-specific menu ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 4),
                      child: Text(
                        'Menyu',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.soil,
                        ),
                      ),
                    ),
                    ..._menuItems(context, user, roleColor),
                    const SizedBox(height: 20),

                    // ── Account info ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 4),
                      child: Text(
                        'Taarifa za Akaunti',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.soil,
                        ),
                      ),
                    ),
                    _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Barua Pepe',
                        value: user.email),
                    if (user.role == UserRole.mkulima &&
                        user.farmSize != null)
                      _InfoTile(
                          icon: Icons.landscape_outlined,
                          label: 'Ukubwa wa Shamba',
                          value: '${user.farmSize} Ekari'),
                    if (user.role == UserRole.duka && user.shopName != null)
                      _InfoTile(
                          icon: Icons.store_outlined,
                          label: 'Jina la Duka',
                          value: user.shopName!),
                    if (user.role == UserRole.muuzaji &&
                        user.businessName != null)
                      _InfoTile(
                          icon: Icons.business_outlined,
                          label: 'Jina la Biashara',
                          value: user.businessName!),

                    const SizedBox(height: 20),

                    // ── Logout ────────────────────────────────────────────────
                    ShambaCard(
                      onTap: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.logout,
                              color: Color(0xFFB71C1C), size: 22),
                          const SizedBox(width: 14),
                          Text(
                            'Toka',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFFB71C1C),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build role-specific menu items
  List<Widget> _menuItems(
      BuildContext context, UserModel user, Color color) {
    final items = switch (user.role) {
      UserRole.mkulima => [
          _MenuItem(
            icon: Icons.landscape,
            title: 'Shamba Langu',
            subtitle: 'Angalia na hariri taarifa za shamba',
            color: color,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.trending_up,
            title: 'Bei za Soko',
            subtitle: 'Bei za mazao Tanzania leo',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MarketScreen())),
          ),
          _MenuItem(
            icon: Icons.cloud_outlined,
            title: 'Hali ya Hewa',
            subtitle: 'Utabiri wa hali ya hewa shambani',
            color: color,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.psychology_outlined,
            title: 'Mshauri wa AI',
            subtitle: 'Uliza maswali ya kilimo kwa Claude',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ForumScreen())),
          ),
          _MenuItem(
            icon: Icons.settings_outlined,
            title: 'Mipangilio',
            subtitle: 'Badilisha taarifa za akaunti yako',
            color: AppColors.mid,
            onTap: () {},
          ),
        ],
      UserRole.duka => [
          _MenuItem(
            icon: Icons.inventory_2_outlined,
            title: 'Bidhaa Zangu',
            subtitle: 'Angalia na simamia orodha yako',
            color: color,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.inbox_outlined,
            title: 'Maombi ya Wateja',
            subtitle: 'Maombi mapya: 3 yanangoja jibu',
            color: color,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.bar_chart_outlined,
            title: 'Takwimu za Mauzo',
            subtitle: 'Angalia mwenendo wa mauzo yako',
            color: color,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.settings_outlined,
            title: 'Mipangilio',
            subtitle: 'Badilisha taarifa za akaunti yako',
            color: AppColors.mid,
            onTap: () {},
          ),
        ],
      UserRole.muuzaji => [
          _MenuItem(
            icon: Icons.shopping_basket_outlined,
            title: 'Mazao Ninayonunua',
            subtitle: user.cropsTraded ?? 'Weka mazao unayonunua',
            color: color,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.storefront_outlined,
            title: 'Biashara Yangu',
            subtitle: 'Angalia mauzo na manunuzi yako',
            color: color,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.local_shipping_outlined,
            title: 'Usafiri',
            subtitle: 'Panga safari za kubeba mazao',
            color: color,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.settings_outlined,
            title: 'Mipangilio',
            subtitle: 'Badilisha taarifa za akaunti yako',
            color: AppColors.mid,
            onTap: () {},
          ),
        ],
      UserRole.mwekezaji => [
          _MenuItem(
            icon: Icons.landscape_outlined,
            title: 'Mashamba Yangu',
            subtitle: 'Angalia mashamba unayomiliki au kukodisha',
            color: color,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.pie_chart_outline,
            title: 'Takwimu za Uwekezaji',
            subtitle: 'ROI, faida, na mwenendo wa portfolio',
            color: color,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.volunteer_activism_outlined,
            title: 'Wakulima Wanaohitaji Msaada',
            subtitle: 'Wakulima 12 wanatafuta mwekezaji',
            color: color,
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.settings_outlined,
            title: 'Mipangilio',
            subtitle: 'Badilisha taarifa za akaunti yako',
            color: AppColors.mid,
            onTap: () {},
          ),
        ],
    };

    return items
        .map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: item,
            ))
        .toList();
  }

  // Format join date as Swahili month + year
  String _joinedLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// Stat shown in the header row
class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
              color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }
}

// One menu row item
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ShambaCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.1),
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
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.mid,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: AppColors.mid.withValues(alpha: 0.4), size: 20),
        ],
      ),
    );
  }
}

// Simple info tile for account details section
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShambaCard(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.mid, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.mid)),
                Text(value,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
