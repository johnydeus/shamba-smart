import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/agrovet_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/agrovet_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'register_agrovet_screen.dart';

const _kRegions = [
  'Zote', 'Arusha', 'Dar es Salaam', 'Dodoma', 'Geita', 'Iringa', 'Kagera',
  'Katavi', 'Kigoma', 'Kilimanjaro', 'Lindi', 'Manyara', 'Mara', 'Mbeya',
  'Morogoro', 'Mtwara', 'Mwanza', 'Njombe', 'Pwani', 'Rukwa', 'Ruvuma',
  'Shinyanga', 'Simiyu', 'Singida', 'Songwe', 'Tabora', 'Tanga',
];

class FindAgrovetsScreen extends StatefulWidget {
  /// Optionally open pre-filtered to one category (e.g. from IPM -> pesticides).
  final AgrovetCategory? initialCategory;

  /// When true, render without its own AppBar (for use inside a TabBarView).
  final bool embedded;
  const FindAgrovetsScreen({super.key, this.initialCategory, this.embedded = false});

  @override
  State<FindAgrovetsScreen> createState() => _FindAgrovetsScreenState();
}

class _FindAgrovetsScreenState extends State<FindAgrovetsScreen> {
  AgrovetCategory? _category;
  String _region = 'Zote';
  bool _nearMe = false;
  bool _loading = true;
  List<AgrovetModel> _agrovets = [];
  double? _lat, _lng;

  static const _filterCategories = [
    AgrovetCategory.fertilizer,
    AgrovetCategory.seeds,
    AgrovetCategory.pesticides,
    AgrovetCategory.cropBuying,
    AgrovetCategory.equipment,
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await AgrovetService.fetch(
      region: _nearMe ? null : _region,
      category: _category?.key,
    );
    if (_nearMe && _lat != null && _lng != null) {
      list.sort((a, b) => _distance(a).compareTo(_distance(b)));
    }
    if (mounted) {
      setState(() {
        _agrovets = list;
        _loading = false;
      });
    }
  }

  double _distance(AgrovetModel a) {
    if (a.latitude == null || a.longitude == null || _lat == null || _lng == null) {
      return double.maxFinite;
    }
    final dLat = a.latitude! - _lat!;
    final dLng = a.longitude! - _lng!;
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  Future<void> _toggleNearMe() async {
    if (_nearMe) {
      setState(() => _nearMe = false);
      _load();
      return;
    }
    final (lat, lng) = await LocationService.getLocationOrDefault();
    setState(() {
      _nearMe = true;
      _lat = lat;
      _lng = lng;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isDuka = user?.role == UserRole.biashara &&
        user?.biasharaType == BiasharaType.duka;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              title: Text('Maduka ya Pembejeo',
                  style: GoogleFonts.playfairDisplay(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
      floatingActionButton: isDuka
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_business, color: Colors.white),
              label: const Text('Sajili Duka',
                  style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterAgrovetScreen())),
            )
          : null,
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _agrovets.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _agrovets.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _AgrovetCard(agrovet: _agrovets[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Category chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('Zote', _category == null, () {
                  setState(() => _category = null);
                  _load();
                }),
                ..._filterCategories.map((c) => _chip(
                      '${c.emoji} ${c.labelSw}',
                      _category == c,
                      () {
                        setState(() => _category = c);
                        _load();
                      },
                    )),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Region + near me
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _region,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.location_on, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: _kRegions
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: _nearMe
                        ? null
                        : (v) {
                            if (v != null) {
                              setState(() => _region = v);
                              _load();
                            }
                          },
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(Icons.my_location,
                      size: 16,
                      color: _nearMe ? Colors.white : AppColors.primary),
                  label: const Text('Karibu nami'),
                  selected: _nearMe,
                  onSelected: (_) => _toggleNearMe(),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color: _nearMe ? Colors.white : AppColors.primary,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12),
        ),
      );

  Widget _emptyState() => ListView(
        children: [
          const SizedBox(height: 80),
          const Center(child: Text('🏪', style: TextStyle(fontSize: 56))),
          const SizedBox(height: 12),
          Center(
            child: Text('Hakuna maduka yaliyopatikana',
                style: GoogleFonts.dmSans(
                    color: AppColors.textTertiary, fontSize: 15)),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Badilisha kichujio au mkoa. Maduka mapya yanaongezwa kadiri '
              'wamiliki wanavyojisajili.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  color: AppColors.textTertiary, fontSize: 12),
            ),
          ),
        ],
      );
}

class _AgrovetCard extends StatelessWidget {
  final AgrovetModel agrovet;
  const _AgrovetCard({required this.agrovet});

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _whatsapp(String number) async {
    final clean = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = [agrovet.ward, agrovet.district, agrovet.region]
        .where((e) => e != null && e.isNotEmpty)
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(agrovet.name,
                    style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              if (agrovet.isVerified)
                const Icon(Icons.verified, size: 16, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: agrovet.isGovernment
                      ? AppColors.infoBg
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(agrovet.typeLabelSw,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: agrovet.isGovernment
                            ? AppColors.info
                            : AppColors.primary)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.location_on, size: 12, color: AppColors.textTertiary),
              Expanded(
                child: Text(loc,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
              ),
            ],
          ),
          if (agrovet.description != null && agrovet.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(agrovet.description!,
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: agrovet.categoryEnums
                .map((c) => Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${c.emoji} ${c.labelSw}',
                          style: const TextStyle(fontSize: 10)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (agrovet.phone != null && agrovet.phone!.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _call(agrovet.phone!),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Piga simu', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              if ((agrovet.whatsapp ?? agrovet.phone) != null &&
                  (agrovet.whatsapp ?? agrovet.phone)!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _whatsapp(agrovet.whatsapp ?? agrovet.phone!),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
