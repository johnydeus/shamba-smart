import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/satellite_models.dart';
import '../providers/satellite_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';

// ── Colour helpers ─────────────────────────────────────────────────────────────

Color _ndviColor(NdviHealthStatus s) =>
    Color(s.colorValue).withValues(alpha: 1.0);

Color _ndwiColor(NdwiHealthStatus s) =>
    Color(s.colorValue).withValues(alpha: 1.0);

Color _scoreColor(double score) =>
    score >= 70 ? AppColors.leaf : score >= 45 ? AppColors.sun : Colors.red;

// ── Main satellite screen ──────────────────────────────────────────────────────

class SatelliteScreen extends StatefulWidget {
  const SatelliteScreen({super.key});

  @override
  State<SatelliteScreen> createState() => _SatelliteScreenState();
}

class _SatelliteScreenState extends State<SatelliteScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sat = context.watch<SatelliteProvider>();

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text(
          '🛰️ Satellite — Uchambuzi wa Shamba',
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (sat.hasField)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Sasisha NDVI',
              onPressed: sat.isLoading ? null : sat.fetchNdviData,
            ),
          if (sat.hasField)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              tooltip: 'Futa Shamba',
              onPressed: () => _confirmClearField(context, sat),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppColors.sun,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'Ramani'),
            Tab(icon: Icon(Icons.biotech_outlined), text: 'Afya'),
          ],
        ),
      ),
      body: !sat.hasField
          ? _SetupFieldView()
          : TabBarView(
              controller: _tabs,
              children: [
                _NdviMapTab(),
                _CropAnalysisTab(),
              ],
            ),
    );
  }

  void _confirmClearField(BuildContext ctx, SatelliteProvider sat) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Futa Shamba?',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: const Text('Data yote ya NDVI na uchambuzi itafutwa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hapana')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              sat.clearField();
            },
            child: const Text('Futa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Setup field view — shown when no field is defined ─────────────────────────

class _SetupFieldView extends StatefulWidget {
  @override
  State<_SetupFieldView> createState() => _SetupFieldViewState();
}

class _SetupFieldViewState extends State<_SetupFieldView> {
  final _nameCtrl = TextEditingController(text: 'Shamba Langu');

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sat = context.watch<SatelliteProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero illustration
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.soil,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🛰️', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(
                    'Uchambuzi wa Satellite',
                    style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'NDVI • Afya ya Mazao • Maji • Virutubisho',
                    style: GoogleFonts.dmSans(
                        color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          ShambaCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Weka Mipaka ya Shamba Lako',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.soil),
                ),
                const SizedBox(height: 16),

                // Field name
                _Field(_nameCtrl, 'Jina la Shamba', Icons.landscape_outlined),
                const SizedBox(height: 14),

                // GPS note
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.leaf.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed,
                          color: AppColors.leaf, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Eneo lako la GPS litatumika kupata picha za satellite za shamba lako.',
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.leaf),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Error display
                if (sat.error.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(sat.error,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13)),
                  ),

                // Status
                if (sat.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.leaf),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(sat.statusMessage,
                              style: GoogleFonts.dmSans(
                                  color: AppColors.mid, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                // Setup button
                ElevatedButton.icon(
                  onPressed: sat.isLoading ? null : () => _setup(context, sat),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leaf,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.satellite_alt, color: Colors.white),
                  label: Text('Anza Uchambuzi wa Satellite',
                      style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // What it does info card
          ShambaCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Utapata Nini?',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.soil)),
                const SizedBox(height: 10),
                for (final item in [
                  ('🗺️', 'Ramani ya NDVI ya shamba lako'),
                  ('📈', 'Grafu ya afya ya mazao - siku 30'),
                  ('💧', 'Uchambuzi wa mkazo wa maji'),
                  ('🌱', 'Hali ya virutubisho vya udongo'),
                  ('🛡️', 'Hatari za wadudu na magonjwa'),
                  ('🤖', 'Muhtasari wa Claude AI kwa Kiswahili'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(item.$1, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text(item.$2,
                            style: GoogleFonts.dmSans(
                                fontSize: 13, color: AppColors.ink)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setup(BuildContext ctx, SatelliteProvider sat) async {
    if (_nameCtrl.text.trim().isEmpty) return;
    await sat.createFieldFromGps(fieldName: _nameCtrl.text.trim());
  }
}

// ── NDVI Map Tab ───────────────────────────────────────────────────────────────

class _NdviMapTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sat = context.watch<SatelliteProvider>();
    final field = sat.field!;
    final latest = sat.latestNdvi;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Map
          SizedBox(
            height: 280,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: field.center,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.shambasmart.shamba_smart',
                ),
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: field.coordinates,
                      color: (latest != null
                              ? _ndviColor(latest.healthStatus)
                              : AppColors.leaf)
                          .withValues(alpha: 0.35),
                      borderColor: latest != null
                          ? _ndviColor(latest.healthStatus)
                          : AppColors.leaf,
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: field.center,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.soil,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Text('🌿',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // NDVI colour legend
                _NdviLegend(),
                const SizedBox(height: 16),

                // Latest NDVI stats card
                if (latest != null) _NdviStatsCard(reading: latest),
                const SizedBox(height: 16),

                // Field info card
                ShambaCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.landscape_outlined,
                          color: AppColors.leaf),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(field.name,
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.ink)),
                            Text(
                                'ID: ${field.id.length > 16 ? '${field.id.substring(0, 16)}...' : field.id}',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppColors.mid)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Loading state
                if (sat.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.leaf),
                        ),
                        const SizedBox(width: 10),
                        Text(sat.statusMessage,
                            style: GoogleFonts.dmSans(
                                color: AppColors.mid)),
                      ],
                    ),
                  ),

                // NDVI timeline chart
                if (sat.ndviReadings.length > 1) ...[
                  Text('Mwenendo wa NDVI — Siku 30',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.soil)),
                  const SizedBox(height: 12),
                  _NdviChart(readings: sat.ndviReadings),
                ],

                const SizedBox(height: 20),

                // ── NDWI section ──────────────────────────────────────────
                Row(
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'NDWI — Mkazo wa Maji',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: const Color(0xFF0D47A1)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Normalized Difference Water Index',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.mid),
                ),
                const SizedBox(height: 12),

                // NDWI colour legend
                _NdwiLegend(),
                const SizedBox(height: 12),

                // Latest NDWI stats card
                if (sat.latestNdwi != null)
                  _NdwiStatsCard(reading: sat.latestNdwi!),

                // NDWI timeline chart
                if (sat.ndwiReadings.length > 1) ...[
                  const SizedBox(height: 16),
                  Text('Mwenendo wa NDWI — Siku 30',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.soil)),
                  const SizedBox(height: 12),
                  _NdwiChart(readings: sat.ndwiReadings),
                  const SizedBox(height: 8),
                  // Interpretation guide
                  ShambaCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jinsi ya Kusoma NDWI:',
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.soil)),
                        const SizedBox(height: 6),
                        for (final item in [
                          ('> 0.2',  'Maji Mengi — Punguza umwagiliaji'),
                          ('0.05–0.2', 'Maji ya Kutosha — Endelea kawaida'),
                          ('-0.1–0.05', 'Mkazo Mdogo — Ongeza maji kidogo'),
                          ('-0.2– -0.1', 'Mkazo wa Wastani — Mwagilia mara 2/siku'),
                          ('< -0.2', '🚨 Mkazo Mkali — Mwagilia SASA HIVI'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(item.$1,
                                      style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0D47A1))),
                                ),
                                Expanded(
                                  child: Text(item.$2,
                                      style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          color: AppColors.ink)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Crop Analysis Tab ──────────────────────────────────────────────────────────

class _CropAnalysisTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sat = context.watch<SatelliteProvider>();
    final report = sat.report;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Run analysis button
          ElevatedButton.icon(
            onPressed: sat.isLoading ? null : sat.runAnalysis,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.soil,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: sat.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.biotech_outlined,
                    color: Colors.white),
            label: Text(
              sat.isLoading ? sat.statusMessage : '🤖 Changanua Shamba Sasa',
              style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),

          if (report == null && !sat.isLoading) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Text('🔬', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('Bonyeza kitufe juu kuanza uchambuzi.',
                      style: GoogleFonts.dmSans(
                          color: AppColors.mid, fontSize: 14)),
                  Text(
                      'Claude AI atachambua data ya satellite na kutoa ripoti.',
                      style: GoogleFonts.dmSans(
                          color: AppColors.mid, fontSize: 12),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ],

          if (report != null) ...[
            const SizedBox(height: 16),

            // Overall health score
            _HealthScoreCard(score: report.overallHealthScore),
            const SizedBox(height: 12),

            // AI summary
            _AiSummaryCard(summary: report.aiSummary),
            const SizedBox(height: 12),

            // Water stress
            _AnalysisSection(
              icon: '💧',
              title: 'Hali ya Maji',
              color: const Color(0xFF0277BD),
              child: _WaterStressCard(analysis: report.waterStress),
            ),
            const SizedBox(height: 10),

            // Soil
            _AnalysisSection(
              icon: '🌍',
              title: 'Hali ya Udongo',
              color: AppColors.earth,
              child: _SoilCard(analysis: report.soilAnalysis),
            ),
            const SizedBox(height: 10),

            // Nutrients
            _AnalysisSection(
              icon: '🌱',
              title: 'Virutubisho',
              color: AppColors.leaf,
              child: _NutrientsCard(analysis: report.nutrients),
            ),
            const SizedBox(height: 10),

            // Pests
            _AnalysisSection(
              icon: '🛡️',
              title: 'Wadudu na Magonjwa',
              color: const Color(0xFFB71C1C),
              child: _PestCard(analysis: report.pestDisease),
            ),
            const SizedBox(height: 10),

            // Recommendations
            _AnalysisSection(
              icon: '📋',
              title: 'Mapendekezo',
              color: AppColors.harvest,
              child: _RecommendationsCard(recs: report.recommendations),
            ),

            const SizedBox(height: 20),

            Text(
              'Uchambuzi uliofanywa: ${_fmtDate(report.generatedAt)}',
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.mid),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _NdviLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShambaCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kiwango cha Kijani (NDVI)',
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.soil)),
          const SizedBox(height: 8),
          Row(
            children: NdviHealthStatus.values.map((s) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: _ndviColor(s),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(s.labelSw,
                        style: GoogleFonts.dmSans(
                            fontSize: 9, color: AppColors.mid),
                        textAlign: TextAlign.center),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _NdviStatsCard extends StatelessWidget {
  final NdviReading reading;
  const _NdviStatsCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    final color = _ndviColor(reading.healthStatus);
    return ShambaCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                reading.average.toStringAsFixed(2),
                style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NDVI ya Leo',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.mid)),
                Text(reading.healthStatus.labelSw,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(
                    'Min: ${reading.min.toStringAsFixed(2)}  '
                    'Max: ${reading.max.toStringAsFixed(2)}',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.mid)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NdviChart extends StatelessWidget {
  final List<NdviReading> readings;
  const _NdviChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final spots = readings.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.average);
    }).toList();

    return ShambaCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 1,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 0.2,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.mid.withValues(alpha: 0.15),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 0.2,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) => Text(
                    v.toStringAsFixed(1),
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.mid),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (readings.length / 4).ceilToDouble(),
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= readings.length) {
                      return const SizedBox.shrink();
                    }
                    final d = readings[idx].date;
                    return Text(
                      '${d.day}/${d.month}',
                      style: GoogleFonts.dmSans(
                          fontSize: 10, color: AppColors.mid),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: AppColors.leaf,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, idx) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: _ndviColor(NdviReading(
                      date: DateTime.now(),
                      average: spot.y,
                      min: 0,
                      max: 1,
                      cloudCover: 0,
                    ).healthStatus),
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.leaf.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  final double score;
  const _HealthScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    final emoji = score >= 70 ? '🟢' : score >= 45 ? '🟡' : '🔴';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.soil, color.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alama ya Afya ya Shamba',
                    style: GoogleFonts.dmSans(
                        color: Colors.white60, fontSize: 12)),
                Text(
                  '${score.toStringAsFixed(0)}/100',
                  style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: score / 100,
              color: Colors.white,
              backgroundColor: Colors.white24,
              strokeWidth: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  final String summary;
  const _AiSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.soil,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('Muhtasari wa Claude AI',
                  style: GoogleFonts.dmSans(
                      color: AppColors.sprout,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(summary,
              style: GoogleFonts.dmSans(
                  color: AppColors.cream,
                  fontSize: 13,
                  height: 1.6)),
        ],
      ),
    );
  }
}

class _AnalysisSection extends StatelessWidget {
  final String icon;
  final String title;
  final Color color;
  final Widget child;

  const _AnalysisSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ShambaCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _WaterStressCard extends StatelessWidget {
  final WaterStressAnalysis analysis;
  const _WaterStressCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final ndwi = analysis.ndwiReading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show NDWI badge if we have real data
        if (ndwi != null) ...[
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _ndwiColor(ndwi.healthStatus)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _ndwiColor(ndwi.healthStatus)
                          .withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      'NDWI: ${ndwi.average.toStringAsFixed(3)}',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _ndwiColor(ndwi.healthStatus)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ndwi.healthStatus.labelSw,
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: _ndwiColor(ndwi.healthStatus)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Water content bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Maudhui ya Maji Mwilini:',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.mid)),
                  Text(
                      '${ndwi.waterContentPercent.toStringAsFixed(0)}%',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _ndwiColor(ndwi.healthStatus))),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: ndwi.waterContentPercent / 100,
                backgroundColor: const Color(0xFFE3F2FD),
                color: _ndwiColor(ndwi.healthStatus),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Stress index bar (always shown)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Kiwango cha Mkazo:',
                style: GoogleFonts.dmSans(color: AppColors.mid, fontSize: 12)),
            Text(analysis.level,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: analysis.stressIndex,
          backgroundColor: const Color(0xFFE3F2FD),
          color: analysis.stressIndex > 0.5
              ? Colors.red
              : analysis.stressIndex > 0.25
                  ? AppColors.sun
                  : AppColors.leaf,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 10),
        Text(analysis.recommendation,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.ink)),

        if (ndwi == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '(Hii ni makadirio — NDWI haikupatikana)',
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.mid,
                  fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}

class _SoilCard extends StatelessWidget {
  final SoilAnalysis analysis;
  const _SoilCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row('Hali ya Udongo', analysis.status),
        _Row('Unyevu', '${analysis.moistureLevel.toStringAsFixed(0)}%'),
        _Row('Aina ya Udongo', analysis.texture),
        const SizedBox(height: 8),
        Text('Virutubisho:',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.mid)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: analysis.nutrientLevels.entries.map((e) {
            final isGood = e.value == 'Kutosha';
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isGood ? AppColors.leaf : AppColors.sun)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isGood ? AppColors.leaf : AppColors.sun)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Text('${e.key}: ${e.value}',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color:
                          isGood ? AppColors.leaf : AppColors.harvest,
                      fontWeight: FontWeight.bold)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _NutrientsCard extends StatelessWidget {
  final NutrientAnalysis analysis;
  const _NutrientsCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(analysis.overallStatus,
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.leaf)),
        if (analysis.deficiencies.isEmpty) ...[
          const SizedBox(height: 6),
          Text('✅ Virutubisho vya kutosha',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.ink)),
        ],
        for (final d in analysis.deficiencies) ...[
          const SizedBox(height: 10),
          Text(d.nutrient,
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.harvest)),
          Text('Ukali: ${d.severity}',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.mid)),
          Text('Dalili: ${d.symptoms}',
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.ink)),
          Text('Matibabu: ${d.treatment}',
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.leaf,
                  fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

class _PestCard extends StatelessWidget {
  final PestDiseaseAnalysis analysis;
  const _PestCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row('Kiwango cha Hatari', analysis.riskLevel),
        if (analysis.threats.isEmpty) ...[
          const SizedBox(height: 6),
          Text('✅ Hakuna vitisho vya wadudu au magonjwa.',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.ink)),
        ],
        for (final t in analysis.threats) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Text(t.type == 'Wadudu' ? '🐛' : '🦠',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.name,
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.red.shade700)),
              ),
            ],
          ),
          Text(t.description,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.mid)),
          const SizedBox(height: 4),
          for (final tr in t.treatments)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('→ ', style: TextStyle(color: AppColors.leaf)),
                  Expanded(
                    child: Text(tr,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.ink)),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final List<String> recs;
  const _RecommendationsCard({required this.recs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recs
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(r,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.ink,
                        height: 1.4)),
              ))
          .toList(),
    );
  }
}

// ── NDWI widgets ──────────────────────────────────────────────────────────────

class _NdwiLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShambaCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kiwango cha Maji (NDWI)',
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.soil)),
          const SizedBox(height: 8),
          Row(
            children: NdwiHealthStatus.values.map((s) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: _ndwiColor(s),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(s.labelSw,
                        style: GoogleFonts.dmSans(
                            fontSize: 8, color: AppColors.mid),
                        textAlign: TextAlign.center,
                        maxLines: 2),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _NdwiStatsCard extends StatelessWidget {
  final NdwiReading reading;
  const _NdwiStatsCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    final color = _ndwiColor(reading.healthStatus);
    return ShambaCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                reading.average.toStringAsFixed(3),
                style: GoogleFonts.playfairDisplay(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NDWI ya Leo',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.mid)),
                Text(reading.healthStatus.labelSw,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(
                    'Maji: ${reading.waterContentPercent.toStringAsFixed(0)}%  '
                    'Min: ${reading.min.toStringAsFixed(3)}  '
                    'Max: ${reading.max.toStringAsFixed(3)}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.mid)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NdwiChart extends StatelessWidget {
  final List<NdwiReading> readings;
  const _NdwiChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final spots = readings.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.average);
    }).toList();

    return ShambaCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(
            minY: -0.5,
            maxY: 0.5,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 0.1,
              getDrawingHorizontalLine: (v) {
                // Highlight the 0 line (stress threshold)
                if (v == 0.0) {
                  return const FlLine(
                      color: Color(0xFF0D47A1),
                      strokeWidth: 1.5,
                      dashArray: [4, 4]);
                }
                return FlLine(
                    color: AppColors.mid.withValues(alpha: 0.12),
                    strokeWidth: 1);
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 0.2,
                  reservedSize: 36,
                  getTitlesWidget: (v, _) => Text(
                    v.toStringAsFixed(1),
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.mid),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (readings.length / 4).ceilToDouble(),
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= readings.length) {
                      return const SizedBox.shrink();
                    }
                    final d = readings[idx].date;
                    return Text('${d.day}/${d.month}',
                        style: GoogleFonts.dmSans(
                            fontSize: 10, color: AppColors.mid));
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: const Color(0xFF1976D2),
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, idx) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: _ndwiColor(NdwiReading(
                      date: DateTime.now(),
                      average: spot.y,
                      min: 0,
                      max: 0,
                      cloudCover: 0,
                    ).healthStatus),
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF1976D2).withValues(alpha: 0.08),
                ),
              ),
              // Zero reference line
              LineChartBarData(
                spots: [
                  FlSpot(0, 0),
                  FlSpot(readings.length.toDouble() - 1, 0),
                ],
                color: const Color(0xFF0D47A1).withValues(alpha: 0.4),
                barWidth: 1,
                dotData: const FlDotData(show: false),
                dashArray: [4, 4],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small key-value row
class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.mid)),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
        ],
      ),
    );
  }
}

// Setup screen helper widgets
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  const _Field(this.ctrl, this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.mid),
        filled: true,
        fillColor: AppColors.mist,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.leaf, width: 1.5),
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}, '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
