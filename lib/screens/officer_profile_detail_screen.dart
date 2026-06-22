import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/field_officer.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

/// Wasifu — full profile of a field officer (Afisa Kilimo).
class OfficerProfileDetailScreen extends StatelessWidget {
  final FieldOfficer officer;
  const OfficerProfileDetailScreen({super.key, required this.officer});

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          contactId: officer.userId,
          contactName: officer.fullName,
          contactRole: UserRole.afisa,
          contactColorHex: '00695C',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = officer;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        title: Text('Wasifu wa Mtaalamu',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF00695C).withValues(alpha: 0.1),
                child: Text(
                  o.fullName.isNotEmpty ? o.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00695C)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.fullName,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 19, fontWeight: FontWeight.bold)),
                    Text('${o.title} — ${o.region}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 6),
                    _statusBadge(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Quick stats ──
          Row(
            children: [
              _stat(o.ratingCount == 0 ? 'Mpya' : o.rating.toStringAsFixed(1),
                  o.ratingCount == 0 ? 'Hakuna kura' : 'Kura ${o.ratingCount}'),
              _stat('${o.farmersServed}', 'Wakulima'),
              _stat(
                  o.avgResponseHours == null
                      ? '—'
                      : '${o.avgResponseHours!.round()}h',
                  'Hujibu'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Wasifu ──
          _sectionTitle('Wasifu'),
          Text(o.wasifu.isEmpty ? '—' : o.wasifu,
              style: GoogleFonts.dmSans(fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),

          // ── Crops ──
          if (o.crops.isNotEmpty) ...[
            _sectionTitle('Mazao anayobobea'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: o.crops
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.leaf.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(c,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.leaf,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ── Visit fee ──
          if (o.visitFeeTzs != null) ...[
            _sectionTitle('Ada ya ziara'),
            Text('TZS ${o.visitFeeTzs}',
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
          ],

          // ── Contacts ──
          _sectionTitle('Mawasiliano'),
          if ((o.phone ?? '').isNotEmpty)
            _contactTile(Icons.call, 'Piga simu', o.phone!,
                () => _launch(Uri.parse('tel:${o.phone!.replaceAll(' ', '')}'))),
          if ((o.whatsapp ?? '').isNotEmpty)
            _contactTile(Icons.chat, 'WhatsApp', o.whatsapp!, () {
              final clean = o.whatsapp!.replaceAll(RegExp(r'[^0-9]'), '');
              _launch(Uri.parse('https://wa.me/$clean'));
            }),
          if ((o.email ?? '').isNotEmpty)
            _contactTile(Icons.email_outlined, 'Barua pepe', o.email!,
                () => _launch(Uri.parse('mailto:${o.email}'))),

          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.harvest,
                  foregroundColor: Colors.white),
              icon: const Icon(Icons.send),
              label: Text('Tuma Ujumbe',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () => _openChat(context),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    if (officer.verified) {
      return Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.verified, color: Color(0xFF1565C0), size: 16),
        SizedBox(width: 4),
        Text('Imethibitishwa',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w600)),
      ]);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
      child: Text('Inasubiri uthibitisho',
          style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00695C))),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.soil)),
      );

  Widget _contactTile(
          IconData icon, String label, String value, VoidCallback onTap) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: const Color(0xFF00695C)),
        title: Text(label, style: const TextStyle(fontSize: 13)),
        subtitle: Text(value, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
        onTap: onTap,
      );
}
