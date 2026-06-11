import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/crop_calendar_data.dart';
import '../data/crop_production_data.dart';
import '../data/fertilizer_data.dart';
import '../services/kanda_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/government_badge.dart';
import 'mbolea_screen.dart';

// "Mazao Yanayofaa Kwako" — personalised crop suitability advisor based on
// GPS location and the official Ministry of Agriculture guide (2022).
class MazaoYanayofaaScreen extends StatefulWidget {
  const MazaoYanayofaaScreen({super.key});

  @override
  State<MazaoYanayofaaScreen> createState() => _MazaoYanayofaaScreenState();
}

class _MazaoYanayofaaScreenState extends State<MazaoYanayofaaScreen> {
  bool _loading = true;
  String _region = 'Morogoro';
  String _wilaya = '';
  String _filter = 'zote'; // chakula | biashara | zote
  bool _seasonOnly = false;
  String? _expandedCrop;

  List<Map<String, dynamic>> _ranked = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final (lat, lng) = await LocationService.getLocationOrDefault();
      _region = KandaService.getRegionFromCoordinates(lat, lng);
      final districts = KandaService.districtsOf(_region);
      if (_wilaya.isEmpty || !districts.contains(_wilaya)) {
        _wilaya = districts.isNotEmpty ? districts.first : '';
      }
    } catch (_) {}
    _rank();
    if (mounted) setState(() => _loading = false);
  }

  void _rank() {
    final month = DateTime.now().month;
    final crops = CropProductionData.candidateCrops(_region, _wilaya);
    _ranked = crops.map((c) {
      final s = CropProductionData.suitability(
        crop: c,
        mkoa: _region,
        wilaya: _wilaya,
        currentMonth: month,
      );
      return {'crop': c, ...s};
    }).toList()
      ..sort((a, b) =>
          (b['score'] as double).compareTo(a['score'] as double));
  }

  List<Map<String, dynamic>> get _visible {
    final month = DateTime.now().month;
    return _ranked.where((r) {
      final crop = r['crop'] as String;
      if (_filter == 'biashara' &&
          !CropProductionData.isCashCrop(crop, _region)) {
        return false;
      }
      if (_filter == 'chakula' &&
          CropProductionData.isCashCrop(crop, _region)) {
        return false;
      }
      if (_seasonOnly) {
        final entry = CropCalendarData.entryFor(crop, _region);
        final planting =
            (entry?['activities'] as Map?)?['kupanda'] as List? ?? [];
        if (!planting.contains(month)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final season = CropProductionData.seasonName(now.month);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Mazao Yanayofaa Kwako')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // ── Header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primarySoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '🌱 $_wilaya, $_region',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$season ${now.year}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Kulingana na Wizara ya Kilimo Tanzania',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textTertiary),
                            ),
                          ),
                          const GovernmentBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // District picker
                      DropdownButtonFormField<String>(
                        initialValue: _wilaya.isEmpty ? null : _wilaya,
                        decoration: const InputDecoration(
                          labelText: 'Wilaya',
                          isDense: true,
                          prefixIcon: Icon(Icons.location_city, size: 18),
                        ),
                        items: KandaService.districtsOf(_region)
                            .map((d) => DropdownMenuItem(
                                value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _wilaya = v;
                            _rank();
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // ── Filters ──
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    children: [
                      _filterChip('Zote', 'zote'),
                      _filterChip('Chakula', 'chakula'),
                      _filterChip('Biashara', 'biashara'),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: const Text('Msimu wa sasa'),
                        selected: _seasonOnly,
                        selectedColor: AppColors.primarySoft,
                        checkmarkColor: AppColors.primary,
                        onSelected: (v) =>
                            setState(() => _seasonOnly = v),
                      ),
                    ],
                  ),
                ),

                // ── Crop cards ──
                Expanded(
                  child: _visible.isEmpty
                      ? Center(
                          child: Text(
                            'Hakuna mazao kwenye kichujio hiki.',
                            style: GoogleFonts.poppins(
                                color: AppColors.textTertiary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _visible.length + 1,
                          itemBuilder: (context, i) {
                            if (i == _visible.length) {
                              return const GovernmentSourceFooter();
                            }
                            return _cropCard(_visible[i]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String label, String key) {
    final selected = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.poppins(
            fontSize: 12.5,
            color: selected ? Colors.white : AppColors.textSecondary),
        onSelected: (_) => setState(() => _filter = key),
      ),
    );
  }

  Widget _cropCard(Map<String, dynamic> r) {
    final crop = r['crop'] as String;
    final stars = r['stars'] as int;
    final badge = r['badge'] as String;
    final reasons = (r['reasons'] as List).cast<String>();
    final zone = r['zone'] as String?;
    final eco = r['ecology'] as Map<String, dynamic>?;
    final yieldData = KandaService.getCropYield(crop, zone ?? '');
    final t9 = FertilizerData.findCrop(crop);
    final expanded = _expandedCrop == crop;

    final badgeColor = switch (badge) {
      'INAFAA SANA' => AppColors.success,
      'INAFAA' => const Color(0xFFF9A825),
      _ => AppColors.warning,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () =>
            setState(() => _expandedCrop = expanded ? null : crop),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(CropProductionData.emojiFor(crop),
                      style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(crop,
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < stars
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 15,
                              color: const Color(0xFFF9A825),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(badge,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor)),
                  ),
                ],
              ),
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: reasons
                      .map((m) => Text('✓ $m',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.success)))
                      .toList(),
                ),
              ],
              if (expanded) ...[
                const Divider(height: 20),
                _detail('📍', 'Inafaa kwa', '$_wilaya, $_region'),
                if (yieldData.isNotEmpty) ...[
                  _detail(
                      '📈',
                      'Mavuno yanayowezekana',
                      '${yieldData['lengo']} '
                          '${yieldData['kipimo'] ?? 't/ha'}'),
                  _detail('🚀', 'Tofauti na sasa',
                      '+${yieldData['ongezeko']}% zaidi'),
                ],
                if (eco != null) ...[
                  _detail('🌧️', 'Mvua inayohitajika',
                      '${eco['mvua'][0]}–${eco['mvua'][1]} mm'),
                  _detail('⛰️', 'Urefu unaofaa',
                      '${eco['mwinuko'][0]}–${eco['mwinuko'][1]} m'),
                  _detail('⚗️', 'pH inayohitajika',
                      '${eco['ph'][0]}–${eco['ph'][1]}'),
                ],
                if (t9 != null)
                  _detail(
                      '⏱️',
                      'Muda hadi mavuno',
                      '${t9['maturityMonths'][0]}–'
                          '${t9['maturityMonths'][1]} miezi'),
                const SizedBox(height: 8),
                _plantingCalendar(crop),
                const SizedBox(height: 8),
                _fertilizerQuickView(crop, t9),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w600)),
          Expanded(
            child:
                Text(value, style: GoogleFonts.poppins(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  // Mini 12-month planting calendar strip
  Widget _plantingCalendar(String crop) {
    final entry = CropCalendarData.entryFor(crop, _region);
    if (entry == null) return const SizedBox.shrink();
    final planting =
        ((entry['activities'] as Map)['kupanda'] as List?) ?? [];
    final harvest =
        ((entry['activities'] as Map)['kuvuna'] as List?) ?? [];
    const monthNames = [
      'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
    ];
    final nowMonth = DateTime.now().month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wakati Bora wa Kupanda $crop ($_region):',
            style: GoogleFonts.poppins(
                fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: List.generate(12, (i) {
            final m = i + 1;
            final isPlant = planting.contains(m);
            final isHarvest = harvest.contains(m);
            final isNow = m == nowMonth;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: isPlant
                      ? AppColors.critical.withValues(alpha: 0.85)
                      : isHarvest
                          ? AppColors.success.withValues(alpha: 0.85)
                          : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                  border: isNow
                      ? Border.all(color: Colors.black87, width: 1.5)
                      : null,
                ),
                child: Text(
                  monthNames[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: (isPlant || isHarvest)
                          ? Colors.white
                          : AppColors.textTertiary),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _legendDot(AppColors.critical, 'Kupanda'),
            const SizedBox(width: 12),
            _legendDot(AppColors.success, 'Kuvuna'),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _fertilizerQuickView(String crop, Map<String, dynamic>? t9) {
    if (t9 == null) return const SizedBox.shrink();
    final ferts = (t9['fertilizers'] as Map).cast<String, dynamic>();
    final parts = <String>[];
    double cost = 0;
    ferts.forEach((k, v) {
      final amt = FertilizerData.fertilizerAmount(v);
      if (amt <= 0) return;
      parts.add('$k: ${amt.toStringAsFixed(0)} kg/ha');
      cost += amt * (FertilizerData.fertilizerPriceTzsPerKg[k] ?? 1200);
    });
    if (parts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💊 Mbolea Inayohitajika (kwa hekta):',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6A1B9A))),
          const SizedBox(height: 4),
          Text(parts.join(' • '),
              style: GoogleFonts.poppins(fontSize: 12)),
          Text(
              'Gharama ya makadirio: '
              '${cost.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} TZS/ha',
              style: GoogleFonts.poppins(
                  fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MboleaScreen(initialCrop: crop)),
            ),
            child: Text('Angalia mwongozo kamili wa mbolea →',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6A1B9A))),
          ),
        ],
      ),
    );
  }
}
