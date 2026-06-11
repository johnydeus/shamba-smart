import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/crop_production_data.dart';
import '../data/fertilizer_data.dart';
import '../data/kanda_data.dart';
import '../providers/auth_provider.dart';
import '../services/kanda_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/government_badge.dart';
import 'irrigation_screen.dart';
import 'mbolea_screen.dart';
import 'scan_screen.dart';
import 'seeds_screen.dart';

// "Uchambuzi wa Mavuno" — yield gap analysis: farmer's yield vs Tanzania
// average vs official Ministry target.
class YieldGapScreen extends StatefulWidget {
  const YieldGapScreen({super.key});

  @override
  State<YieldGapScreen> createState() => _YieldGapScreenState();
}

class _YieldGapScreenState extends State<YieldGapScreen> {
  bool _loading = true;
  String _region = 'Morogoro';
  String _zoneName = 'Kanda ya Mashariki';
  String _crop = 'Mahindi';
  final _myYieldCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _myYieldCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final (lat, lng) = await LocationService.getLocationOrDefault();
      _region = KandaService.getRegionFromCoordinates(lat, lng);
      _zoneName = KandaService.getZoneFromCoordinates(lat, lng);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<String> get _zoneCrops {
    final zone = KandaData.zones[_zoneName];
    final yields = zone?['yields'] as Map<String, dynamic>? ?? {};
    final list = yields.keys.toList();
    if (!list.contains(_crop) && list.isNotEmpty) _crop = list.first;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Uchambuzi wa Mavuno')),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final crops = _zoneCrops;
    final yieldData = KandaService.getCropYield(_crop, _zoneName);
    final sasa = (yieldData['sasa'] as num?)?.toDouble() ?? 0;
    final lengo = (yieldData['lengo'] as num?)?.toDouble() ?? 0;
    final unit = yieldData['kipimo'] as String? ?? 't/ha';
    final myYield = double.tryParse(_myYieldCtrl.text.trim());
    final priceKg = FertilizerData.cropPriceTzsPerKg[_crop] ?? 1000;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Uchambuzi wa Mavuno Yako')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('📊 Je, unaweza kulima zaidi?',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const GovernmentBadge(),
            ],
          ),
          const SizedBox(height: 14),

          // ── Selectors ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: crops.contains(_crop) ? _crop : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Zao lako',
                    prefixIcon: Icon(Icons.grass),
                  ),
                  items: crops
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                              '${CropProductionData.emojiFor(c)} $c')))
                      .toList(),
                  onChanged: (v) => setState(() => _crop = v!),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Kanda yako (imetambuliwa kwa GPS)',
                    prefixIcon: Icon(Icons.public),
                  ),
                  child: Text('$_zoneName — $_region',
                      style: GoogleFonts.poppins(fontSize: 14)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _myYieldCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Mavuno yako kwa hekta ($unit)',
                    prefixIcon: const Icon(Icons.agriculture),
                    hintText: 'mf. 1.5',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Comparison bars ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ulinganisho wa Mavuno ($unit)',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                _bar('Wastani wa Tanzania', sasa, lengo,
                    const Color(0xFF9E9E9E)),
                _bar('Lengo la Serikali', lengo, lengo, AppColors.success),
                if (myYield != null)
                  _bar('Mavuno Yako', myYield, lengo,
                      const Color(0xFF1565C0)),
                if (myYield == null)
                  Text(
                    'Ingiza mavuno yako hapo juu ili kujilinganisha',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textTertiary),
                  ),
                if (myYield != null && sasa > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    myYield >= sasa
                        ? '✅ Uko juu ya wastani wa Tanzania kwa '
                            '${((myYield - sasa) / sasa * 100).round()}%'
                        : '⚠️ Uko chini ya wastani wa Tanzania kwa '
                            '${((sasa - myYield) / sasa * 100).round()}%',
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: myYield >= sasa
                            ? AppColors.success
                            : AppColors.warning),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Improvement potential ──
          _improvementCard(myYield ?? sasa, lengo, unit, priceKg),
          const SizedBox(height: 16),

          // ── Top 5 improvements ──
          _top5Card(),
          const SizedBox(height: 16),

          // ── National comparison ──
          _nationalComparisonCard(unit),
          const SizedBox(height: 16),

          // ── Save ──
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Hifadhi Uchambuzi Huu'),
            onPressed: () => _saveAnalysis(myYield, sasa, lengo, unit),
          ),
          const GovernmentSourceFooter(),
        ],
      ),
    );
  }

  Widget _bar(String label, double value, double max, Color color) {
    final frac = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(label, style: GoogleFonts.poppins(fontSize: 12.5)),
              ),
              Text(value.toStringAsFixed(2),
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 14,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _improvementCard(
      double from, double lengo, String unit, int priceKg) {
    final gainPct =
        from > 0 ? ((lengo - from) / from * 100).round() : 0;
    final isTon = unit == 't/ha';
    final fromKg = isTon ? from * 1000 : from;
    final lengoKg = isTon ? lengo * 1000 : lengo;
    final extraKg = lengoKg - fromKg;
    final fromTzs = fromKg * priceKg;
    final extraTzs = extraKg * priceKg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Unaweza Kuongeza Kwa:',
              style:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
          Text('+$gainPct% mavuno zaidi',
              style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text('Kwa kutumia mbinu bora za kilimo',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
          if (gainPct > 0 && isTon) ...[
            const Divider(color: Colors.white24, height: 24),
            Text('Hii inamaanisha (kwa hekta moja):',
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 6),
            _whiteRow('Mavuno yako sasa',
                '${_fmt(fromKg)} kg = ${_fmt(fromTzs)} TZS'),
            _whiteRow('Ukiboresha',
                '${_fmt(lengoKg)} kg → +${_fmt(extraTzs)} TZS zaidi'),
            const SizedBox(height: 4),
            Text('Faida ya ziada kwa msimu: ${_fmt(extraTzs)} TZS',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFD60A))),
          ],
        ],
      ),
    );
  }

  Widget _whiteRow(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(l,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.white70)),
          ),
          Text(v,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _top5Card() {
    final items = [
      ('Tumia mbegu bora (TOSCI certified)', '+15-20% mavuno',
          () => const SeedsScreen()),
      ('Weka mbolea kwa wakati sahihi', '+20-25% mavuno',
          () => MboleaScreen(initialCrop: _crop)),
      ('Mwagilia kwa usahihi (inapohitajika)', '+10-15% mavuno',
          () => const IrrigationScreen()),
      ('Dhibiti magonjwa mapema', '+15-20% mavuno',
          () => const ScanScreen()),
      ('Fuata nafasi sahihi za upandaji', '+10% mavuno',
          () => MboleaScreen(initialCrop: _crop)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mambo 5 ya Kuboresha Mavuno:',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...List.generate(items.length, (i) {
            final (title, effect, builder) = items[i];
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => builder()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primarySoft,
                      child: Text('${i + 1}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.poppins(fontSize: 13)),
                          Text('Athari: $effect',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textHint),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Zone-by-zone comparison for the selected crop
  Widget _nationalComparisonCard(String unit) {
    final rows = <(String, double, int)>[];
    double maxVal = 0;
    KandaData.zones.forEach((name, zone) {
      final yields = zone['yields'] as Map<String, dynamic>;
      for (final e in yields.entries) {
        if (e.key.toLowerCase() == _crop.toLowerCase()) {
          final v = ((e.value as Map)['sasa'] as num).toDouble();
          rows.add((name, v, zone['color'] as int));
          if (v > maxVal) maxVal = v;
        }
      }
    });
    if (rows.isEmpty) return const SizedBox.shrink();
    rows.sort((a, b) => b.$2.compareTo(a.$2));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Unalinganishwa na Tanzania — $_crop',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          Text('Wastani wa sasa kwa kanda ($unit)',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 10),
          ...rows.map((r) {
            final isMine = r.$1 == _zoneName;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      r.$1.replaceAll('Kanda ya ', ''),
                      style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: isMine
                              ? FontWeight.w800
                              : FontWeight.w400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxVal > 0 ? r.$2 / maxVal : 0,
                        minHeight: 12,
                        backgroundColor:
                            Color(r.$3).withValues(alpha: 0.1),
                        valueColor:
                            AlwaysStoppedAnimation(Color(r.$3)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(r.$2.toStringAsFixed(2),
                      style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600)),
                  if (isMine)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.person_pin,
                          size: 14, color: AppColors.primary),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _saveAnalysis(
      double? myYield, double sasa, double lengo, String unit) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    try {
      await Supabase.instance.client.from('farm_events').insert({
        'farmer_id': userId,
        'event_type': 'uchambuzi',
        'event_date': DateTime.now().toIso8601String(),
        'crop_name': _crop,
        'description': 'Uchambuzi wa mavuno: $_crop ($_zoneName). '
            'Wastani TZ: $sasa $unit, Lengo: $lengo $unit'
            '${myYield != null ? ', Yangu: $myYield $unit' : ''}',
        'notes': 'Chanzo: Wizara ya Kilimo Tanzania 2022',
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Uchambuzi umehifadhiwa kwenye Diari')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hitilafu: $e')));
      }
    }
  }

  BoxDecoration get _cardDeco => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.sm,
      );

  static String _fmt(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final left = s.length - i - 1;
      if (left > 0 && left % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }
}
