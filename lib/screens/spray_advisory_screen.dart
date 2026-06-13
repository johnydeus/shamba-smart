import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class SprayAdvisoryScreen extends StatefulWidget {
  const SprayAdvisoryScreen({super.key});

  @override
  State<SprayAdvisoryScreen> createState() => _SprayAdvisoryScreenState();
}

class _SprayAdvisoryScreenState extends State<SprayAdvisoryScreen> {
  bool _loading = false;
  Map<String, dynamic>? _current;
  List<Map<String, dynamic>> _daily = [];
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final pos = await LocationService.getCurrentLocation();
      _lat = pos.latitude;
      _lng = pos.longitude;

      final uri = Uri.parse('https://api.open-meteo.com/v1/forecast').replace(
        queryParameters: {
          'latitude': _lat!.toStringAsFixed(4),
          'longitude': _lng!.toStringAsFixed(4),
          'current': 'temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation_probability,uv_index,weather_code',
          'hourly': 'temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation_probability,uv_index',
          'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max,precipitation_probability_max,uv_index_max',
          'timezone': 'Africa/Nairobi',
          'forecast_days': '7',
        },
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        _parseCurrent(json);
        _parseDaily(json);
      } else {
        _useDemoData();
      }
    } catch (e) {
      _useDemoData();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _parseCurrent(Map<String, dynamic> json) {
    final cur = json['current'] as Map<String, dynamic>? ?? {};
    _current = {
      'temp': (cur['temperature_2m'] as num?)?.toDouble() ?? 27.0,
      'humidity': (cur['relative_humidity_2m'] as num?)?.toDouble() ?? 65.0,
      'wind': (cur['wind_speed_10m'] as num?)?.toDouble() ?? 8.0,
      'rain_prob': (cur['precipitation_probability'] as num?)?.toDouble() ?? 20.0,
      'uv': (cur['uv_index'] as num?)?.toDouble() ?? 6.0,
    };
  }

  void _parseDaily(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>? ?? {};
    final dates = (daily['time'] as List? ?? []).cast<String>();
    final maxTemps = (daily['temperature_2m_max'] as List? ?? []).cast<num>();
    final rain = (daily['precipitation_sum'] as List? ?? []).cast<num?>();
    final wind = (daily['wind_speed_10m_max'] as List? ?? []).cast<num>();
    final rainProb = (daily['precipitation_probability_max'] as List? ?? []).cast<num>();
    final uv = (daily['uv_index_max'] as List? ?? []).cast<num?>();

    _daily = List.generate(dates.length, (i) {
      final windVal = wind[i].toDouble();
      final rainProbVal = rainProb[i].toDouble();
      final tempVal = maxTemps[i].toDouble();
      final uvVal = (uv[i] ?? 6).toDouble();
      return {
        'date': dates[i],
        'temp': tempVal,
        'rain_mm': (rain[i] ?? 0).toDouble(),
        'wind': windVal,
        'rain_prob': rainProbVal,
        'uv': uvVal,
        'safe': windVal < 15 && rainProbVal < 30 && tempVal < 32,
        'caution': (windVal >= 15 && windVal < 20) ||
            (rainProbVal >= 30 && rainProbVal < 60),
      };
    });
  }

  void _useDemoData() {
    _current = {
      'temp': 27.0, 'humidity': 65.0, 'wind': 8.5,
      'rain_prob': 15.0, 'uv': 6.5,
    };
    final now = DateTime.now();
    _daily = List.generate(7, (i) => {
      'date': now.add(Duration(days: i)).toIso8601String().substring(0, 10),
      'temp': 27.0 + i * 0.5,
      'rain_mm': i == 3 ? 12.0 : 0.0,
      'wind': 8.0 + i * 0.3,
      'rain_prob': i == 3 ? 70.0 : 15.0,
      'uv': 7.0,
      'safe': i != 3,
      'caution': false,
    });
  }

  // TPRI spray safety logic
  bool _isSafe(Map<String, dynamic> d) {
    final wind = (d['wind'] as num).toDouble();
    final rain = (d['rain_prob'] as num).toDouble();
    final temp = (d['temp'] as num).toDouble();
    final humidity = (d['humidity'] as num? ?? 65).toDouble();
    final uv = (d['uv'] as num? ?? 5).toDouble();
    return wind < 15 && rain < 30 && temp < 32 && humidity >= 40 && humidity <= 80 && uv < 8;
  }

  String _safetyLabel(Map<String, dynamic> d) {
    if (_isSafe(d)) return 'SALAMA KUPULIZIA';
    final wind = (d['wind'] as num).toDouble();
    final rain = (d['rain_prob'] as num).toDouble();
    if (rain > 60 || wind > 20) return 'USIPULIZIE LEO';
    return 'ANGALIA HALI — SUBIRI ASUBUHI';
  }

  Color _safetyColor(Map<String, dynamic> d) {
    final label = _safetyLabel(d);
    if (label.contains('SALAMA')) return const Color(0xFF2E7D32);
    if (label.contains('ANGALIA')) return const Color(0xFFE65100);
    return const Color(0xFFB71C1C);
  }

  String _dayNameSw(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    const fullDays = ['Jumapili', 'Jumatatu', 'Jumanne', 'Jumatano',
                      'Alhamisi', 'Ijumaa', 'Jumamosi'];
    return fullDays[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Ushauri wa Kupulizia'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's safety card
                  if (_current != null) _buildTodaySafety(),
                  const SizedBox(height: 20),
                  // 7-day calendar
                  Text('Kalenda ya Siku 7',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (_daily.isNotEmpty) _buildWeekCalendar(),
                  const SizedBox(height: 20),
                  // Best window
                  _buildBestWindow(),
                  const SizedBox(height: 20),
                  // TPRI Guidelines
                  Text('Mwongozo wa TPRI',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildGuidelines(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildTodaySafety() {
    final d = _current!;
    final color = _safetyColor(d);
    final label = _safetyLabel(d);

    final wind = (d['wind'] as num).toDouble();
    final rain = (d['rain_prob'] as num).toDouble();
    final temp = (d['temp'] as num).toDouble();
    final humidity = (d['humidity'] as num).toDouble();
    final uv = (d['uv'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.water_drop_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Ushauri wa Leo',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          // Conditions
          _ConditionRow(
            ok: wind < 15, label: 'Upepo: ${wind.toStringAsFixed(0)}km/h',
            detail: 'Kikomo: 15km/h'),
          _ConditionRow(
            ok: rain < 30, label: 'Mvua: ${rain.toStringAsFixed(0)}%',
            detail: 'Kikomo: 30%'),
          _ConditionRow(
            ok: temp < 32, label: 'Joto: ${temp.toStringAsFixed(0)}°C',
            detail: 'Kikomo: 32°C'),
          _ConditionRow(
            ok: humidity >= 40 && humidity <= 80,
            label: 'Unyevu: ${humidity.toStringAsFixed(0)}%',
            detail: 'Bora: 40-80%'),
          _ConditionRow(
            ok: uv < 8, label: 'UV: ${uv.toStringAsFixed(1)}',
            detail: 'Kikomo: 8'),
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _daily.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = _daily[i];
          final color = _safetyColor(d);
          final dateStr = d['date'] as String;
          final dayName = i == 0 ? 'Leo' : _dayNameSw(dateStr);
          final rain = (d['rain_prob'] as num).toDouble();

          return Container(
            width: 80,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: AppShadow.xs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dayName, style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(rain > 50 ? '🌧️' : rain > 20 ? '⛅' : '☀️',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 6),
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(height: 4),
                Text('${(d['temp'] as num).round()}°',
                    style: GoogleFonts.poppins(fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBestWindow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A5C2E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.access_time, color: Color(0xFF1A5C2E)),
            ),
            const SizedBox(width: 12),
            Text('Wakati Bora wa Kupulizia',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
          const SizedBox(height: 16),
          _WindowRow(time: 'Saa 12–3 asubuhi (6am–9am)',
              label: '⭐ Bora Kabisa', color: const Color(0xFF2E7D32)),
          _WindowRow(time: 'Saa 10–12 jioni (4pm–6pm)',
              label: 'Nzuri', color: const Color(0xFF4CAF50)),
          _WindowRow(time: 'Saa 4–10 mchana (10am–4pm)',
              label: '⚠️ Epuka', color: const Color(0xFFE65100)),
          _WindowRow(time: 'Wakati wa mvua / baada ya mvua saa 2',
              label: '❌ Kamwe', color: const Color(0xFFB71C1C)),
        ],
      ),
    );
  }

  Widget _buildGuidelines() {
    final items = [
      {
        'title': 'Fungicides — Dawa za Kuvu',
        'icon': '🍄',
        'content': 'Pulizia wakati unyevu wa hewa ni kati ya 60–80%. '
            'Usipulizie jua kali au wakati wa mvua. '
            'Bora asubuhi mapema kabla ya jua kukaa.',
      },
      {
        'title': 'Insecticides — Dawa za Wadudu',
        'icon': '🐛',
        'content': 'Bora kupulizia asubuhi mapema. Wadudu wanatulia usiku '
            'hivyo pulizia wakati wanaposimama. '
            'Epuka wakati wa upepo mkali.',
      },
      {
        'title': 'Herbicides — Dawa za Magugu',
        'icon': '🌿',
        'content': 'Magugu lazima yawe na unyevu kidogo. '
            'Usipulizie saa za joto kali. '
            'Subiri saa 4 baada ya kutumia kabla ya mvua.',
      },
    ];

    return Column(
      children: items.map((item) => _GuidelineCard(
        icon: item['icon']!,
        title: item['title']!,
        content: item['content']!,
      )).toList(),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final bool ok;
  final String label;
  final String detail;
  const _ConditionRow({required this.ok, required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.cancel,
            color: ok ? Colors.greenAccent : Colors.redAccent, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(label,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13))),
        Text(detail,
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
      ]),
    );
  }
}

class _WindowRow extends StatelessWidget {
  final String time;
  final String label;
  final Color color;
  const _WindowRow({required this.time, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(width: 4, height: 36, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color)),
          ],
        )),
      ]),
    );
  }
}

class _GuidelineCard extends StatefulWidget {
  final String icon;
  final String title;
  final String content;
  const _GuidelineCard({required this.icon, required this.title, required this.content});

  @override
  State<_GuidelineCard> createState() => _GuidelineCardState();
}

class _GuidelineCardState extends State<_GuidelineCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadow.xs,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(widget.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13))),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey),
              ]),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(widget.content,
                    style: GoogleFonts.poppins(fontSize: 12, height: 1.6,
                        color: Colors.grey.shade700)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
