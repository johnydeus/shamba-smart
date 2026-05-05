import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'marketplace_screen.dart';
import 'satellite_screen.dart';
import 'soil_screen.dart';
import 'farms_screen.dart';
import 'consultation_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> _screens(UserRole role) => [
        const HomeScreen(),
        const SatelliteScreen(),
        switch (role) {
          UserRole.mkulima => const FarmsScreen(),
          UserRole.afisa   => const ConsultationScreen(),
          _                => const SoilScreen(),
        },
        const MarketplaceScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final role = user?.role ?? UserRole.mkulima;
    final roleColor = AppColors.roleColor(role);

    return Scaffold(
      // Prevent keyboard from pushing/hiding the bottom navigation bar
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens(role),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        role: role,
        roleColor: roleColor,
        onTap: (i) => setState(() => _currentIndex = i),
        tab3Icon: _tab3Icon(role),
        tab3Label: _tab3Label(role),
      ),
    );
  }

  IconData _tab3Icon(UserRole role) => switch (role) {
        UserRole.mkulima => Icons.agriculture_outlined,
        UserRole.afisa   => Icons.people_outline,
        _                => Icons.landscape_outlined,
      };

  String _tab3Label(UserRole role) => switch (role) {
        UserRole.mkulima => 'Mashamba',
        UserRole.afisa   => 'Wakulima',
        _                => 'Udongo',
      };
}

// ── Fixed bottom navigation — never hidden by keyboard ───────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final UserRole role;
  final Color roleColor;
  final ValueChanged<int> onTap;
  final IconData tab3Icon;
  final String tab3Label;

  const _BottomNav({
    required this.currentIndex,
    required this.role,
    required this.roleColor,
    required this.onTap,
    required this.tab3Icon,
    required this.tab3Label,
  });

  @override
  Widget build(BuildContext context) {
    // SafeArea bottom accounts for home indicator on modern phones
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      color: const Color(0xFFFFFDF8), // AppColors.cream
      elevation: 8,
      child: SizedBox(
        height: 62 + bottomPadding,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Nyumbani',
                index: 0,
                current: currentIndex,
                color: roleColor,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.satellite_alt_outlined,
                activeIcon: Icons.satellite_alt,
                label: 'Sateliti',
                index: 1,
                current: currentIndex,
                color: AppColors.leaf,
                onTap: onTap,
              ),
              _NavItem(
                icon: tab3Icon,
                activeIcon: tab3Icon,
                label: tab3Label,
                index: 2,
                current: currentIndex,
                color: roleColor,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront,
                label: 'Masoko',
                index: 3,
                current: currentIndex,
                color: roleColor,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Akaunti',
                index: 4,
                current: currentIndex,
                color: roleColor,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final Color color;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? color : const Color(0xFF9E9E9E),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? color : const Color(0xFF9E9E9E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
