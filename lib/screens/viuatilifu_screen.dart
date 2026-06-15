// viuatilifu_screen.dart
// Pesticides + Fertilizers screen with TPRI live data and agrovet dealer info.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_data.dart';
import '../services/pesticide_service.dart';
import 'agrovet_screen.dart';
import '../routes/fade_slide_route.dart';
import 'pesticide_detail_screen.dart';

// Safely parse target_crops whether stored as List or JSON string
List<String> _parseCrops(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) return raw.cast<String>();
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    // plain comma-separated fallback
    return raw
        .replaceAll('[', '').replaceAll(']', '').replaceAll('"', '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return [];
}

class ViuatiliziBody extends StatefulWidget {
  const ViuatiliziBody({super.key});
  @override
  State<ViuatiliziBody> createState() => _ViuatiliziBodyState();
}

class _ViuatiliziBodyState extends State<ViuatiliziBody>
    with SingleTickerProviderStateMixin {
  // 0 = Viuatilifu, 1 = Mbolea
  int _section = 0;
  late TabController _tabCtrl;

  // TPRI live pesticides from Supabase
  List<Map<String, dynamic>> _livePesticides = [];
  // Agrovets from Supabase for "Patikana Wapi"
  List<Map<String, dynamic>> _agrovets = [];

  bool _loading = true;
  bool _loadError = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // ── Category filters ──────────────────────────────────────────────────────
  static const _pesticideCategories = [
    {'key': 'all',                   'label': 'Zote',      'color': 0xFF1A5C2E},
    {'key': 'insecticide',           'label': 'Wadudu',    'color': 0xFF1565C0},
    {'key': 'herbicide',             'label': 'Magugu',    'color': 0xFF2E7D32},
    {'key': 'fungicide',             'label': 'Kuvu',      'color': 0xFFE65100},
    {'key': 'acaricide',             'label': 'Utitiri',   'color': 0xFFB71C1C},
    {'key': 'restricted_herbicide',  'label': 'Marufuku',  'color': 0xFFBF360C},
    {'key': 'plant_growth_regulator','label': 'Ukuaji',    'color': 0xFF6A1B9A},
    {'key': 'rodenticide',           'label': 'Panya',     'color': 0xFF4E342E},
    {'key': 'nematicide',            'label': 'Minyoo',    'color': 0xFF00695C},
  ];

  static const _fertilizerCategories = [
    {'key': 'Zote',        'label': 'Zote',            'color': 0xFF1A5C2E},
    {'key': 'Nitrojeni',   'label': 'Nitrojeni (N)',    'color': 0xFF1565C0},
    {'key': 'Fosfeti',     'label': 'Fosfeti (P)',      'color': 0xFF6A1B9A},
    {'key': 'Potasiamu',   'label': 'Potasiamu (K)',    'color': 0xFFC8860A},
    {'key': 'NPK',         'label': 'NPK/Mchanganyiko', 'color': 0xFF2E7D32},
    {'key': 'Kikaboni',    'label': 'Kikaboni',         'color': 0xFF4E342E},
    {'key': 'Virutubisho', 'label': 'Virutubisho',      'color': 0xFF00695C},
  ];

  List<Map<String, dynamic>> get _currentCats =>
      _section == 0 ? _pesticideCategories : _fertilizerCategories;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
        length: _pesticideCategories.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Load TPRI pesticides + agrovets simultaneously
  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final db = Supabase.instance.client;

    // Load pesticides — independent try/catch so one failure can't block the other
    List<Map<String, dynamic>> pests = [];
    List<Map<String, dynamic>> agros = [];

    bool hadError = false;
    try {
      pests = await PesticideService.getAllPesticides();
    } catch (e) {
      hadError = true;
      debugPrint('viuatilifu load pesticides error: $e');
    }

    try {
      final r = await db
          .from('agrovets')
          .select('shop_name, region, district, phone, verified, source')
          .order('shop_name')
          .limit(50);
      agros = (r as List).cast<Map<String, dynamic>>();
    } catch (e) {
      hadError = true;
      debugPrint('viuatilifu load agrovets error: $e');
    }

    setState(() {
      _livePesticides = pests;
      _agrovets       = agros;
      _loading        = false;
      _loadError      = hadError;
    });
  }

  void _switchSection(int idx) {
    _tabCtrl.dispose();
    setState(() {
      _section = idx;
      _tabCtrl = TabController(
          length: _currentCats.length, vsync: this);
      _tabCtrl.addListener(() => setState(() {}));
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  // Filter pesticides (live Supabase data)
  List<Map<String, dynamic>> get _filteredPesticides {
    final catKey = _pesticideCategories[_tabCtrl.index]['key'] as String;
    final q = _searchQuery.toLowerCase();
    return _livePesticides.where((p) {
      final matchCat = catKey == 'all' || p['category'] == catKey;
      final matchQ = q.isEmpty ||
          (p['brand_name'] ?? '').toString().toLowerCase().contains(q) ||
          (p['active_ingredient'] ?? '').toString().toLowerCase().contains(q) ||
          (p['manufacturer'] ?? '').toString().toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();
  }

  // Filter fertilizers (local static data)
  List<Map<String, dynamic>> get _filteredFertilizers {
    final cats = _fertilizerCategories;
    final catKey = cats[_tabCtrl.index]['key'] as String;
    final q = _searchQuery.toLowerCase();
    return LocalData.fertilizers.where((f) {
      final matchCat = catKey == 'Zote' || f['category'] == catKey;
      final matchQ = q.isEmpty ||
          (f['brand_name'] ?? '').toString().toLowerCase().contains(q) ||
          (f['npk'] ?? '').toString().toLowerCase().contains(q) ||
          (f['crops'] ?? '').toString().toLowerCase().contains(q) ||
          (f['manufacturer'] ?? '').toString().toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _section == 0 ? _filteredPesticides : _filteredFertilizers;

    return Column(
      children: [
        // ── Green header: section toggle + category tabs + refresh ────────
        Container(
          color: const Color(0xFF1A5C2E),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _SegBtn('🧪 Viuatilifu', _section == 0,
                                () => _switchSection(0)),
                            _SegBtn('🌿 Mbolea', _section == 1,
                                () => _switchSection(1)),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Pakia upya',
                      onPressed: _loadAll,
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                tabs: _currentCats
                    .map((c) => Tab(text: c['label'] as String))
                    .toList(),
              ),
            ],
          ),
        ),

        // ── Offline banner ────────────────────────────────────────────────
        if (_loadError)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFFF3E0),
            child: Row(
              children: const [
                Icon(Icons.wifi_off, color: Color(0xFFE65100), size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Hakuna mtandao — data inaweza kuwa si kamili.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFE65100)),
                  ),
                ),
              ],
            ),
          ),

        // ── Source banner ─────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          color: const Color(0xFFE8F5E9),
          child: Row(
            children: [
              const Icon(Icons.verified_user,
                  color: Color(0xFF1A5C2E), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _section == 0
                      ? 'Chanzo: TPRI Tanzania • ${_livePesticides.length} dawa zimesajiliwa'
                      : 'Chanzo: TFRA Tanzania • Wizara ya Kilimo',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF1A5C2E)),
                ),
              ),
            ],
          ),
        ),

        // ── Search bar ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: _section == 0
                  ? 'Tafuta dawa, kiambato, au registrant...'
                  : 'Tafuta mbolea, NPK, au zao...',
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF1A5C2E)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      })
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),

        // ── Count row ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              Text(
                '${items.length} ${_section == 0 ? "dawa" : "mbolea"} zimepatikana',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),

        // ── Main list ─────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                          color: Color(0xFF1A5C2E)),
                      SizedBox(height: 12),
                      Text('Inapakia kutoka TPRI...',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _section == 0
                                ? Icons.bug_report_outlined
                                : Icons.eco_outlined,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Hakuna ${_section == 0 ? "dawa" : "mbolea"} iliyopatikana.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => _section == 0
                          ? _PesticideCard(
                              item: items[i],
                              agrovets: _agrovets,
                            )
                          : _FertilizerCard(item: items[i]),
                    ),
        ),
      ],
    );
  }
}

class ViuatiliziScreen extends StatelessWidget {
  const ViuatiliziScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5C2E),
        foregroundColor: Colors.white,
        title: Text('Viuatilifu & Mbolea',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: const ViuatiliziBody(),
    );
  }
}

// ── Segment toggle button ─────────────────────────────────────────────────────
class _SegBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SegBtn(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active
                  ? const Color(0xFF1A5C2E)
                  : Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pesticide card (TPRI live data) ──────────────────────────────────────────
class _PesticideCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> agrovets;
  const _PesticideCard(
      {required this.item, required this.agrovets});

  @override
  Widget build(BuildContext context) {
    final cat       = item['category'] as String? ?? 'insecticide';
    final typeColor = Color(PesticideService.getTypeColor(cat));
    final typeLabel = PesticideService.getTypeLabel(cat);
    final name      = item['brand_name'] as String? ?? '';
    final ai        = item['active_ingredient'] as String? ?? '';
    final mfr       = item['manufacturer'] as String? ?? '';
    final usage     = item['description_sw'] as String? ?? '';
    final crops     = _parseCrops(item['target_crops']);
    final isRestricted = cat == 'restricted_herbicide';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      elevation: 1.5,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(13))),
        // ── Collapsed header ──────────────────────────────────────────
        leading: GestureDetector(
          onTap: () => Navigator.push(
            context,
            FadeSlideRoute(
              page: PesticideDetailScreen(
                pesticide: item,
                heroTag: 'pesticide-$name',
              ),
            ),
          ),
          child: Hero(
            tag: 'pesticide-$name',
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(_emoji(cat),
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ),
        title: Text(name,
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ai.isNotEmpty)
              Text(ai,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                _Chip(typeLabel, typeColor),
                if (isRestricted)
                  _Chip('⚠ Marufuku', const Color(0xFFBF360C)),
                const _Chip('TPRI ✓', Color(0xFF1A5C2E)),
              ],
            ),
          ],
        ),

        // ── Expanded detail ───────────────────────────────────────────
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),

                // Usage / Target pest
                if (usage.isNotEmpty) ...[
                  _Row(Icons.pest_control, 'Matumizi:', usage,
                      typeColor),
                  const SizedBox(height: 4),
                ],

                // Registrant / Manufacturer
                if (mfr.isNotEmpty)
                  _Row(Icons.business, 'Registrant:', mfr, typeColor),

                // Target crops
                if (crops.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Mazao:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: crops
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: typeColor
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${_cropEmoji(c)} ${c.replaceAll("_", " ")}',
                                style: TextStyle(
                                    fontSize: 11, color: typeColor),
                              ),
                            ))
                        .toList(),
                  ),
                ],

                // Restricted warning
                if (isRestricted) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFBF360C)
                              .withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber,
                            color: Color(0xFFBF360C), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dawa hii ina vikwazo. Wasiliana na TPHPA au Afisa Kilimo wako.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFBF360C)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Patikana Wapi (Where to Buy) ──────────────────────
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      FadeSlideRoute(
                        page: PesticideDetailScreen(
                          pesticide: item,
                          heroTag: 'pesticide-$name',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Fungua Maelezo Kamili'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A5C2E),
                      side: const BorderSide(color: Color(0xFF1A5C2E)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.storefront,
                        size: 16, color: Color(0xFF1565C0)),
                    const SizedBox(width: 6),
                    const Text('Patikana Wapi (Maduka/Agrovets):',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1565C0))),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AgrovetScreen())),
                      child: const Text(
                        'Angalia zote →',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (agrovets.isEmpty)
                  _dealerTile(
                    name: 'Duka la kilimo — Tanzania yote',
                    region: 'Tanzania yote',
                    phone: '',
                    type: 'Agrovet ya Kawaida',
                  )
                else
                  ..._topDealers(cat).map((d) => _dealerTile(
                        name: d['shop_name'] as String,
                        region:
                            '${d['region'] ?? ''}${d['district'] != null ? " — ${d['district']}" : ""}',
                        phone: d['phone'] as String? ?? '',
                        type: d['source'] as String? ?? 'Agrovet',
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pick the most relevant agrovets for this pesticide type
  List<Map<String, dynamic>> _topDealers(String cat) {
    // TARI centres and company offices first for specific types
    List<Map<String, dynamic>> sorted = List.from(agrovets);

    // Prioritise verified TARI research centres for accuracy
    sorted.sort((a, b) {
      final aIsTari = (a['source'] as String? ?? '').contains('TARI');
      final bIsTari = (b['source'] as String? ?? '').contains('TARI');
      if (aIsTari && !bIsTari) return -1;
      if (!aIsTari && bIsTari) return 1;
      return 0;
    });

    // Return up to 3 dealers
    return sorted.take(3).toList();
  }

  Widget _dealerTile(
      {required String name,
      required String region,
      required String phone,
      required String type}) {
    Color typeColor;
    IconData typeIcon;
    if (type.contains('TARI') || type.contains('Utafiti')) {
      typeColor = const Color(0xFF2E7D32);
      typeIcon = Icons.science;
    } else if (type.contains('company') || type.contains('Kampuni')) {
      typeColor = const Color(0xFF1565C0);
      typeIcon = Icons.business;
    } else if (type.contains('Serikali')) {
      typeColor = const Color(0xFF00695C);
      typeIcon = Icons.account_balance;
    } else {
      typeColor = const Color(0xFF6A1B9A);
      typeIcon = Icons.storefront;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: typeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(typeIcon, color: typeColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: typeColor)),
                if (region.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                          child: Text(region,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey))),
                    ],
                  ),
                if (phone.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.phone,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(phone,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _emoji(String cat) {
    switch (cat) {
      case 'insecticide':             return '🐛';
      case 'herbicide':               return '🌿';
      case 'fungicide':               return '🍄';
      case 'acaricide':               return '🕷️';
      case 'plant_growth_regulator':  return '🌱';
      case 'rodenticide':             return '🐀';
      case 'avicide':                 return '🦅';
      case 'nematicide':              return '🪱';
      case 'restricted_herbicide':    return '⚠️';
      default:                        return '💊';
    }
  }

  String _cropEmoji(String crop) {
    const map = {
      'maize': '🌽', 'tomato': '🍅', 'beans': '🫘',
      'cotton': '🌸', 'coffee': '☕', 'tobacco': '🌿',
      'wheat': '🌾', 'rice': '🍚', 'cashew': '🥜',
      'banana': '🍌', 'cassava': '🍠',
      'horticultural_crops': '🥦', 'stored_grain': '🌾',
      'public_health': '🏥', 'sugarcane': '🎋',
      'flowers': '🌸', 'vegetables': '🥬', 'general': '🌱',
    };
    return map[crop] ?? '🌿';
  }
}

// ── Fertilizer card (local TFRA data) ────────────────────────────────────────
class _FertilizerCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _FertilizerCard({required this.item});

  static const _catColors = {
    'Nitrojeni':   Color(0xFF1565C0),
    'Fosfeti':     Color(0xFF6A1B9A),
    'Potasiamu':   Color(0xFFC8860A),
    'NPK':         Color(0xFF2E7D32),
    'Kikaboni':    Color(0xFF4E342E),
    'Virutubisho': Color(0xFF00695C),
  };
  static const _catIcons = {
    'Nitrojeni':   Icons.air,
    'Fosfeti':     Icons.science,
    'Potasiamu':   Icons.water,
    'NPK':         Icons.auto_awesome,
    'Kikaboni':    Icons.compost,
    'Virutubisho': Icons.biotech,
  };
  static const _catLabels = {
    'Nitrojeni':   'Nitrojeni (N)',
    'Fosfeti':     'Fosfeti (P)',
    'Potasiamu':   'Potasiamu (K)',
    'NPK':         'NPK / Mchanganyiko',
    'Kikaboni':    'Mbolea ya Kikaboni',
    'Virutubisho': 'Virutubisho Vidogo',
  };

  @override
  Widget build(BuildContext context) {
    final cat   = item['category'] as String? ?? 'NPK';
    final color = _catColors[cat] ?? const Color(0xFF2E7D32);
    final icon  = _catIcons[cat]  ?? Icons.eco;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13)),
      elevation: 1.5,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(13))),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(item['brand_name'] ?? '',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((item['npk'] ?? '').isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 2, bottom: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: color.withValues(alpha: 0.3)),
                ),
                child: Text(item['npk'],
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace')),
              ),
            Row(children: [
              _Chip(_catLabels[cat] ?? cat, color),
              if (item['tfra_registered'] == true) ...[
                const SizedBox(width: 6),
                const _Chip('TFRA ✓', Color(0xFF1A5C2E)),
              ],
            ]),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _Row(Icons.grass,       'Mazao:',       item['crops'],         color),
                _Row(Icons.scale,       'Kipimo/Ekari:',item['dose_per_acre'],  color),
                _Row(Icons.how_to_reg,  'Jinsi ya kutumia:', item['application'], color),
                _Row(Icons.schedule,    'Wakati:',      item['timing'],        color),
                _Row(Icons.attach_money,'Bei takriban:',
                    item['price_range_tzs'] != null
                        ? 'TZS ${item['price_range_tzs']}'
                        : null,
                    color),
                _Row(Icons.factory, 'Mtengenezaji:', item['manufacturer'], color),
                if ((item['description_sw'] ?? '').isNotEmpty)
                  _InfoBox(item['description_sw'],
                      color.withValues(alpha: 0.06), color),
                if ((item['warning_sw'] ?? '').isNotEmpty)
                  _InfoBox(item['warning_sw'],
                      const Color(0xFFFFF8E1),
                      const Color(0xFFFF6F00),
                      icon: Icons.warning_amber),

                // Dealers section for fertilizers
                const SizedBox(height: 10),
                const Divider(),
                const Row(
                  children: [
                    Icon(Icons.storefront,
                        size: 16, color: Color(0xFF1565C0)),
                    SizedBox(width: 6),
                    Text('Patikana Wapi:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1565C0))),
                  ],
                ),
                const SizedBox(height: 8),
                ..._fertDealers(item['manufacturer'] as String? ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build dealer tiles based on manufacturer name
  List<Widget> _fertDealers(String mfr) {
    final dealers = <Map<String, String>>[];

    if (mfr.toLowerCase().contains('yara')) {
      dealers.add({
        'name': 'Yara Tanzania — Dar es Salaam',
        'phone': '+255 22 286 4000',
        'region': 'Dar es Salaam',
        'type': 'Ofisi ya Kampuni',
      });
    }
    if (mfr.toLowerCase().contains('minjingu')) {
      dealers.add({
        'name': 'Minjingu Mines & Fertiliser Ltd',
        'phone': '+255 27 255 0301',
        'region': 'Arusha',
        'type': 'Ofisi ya Kampuni',
      });
    }
    if (mfr.toLowerCase().contains('bayer')) {
      dealers.add({
        'name': 'Balton Tanzania — Dar es Salaam',
        'phone': '+255 22 218 0033',
        'region': 'Dar es Salaam',
        'type': 'Ofisi ya Kampuni',
      });
    }

    // Always add generic dealer
    dealers.add({
      'name': 'Maduka ya Kilimo — Tanzania yote',
      'phone': '',
      'region': 'Tanzania yote',
      'type': 'Agrovet ya Kawaida',
    });

    return dealers
        .map((d) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF1565C0)
                        .withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront,
                      color: Color(0xFF1565C0), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['name']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF1565C0))),
                        if ((d['region'] ?? '').isNotEmpty)
                          Row(children: [
                            const Icon(Icons.location_on,
                                size: 11, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text(d['region']!,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ]),
                        if ((d['phone'] ?? '').isNotEmpty)
                          Row(children: [
                            const Icon(Icons.phone,
                                size: 11, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text(d['phone']!,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ]),
                      ],
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final Color color;
  const _Row(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$label ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
              child: Text(value.toString(),
                  style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final dynamic text;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _InfoBox(this.text, this.bg, this.fg,
      {this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    if (text == null || text.toString().isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 15),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text.toString(),
                  style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
