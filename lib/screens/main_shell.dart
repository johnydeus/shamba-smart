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
        role == UserRole.mkulima
            ? const FarmsScreen()   // farmers manage their farms here
            : const SoilScreen(),   // others still get soil data
        const MarketplaceScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final role = user?.role ?? UserRole.mkulima;
    final roleColor = AppColors.roleColor(role);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens(role),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.cream,
        indicatorColor: roleColor.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          // Tab 1 — Nyumbani
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: roleColor),
            label: 'Nyumbani',
          ),
          // Tab 2 — Sateliti
          NavigationDestination(
            icon: const Icon(Icons.satellite_alt_outlined),
            selectedIcon:
                Icon(Icons.satellite_alt, color: AppColors.leaf),
            label: 'Sateliti',
          ),
          // Tab 3 — Udongo (Mashamba for mkulima)
          NavigationDestination(
            icon: Icon(_tab3Icon(role)),
            selectedIcon: Icon(_tab3Icon(role), color: roleColor),
            label: _tab3Label(role),
          ),
          // Tab 4 — Masoko
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: roleColor),
            label: 'Masoko',
          ),
          // Tab 5 — Akaunti
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: roleColor),
            label: 'Akaunti',
          ),
        ],
      ),
    );
  }

  // Tab 3: mkulima sees Mashamba, everyone else sees Udongo
  IconData _tab3Icon(UserRole role) =>
      role == UserRole.mkulima ? Icons.agriculture_outlined : Icons.landscape_outlined;

  String _tab3Label(UserRole role) =>
      role == UserRole.mkulima ? 'Mashamba' : 'Udongo';
}
