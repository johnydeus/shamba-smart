import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'seeds_screen.dart';
import 'mbolea_screen.dart';
import 'agrovet_screen.dart';

class PembejeoScreen extends StatelessWidget {
  /// Initial tab: 0 = Mbegu, 1 = Mbolea, 2 = Maduka
  final int initialIndex;
  const PembejeoScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF15803D),
          foregroundColor: Colors.white,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🌱 Pembejeo',
                style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                'Mbegu, mbolea na maduka mahali pamoja',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.80)),
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Colors.white,
            indicatorWeight: 2.5,
            labelStyle: GoogleFonts.dmSans(
                fontSize: 12.5, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12.5),
            tabs: const [
              Tab(text: '🌱 Mbegu'),
              Tab(text: '🧪 Mbolea'),
              Tab(text: '🏪 Maduka'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SeedsBody(),
            MboleaBody(),
            AgrovetBody(),
          ],
        ),
      ),
    );
  }
}
