import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/farm_model.dart';
import '../services/claude_service.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IoT Dashboard — shows real-time sensor data for a farm.
// Fully optional: shows setup guide if no sensors are connected.
// ─────────────────────────────────────────────────────────────────────────────

class IoTDashboardScreen extends StatefulWidget {
  final FarmModel farm;
  const IoTDashboardScreen({super.key, required this.farm});

  @override
  State<IoTDashboardScreen> createState() => _IoTDashboardScreenState();
}

class _IoTDashboardScreenState extends State<IoTDashboardScreen> {
  static SupabaseClient get _db => Supabase.instance.client;

  // Latest reading per sensor type
  Map<String, Map<String, dynamic>> _latest = {};

  // Historical readings for charts (last 24 readings per type)
  Map<String, List<Map<String, dynamic>>> _history = {};

  // AI alert state
  String? _aiAlert;
  bool _aiLoading = false;

  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Poll every 30 seconds for new sensor data
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Get latest reading per sensor type
      final rows = await _db
          .from('iot_readings')
          .select()
          .eq('farm_id', widget.farm.id)
          .order('recorded_at', ascending: false)
          .limit(200);

      final latestMap = <String, Map<String, dynamic>>{};
      final historyMap = <String, List<Map<String, dynamic>>>{};

      for (final r in rows as List) {
        final type = r['sensor_type'] as String;
        latestMap.putIfAbsent(type, () => r);
        historyMap.putIfAbsent(type, () => []);
        if ((historyMap[type]!.length) < 24) {
          historyMap[type]!.add(r);
        }
      }

      if (mounted) {
        setState(() {
          _latest  = latestMap;
          _history = historyMap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _askAI() async {
    if (_latest.isEmpty) return;
    setState(() { _aiLoading = true; _aiAlert = null; });

    final summary = _latest.entries.map((e) {
      final val = e.value['value'] as Map<String, dynamic>? ?? {};
      return '${e.key}: ${val.entries.map((v) => '${v.key}=${v.value}').join(', ')}';
    }).join('\n');

    final crops = widget.farm.crops.isEmpty
        ? 'mazao mchanganyiko'
        : widget.farm.crops.join(', ');

    final answer = await ClaudeService.askFarmingQuestion(
      question:
          'Shamba la $crops (${widget.farm.region}) lina data hii ya sensa:\n'
          '$summary\n\n'
          'Chunguza data hii na utoe:\n'
          '1. Hali ya sasa ya shamba (nzuri/ya wasiwasi/hatari)\n'
          '2. Tahadhari yoyote inayohitajika SASA HIVI\n'
          '3. Hatua 2-3 za kufanya leo\n'
          'Jibu kwa Kiswahili fupi na wazi.',
      cropContext: crops,
      regionContext: widget.farm.region,
    );

    if (mounted) setState(() { _aiAlert = answer; _aiLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _latest.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IoT Dashboard 📡',
                style: GoogleFonts.playfairDisplay(
                    color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.bold)),
            Text(widget.farm.name,
                style: GoogleFonts.dmSans(
                    color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          if (hasData)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Onyesha upya',
              onPressed: _loadData,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.leaf))
          : hasData
              ? _Dashboard(
                  latest: _latest,
                  history: _history,
                  farm: widget.farm,
                  aiAlert: _aiAlert,
                  aiLoading: _aiLoading,
                  onRefresh: _loadData,
                  onAskAI: _askAI,
                )
              : _NoSensorsView(farm: widget.farm),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Dashboard (when sensors are connected)
// ══════════════════════════════════════════════════════════════════════════════

class _Dashboard extends StatelessWidget {
  final Map<String, Map<String, dynamic>> latest;
  final Map<String, List<Map<String, dynamic>>> history;
  final FarmModel farm;
  final String? aiAlert;
  final bool aiLoading;
  final VoidCallback onRefresh;
  final VoidCallback onAskAI;

  const _Dashboard({
    required this.latest, required this.history, required this.farm,
    required this.aiAlert, required this.aiLoading,
    required this.onRefresh, required this.onAskAI,
  });

  String _ago(String? ts) {
    if (ts == null) return '—';
    try {
      final dt = DateTime.parse(ts).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'sasa hivi';
      if (diff.inMinutes < 60) return '${diff.inMinutes} dak. zilizopita';
      if (diff.inHours < 24) return '${diff.inHours} saa zilizopita';
      return '${diff.inDays} siku zilizopita';
    } catch (_) { return '—'; }
  }

  @override
  Widget build(BuildContext context) {
    final moisture  = latest['soil_moisture'];
    final npk       = latest['npk'];
    final weather   = latest['weather'];
    final ph        = latest['ph'];
    final light     = latest['light'];

    final lastTs = latest.values
        .map((r) => r['recorded_at'] as String?)
        .whereType<String>()
        .fold<String?>(null, (a, b) => a == null || b.compareTo(a) > 0 ? b : a);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.leaf,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status bar ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.leaf.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.leaf.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sensors, color: AppColors.leaf, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${latest.length} sensa zinazo fanya kazi • Imesasishwa: ${_ago(lastTs)}',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.leaf,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── AI Alert button ────────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: aiLoading ? null : onAskAI,
            icon: aiLoading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('🤖', style: TextStyle(fontSize: 16)),
            label: Text(aiLoading
                ? 'Claude anachunguza data...'
                : 'Chunguza Hali ya Shamba kwa AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          // AI Alert result
          if (aiAlert != null) ...[
            const SizedBox(height: 12),
            _AlertCard(message: aiAlert!),
          ],

          const SizedBox(height: 16),

          // ── Sensor cards grid ──────────────────────────────────────────────
          Text('Taarifa za Sensa',
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  color: AppColors.soil, fontSize: 14)),
          const SizedBox(height: 10),

          // Row 1: Soil moisture + Weather
          Row(
            children: [
              Expanded(child: _SoilMoistureCard(data: moisture)),
              const SizedBox(width: 10),
              Expanded(child: _WeatherCard(data: weather)),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: NPK + pH
          Row(
            children: [
              Expanded(child: _NpkCard(data: npk)),
              const SizedBox(width: 10),
              Expanded(child: _PhCard(data: ph)),
            ],
          ),

          if (light != null) ...[
            const SizedBox(height: 10),
            _LightCard(data: light),
          ],

          // ── Trend charts ───────────────────────────────────────────────────
          if (history['soil_moisture'] != null &&
              history['soil_moisture']!.length >= 2) ...[
            const SizedBox(height: 20),
            Text('Mwenendo wa Unyevu (masaa 24)',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: AppColors.soil, fontSize: 14)),
            const SizedBox(height: 8),
            _MoistureTrendChart(readings: history['soil_moisture']!),
          ],

          if (history['weather'] != null &&
              history['weather']!.length >= 2) ...[
            const SizedBox(height: 20),
            Text('Mwenendo wa Joto (masaa 24)',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: AppColors.soil, fontSize: 14)),
            const SizedBox(height: 8),
            _TempTrendChart(readings: history['weather']!),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── AI Alert Card ─────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final String message;
  const _AlertCard({required this.message});

  Color get _bgColor {
    final low = message.toLowerCase();
    if (low.contains('hatari') || low.contains('haraka') ||
        low.contains('mbaya')) return Colors.red.shade50;
    if (low.contains('wasiwasi') || low.contains('angalia') ||
        low.contains('tahadhari')) return Colors.orange.shade50;
    return const Color(0xFFE8F5E9);
  }

  Color get _borderColor {
    final low = message.toLowerCase();
    if (low.contains('hatari') || low.contains('haraka') ||
        low.contains('mbaya')) return Colors.red.shade300;
    if (low.contains('wasiwasi') || low.contains('angalia') ||
        low.contains('tahadhari')) return Colors.orange.shade300;
    return AppColors.leaf;
  }

  String get _emoji {
    final low = message.toLowerCase();
    if (low.contains('hatari') || low.contains('haraka') ||
        low.contains('mbaya')) return '🚨';
    if (low.contains('wasiwasi') || low.contains('angalia') ||
        low.contains('tahadhari')) return '⚠️';
    return '✅';
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Uchambuzi wa AI',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13, color: AppColors.soil)),
              ],
            ),
            const SizedBox(height: 8),
            Text(message,
                style: GoogleFonts.dmSans(
                    fontSize: 13, height: 1.6, color: AppColors.ink)),
          ],
        ),
      );
}

// ── Sensor Cards ──────────────────────────────────────────────────────────────

class _SoilMoistureCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _SoilMoistureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return _NoSensorCard(emoji: '💧', label: 'Unyevu wa Udongo');
    final val = (data!['value'] as Map<String, dynamic>?)?['moisture'] as num?;
    final pct = val?.toDouble() ?? 0;

    Color color;
    String status;
    if (pct < 20) { color = Colors.red; status = 'Kavu sana'; }
    else if (pct < 40) { color = Colors.orange; status = 'Haitoshi'; }
    else if (pct < 70) { color = AppColors.leaf; status = 'Nzuri'; }
    else { color = Colors.blue; status = 'Nyingi sana'; }

    return _SensorCard(
      emoji: '💧',
      label: 'Unyevu wa Udongo',
      value: '${pct.toStringAsFixed(0)}%',
      status: status,
      color: color,
      child: _GaugeBar(value: pct / 100, color: color),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _WeatherCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return _NoSensorCard(emoji: '🌡️', label: 'Hali ya Hewa');
    final val = data!['value'] as Map<String, dynamic>? ?? {};
    final temp = (val['temp'] as num?)?.toDouble();
    final hum  = (val['humidity'] as num?)?.toDouble();

    return _SensorCard(
      emoji: '🌡️',
      label: 'Hali ya Hewa',
      value: temp != null ? '${temp.toStringAsFixed(1)}°C' : '—',
      status: hum != null ? 'Unyevu: ${hum.toStringAsFixed(0)}%' : '',
      color: temp != null && temp > 35 ? Colors.red : AppColors.harvest,
      child: hum != null
          ? _GaugeBar(value: hum / 100, color: Colors.blue.shade300)
          : const SizedBox.shrink(),
    );
  }
}

class _NpkCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _NpkCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return _NoSensorCard(emoji: '🌿', label: 'Rutuba (NPK)');
    final val = data!['value'] as Map<String, dynamic>? ?? {};
    final n = (val['n'] as num?)?.toDouble();
    final p = (val['p'] as num?)?.toDouble();
    final k = (val['k'] as num?)?.toDouble();

    return _SensorCard(
      emoji: '🌿',
      label: 'Rutuba (NPK)',
      value: '',
      status: '',
      color: AppColors.leaf,
      child: Column(
        children: [
          if (n != null) _NpkRow('N', n, Colors.green.shade700),
          if (p != null) _NpkRow('P', p, Colors.orange.shade700),
          if (k != null) _NpkRow('K', k, Colors.purple.shade700),
        ],
      ),
    );
  }
}

class _NpkRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _NpkRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(label,
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: (value / 10).clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text('${value.toStringAsFixed(1)} g/kg',
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: AppColors.soil,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _PhCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _PhCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return _NoSensorCard(emoji: '🧪', label: 'pH ya Udongo');
    final val = (data!['value'] as Map<String, dynamic>?)?['ph'] as num?;
    final ph  = val?.toDouble() ?? 7.0;

    Color color;
    String status;
    if (ph < 5.5) { color = Colors.red; status = 'Tindikali sana'; }
    else if (ph < 6.0) { color = Colors.orange; status = 'Tindikali kidogo'; }
    else if (ph < 7.0) { color = AppColors.leaf; status = 'Nzuri kwa mazao'; }
    else if (ph < 7.5) { color = AppColors.leaf; status = 'Nzuri'; }
    else { color = Colors.orange; status = 'Alkali'; }

    return _SensorCard(
      emoji: '🧪',
      label: 'pH ya Udongo',
      value: ph.toStringAsFixed(1),
      status: status,
      color: color,
      child: _GaugeBar(value: (ph - 3) / 11, color: color),
    );
  }
}

class _LightCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final val  = (data['value'] as Map<String, dynamic>?)?['lux'] as num?;
    final lux  = val?.toDouble() ?? 0;
    final pct  = (lux / 100000).clamp(0.0, 1.0);

    String status;
    if (lux < 5000) status = 'Giza sana';
    else if (lux < 20000) status = 'Haitoshi';
    else if (lux < 60000) status = 'Nzuri';
    else status = 'Kali sana';

    return _SensorCard(
      emoji: '☀️',
      label: 'Mwanga (Lux)',
      value: '${(lux / 1000).toStringAsFixed(0)}k lux',
      status: status,
      color: Colors.amber.shade700,
      child: _GaugeBar(value: pct, color: Colors.amber.shade700),
    );
  }
}

// ── Shared sensor card ────────────────────────────────────────────────────────

class _SensorCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String status;
  final Color color;
  final Widget child;
  const _SensorCard({required this.emoji, required this.label,
      required this.value, required this.status,
      required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(label,
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.mid,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (value.isNotEmpty)
                Text(value,
                    style: GoogleFonts.dmSans(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: color)),
              if (status.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(status,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: color,
                        fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );
}

class _NoSensorCard extends StatelessWidget {
  final String emoji;
  final String label;
  const _NoSensorCard({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.mid,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Haijaunganishwa',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      );
}

class _GaugeBar extends StatelessWidget {
  final double value;
  final Color color;
  const _GaugeBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 8,
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
}

// ── Trend charts ──────────────────────────────────────────────────────────────

class _MoistureTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> readings;
  const _MoistureTrendChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final reversed = readings.reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < reversed.length; i++) {
      final val = (reversed[i]['value'] as Map<String, dynamic>?)?['moisture'];
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), (val as num).toDouble()));
      }
    }
    if (spots.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: SizedBox(
          height: 140,
          child: LineChart(LineChartData(
            gridData: FlGridData(
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 20,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}%',
                    style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.mid),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0, maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue.shade400,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.shade50,
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

class _TempTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> readings;
  const _TempTrendChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final reversed = readings.reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < reversed.length; i++) {
      final val = (reversed[i]['value'] as Map<String, dynamic>?)?['temp'];
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), (val as num).toDouble()));
      }
    }
    if (spots.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: SizedBox(
          height: 140,
          child: LineChart(LineChartData(
            gridData: FlGridData(
              drawHorizontalLine: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}°',
                    style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.mid),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.orange.shade400,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.orange.shade50,
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// No Sensors View — shown when farm has no IoT data
// ══════════════════════════════════════════════════════════════════════════════

class _NoSensorsView extends StatelessWidget {
  final FarmModel farm;
  const _NoSensorsView({required this.farm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('📡', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 12),
                Text('Sensa za IoT — Kipengele cha Ziada',
                    style: GoogleFonts.playfairDisplay(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Shamba la ${farm.name} bado halina sensa zilizounganishwa. '
                  'Sensa ni za hiari — zinasaidia zaidi kwa mbogamboga na matunda.',
                  style: GoogleFonts.dmSans(
                      color: Colors.white70, fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Available sensors
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Sensa Zinazopatikana',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: AppColors.soil, fontSize: 15)),
          ),
          const SizedBox(height: 12),

          ...[
            _SensorInfo(
              emoji: '💧',
              name: 'Soil Moisture Sensor',
              desc: 'Hupima unyevu wa udongo kwa kina. Muhimu sana kwa pilipili, nyanya, na matunda.',
              price: 'TZS 25,000 – 80,000',
              type: 'sensor_type: "soil_moisture"\nvalue: {"moisture": 65, "depth_cm": 10}',
            ),
            _SensorInfo(
              emoji: '🌡️',
              name: 'Weather Station (Mini)',
              desc: 'Hupima joto, unyevu wa hewa, mvua, na upepo shambani mwenyewe.',
              price: 'TZS 150,000 – 500,000',
              type: 'sensor_type: "weather"\nvalue: {"temp": 28.5, "humidity": 72, "rain_mm": 0}',
            ),
            _SensorInfo(
              emoji: '🌿',
              name: 'NPK Soil Sensor',
              desc: 'Hupima Nitrojeni, Fosforasi, na Potasiamu — rutuba ya udongo.',
              price: 'TZS 80,000 – 250,000',
              type: 'sensor_type: "npk"\nvalue: {"n": 3.2, "p": 1.8, "k": 2.5}',
            ),
            _SensorInfo(
              emoji: '🧪',
              name: 'pH Sensor',
              desc: 'Hupima kiwango cha tindikali cha udongo. Muhimu kwa mazao yote.',
              price: 'TZS 50,000 – 150,000',
              type: 'sensor_type: "ph"\nvalue: {"ph": 6.2}',
            ),
            _SensorInfo(
              emoji: '☀️',
              name: 'Light Sensor (PAR)',
              desc: 'Hupima kiwango cha mwanga wanaopokea mimea. Husaidia kujua kivuli.',
              price: 'TZS 40,000 – 120,000',
              type: 'sensor_type: "light"\nvalue: {"lux": 45000}',
            ),
          ],

          const SizedBox(height: 24),

          // How to connect
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔧', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('Jinsi ya Kuunganisha',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                ...[
                  '1️⃣  Nunua sensa (Arduino/Raspberry Pi + sensor)',
                  '2️⃣  Programu sensa itume data kwa HTTP POST → Supabase',
                  '3️⃣  Tumia farm_id = "${farm.id}"',
                  '4️⃣  Data itaonekana kwenye dashboard hii moja kwa moja',
                  '5️⃣  Claude AI itachunguza mwenendo na kutoa tahadhari',
                ].map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(step,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: Colors.blue.shade800,
                          height: 1.4)),
                )),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // API endpoint info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mfano wa API Call (HTTP POST)',
                    style: GoogleFonts.dmSans(
                        color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 8),
                Text(
                  'POST → Supabase /rest/v1/iot_readings\n\n'
                  '{\n'
                  '  "farm_id": "${farm.id}",\n'
                  '  "sensor_type": "soil_moisture",\n'
                  '  "value": {"moisture": 65},\n'
                  '  "device_id": "arduino-01"\n'
                  '}',
                  style: GoogleFonts.dmSans(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      height: 1.6),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SensorInfo extends StatelessWidget {
  final String emoji;
  final String name;
  final String desc;
  final String price;
  final String type;
  const _SensorInfo({required this.emoji, required this.name,
      required this.desc, required this.price, required this.type});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13, color: AppColors.soil)),
                  const SizedBox(height: 3),
                  Text(desc,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.mid, height: 1.4)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.harvest.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('💰 $price',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.harvest,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
