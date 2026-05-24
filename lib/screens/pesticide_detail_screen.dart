// pesticide_detail_screen.dart
// Full detail view for one TPRI-registered pesticide.
// Shown when a farmer taps a card in ViuatiliziScreen.

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/fade_slide_route.dart';
import '../services/pesticide_service.dart';
import '../theme/app_theme.dart';
import '../widgets/info_card.dart';
import '../widgets/shamba_button.dart';
import '../widgets/status_badge.dart';
import 'agrovet_screen.dart';

List<String> _parseCrops(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) return raw.map((e) => e.toString()).toList();
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    return raw
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return [];
}

class PesticideDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pesticide;
  final String? heroTag;

  const PesticideDetailScreen({
    super.key,
    required this.pesticide,
    this.heroTag,
  });

  @override
  State<PesticideDetailScreen> createState() => _PesticideDetailScreenState();
}

class _PesticideDetailScreenState extends State<PesticideDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  double _farmAcres = 2.5;

  Map<String, dynamic> get pesticide => widget.pesticide;

  String get _heroTag =>
      widget.heroTag ??
      'pesticide-${pesticide['brand_name'] ?? pesticide.hashCode}';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  double? _parseDoseMl() {
    final raw = pesticide['ml_per_15l'] ?? pesticide['dose_per_15l'];
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    final s = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s);
  }

  /// Rough field estimate: ~4 tanks of 15L mix per acre (visual aid only).
  double? _totalMlNeeded() {
    final dose = _parseDoseMl();
    if (dose == null) return null;
    return dose * _farmAcres * 4;
  }

  @override
  Widget build(BuildContext context) {
    final name = pesticide['brand_name'] as String? ?? '';
    final ingredient = pesticide['active_ingredient'] as String? ?? '';
    final registrant = pesticide['manufacturer'] as String? ?? '';
    final usage = pesticide['description_sw'] as String? ?? '';
    final category = pesticide['category'] as String? ?? '';
    final typeLabel = PesticideService.getTypeLabel(category);
    final typeColor = Color(PesticideService.getTypeColor(category));
    final isRestricted = category == 'restricted_herbicide';
    final phi = pesticide['phi_days'] as int?;
    final dose = pesticide['ml_per_15l'] ?? pesticide['dose_per_15l'];
    final crops = _parseCrops(pesticide['target_crops']);
    final totalMl = _totalMlNeeded();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: _heroTag,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryMedium],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(56, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _TypeBadge(typeLabel, typeColor),
                              const SizedBox(width: 8),
                              const StatusBadge(
                                label: 'TPRI ✓',
                                type: BadgeType.healthy,
                                showDot: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.white,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.textOnDarkSoft,
              tabs: const [
                Tab(text: 'Maelezo'),
                Tab(text: 'Matumizi'),
                Tab(text: 'Usalama'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _DescriptionTab(
              ingredient: ingredient,
              registrant: registrant,
              isRestricted: isRestricted,
              usage: usage,
              crops: crops,
              hasImages: _hasImages(),
              imageUrls: _imageUrls(),
            ),
            _UsageTab(
              usage: usage,
              crops: crops,
              dose: dose,
              name: name,
              farmAcres: _farmAcres,
              totalMl: totalMl,
              onAcresChanged: (v) => setState(() => _farmAcres = v),
            ),
            _SafetyTab(
              isRestricted: isRestricted,
              phi: phi,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ShambaButton(
            label: 'Pata Dawa Karibu Nawe',
            icon: Icons.store_outlined,
            fullWidth: true,
            onPressed: () {
              Navigator.push(
                context,
                FadeSlideRoute(page: const AgrovetScreen()),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _hasImages() {
    return pesticide['image_url_1'] != null ||
        pesticide['image_url_2'] != null ||
        pesticide['image_url_3'] != null;
  }

  List<String> _imageUrls() {
    return [
      pesticide['image_url_1'],
      pesticide['image_url_2'],
      pesticide['image_url_3'],
    ].where((u) => u != null).cast<String>().toList();
  }
}

// ── Tab 1: Maelezo ────────────────────────────────────────────────────────────

class _DescriptionTab extends StatelessWidget {
  final String ingredient;
  final String registrant;
  final bool isRestricted;
  final String usage;
  final List<String> crops;
  final bool hasImages;
  final List<String> imageUrls;

  const _DescriptionTab({
    required this.ingredient,
    required this.registrant,
    required this.isRestricted,
    required this.usage,
    required this.crops,
    required this.hasImages,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (isRestricted) const _RestrictedBanner(),
        InfoCard(
          label: 'Kiambato Kikuu',
          value: ingredient.isNotEmpty ? ingredient : '—',
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (registrant.isNotEmpty)
          InfoCard(
            label: 'Kampuni',
            value: registrant,
            icon: Icons.business_outlined,
          ),
        const SizedBox(height: AppSpacing.sm),
        InfoCard(
          label: 'Usajili',
          value: isRestricted
              ? 'Restricted Registration'
              : 'Full Registration — TPRI 2011',
          icon: Icons.verified_outlined,
          iconColor: AppColors.success,
        ),
        if (usage.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Muhtasari',
            child: Text(
              usage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
        if (crops.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Mazao Yanayofaa',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: crops.map((c) => _CropChip(c)).toList(),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (hasImages)
          _SectionCard(
            title: 'Picha za Bidhaa',
            child: SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[i],
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 150,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 150,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          _SectionCard(
            title: 'Picha za Bidhaa',
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.image_outlined,
                        size: 40, color: AppColors.textHint),
                    const SizedBox(height: 8),
                    Text(
                      'Picha itaongezwa hivi karibuni',
                      style: GoogleFonts.poppins(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ── Tab 2: Matumizi ───────────────────────────────────────────────────────────

class _UsageTab extends StatelessWidget {
  final String usage;
  final List<String> crops;
  final dynamic dose;
  final String name;
  final double farmAcres;
  final double? totalMl;
  final ValueChanged<double> onAcresChanged;

  const _UsageTab({
    required this.usage,
    required this.crops,
    required this.dose,
    required this.name,
    required this.farmAcres,
    required this.totalMl,
    required this.onAcresChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (usage.isNotEmpty)
          _SectionCard(
            title: 'Maelekezo ya Matumizi',
            child: Text(
              usage,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
            ),
          ),
        if (crops.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Lenga Mazao Haya',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: crops.map((c) => _CropChip(c)).toList(),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Kikokotoo cha Kipimo',
          borderColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shamba lako: ${farmAcres.toStringAsFixed(1)} ekari',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Slider(
                value: farmAcres,
                min: 0.5,
                max: 20,
                divisions: 39,
                activeColor: AppColors.primary,
                label: '${farmAcres.toStringAsFixed(1)} ekari',
                onChanged: onAcresChanged,
              ),
              const SizedBox(height: 8),
              if (dose != null)
                InfoCard(
                  label: 'Kwa lita 15 ya dawa',
                  value: '$dose ml',
                  icon: Icons.water_drop_outlined,
                  iconColor: AppColors.info,
                ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primarySoft, AppColors.white],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalMl != null
                          ? 'Unahitaji: ~${totalMl!.toStringAsFixed(0)} ml ya $name'
                          : 'Wasiliana na duka lako kwa kipimo sahihi',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (totalMl != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Makadirio kwa shamba la ekari ${farmAcres.toStringAsFixed(1)}. '
                        'Thibitisha na mtaalamu wa kilimo kabla ya kutumia.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ── Tab 3: Usalama ────────────────────────────────────────────────────────────

class _SafetyTab extends StatelessWidget {
  final bool isRestricted;
  final int? phi;

  const _SafetyTab({
    required this.isRestricted,
    required this.phi,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (isRestricted) const _RestrictedBanner(),
        _SectionCard(
          title: 'Tahadhari za Usalama',
          borderColor: AppColors.warning,
          child: Column(
            children: [
              if (phi != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: InfoCard(
                    label: 'PHI — Subiri kabla ya kuvuna',
                    value: '⏰ Siku $phi',
                    icon: Icons.timer_outlined,
                    iconColor: AppColors.warning,
                  ),
                ),
              _SafetyTip(Icons.health_and_safety_outlined,
                  'Vaa nguo za kinga wakati wa kupulizia dawa'),
              _SafetyTip(Icons.child_care_outlined,
                  'Hifadhi mbali na watoto na wanyama'),
              _SafetyTip(Icons.water_drop_outlined,
                  'Usipulizie karibu na vyanzo vya maji'),
              _SafetyTip(Icons.wash_outlined,
                  'Osha mikono baada ya kutumia dawa'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Vidokezo vya Hifadhi',
          child: Text(
            'Weka dawa kwenye chumba baridi na kavu. Usitumie baada ya tarehe ya mwisho. '
            'Fuata maelekezo ya TPRI na Afisa Kilimo wa eneo lako.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────────

class _RestrictedBanner extends StatelessWidget {
  const _RestrictedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠ DAWA HII INA VIKWAZO',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This pesticide has restrictions on use.\n'
                  'Contact TPHPA or your agricultural officer.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.warning,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? borderColor;

  const _SectionCard({
    required this.title,
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: borderColor?.withValues(alpha: 0.35) ?? AppColors.divider,
        ),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _SafetyTip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SafetyTip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropChip extends StatelessWidget {
  final String crop;
  const _CropChip(this.crop);

  static const _emojis = {
    'maize': '🌽',
    'tomato': '🍅',
    'beans': '🫘',
    'cotton': '🌸',
    'coffee': '☕',
    'tobacco': '🌿',
    'wheat': '🌾',
    'rice': '🍚',
    'cashew': '🥜',
    'banana': '🍌',
    'cassava': '🍠',
    'horticultural_crops': '🥦',
    'stored_grain': '🌾',
    'public_health': '🏥',
    'sugarcane': '🎋',
    'flowers': '🌸',
    'vegetables': '🥬',
    'general': '🌱',
  };

  @override
  Widget build(BuildContext context) {
    final emoji = _emojis[crop] ?? '🌱';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$emoji ${crop.replaceAll('_', ' ')}',
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
