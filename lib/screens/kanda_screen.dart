import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/crop_production_data.dart';
import '../data/kanda_data.dart';
import '../services/kanda_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/government_badge.dart';
import 'mbolea_screen.dart';

// "Kanda Yangu ya Kilimo" — detects the farmer's ecological agriculture zone
// from GPS and shows official Ministry recommendations for their location.
class KandaScreen extends StatefulWidget {
  const KandaScreen({super.key});

  @override
  State<KandaScreen> createState() => _KandaScreenState();
}

class _KandaScreenState extends State<KandaScreen> {
  bool _loading = true;
  double? _lat;
  double? _lng;
  String _region = 'Morogoro';
  String _zoneName = 'Kanda ya Mashariki';
  String? _selectedWilaya;
  String _accuracyLabel = '';

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    setState(() => _loading = true);
    try {
      final result = await LocationService.getHighAccuracyLocation(
          maxWaitSeconds: 12);
      double lat, lng;
      if (result['success'] == true) {
        lat = (result['recommended_lat'] as num).toDouble();
        lng = (result['recommended_lng'] as num).toDouble();
        _accuracyLabel = result['accuracy_label'] as String? ?? '';
      } else {
        final (dLat, dLng) = await LocationService.getLocationOrDefault();
        lat = dLat;
        lng = dLng;
        _accuracyLabel = 'Makadirio';
      }
      _lat = lat;
      _lng = lng;
      _region = KandaService.getRegionFromCoordinates(lat, lng);
      _zoneName = KandaService.getZoneFromCoordinates(lat, lng);
      final districts = KandaService.districtsOf(_region);
      _selectedWilaya = districts.isNotEmpty ? districts.first : null;
    } catch (_) {
      // keep defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Color get _zoneColor {
    final zone = KandaData.zones[_zoneName];
    return Color(zone?['color'] as int? ?? 0xFF1A5C2E);
  }

  @override
  Widget build(BuildContext context) {
    final zone = KandaService.getZoneData(_zoneName);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Kanda Yangu ya Kilimo'),
        backgroundColor: _zoneColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Tafuta tena mahali',
            onPressed: _detect,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _zoneColor),
                  const SizedBox(height: 16),
                  const Text('Inatafuta mahali pako...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildZoneCard(zone),
                const SizedBox(height: 16),
                _buildCropsSection(zone),
                const SizedBox(height: 16),
                _buildDistrictSection(),
                const SizedBox(height: 16),
                _buildYieldSection(zone),
                const GovernmentSourceFooter(),
              ],
            ),
    );
  }

  // ── SECTION 1: My zone card ────────────────────────────────────────────────
  Widget _buildZoneCard(Map<String, dynamic> zone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_zoneColor, _zoneColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadow.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '🌍 Kanda Yangu ya Kilimo',
                  style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const GovernmentBadge(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${zone['emoji'] ?? ''} $_zoneName',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),
          Text(
            zone['jinaEn'] as String? ?? '',
            style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                'Mkoa: $_region',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (_lat != null && _lng != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.gps_fixed, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 10),
                if (_accuracyLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'GPS: $_accuracyLabel',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── SECTION 2: Priority crops ──────────────────────────────────────────────
  Widget _buildCropsSection(Map<String, dynamic> zone) {
    final food = (zone['foodCrops'] as List?)?.cast<String>() ?? [];
    final cash = (zone['cashCrops'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mazao ya Kipaumbele — Kanda Yako',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Mazao ya Chakula:',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const SizedBox(height: 8),
          _cropChipRow(food, AppColors.primary),
          const SizedBox(height: 14),
          Text('Mazao ya Biashara:',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1565C0))),
          const SizedBox(height: 8),
          _cropChipRow(cash, const Color(0xFF1565C0)),
        ],
      ),
    );
  }

  Widget _cropChipRow(List<String> crops, Color color) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: crops.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final crop = crops[i];
          return ActionChip(
            avatar: Text(CropProductionData.emojiFor(crop),
                style: const TextStyle(fontSize: 14)),
            label: Text(crop,
                style: GoogleFonts.poppins(fontSize: 12, color: color)),
            backgroundColor: color.withValues(alpha: 0.08),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MboleaScreen(initialCrop: crop),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── SECTION 3: District specific data ──────────────────────────────────────
  Widget _buildDistrictSection() {
    final districts = KandaService.districtsOf(_region);
    final data = _selectedWilaya != null
        ? KandaService.getDistrictData(_region, _selectedWilaya!)
        : <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Taarifa za Wilaya',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedWilaya,
            decoration: const InputDecoration(
              labelText: 'Chagua Wilaya yako',
              prefixIcon: Icon(Icons.location_city),
            ),
            items: districts
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _selectedWilaya = v),
          ),
          if (data.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ecoRow('⛰️', 'Mwinuko',
                _rangeText(data['mwinuko'], 'm juu ya usawa wa bahari')),
            _ecoRow('🌧️', 'Mvua kwa mwaka', _rangeText(data['mvua'], 'mm')),
            _ecoRow('🌡️', 'Joto', _rangeText(data['joto'], '°C')),
            if (data['ph'] != null)
              _ecoRow('⚗️', 'pH ya udongo', _rangeText(data['ph'], '')),
            if (data['udongo'] != null)
              _ecoRow('🟤', 'Aina ya udongo', data['udongo'] as String),
            const SizedBox(height: 10),
            _districtCrops('Mazao ya biashara',
                (data['biashara'] as List?)?.cast<String>() ?? [],
                const Color(0xFF1565C0)),
            const SizedBox(height: 8),
            _districtCrops('Mazao ya chakula',
                (data['chakula'] as List?)?.cast<String>() ?? [],
                AppColors.primary),
            if ((data['mengine'] as List?)?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _districtCrops('Mazao mengine yanayowezekana',
                  (data['mengine'] as List).cast<String>(),
                  const Color(0xFF6A1B9A)),
            ],
          ],
        ],
      ),
    );
  }

  String _rangeText(dynamic range, String unit) {
    if (range is! List || range.length != 2) return '—';
    return '${range[0]}–${range[1]} $unit'.trim();
  }

  Widget _ecoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _districtCrops(String title, List<String> crops, Color color) {
    if (crops.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title:',
            style: GoogleFonts.poppins(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: crops
              .map((c) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      '${CropProductionData.emojiFor(c)} $c',
                      style:
                          GoogleFonts.poppins(fontSize: 12, color: color),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ── SECTION 4: Yield opportunity ───────────────────────────────────────────
  Widget _buildYieldSection(Map<String, dynamic> zone) {
    final yields = zone['yields'] as Map<String, dynamic>? ?? {};
    if (yields.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('📈 Fursa ya Kuongeza Mavuno',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const GovernmentBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Wastani wa sasa Tanzania dhidi ya lengo la Wizara',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 14),
          ...yields.entries.map((e) {
            final y = e.value as Map;
            final sasa = (y['sasa'] as num).toDouble();
            final lengo = (y['lengo'] as num).toDouble();
            final unit = y['kipimo'] as String? ?? 't/ha';
            final frac = lengo > 0 ? (sasa / lengo).clamp(0.0, 1.0) : 0.0;
            final gainPct =
                sasa > 0 ? ((lengo - sasa) / sasa * 100).round() : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${CropProductionData.emojiFor(e.key)} ${e.key}',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (y['kipaumbele'] == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('KIPAUMBELE',
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning)),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '$sasa → $lengo $unit',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 8,
                      backgroundColor: _zoneColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(_zoneColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unaweza kuongeza mavuno yako kwa asilimia $gainPct',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.success),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
