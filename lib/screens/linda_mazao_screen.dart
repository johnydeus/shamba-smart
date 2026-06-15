import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'crop_protection_screen.dart';
import 'viuatilifu_screen.dart';
import 'ipm_screen.dart';
import 'spray_advisory_screen.dart';

class LindaMazaoScreen extends StatelessWidget {
  const LindaMazaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
                '🛡️ Linda Mazao',
                style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                'Kila kitu cha kulinda mazao yako mahali pamoja',
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
              Tab(text: '🐛 Wadudu'),
              Tab(text: '🧪 Viuatilifu'),
              Tab(text: '📋 IPM'),
              Tab(text: '☁️ Kupulizia'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CropProtectionBody(),
            ViuatiliziBody(),
            IpmBody(),
            SprayAdvisoryBody(),
          ],
        ),
      ),
    );
  }
}
