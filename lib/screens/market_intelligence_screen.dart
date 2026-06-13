import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/claude_service.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MarketIntelligenceScreen extends StatefulWidget {
  const MarketIntelligenceScreen({super.key});

  @override
  State<MarketIntelligenceScreen> createState() =>
      _MarketIntelligenceScreenState();
}

class _MarketIntelligenceScreenState extends State<MarketIntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _selectedCrop;
  String? _aiAdvice;
  bool _aiLoading = false;
  bool _alertSaving = false;
  final _alertPriceCtrl = TextEditingController();
  String _alertType = 'above';
  String _selectedMarket = 'Kariakoo';
  List<Map<String, dynamic>> _alerts = [];

  static const _markets = ['Kariakoo', 'Tandale', 'Arusha', 'Mbeya', 'Dodoma'];
  static const _crops = ['Mahindi', 'Nyanya', 'Maharagwe', 'Pilipili hoho', 'Ndizi', 'Mchele', 'Muhogo'];

  static SupabaseClient get _db => Supabase.instance.client;

  // 12-week mock price history for demo
  static const _priceHistory = <String, List<int>>{
    'Mahindi': [400, 420, 390, 430, 450, 460, 440, 470, 480, 490, 480, 500],
    'Nyanya': [800, 850, 950, 1000, 980, 1050, 1100, 1080, 1150, 1200, 1180, 1220],
    'Maharagwe': [2200, 2180, 2220, 2150, 2100, 2200, 2250, 2200, 2180, 2200, 2210, 2230],
    'Pilipili hoho': [1800, 1900, 1850, 1950, 2000, 1980, 2050, 2100, 2080, 2150, 2200, 2180],
    'Ndizi': [700, 720, 680, 750, 780, 760, 800, 820, 810, 840, 860, 850],
    'Mchele': [2500, 2480, 2520, 2550, 2480, 2500, 2530, 2560, 2540, 2580, 2600, 2590],
    'Muhogo': [350, 360, 340, 370, 380, 375, 390, 400, 395, 410, 420, 415],
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _selectedCrop = 'Mahindi';
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _alertPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId == null) return;
      final rows = await _db
          .from('price_alerts')
          .select()
          .eq('farmer_id', userId)
          .eq('is_active', true);
      if (mounted) setState(() => _alerts = (rows as List)
          .map((r) => Map<String, dynamic>.from(r)).toList());
    } catch (_) {}
  }

  Future<void> _getAiAdvice() async {
    if (_selectedCrop == null) return;
    setState(() { _aiLoading = true; _aiAdvice = null; });
    try {
      final history = _priceHistory[_selectedCrop] ?? [];
      final historyStr = history.asMap().entries
          .map((e) => 'Wiki ${e.key + 1}: ${e.value} TZS/kg')
          .join(', ');
      final current = history.isNotEmpty ? history.last : 0;
      final avg = history.isEmpty ? 0 : history.reduce((a, b) => a + b) ~/ history.length;

      final prompt = '''Changanua bei ya $selectedCropName katika masoko ya Tanzania.
Historia ya miezi 3 (wiki kwa wiki):
$historyStr

Bei ya sasa: $current TZS/kg
Bei ya wastani: $avg TZS/kg
Soko: $_selectedMarket

Jibu kwa Kiswahili na toa:
1. Je, mkulima auze SASA au asubiri? Na kwa nini?
2. Bei inatarajiwa kwenda wapi wiki 2-4 zijazo?
3. Mwezi bora wa kuuza zao hili (mwezi wa kawaida)
4. Ushauri wa kuhifadhi mazao kama bei ni mbaya''';

      final resp = await ClaudeService.askFarmingQuestion(
          question: prompt,
          cropContext: _selectedCrop ?? 'Mazao ya Tanzania',
          regionContext: 'Tanzania');
      if (mounted) setState(() => _aiAdvice = resp);
    } catch (e) {
      if (mounted) setState(() => _aiAdvice = 'Hitilafu: $e');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  String get selectedCropName => _selectedCrop ?? 'Mazao';

  Future<void> _saveAlert() async {
    final price = int.tryParse(_alertPriceCtrl.text.trim());
    if (price == null || _selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza bei sahihi')));
      return;
    }
    setState(() => _alertSaving = true);
    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      await _db.from('price_alerts').insert({
        'farmer_id': userId,
        'crop_name': _selectedCrop,
        'market_name': _selectedMarket,
        'target_price_tzs': price,
        'alert_type': _alertType,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      _alertPriceCtrl.clear();
      await _loadAlerts();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Arifa imewekwa: ${_selectedCrop} @ $price TZS/kg')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e')));
    } finally {
      if (mounted) setState(() => _alertSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Akili za Soko'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFFFFB300),
          tabs: const [
            Tab(text: 'Bei & Mwelekeo'),
            Tab(text: 'Ushauri wa AI'),
            Tab(text: 'Arifa za Bei'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildPricesTab(),
          _buildAiTab(),
          _buildAlertsTab(),
        ],
      ),
    );
  }

  Widget _buildPricesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Best deal banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📈 Bei Nzuri Zaidi Leo',
                    style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 11)),
                const SizedBox(height: 4),
                Text('Mahindi — Kariakoo — 1,050 TZS/kg',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text('+5% juu ya wastani wa wiki hii',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF95D5B2), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Market selector
          Text('Soko', style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _markets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = _markets[i] == _selectedMarket;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMarket = _markets[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.primary : Colors.grey.shade300),
                    ),
                    child: Text(_markets[i],
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Price list with trends
          Text('Bei za Mazao',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          ..._crops.map((crop) {
            final history = _priceHistory[crop] ?? [0];
            final current = history.last;
            final prev = history.length > 1 ? history[history.length - 2] : current;
            final change = current - prev;
            final changeStr = change >= 0 ? '+$change' : '$change';
            final pct = prev > 0 ? (change / prev * 100) : 0.0;
            final isUp = change >= 0;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedCrop = crop);
                _tabs.animateTo(1);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppShadow.xs,
                ),
                child: Row(children: [
                  Text(_cropEmoji(crop), style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(crop, style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('TZS $current/kg',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  )),
                  // Sparkline
                  SizedBox(
                    width: 60, height: 30,
                    child: CustomPaint(
                      painter: _SparkPainter(
                        data: history.map((v) => v.toDouble()).toList(),
                        color: isUp ? const Color(0xFF2E7D32) : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isUp ? const Color(0xFF2E7D32) : Colors.red)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$changeStr (${pct.toStringAsFixed(0)}%)',
                        style: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: isUp ? const Color(0xFF2E7D32) : Colors.red)),
                  ),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Zao la Kuchunguza',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _crops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = _crops[i] == _selectedCrop;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCrop = _crops[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.primary : Colors.grey.shade300),
                    ),
                    child: Text(_crops[i],
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // History chart
          if (_selectedCrop != null) ...[
            Text('Historia ya Miezi 3 — $_selectedCrop',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              height: 120,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadow.sm,
              ),
              child: CustomPaint(
                painter: _HistoryChartPainter(
                  data: (_priceHistory[_selectedCrop] ?? [])
                      .map((v) => v.toDouble()).toList(),
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          ElevatedButton.icon(
            onPressed: _aiLoading ? null : _getAiAdvice,
            icon: _aiLoading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.psychology_outlined),
            label: Text(_aiLoading ? 'AI inafikiria...' : 'Pata Ushauri wa AI 🤖'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),

          if (_aiAdvice != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15)),
                boxShadow: AppShadow.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('🤖', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('Ushauri wa AI — $_selectedCrop',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 12),
                  Text(_aiAdvice!,
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

  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weka Arifa ya Bei',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadow.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zao', style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCrop,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _crops.map((c) => DropdownMenuItem(
                    value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCrop = v),
                ),
                const SizedBox(height: 12),
                Text('Aina ya Arifa',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: RadioListTile<String>(
                    title: Text('Juu ya', style: GoogleFonts.poppins(fontSize: 13)),
                    value: 'above', groupValue: _alertType,
                    onChanged: (v) => setState(() => _alertType = v!),
                    contentPadding: EdgeInsets.zero,
                  )),
                  Expanded(child: RadioListTile<String>(
                    title: Text('Chini ya', style: GoogleFonts.poppins(fontSize: 13)),
                    value: 'below', groupValue: _alertType,
                    onChanged: (v) => setState(() => _alertType = v!),
                    contentPadding: EdgeInsets.zero,
                  )),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: _alertPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Bei (TZS/kg)',
                    hintText: 'Mfano: 1200',
                    prefixText: 'TZS ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _alertSaving ? null : _saveAlert,
                  icon: _alertSaving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.notifications_active_outlined),
                  label: const Text('Weka Arifa'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_alerts.isNotEmpty) ...[
            Text('Arifa Zilizowekwa (${_alerts.length})',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            ..._alerts.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppShadow.xs,
              ),
              child: Row(children: [
                const Icon(Icons.notifications_active,
                    color: Color(0xFFFFB300)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${a['crop_name']} — ${a['market_name']}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    Text('${a['alert_type'] == 'above' ? 'Juu ya' : 'Chini ya'} '
                        '${a['target_price_tzs']} TZS/kg',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ],
                )),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await _db.from('price_alerts')
                        .update({'is_active': false})
                        .eq('id', a['id']);
                    _loadAlerts();
                  },
                ),
              ]),
            )),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Hakuna arifa zilizowekwa bado',
                    style: GoogleFonts.poppins(color: Colors.grey)),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _cropEmoji(String crop) {
    const map = {
      'Mahindi': '🌽', 'Nyanya': '🍅', 'Maharagwe': '🫘',
      'Pilipili hoho': '🌶️', 'Ndizi': '🍌', 'Mchele': '🍚',
      'Muhogo': '🥬',
    };
    return map[crop] ?? '🌾';
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  const _SparkPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i] - min) / range * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HistoryChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  const _HistoryChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce((a, b) => a < b ? a : b) * 0.95;
    final max = data.reduce((a, b) => a > b ? a : b) * 1.05;
    final range = max - min == 0 ? 1.0 : max - min;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i] - min) / range * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
