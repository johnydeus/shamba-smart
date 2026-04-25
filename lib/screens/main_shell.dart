import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'marketplace_screen.dart';
import 'satellite_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // IndexedStack keeps each screen alive while switching tabs
  final List<Widget> _screens = const [
    HomeScreen(),
    MarketplaceScreen(),
    SatelliteScreen(),   // NEW — Satellite Crop Analysis
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final role = user?.role ?? UserRole.mkulima;
    final roleColor = AppColors.roleColor(role);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.cream,
        indicatorColor: roleColor.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          // Tab 1 — Home
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: roleColor),
            label: 'Nyumbani',
          ),
          // Tab 2 — Marketplace
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: roleColor),
            label: 'Soko',
          ),
          // Tab 3 — Satellite (new)
          NavigationDestination(
            icon: const Icon(Icons.satellite_alt_outlined),
            selectedIcon:
                Icon(Icons.satellite_alt, color: AppColors.leaf),
            label: 'Satellite',
          ),
          // Tab 4 — Role-specific stats
          NavigationDestination(
            icon: Icon(_tab4Icon(role)),
            selectedIcon: Icon(_tab4Icon(role), color: roleColor),
            label: _tab4Label(role),
          ),
          // Tab 5 — Profile
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: roleColor),
            label: 'Akaunti',
          ),
        ],
      ),
    );
  }

  IconData _tab4Icon(UserRole role) => switch (role) {
        UserRole.mkulima   => Icons.landscape_outlined,
        UserRole.duka      => Icons.store_outlined,
        UserRole.muuzaji   => Icons.show_chart,
        UserRole.mwekezaji => Icons.account_balance_wallet_outlined,
      };

  String _tab4Label(UserRole role) => switch (role) {
        UserRole.mkulima   => 'Shamba',
        UserRole.duka      => 'Duka',
        UserRole.muuzaji   => 'Biashara',
        UserRole.mwekezaji => 'Uwekezaji',
      };
}
