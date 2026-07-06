import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/claude_service.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';
import 'soil_screen.dart';

class AfisaFarmDetailScreen extends StatefulWidget {
  /// Combined farm + farmer data from AfisaHubScreen
  final Map<String, dynamic> farmData;
  const AfisaFarmDetailScreen({super.key, required this.farmData});

  @override
  State<AfisaFarmDetailScreen> createState() => _AfisaFarmDetailScreenState();
}

class _AfisaFarmDetailScreenState extends State<AfisaFarmDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // AI Advisor state
  final _questionCtrl = TextEditingController();
  String? _aiResponse;
  bool _aiLoading = false;

  // Visit notes state
  final _notesCtrl = TextEditingController();
  final _recommendCtrl = TextEditingController();
  List<Map<String, dynamic>> _visits = [];
  bool _visitsLoading = false;
  bool _savingVisit = false;

  static SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadVisits();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _questionCtrl.dispose();
    _notesCtrl.dispose();
    _recommendCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _farmName => widget.farmData['name'] as String? ?? 'Shamba';
  String get _farmerName =>
      '${widget.farmData['farmer_first_name'] ?? ''} ${widget.farmData['farmer_last_name'] ?? ''}'.trim();
  String get _farmerId => widget.farmData['farmer_id'] as String? ?? '';
  String get _farmId   => widget.farmData['id']       as String? ?? '';
  String get _region   => widget.farmData['region']   as String? ?? '';
  List<String> get _crops =>
      (widget.farmData['crops'] as List?)?.cast<String>() ?? [];
  double? get _gpsLat => widget.farmData['gps_lat'] as double?;
  double? get _gpsLng => widget.farmData['gps_lng'] as double?;

  // ── AI Advisor ────────────────────────────────────────────────────────────

  Future<void> _askAI() async {
    final q = _questionCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() { _aiLoading = true; _aiResponse = null; });

    final crops  = _crops.isEmpty ? 'mazao mchanganyiko' : _crops.join(', ');
    final acres  = (widget.farmData['acres'] as num?)?.toStringAsFixed(1) ?? '?';
    final soil   = widget.farmData['soil_type'] as String? ?? 'haijulikani';

    final context_ =
        'Shamba linaitwa "$_farmName" linalomilikiwa na $_farmerName, '
        'liko $_region, ekari $acres, mazao: $crops, udongo: $soil.';

    final answer = await ClaudeService.askFarmingQuestion(
      question: '$context_\n\nSwali la Afisa: $q',
      cropContext: crops,
      regionContext: _region,
    );

    if (mounted) setState(() { _aiResponse = answer; _aiLoading = false; });
  }

  // ── Visit Notes ───────────────────────────────────────────────────────────

  Future<void> _loadVisits() async {
    if (_farmId.isEmpty) return;
    setState(() => _visitsLoading = true);
    try {
      final rows = await _db
          .from('farm_visits')
          .select()
          .eq('farm_id', _farmId)
          .order('visit_date', ascending: false)
          .limit(20);
      if (mounted) setState(() => _visits = (rows as List).cast<Map<String, dynamic>>());
    } catch (e) {
      // table may not exist yet — silently ignore
    }
    if (mounted) setState(() => _visitsLoading = false);
  }

  Future<void> _saveVisit() async {
    final notes  = _notesCtrl.text.trim();
    final recomm = _recommendCtrl.text.trim();
    if (notes.isEmpty && recomm.isEmpty) return;

    setState(() => _savingVisit = true);
    final afisaId = context.read<AuthProvider>().currentUser?.id ?? '';

    try {
      await _db.from('farm_visits').insert({
        'afisa_id':       afisaId,
        'farmer_id':      _farmerId,
        'farm_id':        _farmId,
        'farm_name':      _farmName,
        'notes':          notes.isEmpty ? null : notes,
        'recommendations': recomm.isEmpty ? null : recomm,
        'ai_advice':      _aiResponse,
      });
      _notesCtrl.clear();
      _recommendCtrl.clear();
      await _loadVisits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ziara imehifadhiwa'),
              backgroundColor: AppColors.leaf),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Hitilafu: $e'),
              backgroundColor: Colors.red.shade700),
        );
      }
    }
    if (mounted) setState(() => _savingVisit = false);
  }

  @override
  Widget build(BuildContext context) {
    final farmerRole = UserRoleX.fromKey(
        widget.farmData['farmer_role'] as String? ?? 'mkulima');

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: const Color(0xFF00695C),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _Header(
                farmName: _farmName,
                farmerName: _farmerName.isEmpty ? 'Mkulima' : _farmerName,
                farmerRole: farmerRole,
                region: _region,
                crops: _crops,
              ),
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
                Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Shamba'),
                Tab(icon: Icon(Icons.smart_toy_outlined, size: 18), text: 'AI Mshauri'),
                Tab(icon: Icon(Icons.history_outlined, size: 18), text: 'Historia'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _FarmInfoTab(
              farmData: widget.farmData,
              farmerName: _farmerName,
              farmerRole: farmerRole,
              onChat: _openChat,
              onSoil: _openSoil,
            ),
            _AiAdvisorTab(
              ctrl: _questionCtrl,
              response: _aiResponse,
              loading: _aiLoading,
              farmName: _farmName,
              crops: _crops,
              region: _region,
              onAsk: _askAI,
              onSaveVisit: _aiResponse != null ? _saveVisit : null,
            ),
            _HistoryTab(
              visits: _visits,
              loading: _visitsLoading,
              notesCtrl: _notesCtrl,
              recommendCtrl: _recommendCtrl,
              saving: _savingVisit,
              onSave: _saveVisit,
            ),
          ],
        ),
      ),
    );
  }

  void _openChat() {
    if (_farmerId.isEmpty) return;
    final farmerRole = UserRoleX.fromKey(
        widget.farmData['farmer_role'] as String? ?? 'mkulima');
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(
        contactId:       _farmerId,
        contactName:     _farmerName.isEmpty ? 'Mkulima' : _farmerName,
        contactRole:     farmerRole,
        contactColorHex: farmerRole.colorHex,
      ),
    ));
  }

  void _openSoil() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SoilScreen(
        farmLat:  _gpsLat,
        farmLng:  _gpsLng,
        farmName: _farmName,
      ),
    ));
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String farmName;
  final String farmerName;
  final UserRole farmerRole;
  final String region;
  final List<String> crops;
  const _Header({required this.farmName, required this.farmerName,
      required this.farmerRole, required this.region, required this.crops});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 52),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Center(
                    child: Icon(Icons.agriculture_outlined,
                        color: Colors.white, size: 30)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(farmName,
                        style: GoogleFonts.playfairDisplay(
                            color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 13, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text('$farmerName • ${farmerRole.label}',
                            style: GoogleFonts.dmSans(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 13, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text(region,
                            style: GoogleFonts.dmSans(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    if (crops.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: crops.take(3).map((c) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(c,
                              style: GoogleFonts.dmSans(
                                  color: Colors.white, fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        )).toList(),
                      ),
                    ],
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
// TAB 1: TAARIFA ZA SHAMBA
// ══════════════════════════════════════════════════════════════════════════════

class _FarmInfoTab extends StatelessWidget {
  final Map<String, dynamic> farmData;
  final String farmerName;
  final UserRole farmerRole;
  final VoidCallback onChat;
  final VoidCallback onSoil;
  const _FarmInfoTab({required this.farmData, required this.farmerName,
      required this.farmerRole, required this.onChat, required this.onSoil});

  @override
  Widget build(BuildContext context) {
    final crops  = (farmData['crops'] as List?)?.cast<String>() ?? [];
    final acres  = (farmData['acres'] as num?)?.toDouble() ?? 0;
    final hasGps = farmData['gps_lat'] != null;
    final notes  = farmData['notes'] as String?;
    final soil   = farmData['soil_type'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Farmer info ──────────────────────────────────────────────────────
        _Section(
          title: 'Taarifa za Mkulima',
          icon: Icons.person_outline,
          color: AppColors.harvest,
          child: Column(
            children: [
              _Row(Icons.person, 'Jina', farmerName.isEmpty ? 'Haijulikani' : farmerName),
              const Divider(height: 14),
              _Row(Icons.badge_outlined, 'Jukumu', farmerRole.label),
              const Divider(height: 14),
              _Row(Icons.location_city, 'Mkoa', farmData['farmer_region'] as String? ?? '—'),
              if (farmData['farmer_email'] != null && (farmData['farmer_email'] as String).isNotEmpty) ...[
                const Divider(height: 14),
                _Row(Icons.email_outlined, 'Barua pepe', farmData['farmer_email'] as String),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Farm details ─────────────────────────────────────────────────────
        _Section(
          title: 'Taarifa za Shamba',
          icon: Icons.agriculture_outlined,
          color: AppColors.leaf,
          child: Column(
            children: [
              _Row(Icons.straighten, 'Ukubwa', '${acres.toStringAsFixed(1)} ekari'),
              const Divider(height: 14),
              _Row(Icons.location_on, 'Mkoa', farmData['region'] as String? ?? '—'),
              const Divider(height: 14),
              _Row(Icons.gps_fixed, 'GPS',
                  hasGps ? '✅ Imewekwa' : '❌ Haijawekwa',
                  valueColor: hasGps ? AppColors.leaf : Colors.orange),
              if (soil != null) ...[
                const Divider(height: 14),
                _Row(Icons.terrain, 'Aina ya Udongo', soil),
              ],
              if (crops.isNotEmpty) ...[
                const Divider(height: 14),
                _Row(Icons.grass, 'Mazao', crops.join(', ')),
              ],
              if (notes != null && notes.isNotEmpty) ...[
                const Divider(height: 14),
                _Row(Icons.notes, 'Maelezo', notes),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Actions ──────────────────────────────────────────────────────────
        _Section(
          title: 'Vitendo',
          icon: Icons.flash_on_outlined,
          color: const Color(0xFF00695C),
          child: Column(
            children: [
              _ActionBtn(
                emoji: '💬',
                label: 'Zungumza na Mkulima',
                subtitle: 'Fungua mazungumzo ya moja kwa moja',
                color: const Color(0xFF00695C),
                onTap: onChat,
              ),
              const SizedBox(height: 10),
              _ActionBtn(
                emoji: '🧪',
                label: 'Angalia Hali ya Udongo',
                subtitle: hasGps
                    ? 'Pata data ya pH, nitrogen na ushauri'
                    : 'GPS haijawekwa — itatumia GPS ya simu',
                color: const Color(0xFF7A5C3A),
                onTap: onSoil,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2: AI MSHAURI
// ══════════════════════════════════════════════════════════════════════════════

class _AiAdvisorTab extends StatelessWidget {
  final TextEditingController ctrl;
  final String? response;
  final bool loading;
  final String farmName;
  final List<String> crops;
  final String region;
  final VoidCallback onAsk;
  final VoidCallback? onSaveVisit;
  const _AiAdvisorTab({required this.ctrl, required this.response,
      required this.loading, required this.farmName, required this.crops,
      required this.region, required this.onAsk, this.onSaveVisit});

  @override
  Widget build(BuildContext context) {
    final cropText = crops.isEmpty ? 'mazao mchanganyiko' : crops.join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Context banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00695C).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF00695C).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Claude AI — Mshauri wa Shamba',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00695C),
                            fontSize: 13)),
                    Text('Shamba: $farmName | Mazao: $cropText',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.mid),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Quick question chips
        Text('Maswali ya Haraka:',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                color: AppColors.soil, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            'Mazao bora kwa udongo huu?',
            'Dalili za ugonjwa wa ${crops.isNotEmpty ? crops.first : "mazao"}?',
            'Wakati bora wa kupanda $region?',
            'Tatizo la wadudu na suluhisho?',
            'Mbolea inayofaa na kiasi gani?',
            'Umwagiliaji — mara ngapi kwa wiki?',
          ].map((q) => ActionChip(
            label: Text(q,
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: const Color(0xFF00695C))),
            backgroundColor: const Color(0xFF00695C).withValues(alpha: 0.08),
            side: BorderSide(
                color: const Color(0xFF00695C).withValues(alpha: 0.3)),
            onPressed: () {
              ctrl.text = q;
              onAsk();
            },
          )).toList(),
        ),

        const SizedBox(height: 14),

        // Input field
        TextField(
          controller: ctrl,
          maxLines: 3,
          minLines: 2,
          decoration: InputDecoration(
            hintText: 'Andika swali lako kuhusu shamba hili...',
            hintStyle: GoogleFonts.dmSans(color: AppColors.mid, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppColors.mid.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF00695C), width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: loading ? null : onAsk,
          icon: loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(loading ? 'Claude anafikiri...' : 'Uliza AI'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00695C),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // AI Response
        if (response != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text('Jibu la Claude AI',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            color: AppColors.soil, fontSize: 14)),
                  ],
                ),
                const Divider(height: 16),
                Text(response!,
                    style: GoogleFonts.dmSans(
                        fontSize: 13.5, height: 1.7, color: AppColors.ink)),
                if (onSaveVisit != null) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: onSaveVisit,
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Hifadhi kama Historia ya Ziara'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00695C),
                      side: const BorderSide(color: Color(0xFF00695C)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
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
// TAB 3: HISTORIA YA ZIARA
// ══════════════════════════════════════════════════════════════════════════════

class _HistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> visits;
  final bool loading;
  final TextEditingController notesCtrl;
  final TextEditingController recommendCtrl;
  final bool saving;
  final VoidCallback onSave;
  const _HistoryTab({required this.visits, required this.loading,
      required this.notesCtrl, required this.recommendCtrl,
      required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Add visit note ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('Rekodi Ziara Mpya',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          color: AppColors.soil, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Maelezo ya Ziara',
                  hintText: 'Nilikuta nini shambani...',
                  filled: true, fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  labelStyle: GoogleFonts.dmSans(color: AppColors.mid),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: recommendCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mapendekezo kwa Mkulima',
                  hintText: 'Nilimwambia afanye nini...',
                  filled: true, fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  labelStyle: GoogleFonts.dmSans(color: AppColors.mid),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(saving ? 'Inahifadhi...' : 'Hifadhi Ziara'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Visit history ─────────────────────────────────────────────────────
        Row(
          children: [
            Text('Historia ya Ziara (${visits.length})',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: AppColors.soil, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 10),

        if (loading)
          const Center(child: CircularProgressIndicator(
              color: AppColors.leaf, strokeWidth: 2))
        else if (visits.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('📋', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text('Bado hakuna historia ya ziara',
                    style: GoogleFonts.dmSans(
                        color: AppColors.mid, fontSize: 13)),
              ],
            ),
          )
        else
          ...visits.map((v) => _VisitCard(visit: v)),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Map<String, dynamic> visit;
  const _VisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    final date = visit['visit_date'] as String? ?? '';
    DateTime? dt;
    try { dt = DateTime.parse(date).toLocal(); } catch (_) {}

    final dateStr = dt != null
        ? '${dt.day}/${dt.month}/${dt.year} — ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : date;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.mid),
              const SizedBox(width: 6),
              Text(dateStr,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.mid)),
            ],
          ),
          if (visit['notes'] != null && (visit['notes'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('📝 Maelezo:',
                style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppColors.soil)),
            const SizedBox(height: 4),
            Text(visit['notes'] as String,
                style: GoogleFonts.dmSans(
                    fontSize: 13, height: 1.5, color: AppColors.ink)),
          ],
          if (visit['recommendations'] != null &&
              (visit['recommendations'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('✅ Mapendekezo:',
                style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppColors.leaf)),
            const SizedBox(height: 4),
            Text(visit['recommendations'] as String,
                style: GoogleFonts.dmSans(
                    fontSize: 13, height: 1.5, color: AppColors.ink)),
          ],
          if (visit['ai_advice'] != null &&
              (visit['ai_advice'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🤖 ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      'AI: ${(visit['ai_advice'] as String).length > 150 ? '${(visit['ai_advice'] as String).substring(0, 150)}...' : visit['ai_advice'] as String}',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.mid, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  const _Section({required this.title, required this.icon,
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
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 7),
                  Text(title,
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13, color: AppColors.soil)),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _Row(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.mid),
          const SizedBox(width: 7),
          Text('$label: ',
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.mid)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.ink)),
          ),
        ],
      );
}

class _ActionBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.emoji, required this.label,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13, color: color)),
                    Text(subtitle,
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.mid, height: 1.3)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
        ),
      );
}
