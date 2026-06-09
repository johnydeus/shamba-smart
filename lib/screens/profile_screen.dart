import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/farm_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'market_screen.dart';
import 'forum_screen.dart';
import 'farms_screen.dart';
import 'irrigation_screen.dart';
import 'soil_screen.dart';
import 'marketplace_screen.dart';
import 'consultation_screen.dart';
import '../widgets/soil/soil_profile_summary_card.dart';
import 'expert_profile_screen.dart' show kSpecializations;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final roleColor = AppColors.roleColor(user.role);
    final farmCount = context.watch<FarmProvider>().farms.length;

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
                        if (user.role == UserRole.mkulima)
                          _HeaderStat(
                              value: '$farmCount',
                              label: 'Mashamba'),
                        if (user.role != UserRole.mkulima)
                          _HeaderStat(
                              value: '${user.listingCount}',
                              label: 'Orodha'),
                        Container(height: 30, width: 1, color: Colors.white24),
                        _HeaderStat(
                            value: '${user.salesCount}', label: 'Mauzo'),
                        Container(height: 30, width: 1, color: Colors.white24),
                        _HeaderStat(
                            value: _joinedLabel(user.joinedAt),
                            label: 'Mwanachama'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Soil health summary ───────────────────────────────────────
              if (user.role == UserRole.mkulima || user.role == UserRole.afisa)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SoilProfileSummaryCard(farmerRegion: user.region),
                ),

              if (user.role == UserRole.mkulima || user.role == UserRole.afisa)
                const SizedBox(height: 16),

              // ── Role switcher ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RoleSwitcherCard(user: user),
              ),

              const SizedBox(height: 4),

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
                    if (user.role == UserRole.afisa &&
                        user.organization != null)
                      _InfoTile(
                          icon: Icons.account_balance_outlined,
                          label: 'Shirika',
                          value: user.organization!),
                    if (user.role == UserRole.afisa &&
                        user.badgeNumber != null)
                      _InfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Badge No.',
                          value: user.badgeNumber!),
                    if (user.role == UserRole.afisa &&
                        user.district != null)
                      _InfoTile(
                          icon: Icons.map_outlined,
                          label: 'Wilaya',
                          value: user.district!),

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
            icon: Icons.agriculture,
            title: 'Mashamba Yangu',
            subtitle: 'Angalia na simamia mashamba yako',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FarmsScreen())),
          ),
          _MenuItem(
            icon: Icons.landscape_outlined,
            title: 'Udongo wa Shamba',
            subtitle: 'Pata data za udongo kwa GPS',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SoilScreen())),
          ),
          _MenuItem(
            icon: Icons.storefront_outlined,
            title: 'Soko la Mazao',
            subtitle: 'Nunua na uza mazao, mbegu, na zana',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
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
            icon: Icons.water_drop_outlined,
            title: 'Hali ya Hewa & Umwagiliaji',
            subtitle: 'Utabiri wa hewa na mpango wa umwagiliaji',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const IrrigationScreen())),
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
            onTap: () => _showSettingsDialog(context, user),
          ),
        ],
      UserRole.duka => [
          _MenuItem(
            icon: Icons.inventory_2_outlined,
            title: 'Bidhaa Zangu',
            subtitle: 'Angalia na simamia orodha yako',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MarketScreen())),
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
            onTap: () => _showSettingsDialog(context, user),
          ),
        ],
      UserRole.muuzaji => [
          _MenuItem(
            icon: Icons.storefront_outlined,
            title: 'Bei za Soko',
            subtitle: 'Fuatilia bei za mazao Tanzania',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MarketScreen())),
          ),
          _MenuItem(
            icon: Icons.psychology_outlined,
            title: 'Mshauri wa AI',
            subtitle: 'Uliza maswali ya biashara kwa Claude',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ForumScreen())),
          ),
          _MenuItem(
            icon: Icons.settings_outlined,
            title: 'Mipangilio',
            subtitle: 'Badilisha taarifa za akaunti yako',
            color: AppColors.mid,
            onTap: () => _showSettingsDialog(context, user),
          ),
        ],
      UserRole.afisa => [
          _MenuItem(
            icon: Icons.workspace_premium_outlined,
            title: 'Simamia Profaili ya Mtaalamu',
            subtitle: 'Weka utaalamu wako, bio, na upatikanaji wako',
            color: color,
            onTap: () => _showAfisaProfileEditor(context, user),
          ),
          _MenuItem(
            icon: Icons.people,
            title: 'Ushauri wa Wakulima',
            subtitle: 'Ongea na wakulima wa eneo lako',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const ConsultationScreen())),
          ),
          _MenuItem(
            icon: Icons.landscape_outlined,
            title: 'Data za Udongo',
            subtitle: 'Angalia hali ya udongo shambani',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SoilScreen())),
          ),
          _MenuItem(
            icon: Icons.satellite_alt_outlined,
            title: 'Bei za Soko',
            subtitle: 'Bei za mazao Tanzania leo',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MarketScreen())),
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
            subtitle: 'Taarifa za akaunti yako',
            color: AppColors.mid,
            onTap: () => _showSettingsDialog(context, user),
          ),
        ],
      UserRole.mwekezaji => [
          _MenuItem(
            icon: Icons.trending_up,
            title: 'Bei za Soko',
            subtitle: 'Fuatilia bei za mazao Tanzania',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MarketScreen())),
          ),
          _MenuItem(
            icon: Icons.psychology_outlined,
            title: 'Mshauri wa AI',
            subtitle: 'Uliza maswali ya uwekezaji kwa Claude',
            color: color,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ForumScreen())),
          ),
          _MenuItem(
            icon: Icons.settings_outlined,
            title: 'Mipangilio',
            subtitle: 'Badilisha taarifa za akaunti yako',
            color: AppColors.mid,
            onTap: () => _showSettingsDialog(context, user),
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

  void _showAfisaProfileEditor(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AfisaProfileEditor(userId: user.id),
    );
  }

  void _showSettingsDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Taarifa za Akaunti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingRow('Jina', user.displayName),
            _SettingRow('Barua Pepe', user.email),
            _SettingRow('Mkoa', user.region),
            _SettingRow('Aina ya Akaunti', user.role.label),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Funga'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Sehemu ya kuhariri akaunti inakuja hivi karibuni.'),
                  backgroundColor: AppColors.leaf,
                ),
              );
            },
            child: const Text('Hariri'),
          ),
        ],
      ),
    );
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

// ── Role switcher card ────────────────────────────────────────────────────────

class _RoleSwitcherCard extends StatelessWidget {
  final UserModel user;
  const _RoleSwitcherCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final allRoles = user.allRoles;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: AppColors.leaf, size: 20),
                const SizedBox(width: 8),
                Text('Majukumu Yangu',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddRoleSheet(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ongeza', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.leaf,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allRoles.map((role) {
                final isActive = role == user.role;
                final color = AppColors.roleColor(role);
                return GestureDetector(
                  onTap: isActive
                      ? null
                      : () {
                          context.read<AuthProvider>().switchRole(role);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Umebadilisha jukumu → ${role.label}'),
                              backgroundColor: color,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color
                          : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? color
                            : color.withValues(alpha: 0.3),
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.check_circle,
                                color: Colors.white, size: 14),
                          ),
                        Text(
                          role.label,
                          style: TextStyle(
                            color: isActive ? Colors.white : color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.touch_app,
                              color: color.withValues(alpha: 0.6),
                              size: 13),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (allRoles.length == 1) ...[
              const SizedBox(height: 8),
              Text(
                'Gonga "Ongeza" kuongeza jukumu lingine bila akaunti mpya.',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddRoleSheet(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final available = UserRole.values
        .where((r) => !user.allRoles.contains(r))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Una majukumu yote tayari kwenye akaunti hii.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRoleSheet(availableRoles: available),
    );
  }
}

// ── Add Role bottom sheet ─────────────────────────────────────────────────────

class _AddRoleSheet extends StatefulWidget {
  final List<UserRole> availableRoles;
  const _AddRoleSheet({required this.availableRoles});

  @override
  State<_AddRoleSheet> createState() => _AddRoleSheetState();
}

class _AddRoleSheetState extends State<_AddRoleSheet> {
  UserRole? _selected;
  final _shopNameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _badgeCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  static const Map<UserRole, Map<String, dynamic>> _roleMeta = {
    UserRole.mkulima:   {'emoji': '🌿', 'color': Color(0xFF2E7D32)},
    UserRole.duka:      {'emoji': '🏪', 'color': Color(0xFF1565C0)},
    UserRole.muuzaji:   {'emoji': '📈', 'color': Color(0xFF6A1B9A)},
    UserRole.mwekezaji: {'emoji': '💼', 'color': Color(0xFFC8860A)},
    UserRole.afisa:     {'emoji': '🏛️', 'color': Color(0xFF00695C)},
  };

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _businessCtrl.dispose();
    _orgCtrl.dispose();
    _badgeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() { _saving = true; _error = null; });

    final error = await context.read<AuthProvider>().addRole(
      role: _selected!,
      shopName: _selected == UserRole.duka
          ? _shopNameCtrl.text.trim() : null,
      businessName: _selected == UserRole.muuzaji
          ? _businessCtrl.text.trim() : null,
      organization: _selected == UserRole.afisa
          ? _orgCtrl.text.trim() : null,
      badgeNumber: _selected == UserRole.afisa
          ? _badgeCtrl.text.trim() : null,
    );

    setState(() => _saving = false);

    if (error != null) {
      setState(() => _error = error);
    } else if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Jukumu la ${_selected!.label} limeongezwa! Gonga kuchagua.'),
          backgroundColor: AppColors.leaf,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDF6EE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Handle
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),

            Text('Ongeza Jukumu Jipya',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Chagua jukumu unalotaka kuongeza bila kuunda akaunti mpya.',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 20),

            // Role selector chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.availableRoles.map((role) {
                final meta = _roleMeta[role]!;
                final color = meta['color'] as Color;
                final isSelected = _selected == role;
                return GestureDetector(
                  onTap: () => setState(() => _selected = role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : color.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(meta['emoji'] as String,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(role.label,
                            style: TextStyle(
                                color: isSelected ? Colors.white : color,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // Role-specific fields
            if (_selected != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              if (_selected == UserRole.duka) ...[
                _buildField(_shopNameCtrl, 'Jina la Duka',
                    Icons.store_outlined),
              ],
              if (_selected == UserRole.muuzaji) ...[
                _buildField(_businessCtrl, 'Jina la Biashara',
                    Icons.business_outlined),
              ],
              if (_selected == UserRole.afisa) ...[
                _buildField(_orgCtrl, 'Shirika / Wizara',
                    Icons.account_balance_outlined),
                const SizedBox(height: 10),
                _buildField(_badgeCtrl, 'Nambari ya Kitambulisho',
                    Icons.badge_outlined),
              ],
              if (_selected == UserRole.mkulima ||
                  _selected == UserRole.mwekezaji)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.leaf.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.leaf, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selected == UserRole.mkulima
                                ? 'Utaweza kuongeza mashamba yako baada ya kuchagua jukumu hili.'
                                : 'Taarifa za uwekezaji zinaweza kuongezwa kutoka menyu yako.',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.leaf),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_error!,
                    style: TextStyle(color: Colors.red.shade700,
                        fontSize: 13)),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: (_selected == null || _saving) ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_circle_outline),
              label: Text(
                _saving ? 'Inaongeza...' : 'Ongeza Jukumu',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12),
            ),
          ),
        ),
      );
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  const _SettingRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );
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

// ── Afisa Profile Editor ─────────────────────────────────────────────────────

class _AfisaProfileEditor extends StatefulWidget {
  final String userId;
  const _AfisaProfileEditor({required this.userId});

  @override
  State<_AfisaProfileEditor> createState() => _AfisaProfileEditorState();
}

class _AfisaProfileEditorState extends State<_AfisaProfileEditor> {
  static SupabaseClient get _db => Supabase.instance.client;

  final _bioCtrl = TextEditingController();
  Set<String> _selectedSpecs = {};
  bool _isAvailable = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final row = await _db
          .from('profiles')
          .select('bio, specializations, is_available')
          .eq('id', widget.userId)
          .single();
      if (mounted) {
        setState(() {
          _bioCtrl.text = row['bio'] as String? ?? '';
          _selectedSpecs = Set<String>.from(
              (row['specializations'] as List?)?.cast<String>() ?? []);
          _isAvailable = row['is_available'] as bool? ?? true;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _db.from('profiles').update({
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'specializations': _selectedSpecs.toList(),
        'is_available': _isAvailable,
      }).eq('id', widget.userId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profaili imesasishwa'),
              backgroundColor: Color(0xFF00695C)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Hitilafu: $e'),
              backgroundColor: Colors.red.shade700),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFDF6EE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: _loading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(
                  color: Color(0xFF00695C))))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Profaili ya Mtaalamu',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 18, fontWeight: FontWeight.bold,
                          color: const Color(0xFF00695C))),
                  const SizedBox(height: 4),
                  Text('Taarifa hizi zitaonekana kwa wakulima wanaokutafuta',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),

                  // ── Availability toggle ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isAvailable
                          ? const Color(0xFF00695C).withValues(alpha: 0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _isAvailable
                              ? const Color(0xFF00695C).withValues(alpha: 0.3)
                              : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isAvailable
                              ? Icons.circle
                              : Icons.circle_outlined,
                          color: _isAvailable ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAvailable
                                    ? 'Ninapatikana kwa Ushauri'
                                    : 'Nje ya Mtandao / Siwezi Sasa',
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _isAvailable
                                        ? const Color(0xFF00695C)
                                        : Colors.grey.shade700),
                              ),
                              Text(
                                _isAvailable
                                    ? 'Wakulima watakuona kama "Mtandaoni"'
                                    : 'Wakulima watajua utajibu baadaye',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isAvailable,
                          activeThumbColor: const Color(0xFF00695C),
                          activeTrackColor: const Color(0xFF00695C).withValues(alpha: 0.4),
                          onChanged: (v) => setState(() => _isAvailable = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Bio ────────────────────────────────────────────────────
                  Text('Maelezo Yako (Bio)',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13, color: const Color(0xFF004D40))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText:
                          'Mfano: Nina uzoefu wa miaka 10 katika kilimo cha kahawa na mbogamboga...',
                      hintStyle: GoogleFonts.dmSans(
                          color: Colors.grey, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF00695C), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Specializations ────────────────────────────────────────
                  Text('Maeneo ya Utaalamu Wako',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13, color: const Color(0xFF004D40))),
                  const SizedBox(height: 4),
                  Text('Chagua mazao au mada unayoijua vizuri:',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: kSpecializations.map((spec) {
                      final key = spec['key']!;
                      final label = spec['label']!;
                      final selected = _selectedSpecs.contains(key);
                      return FilterChip(
                        label: Text(label,
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF00695C),
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedSpecs.add(key);
                          } else {
                            _selectedSpecs.remove(key);
                          }
                        }),
                        selectedColor: const Color(0xFF00695C),
                        backgroundColor: const Color(0xFF00695C)
                            .withValues(alpha: 0.08),
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                            color: selected
                                ? const Color(0xFF00695C)
                                : const Color(0xFF00695C)
                                    .withValues(alpha: 0.3)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Save button ────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                          _saving ? 'Inahifadhi...' : 'Hifadhi Mabadiliko',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00695C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
