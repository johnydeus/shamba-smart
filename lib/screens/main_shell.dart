import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'farms_screen.dart';
import 'scan_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'consultation_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> _screens(UserRole role) => [
        const HomeScreen(),
        switch (role) {
          UserRole.mkulima => const FarmsScreen(),
          UserRole.afisa   => const ConsultationScreen(),
          _                => const FarmsScreen(),
        },
        const ScanScreen(),
        const MessagesScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final role = user?.role ?? UserRole.mkulima;
    final roleColor = AppColors.roleColor(role);

    return Scaffold(
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
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final UserRole role;
  final Color roleColor;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.role,
    required this.roleColor,
    required this.onTap,
  });

  String _tab2Label(UserRole role) => switch (role) {
        UserRole.afisa => 'Wakulima',
        _              => 'Mashamba',
      };

  IconData _tab2Icon(UserRole role) => switch (role) {
        UserRole.afisa => Icons.people_outline,
        _              => Icons.agriculture_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      color: const Color(0xFFFFFDF8),
      elevation: 8,
      child: SizedBox(
        height: 62 + bottomPadding,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home,
                  label: 'Nyumbani', index: 0, current: currentIndex,
                  color: roleColor, onTap: onTap),
              _NavItem(icon: _tab2Icon(role), activeIcon: _tab2Icon(role),
                  label: _tab2Label(role), index: 1, current: currentIndex,
                  color: AppColors.leaf, onTap: onTap),
              // Scan — centre button with elevated style
              _ScanNavItem(isActive: currentIndex == 2, onTap: () => onTap(2)),
              _NavItem(icon: Icons.forum_outlined, activeIcon: Icons.forum,
                  label: 'Jamii', index: 3, current: currentIndex,
                  color: roleColor, onTap: onTap),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person,
                  label: 'Akaunti', index: 4, current: currentIndex,
                  color: roleColor, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Centre scan button ────────────────────────────────────────────────────────

class _ScanNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _ScanNavItem({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive ? AppColors.leaf : AppColors.leaf.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.leaf.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.document_scanner_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(height: 2),
            Text('Scan',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.leaf : const Color(0xFF9E9E9E),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final Color color;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.index, required this.current, required this.color,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(isActive ? activeIcon : icon,
                  color: isActive ? color : const Color(0xFF9E9E9E), size: 22),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? color : const Color(0xFF9E9E9E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
