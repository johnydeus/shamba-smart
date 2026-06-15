import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/crop_production_data.dart';
import '../data/fertilizer_data.dart';
import '../theme/app_theme.dart';
import '../widgets/government_badge.dart';
import 'agrovet_screen.dart';
import 'soil_screen.dart';

// "Mwongozo wa Mbolea" — official fertilizer prescription per crop and farm
// size, from Ministry of Agriculture Table 9 (2022).
class MboleaBody extends StatefulWidget {
  final String? initialCrop;
  const MboleaBody({super.key, this.initialCrop});

  @override
  State<MboleaBody> createState() => _MboleaBodyState();
}

class _MboleaBodyState extends State<MboleaBody> {
  static const double _acreToHa = 0.4047;

  late String _crop;
  final _sizeCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    final names = FertilizerData.cropNames;
    _crop = names.first;
    if (widget.initialCrop != null) {
      final match = FertilizerData.findCrop(widget.initialCrop!);
      if (match != null) _crop = match['jina'] as String;
    }
  }

  @override
  void dispose() {
    _sizeCtrl.dispose();
    super.dispose();
  }

  double get _acres => double.tryParse(_sizeCtrl.text.trim()) ?? 1.0;
  double get _hectares => _acres * _acreToHa;

  // Basal fertilizers applied at planting vs nitrogen top dressing
  static const _topDressing = {'UREA', 'CAN', 'SA'};

  @override
  Widget build(BuildContext context) {
    final crop = FertilizerData.findCrop(_crop)!;
    final ferts = (crop['fertilizers'] as Map).cast<String, dynamic>();
    final basal = <String, double>{};
    final top = <String, double>{};
    ferts.forEach((k, v) {
      final amt = FertilizerData.fertilizerAmount(v);
      if (amt <= 0) return;
      if (_topDressing.contains(k)) {
        top[k] = amt;
      } else {
        basal[k] = amt;
      }
    });

    double totalKg = 0;
    double totalCost = 0;
    void tally(Map<String, double> m) {
      m.forEach((k, perHa) {
        final farmKg = perHa * _hectares;
        totalKg += farmKg;
        totalCost +=
            farmKg * (FertilizerData.fertilizerPriceTzsPerKg[k] ?? 1200);
      });
    }

    tally(basal);
    tally(top);

    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '💊 Kulingana na Wizara ya Kilimo Tanzania',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              const GovernmentBadge(),
            ],
          ),
          const SizedBox(height: 14),

          // ── Inputs ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _crop,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Chagua Zao',
                    prefixIcon: Icon(Icons.grass),
                  ),
                  items: FertilizerData.cropNames
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                              '${CropProductionData.emojiFor(c)} $c')))
                      .toList(),
                  onChanged: (v) => setState(() => _crop = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sizeCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Ukubwa wa Shamba (ekari)',
                    prefixIcon: const Icon(Icons.crop_square),
                    suffixText: '= ${_hectares.toStringAsFixed(2)} hekta',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Results ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mbolea kwa $_crop kwenye ekari '
                  '${_acres.toStringAsFixed(1)} '
                  '(${_hectares.toStringAsFixed(2)} hekta)',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                if ((crop['fertilizerNote'] ?? '') != '') ...[
                  const SizedBox(height: 4),
                  Text(crop['fertilizerNote'] as String,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textTertiary)),
                ],
                const SizedBox(height: 12),
                if (basal.isEmpty && top.isEmpty)
                  Text(
                    'Zao hili halina kiwango maalum cha mbolea za viwandani '
                    'kwenye mwongozo. Tumia samadi/mboji na ushauri wa afisa '
                    'ugani.',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                if (basal.isNotEmpty) ...[
                  _tableTitle('Mbolea ya Kupandia (Basal)'),
                  _fertTable(basal),
                  const SizedBox(height: 12),
                ],
                if (top.isNotEmpty) ...[
                  _tableTitle('Mbolea ya Kukuzia (Top Dressing)'),
                  _fertTable(top),
                  const SizedBox(height: 12),
                ],
                if (totalKg > 0) ...[
                  const Divider(),
                  _summaryRow('Jumla ya mbolea',
                      '${totalKg.toStringAsFixed(0)} kg'),
                  _summaryRow('Gharama ya jumla (makadirio)',
                      '${_fmtTzs(totalCost)} TZS'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Application timing ──
          if (basal.isNotEmpty || top.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDeco,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⏱️ Wakati wa Kuweka Mbolea',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (basal.isNotEmpty)
                    _timelineRow('Siku 0', basal.keys.join(' / '),
                        'Wakati wa kupanda — changanya na udongo shimoni',
                        AppColors.primary),
                  if (top.isNotEmpty) ...[
                    _timelineRow('Wiki 4', top.keys.join(' / '),
                        'Palizi la kwanza — weka pembeni ya mstari',
                        const Color(0xFF6A1B9A)),
                    _timelineRow('Wiki 8', top.keys.join(' / '),
                        'Palizi la pili (ikihitajika)',
                        const Color(0xFF1565C0)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Spacing guide ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📏 Nafasi za Upandaji',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _summaryRow('Nafasi', crop['spacing'] as String),
                _summaryRow('Mbegu', crop['seedRate'] as String? ?? '—'),
                _summaryRow(
                    'Mimea kwa hekta', _plantsText(crop['plantsPerHa'])),
                _summaryRow('Muda hadi kukomaa',
                    '${_rangeNum(crop['maturityMonths'])} miezi'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Expected results ──
          _buildExpectedResults(crop),
          const SizedBox(height: 16),

          // ── Ministry note ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️ Angalizo la Wizara ya Kilimo:',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning)),
                const SizedBox(height: 4),
                Text(
                  'Maelekezo haya ni ya jumla. Kupima afya ya udongo wa '
                  'shamba lako kutakupa kiasi sahihi zaidi.',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.warning),
                  icon: const Icon(Icons.science, size: 16),
                  label: const Text('Pima Udongo Wako'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SoilScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Agrovet button ──
          ElevatedButton.icon(
            icon: const Icon(Icons.storefront),
            label: const Text('Nunua Mbolea Karibu Nawe'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AgrovetScreen()),
            ),
          ),
          const GovernmentSourceFooter(),
        ],
    );
  }

  Widget _buildExpectedResults(Map<String, dynamic> crop) {
    final yieldNow = (crop['yieldNow'] as num).toDouble();
    final yieldPot = (crop['yieldPotential'] as num).toDouble();
    final unit = crop['yieldUnit'] as String;
    final isTonHa = unit == 't/ha';
    final priceKg = FertilizerData.cropPriceTzsPerKg[_crop];

    double? estKg;
    double? revenue;
    if (isTonHa) {
      estKg = yieldPot * 1000 * _hectares;
      if (priceKg != null) revenue = estKg * priceKg;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 Mavuno Yanayotarajiwa',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _summaryRow('Wastani wa Tanzania sasa', '$yieldNow $unit'),
          _summaryRow('Lengo la Wizara (mbinu bora)', '$yieldPot $unit'),
          if (estKg != null)
            _summaryRow('Makadirio ya mavuno yako',
                '${_fmtTzs(estKg)} kg'),
          if (revenue != null)
            _summaryRow('Mapato yanayotarajiwa',
                '${_fmtTzs(revenue)} TZS',
                highlight: true),
          if (revenue != null)
            Text(
              'Bei ya makadirio: ${_fmtTzs(priceKg!.toDouble())} TZS/kg — '
              'angalia bei halisi kwenye skrini ya Soko',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }

  BoxDecoration get _cardDeco => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.sm,
      );

  Widget _tableTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      );

  Widget _fertTable(Map<String, double> ferts) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(6)),
          children: ['Mbolea', 'Kwa hekta', 'Shamba lako', 'Bei TZS']
              .map((h) => Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(h,
                        style: GoogleFonts.poppins(
                            fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ))
              .toList(),
        ),
        ...ferts.entries.map((e) {
          final farmKg = e.value * _hectares;
          final cost = farmKg *
              (FertilizerData.fertilizerPriceTzsPerKg[e.key] ?? 1200);
          return TableRow(
            children: [
              e.key,
              '${e.value.toStringAsFixed(0)} kg',
              '${farmKg.toStringAsFixed(1)} kg',
              _fmtTzs(cost),
            ]
                .map((v) => Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(v,
                          style: GoogleFonts.poppins(fontSize: 12)),
                    ))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _timelineRow(
      String when, String what, String how, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(when,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(what,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(how,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.poppins(fontSize: 13)),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    highlight ? AppColors.success : AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  String _plantsText(dynamic v) {
    if (v is List && v.length == 2) {
      if (v[0] == v[1]) return _fmtTzs((v[0] as num).toDouble());
      return '${_fmtTzs((v[0] as num).toDouble())} – '
          '${_fmtTzs((v[1] as num).toDouble())}';
    }
    return '—';
  }

  String _rangeNum(dynamic v) {
    if (v is List && v.length == 2) {
      if (v[0] == v[1]) return '${v[0]}';
      return '${v[0]}–${v[1]}';
    }
    return '—';
  }

  static String _fmtTzs(double v) {
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

class MboleaScreen extends StatelessWidget {
  final String? initialCrop;
  const MboleaScreen({super.key, this.initialCrop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Mwongozo wa Mbolea')),
      body: MboleaBody(initialCrop: initialCrop),
    );
  }
}
