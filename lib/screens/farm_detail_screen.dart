import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/farm_model.dart';
import '../providers/auth_provider.dart';
import '../services/claude_service.dart';
import '../services/weather_service.dart';
import '../theme/app_colors.dart';
import 'add_farm_screen.dart';
import 'scan_screen.dart';
import 'soil_screen.dart';
import 'irrigation_screen.dart';
import 'iot_dashboard_screen.dart';

class FarmDetailScreen extends StatefulWidget {
  final FarmModel farm;
  const FarmDetailScreen({super.key, required this.farm});

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Ratiba AI state
  String? _scheduleText;
  bool _scheduleLoading = false;

  // Weather state
  List<Map<String, dynamic>> _forecast = [];
  bool _weatherLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadWeather();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    if (widget.farm.gpsLat == null || widget.farm.gpsLng == null) return;
    setState(() => _weatherLoading = true);
    try {
      final data = await WeatherService.getWeeklyForecast(
        lat: widget.farm.gpsLat!,
        lng: widget.farm.gpsLng!,
      );
      if (mounted) setState(() => _forecast = data);
    } catch (_) {}
    if (mounted) setState(() => _weatherLoading = false);
  }

  Future<void> _generateSchedule() async {
    setState(() { _scheduleLoading = true; _scheduleText = null; });
    final crops = widget.farm.crops.isEmpty
        ? 'mazao mchanganyiko'
        : widget.farm.crops.join(', ');
    final region = widget.farm.region;
    final acres  = widget.farm.acresDisplay;
    final soil   = widget.farm.soilType ?? 'haijulikani';
    final now    = DateTime.now();
    final months = ['Januari','Februari','Machi','Aprili','Mei','Juni',
                    'Julai','Agosti','Septemba','Oktoba','Novemba','Desemba'];
    final month  = months[now.month - 1];

    final prompt =
        'Mkulima kutoka $region ana shamba la $acres analima: $crops. '
        'Aina ya udongo: $soil. Mwezi wa sasa: $month.\n\n'
        'Toa ratiba kamili ya kilimo kwa mwaka huu ukijumuisha:\n'
        '1. 🌿 MAANDALIZI YA SHAMBA — wiki/mwezi gani, na jinsi ya kufanya\n'
        '2. 🌱 KUPANDA — wakati bora wa kupanda kwa mazao hayo katika mkoa huu\n'
        '3. 🌾 KUPALILIA — mara ngapi na wakati gani\n'
        '4. 💊 KUWEKA DAWA/MBOLEA — aina gani na wakati gani\n'
        '5. 💧 UMWAGILIAJI — kama mvua haitoshi, ratiba ya umwagiliaji\n'
        '6. 🌾 KUVUNA — wakati wa kuvuna na jinsi ya kuhifadhi\n'
        '7. 📅 KALENDA — orodha ya miezi na kazi za kila mwezi\n\n'
        'Jibu kwa Kiswahili rahisi. Fanya iwe maalum kwa mazao na mkoa huo.';

    final result = await ClaudeService.askFarmingQuestion(
      question: prompt,
      cropContext: crops,
      regionContext: region,
    );
    if (mounted) setState(() { _scheduleText = result; _scheduleLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final farm = widget.farm;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.soil,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Hariri',
                onPressed: () {
                  final uid = context.read<AuthProvider>().currentUser?.id ?? '';
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AddFarmScreen(farmerId: uid, editFarm: farm)));
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _FarmHeader(farm: farm),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AppColors.harvest,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Muhtasari'),
                Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: 'Ratiba'),
                Tab(icon: Icon(Icons.health_and_safety_outlined, size: 18), text: 'Afya'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _OverviewTab(farm: farm, forecast: _forecast, weatherLoading: _weatherLoading),
            _ScheduleTab(
              farm: farm,
              scheduleText: _scheduleText,
              loading: _scheduleLoading,
              onGenerate: _generateSchedule,
            ),
            _HealthTab(farm: farm),
          ],
        ),
      ),
    );
  }
}

// ── Farm header (collapsible) ─────────────────────────────────────────────────

class _FarmHeader extends StatelessWidget {
  final FarmModel farm;
  const _FarmHeader({required this.farm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A1E), Color(0xFF2E6B35)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 56),
          child: Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Center(child: Text('🌾', style: TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(farm.name,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white60, size: 13),
                        const SizedBox(width: 3),
                        Text(farm.region,
                            style: GoogleFonts.dmSans(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 12),
                        const Icon(Icons.straighten, color: Colors.white60, size: 13),
                        const SizedBox(width: 3),
                        Text(farm.acresDisplay,
                            style: GoogleFonts.dmSans(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (farm.crops.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        children: farm.crops.take(3).map((c) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.harvest.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.harvest.withValues(alpha: 0.5)),
                          ),
                          child: Text(c,
                              style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        )).toList(),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Mazao hayajawekwa',
                            style: GoogleFonts.dmSans(
                                color: Colors.white60, fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — MUHTASARI (Overview)
// ══════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final FarmModel farm;
  final List<Map<String, dynamic>> forecast;
  final bool weatherLoading;

  const _OverviewTab({
    required this.farm,
    required this.forecast,
    required this.weatherLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Quick stats ──────────────────────────────────────────────────────
        Row(
          children: [
            _StatCard(emoji: '📐', label: 'Ukubwa', value: farm.acresDisplay,
                color: AppColors.leaf),
            const SizedBox(width: 10),
            _StatCard(emoji: '🌱', label: 'Mazao',
                value: farm.crops.isEmpty ? '—' : '${farm.crops.length} aina',
                color: AppColors.harvest),
            const SizedBox(width: 10),
            _StatCard(emoji: '📍', label: 'GPS',
                value: farm.hasLocation ? 'Imewekwa' : 'Haijawekwa',
                color: farm.hasLocation ? AppColors.leaf : Colors.orange),
          ],
        ),

        const SizedBox(height: 16),

        // ── Vitendo vya haraka ──────────────────────────────────────────────
        _SectionTitle('Vitendo vya Haraka'),
        const SizedBox(height: 10),
        Row(
          children: [
            _QuickAction(emoji: '🔬', label: 'Chunguza\nUgonjwa',
                color: const Color(0xFF1A5C2E),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ScanScreen()))),
            const SizedBox(width: 10),
            _QuickAction(emoji: '🧪', label: 'Data ya\nUdongo',
                color: const Color(0xFF7A5C3A),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => SoilScreen(
                      farmLat: farm.gpsLat,
                      farmLng: farm.gpsLng,
                      farmName: farm.name,
                    )))),
            const SizedBox(width: 10),
            _QuickAction(emoji: '💧', label: 'Mpango\nUmwagiliaji',
                color: const Color(0xFF0277BD),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const IrrigationScreen()))),
          ],
        ),

        const SizedBox(height: 16),

        // ── GPS location ────────────────────────────────────────────────────
        if (farm.hasLocation) ...[
          _SectionTitle('Eneo la Shamba'),
          const SizedBox(height: 10),
          _InfoCard(children: [
            _InfoRow(Icons.gps_fixed, 'Latitudo',
                farm.gpsLat!.toStringAsFixed(6)),
            const Divider(height: 16),
            _InfoRow(Icons.gps_fixed, 'Longitudo',
                farm.gpsLng!.toStringAsFixed(6)),
          ]),
          const SizedBox(height: 16),
        ],

        // ── Hali ya hewa (7-day forecast) ───────────────────────────────────
        _SectionTitle('Hali ya Hewa — Wiki Hii'),
        const SizedBox(height: 10),
        _WeatherCard(forecast: forecast, loading: weatherLoading),

        const SizedBox(height: 16),

        // ── Mazao ───────────────────────────────────────────────────────────
        if (farm.crops.isNotEmpty) ...[
          _SectionTitle('Mazao ya Shamba'),
          const SizedBox(height: 10),
          _InfoCard(children: [
            Wrap(
              spacing: 8, runSpacing: 8,
              children: farm.crops.map((c) => Chip(
                label: Text(c, style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.leaf,
                    fontWeight: FontWeight.w600)),
                backgroundColor: AppColors.leaf.withValues(alpha: 0.1),
                side: BorderSide(color: AppColors.leaf.withValues(alpha: 0.3)),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ]),
          const SizedBox(height: 16),
        ],

        // ── Notes ───────────────────────────────────────────────────────────
        if (farm.notes != null && farm.notes!.isNotEmpty) ...[
          _SectionTitle('Maelezo'),
          const SizedBox(height: 10),
          _InfoCard(children: [
            Text(farm.notes!,
                style: GoogleFonts.dmSans(fontSize: 13, height: 1.5)),
          ]),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — RATIBA (AI Farming Schedule)
// ══════════════════════════════════════════════════════════════════════════════

class _ScheduleTab extends StatelessWidget {
  final FarmModel farm;
  final String? scheduleText;
  final bool loading;
  final VoidCallback onGenerate;

  const _ScheduleTab({
    required this.farm,
    required this.scheduleText,
    required this.loading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A1E), Color(0xFF2E6B35)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ratiba ya Kilimo',
                        style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(
                      farm.crops.isEmpty
                          ? 'Bonyeza upate ratiba ya kilimo'
                          : 'Kwa: ${farm.crops.take(2).join(", ")}${farm.crops.length > 2 ? "..." : ""}',
                      style: GoogleFonts.dmSans(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Generate button or results
        if (!loading && scheduleText == null) ...[
          ElevatedButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Tengeneza Ratiba kwa AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.leaf,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Claude AI ataunda ratiba maalum kwa mazao yako na mkoa wako — '
              'kuanzia maandalizi ya shamba hadi kuvuna.',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.leaf, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ] else if (loading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator(color: AppColors.leaf)),
          const SizedBox(height: 16),
          Center(
            child: Text('AI inaandaa ratiba yako...',
                style: GoogleFonts.dmSans(color: AppColors.mid, fontSize: 13)),
          ),
        ] else if (scheduleText != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text('Ratiba ya Claude AI',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            color: AppColors.soil,
                            fontSize: 14)),
                  ],
                ),
                const Divider(height: 20),
                Text(scheduleText!,
                    style: GoogleFonts.dmSans(
                        fontSize: 13.5, height: 1.7, color: AppColors.ink)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Tengeneza Upya'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.leaf,
                    side: const BorderSide(color: AppColors.leaf),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — AFYA YA SHAMBA (Health)
// ══════════════════════════════════════════════════════════════════════════════

class _HealthTab extends StatelessWidget {
  final FarmModel farm;
  const _HealthTab({required this.farm});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Disease camera card
        _HealthCard(
          emoji: '🔬',
          title: 'Chunguza Ugonjwa wa Zao',
          subtitle: 'Piga picha ya jani — AI itachunguza ugonjwa, wadudu, au magugu',
          buttonLabel: 'Fungua Kamera ya Uchunguzi',
          buttonColor: const Color(0xFF1A5C2E),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ScanScreen())),
        ),

        const SizedBox(height: 14),

        // Soil data card
        _HealthCard(
          emoji: '🧪',
          title: 'Hali ya Udongo wa Shamba',
          subtitle: farm.hasLocation
              ? 'Angalia pH, Nitrojeni, muundo wa udongo na upate ushauri wa AI'
              : 'Weka GPS kwanza ili kupata data sahihi ya udongo',
          buttonLabel: 'Pata Data ya Udongo',
          buttonColor: const Color(0xFF7A5C3A),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => SoilScreen(
                farmLat: farm.gpsLat,
                farmLng: farm.gpsLng,
                farmName: farm.name,
              ))),
        ),

        const SizedBox(height: 14),

        // Irrigation card
        _HealthCard(
          emoji: '💧',
          title: 'Mpango wa Umwagiliaji',
          subtitle: 'Pata ratiba kamili ya umwagiliaji kulingana na zao na hali ya hewa',
          buttonLabel: 'Tengeneza Mpango wa Umwagiliaji',
          buttonColor: const Color(0xFF0277BD),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const IrrigationScreen())),
        ),

        const SizedBox(height: 14),

        // IoT Dashboard card
        _HealthCard(
          emoji: '📡',
          title: 'Sensa za IoT — Uangalizi wa Wakati Halisi',
          subtitle: 'Angalia data za unyevu, joto, NPK, pH kutoka kwa sensa zilizounganishwa shambani (kipengele cha hiari)',
          buttonLabel: 'Fungua IoT Dashboard',
          buttonColor: const Color(0xFF1A237E),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => IoTDashboardScreen(farm: farm))),
        ),

        const SizedBox(height: 14),

        // Tips card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.leaf.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('Vidokezo vya Afya ya Shamba',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          color: AppColors.soil,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              ...[
                '🌿 Angalia mimea kila wiki 2 kwa dalili za ugonjwa',
                '🌧️ Fuatilia mvua na umwagilia tu zinahitajika',
                '🐛 Chunguza wadudu mapema asubuhi au jioni',
                '🧪 Pima udongo kila msimu wa kilimo',
                '📷 Piga picha ukiona dalili yoyote ya ugonjwa',
              ].map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(tip,
                    style: GoogleFonts.dmSans(
                        fontSize: 13, height: 1.4, color: AppColors.ink)),
              )),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Helper Widgets
// ══════════════════════════════════════════════════════════════════════════════

class _WeatherCard extends StatelessWidget {
  final List<Map<String, dynamic>> forecast;
  final bool loading;
  const _WeatherCard({required this.forecast, required this.loading});

  String _weatherEmoji(double? rain) {
    if (rain == null) return '☁️';
    if (rain > 5) return '🌧️';
    if (rain > 1) return '🌦️';
    return '☀️';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator(
              color: AppColors.leaf, strokeWidth: 2)),
        ),
      );
    }
    if (forecast.isEmpty) {
      return _InfoCard(children: [
        Row(children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.mid, size: 16),
          const SizedBox(width: 8),
          Text('Weka GPS kupata hali ya hewa ya shamba lako',
              style: GoogleFonts.dmSans(color: AppColors.mid, fontSize: 13)),
        ]),
      ]);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: forecast.take(7).map((day) {
              final date = day['date'] as String? ?? '';
              final maxTemp = day['temp_max'] as double?;
              final rain = day['precipitation'] as double?;
              final parts = date.split('-');
              final label = parts.length >= 3
                  ? '${parts[2]}/${parts[1]}'
                  : date;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Text(label,
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.mid)),
                    const SizedBox(height: 4),
                    Text(_weatherEmoji(rain),
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(maxTemp != null
                        ? '${maxTemp.toStringAsFixed(0)}°'
                        : '--',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    if (rain != null && rain > 0)
                      Text('${rain.toStringAsFixed(0)}mm',
                          style: GoogleFonts.dmSans(
                              fontSize: 10, color: Colors.blue.shade400)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.emoji, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(value,
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: AppColors.mid),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.emoji, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                        height: 1.3)),
              ],
            ),
          ),
        ),
      );
}

class _HealthCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onTap;
  const _HealthCard({required this.emoji, required this.title,
      required this.subtitle, required this.buttonLabel,
      required this.buttonColor, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.soil)),
                        const SizedBox(height: 3),
                        Text(subtitle,
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.mid,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(buttonLabel,
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.dmSans(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.soil));
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.mid),
          const SizedBox(width: 6),
          Text('$label: ',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.mid)),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
        ],
      );
}
