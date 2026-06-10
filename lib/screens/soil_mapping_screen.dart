import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/audio_service.dart';
import '../services/claude_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

// ── Soil Mapping Screen — iSDAsoil API ────────────────────────────────────────

class SoilMappingScreen extends StatefulWidget {
  final double? farmLat;
  final double? farmLng;
  final String? farmName;

  const SoilMappingScreen({
    super.key,
    this.farmLat,
    this.farmLng,
    this.farmName,
  });

  @override
  State<SoilMappingScreen> createState() => _SoilMappingScreenState();
}

class _SoilMappingScreenState extends State<SoilMappingScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic> _soilData = {};
  String? _aiRecommendation;
  bool _aiLoading = false;
  double? _lat;
  double? _lng;
  String _selectedCrop = 'Mahindi';
  DateTime? _lastFetch;

  static const _crops = ['Mahindi', 'Nyanya', 'Maharagwe', 'Pilipili', 'Mchele', 'Muhogo'];

  @override
  void initState() {
    super.initState();
    _lat = widget.farmLat;
    _lng = widget.farmLng;
    if (_lat != null && _lng != null) {
      _fetchSoilData();
    }
  }

  Future<void> _getLocation() async {
    setState(() { _loading = true; _error = null; });
    try {
      final pos = await LocationService.getCurrentLocation();
      _lat = pos.latitude;
      _lng = pos.longitude;
      await _fetchSoilData();
    } catch (e) {
      setState(() {
        _error = 'Imeshindwa kupata mahali: $e';
        _loading = false;
      });
    }
  }

  Future<void> _fetchSoilData() async {
    if (_lat == null || _lng == null) return;
    setState(() { _loading = true; _error = null; _soilData = {}; _aiRecommendation = null; });

    final token = dotenv.env['ISDASOIL_TOKEN'] ?? '';
    // Use ISRIC SoilGrids as free fallback when no iSDAsoil token
    final useIsda = token.isNotEmpty;

    try {
      if (useIsda) {
        await _fetchFromIsdaSoil(token);
      } else {
        await _fetchFromSoilGrids();
      }
      _lastFetch = DateTime.now();
    } catch (e) {
      setState(() { _error = 'Hitilafu ya data ya udongo: $e'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchFromIsdaSoil(String token) async {
    final props = ['ph', 'nitrogen_total', 'phosphorus_extractable',
                   'potassium_extractable', 'organic_carbon', 'clay',
                   'sand', 'silt', 'bulk_density', 'cation_exchange_capacity'];
    final combined = <String, dynamic>{};

    for (final prop in props) {
      try {
        final uri = Uri.parse('https://api.isda-africa.com/v1/soil').replace(
          queryParameters: {
            'lat': _lat!.toStringAsFixed(6),
            'lon': _lng!.toStringAsFixed(6),
            'property': prop,
            'depth': '0-20',
          },
        );
        final resp = await http.get(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 15));

        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final val = json['data']?['value'];
          if (val != null) combined[prop] = val;
        } else if (resp.statusCode == 401) {
          throw Exception('Token ya iSDAsoil imeisha muda — angalia mipangilio');
        }
      } catch (e) {
        // Skip individual property failure, try SoilGrids instead
      }
    }

    if (combined.isEmpty) {
      await _fetchFromSoilGrids();
    } else {
      setState(() => _soilData = combined);
    }
  }

  Future<void> _fetchFromSoilGrids() async {
    final url = Uri.parse(
      'https://rest.isric.org/soilgrids/v2.0/properties/query'
      '?lat=${_lat!.toStringAsFixed(6)}'
      '&lon=${_lng!.toStringAsFixed(6)}'
      '&property=phh2o&property=clay&property=sand&property=silt'
      '&property=nitrogen&property=soc'
      '&depth=0-5cm&value=mean',
    );
    final resp = await http.get(url, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final props = json['properties']?['layers'] as List? ?? [];
      final data = <String, dynamic>{};
      for (final layer in props) {
        final name = layer['name'] as String? ?? '';
        final depths = layer['depths'] as List? ?? [];
        if (depths.isNotEmpty) {
          final values = depths[0]['values'] as Map? ?? {};
          final mean = values['mean'];
          if (mean != null) {
            switch (name) {
              case 'phh2o': data['ph'] = (mean as num) / 10.0; break;
              case 'clay': data['clay'] = (mean as num) / 10.0; break;
              case 'sand': data['sand'] = (mean as num) / 10.0; break;
              case 'silt': data['silt'] = (mean as num) / 10.0; break;
              case 'nitrogen': data['nitrogen_total'] = (mean as num) / 100.0; break;
              case 'soc': data['organic_carbon'] = (mean as num) / 10.0; break;
            }
          }
        }
      }
      setState(() => _soilData = data);
    } else {
      throw Exception('Seva ya udongo ilijibu kosa ${resp.statusCode}');
    }
  }

  int _soilScore() {
    if (_soilData.isEmpty) return 0;
    int score = 50;
    final ph = (_soilData['ph'] as num?)?.toDouble() ?? 6.5;
    if (ph >= 6.0 && ph <= 7.0) score += 20;
    else if (ph >= 5.5 && ph <= 7.5) score += 10;
    else score -= 10;
    final n = (_soilData['nitrogen_total'] as num?)?.toDouble() ?? 0;
    if (n >= 1.5) score += 10;
    else if (n >= 0.8) score += 5;
    final oc = (_soilData['organic_carbon'] as num?)?.toDouble() ?? 0;
    if (oc >= 10) score += 10;
    else if (oc >= 5) score += 5;
    final clay = (_soilData['clay'] as num?)?.toDouble() ?? 30;
    if (clay >= 15 && clay <= 45) score += 10;
    return score.clamp(0, 100);
  }

  Future<void> _getAiAdvice() async {
    if (_soilData.isEmpty) return;
    setState(() { _aiLoading = true; _aiRecommendation = null; });
    try {
      final ph = (_soilData['ph'] as num?)?.toStringAsFixed(1) ?? 'N/A';
      final n = (_soilData['nitrogen_total'] as num?)?.toStringAsFixed(2) ?? 'N/A';
      final p = (_soilData['phosphorus_extractable'] as num?)?.toStringAsFixed(1) ?? 'N/A';
      final k = (_soilData['potassium_extractable'] as num?)?.toStringAsFixed(1) ?? 'N/A';
      final oc = (_soilData['organic_carbon'] as num?)?.toStringAsFixed(1) ?? 'N/A';

      final prompt = '''Toa mapendekezo ya mbolea kwa mkulima wa Tanzania.
Zao: $_selectedCrop
Data ya udongo:
- pH: $ph
- Nitrojeni: $n g/kg
- Fosforasi: $p mg/kg
- Potasiamu: $k mg/kg
- Kaboni ya Kikaboni: $oc g/kg
- Eneo: lat=$_lat, lng=$_lng

Jibu kwa Kiswahili. Taja:
1. Hali ya udongo kwa ufupi
2. Mbolea zinazopendekezwa (DAP, Urea, CAN, NPK) na viwango kwa ekari
3. Bei ya takriban kwa TZS
4. Hatua za kuimarisha udongo''';

      final advice = await ClaudeService.askFarmingQuestion(
          question: prompt,
          cropContext: _selectedCrop,
          regionContext: 'Tanzania');
      if (mounted) setState(() => _aiRecommendation = advice);
    } catch (e) {
      if (mounted) setState(() => _aiRecommendation = 'Imeshindwa kupata ushauri: $e');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.farmName ?? 'Ramani ya Udongo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _lat != null ? _fetchSoilData : null,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _soilData.isEmpty
              ? _buildEmpty()
              : _buildContent(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌍', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('Ramani ya Udongo',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Gundua afya ya udongo wa shamba lako',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.criticalBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: GoogleFonts.poppins(
                  color: AppColors.critical, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Tumia GPS Yangu'),
            ),
            const SizedBox(height: 12),
            if (widget.farmLat != null)
              OutlinedButton.icon(
                onPressed: _fetchSoilData,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Tumia GPS ya Shamba'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final score = _soilScore();
    final scoreColor = score >= 70
        ? const Color(0xFF2E7D32)
        : score >= 40
            ? const Color(0xFFE65100)
            : const Color(0xFFB71C1C);
    final scoreLabel = score >= 70 ? 'Udongo Mzuri' : score >= 40 ? 'Wastani' : 'Udongo Dhaifu';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadow.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF1A5C2E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.farmName ?? 'Mahali Pako',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Text(
                        '${_lat?.toStringAsFixed(4)}°, ${_lng?.toStringAsFixed(4)}°',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (_lastFetch != null)
                  Text(
                    'Ilisasishwa sasa hivi',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Health Score
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scoreColor, scoreColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        color: Colors.white,
                      ),
                      Text('$score',
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alama ya Udongo',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 12)),
                    Text(scoreLabel,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    Text('kati ya 100',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nutrient Cards
          Text('Virutubisho vya Udongo',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildNutrientGrid(),
          const SizedBox(height: 16),

          // Crop selector
          Text('Chagua Zao',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _crops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = _crops[i] == _selectedCrop;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCrop = _crops[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(_crops[i],
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // AI Advice
          ElevatedButton.icon(
            onPressed: _aiLoading ? null : _getAiAdvice,
            icon: _aiLoading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.psychology_outlined),
            label: Text(_aiLoading ? 'AI inafikiria...' : 'Pata Ushauri wa AI 🤖'),
          ),

          if (_aiRecommendation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                boxShadow: AppShadow.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🤖', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text('Ushauri wa AI kwa $_selectedCrop',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const Spacer(),
                      SpeakerButton(text: _aiRecommendation!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_aiRecommendation!,
                      style: GoogleFonts.poppins(fontSize: 13, height: 1.6)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNutrientGrid() {
    final nutrients = [
      _NutrientData(
        icon: '🧪', label: 'pH ya Udongo',
        value: (_soilData['ph'] as num?)?.toStringAsFixed(1) ?? '—',
        unit: '',
        min: 5.5, max: 7.5, current: (_soilData['ph'] as num?)?.toDouble(),
        optMin: 6.0, optMax: 7.0,
      ),
      _NutrientData(
        icon: '🌿', label: 'Nitrojeni (N)',
        value: (_soilData['nitrogen_total'] as num?)?.toStringAsFixed(2) ?? '—',
        unit: 'g/kg',
        min: 0, max: 5, current: (_soilData['nitrogen_total'] as num?)?.toDouble(),
        optMin: 1.5, optMax: 4.0,
      ),
      _NutrientData(
        icon: '🔵', label: 'Fosforasi (P)',
        value: (_soilData['phosphorus_extractable'] as num?)?.toStringAsFixed(1) ?? '—',
        unit: 'mg/kg',
        min: 0, max: 80, current: (_soilData['phosphorus_extractable'] as num?)?.toDouble(),
        optMin: 15, optMax: 60,
      ),
      _NutrientData(
        icon: '🟡', label: 'Potasiamu (K)',
        value: (_soilData['potassium_extractable'] as num?)?.toStringAsFixed(0) ?? '—',
        unit: 'mg/kg',
        min: 0, max: 300, current: (_soilData['potassium_extractable'] as num?)?.toDouble(),
        optMin: 80, optMax: 250,
      ),
      _NutrientData(
        icon: '♻️', label: 'Kaboni',
        value: (_soilData['organic_carbon'] as num?)?.toStringAsFixed(1) ?? '—',
        unit: 'g/kg',
        min: 0, max: 30, current: (_soilData['organic_carbon'] as num?)?.toDouble(),
        optMin: 10, optMax: 25,
      ),
      _NutrientData(
        icon: '🏔️', label: 'Udongo (Mchanganyiko)',
        value: 'Tifutifu',
        unit: '',
        min: 0, max: 100,
        current: (_soilData['clay'] as num?)?.toDouble(),
        optMin: 15, optMax: 45,
        displayOverride: _textureLabel(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: nutrients.length,
      itemBuilder: (_, i) => _NutrientCard(data: nutrients[i]),
    );
  }

  String _textureLabel() {
    final clay = (_soilData['clay'] as num?)?.toDouble() ?? 30;
    final sand = (_soilData['sand'] as num?)?.toDouble() ?? 40;
    if (sand > 65) return 'Mchanga';
    if (clay > 50) return 'Tifutifu Nzito';
    if (clay > 25) return 'Tifutifu';
    return 'Tifutifu Laini';
  }
}

class _NutrientData {
  final String icon;
  final String label;
  final String value;
  final String unit;
  final double min;
  final double max;
  final double? current;
  final double optMin;
  final double optMax;
  final String? displayOverride;

  const _NutrientData({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    this.current,
    required this.optMin,
    required this.optMax,
    this.displayOverride,
  });

  Color get statusColor {
    if (current == null) return Colors.grey;
    if (current! >= optMin && current! <= optMax) return const Color(0xFF2E7D32);
    if (current! < optMin * 0.6 || current! > optMax * 1.5) return const Color(0xFFB71C1C);
    return const Color(0xFFE65100);
  }

  String get statusEmoji {
    if (current == null) return '⚪';
    if (current! >= optMin && current! <= optMax) return '🟢';
    if (current! < optMin * 0.6 || current! > optMax * 1.5) return '🔴';
    return '🟡';
  }
}

class _NutrientCard extends StatelessWidget {
  final _NutrientData data;
  const _NutrientCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final progress = data.current != null
        ? ((data.current! - data.min) / (data.max - data.min)).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(data.icon, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              Text(data.statusEmoji, style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Text(data.label,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            data.displayOverride ?? '${data.value}${data.unit.isEmpty ? '' : ' ${data.unit}'}',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: data.statusColor),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(data.statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
