import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'scan_screen.dart';
import 'soil_screen.dart';
import 'consultation_screen.dart';
import 'agrovet_screen.dart';
import 'market_screen.dart';
import 'irrigation_screen.dart';
import 'forum_screen.dart';
import 'login_screen.dart';
import 'pesticides_screen.dart';
import 'seeds_screen.dart';
import 'crop_protection_screen.dart';
import 'messages_screen.dart';
import 'farms_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

const _kGreen     = Color(0xFF1B4332);
const _kGreenDark = Color(0xFF081C15);
const _kGreenMid  = Color(0xFF2D6A4F);
const _kMint      = Color(0xFFD8F3DC);
const _kGold      = Color(0xFFFFB703);
const _kGoldLight = Color(0xFFFFD60A);

TextStyle _jakarta({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = Colors.black,
  double height = 1.4,
}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size, fontWeight: weight, color: color, height: height);

// ── HomeScreen ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final firstName = user?.firstName ?? 'Mkulima';
    final role = user?.role ?? UserRole.mkulima;
    final unread = context.watch<ChatProvider>().totalUnread;

    void go(Widget screen) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Header(
              firstName: firstName,
              role: role,
              unread: unread,
              onMessages: () => go(const MessagesScreen()),
              onLogout: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
            ),
          ),

          // ── Hero Diagnostic Card ────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroDiagnosticCard(
              scanCtrl: _scanCtrl,
              pulseCtrl: _pulseCtrl,
              onTap: () => go(const ScanScreen()),
            ),
          ),

          // ── Quick actions ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _QuickActions(role: role, go: go),
          ),

          // ── Bento grid ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _BentoGrid(go: go),
          ),

          // ── Huduma section ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ServicesSection(role: role, go: go),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String firstName;
  final UserRole role;
  final int unread;
  final VoidCallback onMessages;
  final VoidCallback onLogout;

  const _Header({
    required this.firstName,
    required this.role,
    required this.unread,
    required this.onMessages,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Organic curved background
        CustomPaint(
          size: Size(MediaQuery.of(context).size.width, 220),
          painter: _HeaderPainter(),
        ),

        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: logo + actions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('🌿',
                              style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text('Shamba Smart',
                              style: _jakarta(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Messages
                    _GlassIconBtn(
                      onTap: onMessages,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 22),
                          if (unread > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                    color: _kGold,
                                    shape: BoxShape.circle),
                                child: Text('$unread',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GlassIconBtn(
                      onTap: onLogout,
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Greeting row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: _jakarta(
                                size: 13,
                                color: _kMint,
                                weight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            firstName,
                            style: _jakarta(
                                size: 28,
                                weight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1),
                          ),
                          const SizedBox(height: 8),
                          _RoleChip(role: role),
                        ],
                      ),
                    ),
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_kGold, _kGoldLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _kGold.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'M',
                          style: _jakarta(
                              size: 24,
                              weight: FontWeight.w800,
                              color: _kGreenDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Habari za Asubuhi ☀️';
    if (h < 17) return 'Habari za Mchana 🌤️';
    return 'Habari za Jioni 🌙';
  }
}

class _GlassIconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _GlassIconBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final UserRole role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: _kGold, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(role.label,
              style: _jakarta(
                  size: 11,
                  weight: FontWeight.w600,
                  color: _kGold)),
        ],
      ),
    );
  }
}

// Custom painter for organic header wave
class _HeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [_kGreenDark, _kGreen],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.72)
      ..cubicTo(
        size.width * 0.75, size.height * 0.95,
        size.width * 0.35, size.height * 0.82,
        0, size.height,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Decorative circles
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.15), 80, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.85), 50, circlePaint);

    // Dot grid pattern (subtle)
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int x = 0; x < 6; x++) {
      for (int y = 0; y < 4; y++) {
        canvas.drawCircle(
          Offset(size.width * 0.6 + x * 18.0, 20.0 + y * 18.0),
          1.5,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Hero Diagnostic Card ──────────────────────────────────────────────────────

class _HeroDiagnosticCard extends StatelessWidget {
  final AnimationController scanCtrl;
  final AnimationController pulseCtrl;
  final VoidCallback onTap;

  const _HeroDiagnosticCard({
    required this.scanCtrl,
    required this.pulseCtrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 210,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kGreenMid, _kGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _kGreen.withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: CustomPaint(painter: _HeroBgPainter()),
                ),

                // Scan line animation
                AnimatedBuilder(
                  animation: scanCtrl,
                  builder: (context, _) {
                    final y = scanCtrl.value;
                    return Positioned(
                      left: 24,
                      right: 24,
                      top: 24 + (162.0 * y), // animate from top to bottom
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _kGold.withValues(alpha: 0.9),
                              _kGoldLight,
                              _kGold.withValues(alpha: 0.9),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kGold.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Corner brackets (viewfinder)
                ..._cornerBrackets(),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _kGold.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                      color: _kGold,
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 5),
                                Text('AI Inafanya Kazi',
                                    style: _jakarta(
                                        size: 10,
                                        weight: FontWeight.w600,
                                        color: _kGold)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ],
                      ),

                      const Spacer(),

                      Text('Gundua Ugonjwa',
                          style: _jakarta(
                              size: 22,
                              weight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1)),
                      const SizedBox(height: 4),
                      Text('Piga picha ya jani — AI itachunguza',
                          style: _jakarta(
                              size: 13,
                              color: _kMint.withValues(alpha: 0.8))),

                      const SizedBox(height: 16),

                      // CTA Row
                      Row(
                        children: [
                          // Animated pulse button
                          AnimatedBuilder(
                            animation: pulseCtrl,
                            builder: (_, child) {
                              final scale =
                                  1.0 + 0.06 * pulseCtrl.value;
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: _kGold,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kGold.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.camera_alt_rounded,
                                      color: _kGreenDark, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Piga Picha',
                                      style: _jakarta(
                                          size: 13,
                                          weight: FontWeight.w700,
                                          color: _kGreenDark)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Text scan option
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Text('Elezea Dalili',
                                style: _jakarta(
                                    size: 13,
                                    weight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _cornerBrackets() {
    const size = 20.0;
    const thickness = 2.5;
    const color = _kGold;
    const radius = 6.0;
    const padding = 18.0;

    Widget bracket(
        {bool top = true, bool left = true}) {
      return Positioned(
        top: top ? padding : null,
        bottom: top ? null : padding,
        left: left ? padding : null,
        right: left ? null : padding,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _BracketPainter(
              top: top,
              left: left,
              color: color,
              thickness: thickness,
              radius: radius,
            ),
          ),
        ),
      );
    }

    return [
      bracket(top: true, left: true),
      bracket(top: true, left: false),
      bracket(top: false, left: true),
      bracket(top: false, left: false),
    ];
  }
}

class _BracketPainter extends CustomPainter {
  final bool top;
  final bool left;
  final Color color;
  final double thickness;
  final double radius;

  const _BracketPainter({
    required this.top,
    required this.left,
    required this.color,
    required this.thickness,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (top && left) {
      path.moveTo(0, h);
      path.lineTo(0, radius);
      path.arcToPoint(Offset(radius, 0),
          radius: Radius.circular(radius), clockwise: true);
      path.lineTo(w, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(w - radius, 0);
      path.arcToPoint(Offset(w, radius),
          radius: Radius.circular(radius), clockwise: true);
      path.lineTo(w, h);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, h - radius);
      path.arcToPoint(Offset(radius, h),
          radius: Radius.circular(radius), clockwise: false);
      path.lineTo(w, h);
    } else {
      path.moveTo(0, h);
      path.lineTo(w - radius, h);
      path.arcToPoint(Offset(w, h - radius),
          radius: Radius.circular(radius), clockwise: false);
      path.lineTo(w, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    // Decorative circles
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.2), 80, paint);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.8), 60, paint);

    // Grid lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final UserRole role;
  final void Function(Widget) go;

  const _QuickActions({required this.role, required this.go});

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text('Vitendo vya Haraka',
              style: _jakarta(
                  size: 16,
                  weight: FontWeight.w700,
                  color: _kGreenDark)),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: actions.length,
            separatorBuilder: (context, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _QuickChip(
              emoji: actions[i]['emoji'] as String,
              label: actions[i]['label'] as String,
              color: actions[i]['color'] as Color,
              onTap: actions[i]['onTap'] as VoidCallback,
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _actions(BuildContext ctx) {
    void nav(Widget w) => go(w);
    return [
      {'emoji': '🛡️', 'label': 'Ulinzi', 'color': const Color(0xFFE65100),
       'onTap': () => nav(const CropProtectionScreen())},
      {'emoji': '💧', 'label': 'Maji', 'color': const Color(0xFF0277BD),
       'onTap': () => nav(const IrrigationScreen())},
      {'emoji': '🌾', 'label': 'Mbegu', 'color': _kGreenMid,
       'onTap': () => nav(const SeedsScreen())},
      {'emoji': '💊', 'label': 'Viuatilifu', 'color': const Color(0xFF6A1B9A),
       'onTap': () => nav(const PesticidesScreen())},
      {'emoji': '🏪', 'label': 'Maduka', 'color': const Color(0xFF2E8B57),
       'onTap': () => nav(const AgrovetScreen())},
      {'emoji': '🤖', 'label': 'Mshauri AI', 'color': _kGreen,
       'onTap': () => nav(const ForumScreen())},
      if (role == UserRole.afisa)
        {'emoji': '👨‍🌾', 'label': 'Wakulima', 'color': const Color(0xFF00695C),
         'onTap': () => nav(const ConsultationScreen())},
      if (role == UserRole.mkulima)
        {'emoji': '🌍', 'label': 'Udongo', 'color': const Color(0xFF795548),
         'onTap': () => nav(const SoilScreen())},
    ];
  }
}

class _QuickChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(label,
                style: _jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Bento Grid ────────────────────────────────────────────────────────────────

class _BentoGrid extends StatelessWidget {
  final void Function(Widget) go;
  const _BentoGrid({required this.go});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashibodi',
              style: _jakarta(
                  size: 16, weight: FontWeight.w700, color: _kGreenDark)),
          const SizedBox(height: 14),

          // Row 1: Weather (tall) + Soil (shorter)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _WeatherBentoCard(),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _SoilHealthBentoCard(
                        onTap: () => go(const SoilScreen())),
                    const SizedBox(height: 12),
                    _CommunityBentoCard(
                        onTap: () => go(const ForumScreen())),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Market Prices (full width sparkline)
          _MarketBentoCard(onTap: () => go(const MarketScreen())),
        ],
      ),
    );
  }
}

// ── Weather Card ──────────────────────────────────────────────────────────────

class _WeatherBentoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wb_sunny_rounded,
                    color: _kGold, size: 20),
              ),
              const Spacer(),
              Text('Leo',
                  style: _jakarta(
                      size: 11,
                      color: Colors.white60,
                      weight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          Text('27°C',
              style: _jakarta(
                  size: 36,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0)),
          const SizedBox(height: 4),
          Text('Jua na Mawingu',
              style: _jakarta(size: 12, color: Colors.white70)),
          const SizedBox(height: 16),

          // Mini forecast row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniWeather('Kesho', '☁️', '24°'),
              _MiniWeather('Ijumaa', '🌧️', '22°'),
              _MiniWeather('Jumamosi', '☀️', '29°'),
            ],
          ),

          const SizedBox(height: 12),

          // Humidity + wind row
          Row(
            children: [
              _WeatherStat(Icons.water_drop_outlined, '65%', 'Unyevu'),
              const SizedBox(width: 12),
              _WeatherStat(Icons.air, '8km/h', 'Upepo'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniWeather extends StatelessWidget {
  final String day;
  final String icon;
  final String temp;
  const _MiniWeather(this.day, this.icon, this.temp);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(day,
            style: _jakarta(size: 10, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(temp,
            style: _jakarta(
                size: 11, color: Colors.white, weight: FontWeight.w600)),
      ],
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _WeatherStat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: _jakarta(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Colors.white)),
              Text(label,
                  style: _jakarta(size: 9, color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Soil Health Card ──────────────────────────────────────────────────────────

class _SoilHealthBentoCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SoilHealthBentoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF795548).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.landscape_rounded,
                      color: Color(0xFF795548), size: 16),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 10),
            Text('Udongo',
                style: _jakarta(
                    size: 12,
                    weight: FontWeight.w700,
                    color: _kGreenDark)),
            const SizedBox(height: 6),

            // Mini gauge
            SizedBox(
              height: 54,
              child: CustomPaint(
                painter: _GaugePainter(
                  value: 0.72,
                  color: const Color(0xFF795548),
                ),
                size: const Size(double.infinity, 54),
              ),
            ),

            const SizedBox(height: 4),
            Text('pH 6.8 — Nzuri',
                style: _jakarta(
                    size: 10,
                    color: _kGreenMid,
                    weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  const _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.85;
    final r = size.height * 0.75;
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Value arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepAngle * value,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Center value text
    final tp = TextPainter(
      text: TextSpan(
        text: '${(value * 100).toInt()}%',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height - 4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Community Card ────────────────────────────────────────────────────────────

class _CommunityBentoCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CommunityBentoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _kGreen.withValues(alpha: 0.9),
              _kGreenMid,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(height: 8),
            Text('Jamii',
                style: _jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text('6 machapisho mapya',
                style: _jakarta(size: 10, color: _kMint)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final emoji in ['🌿', '💰', '🦠'])
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Market Prices Card ────────────────────────────────────────────────────────

class _MarketBentoCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MarketBentoCard({required this.onTap});

  static const _prices = [
    {'crop': 'Mahindi', 'price': 480, 'trend': 0.08, 'emoji': '🌽'},
    {'crop': 'Nyanya',  'price': 1200,'trend': 0.15, 'emoji': '🍅'},
    {'crop': 'Maharagwe','price': 2200,'trend':-0.05,'emoji': '🫘'},
  ];

  static const List<List<double>> _sparkData = [
    [400.0, 420.0, 410.0, 460.0, 440.0, 480.0, 475.0, 490.0],
    [900.0, 950.0, 1000.0, 980.0, 1100.0, 1150.0, 1200.0, 1190.0],
    [2300.0, 2250.0, 2200.0, 2220.0, 2180.0, 2200.0, 2210.0, 2200.0],
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.trending_up_rounded,
                      color: _kGold, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Bei za Soko',
                    style: _jakarta(
                        size: 15,
                        weight: FontWeight.w700,
                        color: _kGreenDark)),
                const Spacer(),
                Text('Kariakoo, Dar',
                    style: _jakarta(size: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),

            for (int i = 0; i < _prices.length; i++) ...[
              _PriceRow(
                emoji: _prices[i]['emoji'] as String,
                crop: _prices[i]['crop'] as String,
                price: _prices[i]['price'] as int,
                trend: _prices[i]['trend'] as double,
                sparkData: _sparkData[i],
              ),
              if (i < _prices.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                      height: 1,
                      color: Colors.grey.withValues(alpha: 0.1)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String emoji;
  final String crop;
  final int price;
  final double trend;
  final List<double> sparkData;

  const _PriceRow({
    required this.emoji,
    required this.crop,
    required this.price,
    required this.trend,
    required this.sparkData,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = trend > 0;
    final trendColor = isUp ? const Color(0xFF2E7D32) : Colors.red;
    final trendLabel =
        '${isUp ? '+' : ''}${(trend * 100).toStringAsFixed(0)}%';

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(crop,
                  style: _jakarta(
                      size: 13,
                      weight: FontWeight.w600,
                      color: _kGreenDark)),
              Text('TZS $price/kg',
                  style: _jakarta(size: 11, color: Colors.grey)),
            ],
          ),
        ),
        // Sparkline
        SizedBox(
          width: 60,
          height: 30,
          child: CustomPaint(
            painter: _SparklinePainter(
              data: sparkData,
              color: isUp ? const Color(0xFF2E7D32) : Colors.red,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: trendColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 10,
                color: trendColor,
              ),
              const SizedBox(width: 2),
              Text(trendLabel,
                  style: _jakarta(
                      size: 10,
                      weight: FontWeight.w700,
                      color: trendColor)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  const _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final minV = data.reduce(math.min);
    final maxV = data.reduce(math.max);
    final range = (maxV - minV).clamp(1.0, double.infinity);

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height - (data[i] - minV) / range * size.height;
      points.add(Offset(x, y));
    }

    // Fill
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dot at last point
    canvas.drawCircle(
      points.last,
      3,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Services Section ──────────────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  final UserRole role;
  final void Function(Widget) go;

  const _ServicesSection({required this.role, required this.go});

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceItem('🌱', 'Mbegu za TOSCI', _kGreenMid,
          () => go(const SeedsScreen())),
      _ServiceItem('🏪', 'Maduka ya Dawa', const Color(0xFF2E8B57),
          () => go(const AgrovetScreen())),
      _ServiceItem('💧', 'Umwagiliaji', const Color(0xFF0277BD),
          () => go(const IrrigationScreen())),
      _ServiceItem('📊', 'Bei za Mazao', const Color(0xFFFF6F00),
          () => go(const MarketScreen())),
      _ServiceItem('🧪', 'Viuatilifu', const Color(0xFF6A1B9A),
          () => go(const PesticidesScreen())),
      _ServiceItem('🛡️', 'Ulinzi wa Mazao', const Color(0xFFE65100),
          () => go(const CropProtectionScreen())),
      if (role == UserRole.mkulima || role == UserRole.afisa)
        _ServiceItem('🌍', 'Data ya Udongo', const Color(0xFF795548),
            () => go(const SoilScreen())),
      if (role == UserRole.mkulima)
        _ServiceItem('🏡', 'Mashamba Yangu', _kGreen,
            () => go(const FarmsScreen())),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Huduma Zote',
              style: _jakarta(
                  size: 16,
                  weight: FontWeight.w700,
                  color: _kGreenDark)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: services.length,
            itemBuilder: (_, i) => _ServiceTile(item: services[i]),
          ),
        ],
      ),
    );
  }
}

class _ServiceItem {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ServiceItem(this.emoji, this.label, this.color, this.onTap);
}

class _ServiceTile extends StatelessWidget {
  final _ServiceItem item;
  const _ServiceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
              color: item.color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(item.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.label,
                  style: _jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: _kGreenDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
