import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../widgets/ai_advisor_box.dart';
import 'messages_screen.dart';
import 'scan_screen.dart';
import 'agrovet_screen.dart';
import 'market_screen.dart';
import 'irrigation_screen.dart';
import 'forum_screen.dart';
import 'login_screen.dart';
import 'pesticides_screen.dart';
import 'seeds_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final displayName = user?.displayName ?? 'Mkulima';
    final role = user?.role ?? UserRole.mkulima;
    final roleColor = AppColors.roleColor(role);

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text(
          'Shamba Smart 🌿',
          style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // Messages icon with unread badge
          _MessagesIcon(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Toka',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome banner ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.soil, roleColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Habari, $displayName! 👋',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RoleChip(role, fontSize: 11),
                        const SizedBox(height: 10),
                        Text(
                          'Piga picha ya jani lililougua ili kupata dawa sahihi.',
                          style: GoogleFonts.dmSans(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  UserAvatarCircle(name: displayName, role: role, size: 52),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick actions row (role-specific) ──────────────────────────
            Text(
              'Vitendo vya Haraka',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.mid,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _quickActions(context, role, roleColor)
                    .map((action) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: Text(action['emoji'] as String,
                                style: const TextStyle(fontSize: 14)),
                            label: Text(
                              action['label'] as String,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                            backgroundColor:
                                roleColor.withValues(alpha: 0.08),
                            side: BorderSide(
                                color: roleColor.withValues(alpha: 0.25)),
                            onPressed: action['onTap'] as VoidCallback,
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── AI Advisor ──────────────────────────────────────────────────
            const AiAdvisorSection(),

            const SizedBox(height: 24),

            // ── Big scan button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: roleColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.camera_alt, size: 26),
                label: Text(
                  'Piga Picha — Gundua Ugonjwa',
                  style: GoogleFonts.dmSans(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ScanScreen())),
              ),
            ),

            const SizedBox(height: 24),

            // ── Activity feed (role-specific) ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shughuli za Hivi Karibuni',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.soil,
                  ),
                ),
                Text(
                  'Ona zote',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: roleColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._activityItems(role).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ActivityTile(
                    emoji: item['emoji'] as String,
                    title: item['title'] as String,
                    subtitle: item['subtitle'] as String,
                    time: item['time'] as String,
                    color: roleColor,
                  ),
                )),

            const SizedBox(height: 24),

            // ── Huduma Zote grid ────────────────────────────────────────────
            Text(
              'Huduma Zote',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.soil,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                _FeatureCard(
                  icon: Icons.question_answer,
                  title: 'Uliza Mtaalamu',
                  subtitle: 'Maswali ya kilimo',
                  color: const Color(0xFF1A5C2E),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ForumScreen())),
                ),
                _FeatureCard(
                  icon: Icons.store,
                  title: 'Maduka ya Dawa',
                  subtitle: 'Pata duka karibu nawe',
                  color: const Color(0xFF2E8B57),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AgrovetScreen())),
                ),
                _FeatureCard(
                  icon: Icons.water_drop,
                  title: 'Umwagiliaji',
                  subtitle: 'Maji sahihi kila siku',
                  color: const Color(0xFF0277BD),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const IrrigationScreen())),
                ),
                _FeatureCard(
                  icon: Icons.trending_up,
                  title: 'Bei za Mazao',
                  subtitle: 'Bei za soko la leo',
                  color: const Color(0xFFFF6F00),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MarketScreen())),
                ),
                _FeatureCard(
                  icon: Icons.science,
                  title: 'Dawa za Kilimo',
                  subtitle: 'TFDA • TPRI Tanzania',
                  color: const Color(0xFF6A1B9A),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const PesticidesScreen())),
                ),
                _FeatureCard(
                  icon: Icons.grass,
                  title: 'Mbegu za TOSCI',
                  subtitle: 'Aina bora za mbegu',
                  color: const Color(0xFF00695C),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SeedsScreen())),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Info footer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.mid.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.leaf, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Teknolojia ya Claude AI inasaidia wakulima '
                      'kugundua magonjwa ya mazao haraka.',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.mid),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Quick actions per role ──────────────────────────────────────────────────

  List<Map<String, dynamic>> _quickActions(
      BuildContext context, UserRole role, Color color) {
    void go(Widget screen) => Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));

    return switch (role) {
      UserRole.mkulima => [
          {'emoji': '🌱', 'label': 'Zao Jipya', 'onTap': () {}},
          {
            'emoji': '📊',
            'label': 'Bei za Soko',
            'onTap': () => go(const MarketScreen())
          },
          {
            'emoji': '💊',
            'label': 'Pata Dawa',
            'onTap': () => go(const PesticidesScreen())
          },
          {
            'emoji': '🌾',
            'label': 'Mbegu',
            'onTap': () => go(const SeedsScreen())
          },
          {'emoji': '🚛', 'label': 'Usafiri', 'onTap': () {}},
          {'emoji': '🌤️', 'label': 'Hali Hewa', 'onTap': () {}},
          {'emoji': '💬', 'label': 'Ongea', 'onTap': () {}},
          {
            'emoji': '🤖',
            'label': 'Mshauri AI',
            'onTap': () => go(const ForumScreen())
          },
        ],
      UserRole.duka => [
          {'emoji': '➕', 'label': 'Ongeza Bidhaa', 'onTap': () {}},
          {'emoji': '👥', 'label': 'Wateja', 'onTap': () {}},
          {'emoji': '🛒', 'label': 'Nunua Mazao', 'onTap': () {}},
          {'emoji': '📋', 'label': 'Orodha Zangu', 'onTap': () {}},
          {
            'emoji': '🌿',
            'label': 'Wakulima',
            'onTap': () => go(const AgrovetScreen())
          },
          {
            'emoji': '🤖',
            'label': 'Mshauri AI',
            'onTap': () => go(const ForumScreen())
          },
        ],
      UserRole.muuzaji => [
          {'emoji': '📝', 'label': 'Toa Orodha', 'onTap': () {}},
          {'emoji': '🛒', 'label': 'Nunua Mazao', 'onTap': () {}},
          {
            'emoji': '📊',
            'label': 'Bei za Soko',
            'onTap': () => go(const MarketScreen())
          },
          {'emoji': '🌿', 'label': 'Wakulima', 'onTap': () {}},
          {'emoji': '🚛', 'label': 'Usafiri', 'onTap': () {}},
          {
            'emoji': '🤖',
            'label': 'Mshauri AI',
            'onTap': () => go(const ForumScreen())
          },
        ],
      UserRole.mwekezaji => [
          {'emoji': '🏡', 'label': 'Mashamba', 'onTap': () {}},
          {'emoji': '📦', 'label': 'Mazao Jumla', 'onTap': () {}},
          {'emoji': '📞', 'label': 'Wasiliana', 'onTap': () {}},
          {'emoji': '📁', 'label': 'Miradi Yangu', 'onTap': () {}},
          {
            'emoji': '📊',
            'label': 'Bei za Soko',
            'onTap': () => go(const MarketScreen())
          },
          {
            'emoji': '🤖',
            'label': 'Mshauri AI',
            'onTap': () => go(const ForumScreen())
          },
        ],
    };
  }

  // ── Activity feed per role ──────────────────────────────────────────────────

  List<Map<String, String>> _activityItems(UserRole role) =>
      switch (role) {
        UserRole.mkulima => [
            {
              'emoji': '🔬',
              'title': 'Ugonjwa uligunduliwa: Mahindi',
              'subtitle': 'Fall Armyworm — ukali: juu — dawa: Coragen SC',
              'time': 'Leo 9:15',
            },
            {
              'emoji': '📊',
              'title': 'Bei mpya: Nyanya',
              'subtitle': 'TZS 1,200/kg — Kariakoo DSM (+8%)',
              'time': 'Jana',
            },
            {
              'emoji': '💧',
              'title': 'Mpango wa umwagiliaji',
              'subtitle': 'Maji 700 lita leo — asubuhi 420L, jioni 280L',
              'time': 'Leo 7:00',
            },
          ],
        UserRole.duka => [
            {
              'emoji': '👤',
              'title': 'Mteja mpya amewasiliana',
              'subtitle': 'Hamisi Omari anataka Coragen SC 500ml',
              'time': 'Dakika 20',
            },
            {
              'emoji': '👁️',
              'title': 'Bidhaa yako imetazamwa',
              'subtitle': 'Mbegu za Nyanya F1 — tazamo 12 leo',
              'time': 'Leo',
            },
            {
              'emoji': '📦',
              'title': 'Bidhaa inaishia',
              'subtitle': 'Ridomil Gold — imebaki pakiti 2 tu',
              'time': 'Jana',
            },
          ],
        UserRole.muuzaji => [
            {
              'emoji': '📈',
              'title': 'Bei ya mahindi imepanda',
              'subtitle': 'TZS 480/kg — Kariakoo (+6% wiki hii)',
              'time': 'Leo',
            },
            {
              'emoji': '🌿',
              'title': 'Mkulima anatafuta mnunuzi',
              'subtitle': 'Fatuma Hassan — tani 3 za mahindi — Morogoro',
              'time': 'Saa 2 iliyopita',
            },
            {
              'emoji': '🚛',
              'title': 'Safari ya kesho imepangwa',
              'subtitle': 'DSM → Morogoro — tani 5 — TZS 120,000',
              'time': 'Jana',
            },
          ],
        UserRole.mwekezaji => [
            {
              'emoji': '🏡',
              'title': 'Shamba jipya linapatikana',
              'subtitle': 'Ekari 10 — Chalinze Pwani — TZS 180,000/mwezi',
              'time': 'Leo',
            },
            {
              'emoji': '💹',
              'title': 'ROI ya mradi imesasishwa',
              'subtitle': 'Alizeti Singida — 18% — miaka 2',
              'time': 'Jana',
            },
            {
              'emoji': '🤝',
              'title': 'Mkulima anahitaji msaada',
              'subtitle': 'Juma Mwangi — ekari 5 — Dodoma — mbegu+mbolea',
              'time': 'Saa 5 iliyopita',
            },
          ],
      };
}

// ── Activity tile widget ─────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ShambaCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child:
                  Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.mid),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.mid),
          ),
        ],
      ),
    );
  }
}

// Chat icon in AppBar with unread count badge
class _MessagesIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final unread = context.watch<ChatProvider>().totalUnread;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'Mazungumzo',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MessagesScreen()),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.harvest,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unread',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Feature grid card ────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
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
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            radius: 24,
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.mid),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
