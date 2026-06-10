import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

// ── Premium IoT Sensor Screen ─────────────────────────────────────────────────

class PremiumSensorScreen extends StatefulWidget {
  const PremiumSensorScreen({super.key});

  @override
  State<PremiumSensorScreen> createState() => _PremiumSensorScreenState();
}

class _PremiumSensorScreenState extends State<PremiumSensorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _isPremium = false; // TODO: check from farmer profile
  List<Map<String, dynamic>> _stations = [];
  Map<String, dynamic>? _selectedStation;
  Map<String, dynamic>? _latestReading;
  bool _loading = false;
  Timer? _pollTimer;

  static SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _checkPremium();
    _loadStations();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_selectedStation != null) _loadLatestReading();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPremium() async {
    // Check subscription status from Supabase
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id;
      if (userId == null) return;
      final rows = await _db
          .from('sensor_stations')
          .select()
          .eq('farmer_id', userId)
          .eq('is_active', true)
          .limit(1);
      setState(() => _isPremium = (rows as List).isNotEmpty);
    } catch (_) {}
  }

  Future<void> _loadStations() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id;
      final rows = await _db
          .from('sensor_stations')
          .select()
          .eq('farmer_id', userId ?? '')
          .eq('is_active', true);
      setState(() {
        _stations = (rows as List).map((r) => Map<String, dynamic>.from(r)).toList();
        if (_stations.isNotEmpty) {
          _selectedStation = _stations.first;
          _loadLatestReading();
        }
      });
    } catch (_) {
      // Demo data for presentation
      setState(() {
        _stations = [
          {'station_id': 'DEMO-001', 'station_name': 'Shamba A - Kaskazini',
           'plot_name': 'Eneo A', 'is_active': true},
        ];
        _selectedStation = _stations.first;
        _latestReading = _demoReading();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLatestReading() async {
    if (_selectedStation == null) return;
    try {
      final rows = await _db
          .from('sensor_readings')
          .select()
          .eq('station_id', _selectedStation!['station_id'])
          .order('timestamp', ascending: false)
          .limit(1);
      if ((rows as List).isNotEmpty && mounted) {
        setState(() => _latestReading = Map<String, dynamic>.from(rows.first));
      }
    } catch (_) {
      if (mounted && _latestReading == null) {
        setState(() => _latestReading = _demoReading());
      }
    }
  }

  Map<String, dynamic> _demoReading() => {
    'soil_moisture_pct': 42.0,
    'soil_temp_c': 24.0,
    'air_temp_c': 28.0,
    'humidity_pct': 68.0,
    'nitrogen_mg_kg': 45.0,
    'phosphorus_mg_kg': 22.0,
    'potassium_mg_kg': 180.0,
    'soil_ph': 6.4,
    'battery_pct': 87.0,
    'timestamp': DateTime.now().toIso8601String(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('IoT Sensor Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFFFFB300),
          tabs: const [
            Tab(text: 'Sensor Data'),
            Tab(text: 'Agronomist'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _isPremium || _stations.isNotEmpty ? _buildSensorTab() : _buildUpsell(),
          _buildAgronomistTab(),
        ],
      ),
    );
  }

  Widget _buildUpsell() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF57F17), Color(0xFFFFB300)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🔒', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('PREMIUM inahitajika',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Pata data ya sensor ya shamba lako kwa wakati halisi',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _BenefitRow(icon: '📡', text: 'Vituo 5 vya sensor kwenye shamba'),
          _BenefitRow(icon: '👨‍🔬', text: 'Agronomist aliyeidhinishwa — mwako peke yako'),
          _BenefitRow(icon: '📊', text: 'Ripoti ya shamba kila wiki (PDF)'),
          _BenefitRow(icon: '⚡', text: 'Arifa za haraka unapoona tatizo'),
          _BenefitRow(icon: '🔬', text: 'Uchunguzi wa AI usio na kikomo'),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('TZS 35,000 / mwezi',
                    style: GoogleFonts.poppins(
                        fontSize: 24, fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                Text('Ghairi wakati wowote',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wasiliana: +255 700 000 000 kwa Premium')),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.black,
            ),
            child: Text('Jisajili kwa Premium',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_latestReading == null) return const Center(child: Text('Hakuna data'));

    final r = _latestReading!;
    final sensors = [
      _SensorData(icon: '💧', label: 'Unyevu wa Udongo',
          value: '${(r['soil_moisture_pct'] ?? 0).toStringAsFixed(1)}%',
          current: (r['soil_moisture_pct'] as num?)?.toDouble() ?? 0,
          min: 0, max: 100, optMin: 40, optMax: 70),
      _SensorData(icon: '🌡️', label: 'Joto la Udongo',
          value: '${(r['soil_temp_c'] ?? 0).toStringAsFixed(1)}°C',
          current: (r['soil_temp_c'] as num?)?.toDouble() ?? 0,
          min: 10, max: 45, optMin: 18, optMax: 30),
      _SensorData(icon: '☁️', label: 'Joto la Hewa',
          value: '${(r['air_temp_c'] ?? 0).toStringAsFixed(1)}°C',
          current: (r['air_temp_c'] as num?)?.toDouble() ?? 0,
          min: 10, max: 45, optMin: 20, optMax: 32),
      _SensorData(icon: '💦', label: 'Unyevu wa Hewa',
          value: '${(r['humidity_pct'] ?? 0).toStringAsFixed(0)}%',
          current: (r['humidity_pct'] as num?)?.toDouble() ?? 0,
          min: 0, max: 100, optMin: 50, optMax: 80),
      _SensorData(icon: '🌿', label: 'Nitrojeni (N)',
          value: '${(r['nitrogen_mg_kg'] ?? 0).toStringAsFixed(1)} mg/kg',
          current: (r['nitrogen_mg_kg'] as num?)?.toDouble() ?? 0,
          min: 0, max: 200, optMin: 40, optMax: 150),
      _SensorData(icon: '🔵', label: 'Fosforasi (P)',
          value: '${(r['phosphorus_mg_kg'] ?? 0).toStringAsFixed(1)} mg/kg',
          current: (r['phosphorus_mg_kg'] as num?)?.toDouble() ?? 0,
          min: 0, max: 100, optMin: 15, optMax: 60),
      _SensorData(icon: '🟡', label: 'Potasiamu (K)',
          value: '${(r['potassium_mg_kg'] ?? 0).toStringAsFixed(0)} mg/kg',
          current: (r['potassium_mg_kg'] as num?)?.toDouble() ?? 0,
          min: 0, max: 400, optMin: 80, optMax: 250),
      _SensorData(icon: '🧪', label: 'pH ya Udongo',
          value: (r['soil_ph'] ?? 0).toStringAsFixed(1),
          current: (r['soil_ph'] as num?)?.toDouble() ?? 0,
          min: 4, max: 9, optMin: 5.5, optMax: 7.0),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF57F17), Color(0xFFFFB300)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PREMIUM',
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontWeight: FontWeight.w800,
                          fontSize: 14, letterSpacing: 1)),
                  Text('Shamba lako linafuatiliwa saa 24/7',
                      style: GoogleFonts.poppins(
                          color: Colors.black54, fontSize: 11)),
                ],
              )),
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Online', style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 16),

          // Station selector
          if (_stations.length > 1) ...[
            Text('Kituo cha Sensor',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _stations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = _stations[i];
                  final sel = s['station_id'] == _selectedStation?['station_id'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedStation = s);
                      _loadLatestReading();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.primary : Colors.grey.shade300),
                      ),
                      child: Text(s['station_name'] ?? s['station_id'],
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : Colors.black87)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text('Kipimo cha Sasa Hivi',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: sensors.length,
            itemBuilder: (_, i) => _SensorCard(data: sensors[i]),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAgronomistTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Agronomist profile
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadow.sm,
            ),
            child: Column(
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primarySoft,
                    child: Text('DA', style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dkt. Amani Mwalimu',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      Text('BSc Agronomy, SUA',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      Text('Mazao ya Nafaka na Mbogamboga',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primary)),
                    ],
                  )),
                  Column(children: [
                    Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32), shape: BoxShape.circle),
                    ),
                    const SizedBox(height: 4),
                    Text('Online', style: GoogleFonts.poppins(fontSize: 10)),
                  ]),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Majibu ndani ya masaa 2',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Options
          _AgronomistOption(
            icon: Icons.chat_outlined,
            title: 'Wasiliana na Agronomist',
            subtitle: 'Tuma ujumbe, picha, data ya sensor',
            color: AppColors.primary,
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AgronomistChatScreen())),
          ),
          const SizedBox(height: 10),
          _AgronomistOption(
            icon: Icons.event_outlined,
            title: 'Omba Ziara ya Shamba',
            subtitle: 'Panga mkutano wa ana kwa ana',
            color: const Color(0xFF1565C0),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Piga simu: +255 700 000 000'))),
          ),
          const SizedBox(height: 10),
          _AgronomistOption(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Ripoti ya Wiki',
            subtitle: 'PDF inazalishwa kila Jumapili',
            color: const Color(0xFFE65100),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ripoti inaandaliwa...'))),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SensorData {
  final String icon;
  final String label;
  final String value;
  final double current;
  final double min;
  final double max;
  final double optMin;
  final double optMax;

  const _SensorData({
    required this.icon, required this.label, required this.value,
    required this.current, required this.min, required this.max,
    required this.optMin, required this.optMax,
  });

  Color get color {
    if (current >= optMin && current <= optMax) return const Color(0xFF2E7D32);
    if (current < optMin * 0.7 || current > optMax * 1.3) return const Color(0xFFB71C1C);
    return const Color(0xFFE65100);
  }

  double get progress => ((current - min) / (max - min)).clamp(0.0, 1.0);
  String get emoji {
    if (current >= optMin && current <= optMax) return '🟢';
    if (current < optMin * 0.7 || current > optMax * 1.3) return '🔴';
    return '🟡';
  }
}

class _SensorCard extends StatelessWidget {
  final _SensorData data;
  const _SensorCard({required this.data});

  @override
  Widget build(BuildContext context) {
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
          Row(children: [
            Text(data.icon, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Text(data.emoji, style: const TextStyle(fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          Text(data.label,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(data.value,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: data.color)),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.progress,
              minHeight: 4,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(data.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text(text,
            style: GoogleFonts.poppins(fontSize: 13))),
      ]),
    );
  }
}

class _AgronomistOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _AgronomistOption({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadow.sm,
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              Text(subtitle, style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey)),
            ],
          )),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
        ]),
      ),
    );
  }
}

// ── Agronomist Chat Screen ────────────────────────────────────────────────────

class AgronomistChatScreen extends StatefulWidget {
  const AgronomistChatScreen({super.key});

  @override
  State<AgronomistChatScreen> createState() => _AgronomistChatScreenState();
}

class _AgronomistChatScreenState extends State<AgronomistChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages = [
      {
        'sender': 'agronomist',
        'text': 'Habari! Mimi ni Dkt. Amani. Niko hapa kukusaidia na changamoto za shamba lako. Una swali gani leo?',
        'time': DateTime.now().toIso8601String(),
      }
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({
        'sender': 'farmer',
        'text': text,
        'time': DateTime.now().toIso8601String(),
      });
      _ctrl.clear();
    });
    // Simulate agronomist response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'agronomist',
            'text': 'Asante kwa swali lako. Ninaangalia data ya sensor ya shamba lako. Nitakujibu hivi karibuni na ushauri wa kina.',
            'time': DateTime.now().toIso8601String(),
          });
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dkt. Amani Mwalimu',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            Text('Agronomist · Online 🟢',
                style: GoogleFonts.poppins(fontSize: 11)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Sensor context banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primarySoft,
            child: Text(
              '📡 Data ya Hivi Karibuni: Unyevu: 42% 🔴 | Joto: 28°C ✅ | pH: 6.2 ✅',
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primary),
            ),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isFarmer = m['sender'] == 'farmer';
                return Align(
                  alignment: isFarmer ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFarmer ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadow.xs,
                    ),
                    child: Text(m['text'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isFarmer ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'Andika ujumbe wako...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
