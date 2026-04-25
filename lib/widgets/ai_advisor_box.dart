import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/ai_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

// The pulsing green dot shown when Claude is thinking
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.sprout,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── AiResponseBox ─────────────────────────────────────────────────────────────
// Dark-themed display area showing idle / loading / response / error states.

class AiResponseBox extends StatelessWidget {
  const AiResponseBox({super.key});

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 80,
        maxHeight: ai.state == AiState.idle ? 80 : 220,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.soil,
        borderRadius: BorderRadius.circular(12),
      ),
      child: switch (ai.state) {
        // ── Idle ─────────────────────────────────────────────────────────
        AiState.idle => Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Uliza swali lolote... 🌱',
                  style: GoogleFonts.dmSans(
                    color: AppColors.mid,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),

        // ── Loading ───────────────────────────────────────────────────────
        AiState.loading => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _PulsingDot(),
                  const SizedBox(width: 8),
                  Text(
                    'Claude anafikiri...',
                    style: GoogleFonts.dmSans(
                      color: AppColors.sprout,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Blinking cursor lines
              _ShimmerLine(width: double.infinity),
              const SizedBox(height: 8),
              _ShimmerLine(width: 220),
              const SizedBox(height: 8),
              _ShimmerLine(width: 160),
            ],
          ),

        // ── Success ───────────────────────────────────────────────────────
        AiState.success => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _PulsingDot(),
                    const SizedBox(width: 8),
                    Text(
                      'Jibu la Claude AI',
                      style: GoogleFonts.dmSans(
                        color: AppColors.sprout,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.read<AiProvider>().reset(),
                      child: const Icon(Icons.close,
                          color: AppColors.mid, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ai.response,
                  style: GoogleFonts.dmSans(
                    color: AppColors.cream,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

        // ── Error ─────────────────────────────────────────────────────────
        AiState.error => Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  color: AppColors.sun, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ai.response,
                  style: GoogleFonts.dmSans(
                    color: AppColors.sun,
                    fontSize: 13,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.read<AiProvider>().reset(),
                child: const Icon(Icons.refresh,
                    color: AppColors.mid, size: 18),
              ),
            ],
          ),
      },
    );
  }
}

// Shimmer line placeholder while loading
class _ShimmerLine extends StatefulWidget {
  final double width;
  const _ShimmerLine({required this.width});

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.15, end: 0.35).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.mid,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

// ── AiAdvisorSection ─────────────────────────────────────────────────────────
// The complete home-screen widget: header + response box + input row.

class AiAdvisorSection extends StatefulWidget {
  const AiAdvisorSection({super.key});

  @override
  State<AiAdvisorSection> createState() => _AiAdvisorSectionState();
}

class _AiAdvisorSectionState extends State<AiAdvisorSection> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;

    final user = context.read<AuthProvider>().currentUser;
    _ctrl.clear();

    await context.read<AiProvider>().askQuestion(
          question: q,
          userRole: user?.role.label ?? 'Mkulima',
          userRegion: user?.region ?? 'Tanzania',
        );
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    final isLoading = ai.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.earth,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Mshauri wa AI',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.leaf.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Claude AI',
                  style: GoogleFonts.dmSans(
                      color: AppColors.sprout,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Response display box
          const AiResponseBox(),

          const SizedBox(height: 12),

          // Input row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    enabled: !isLoading,
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontSize: 13),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _ask(),
                    decoration: InputDecoration(
                      hintText: 'Andika swali lako hapa...',
                      hintStyle: GoogleFonts.dmSans(
                          color: AppColors.mid, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isLoading ? null : _ask,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (_hasText && !isLoading)
                        ? AppColors.sprout
                        : AppColors.mid.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
