import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/local_data.dart';
import '../theme/app_colors.dart';

class PesticidesScreen extends StatefulWidget {
  const PesticidesScreen({super.key});

  @override
  State<PesticidesScreen> createState() => _PesticidesScreenState();
}

class _PesticidesScreenState extends State<PesticidesScreen>
    with SingleTickerProviderStateMixin {
  // Top toggle: 0 = Viuatilifu, 1 = Mbolea
  int _section = 0;
  late TabController _tabCtrl;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // ── Viuatilifu categories ────────────────────────────────────────────────
  static const _pesticideCategories = [
    {'key': 'Zote',        'label': 'Zote',          'color': 0xFF1A5C2E},
    {'key': 'Insecticide', 'label': 'Wadudu',         'color': 0xFFB71C1C},
    {'key': 'Fungicide',   'label': 'Ukungu',         'color': 0xFF1A5C2E},
    {'key': 'Herbicide',   'label': 'Magugu',         'color': 0xFFFF6F00},
    {'key': 'Biopesticide','label': 'Asili',          'color': 0xFF0277BD},
  ];

  // ── Mbolea categories ────────────────────────────────────────────────────
  static const _fertilizerCategories = [
    {'key': 'Zote',         'label': 'Zote',           'color': 0xFF1A5C2E},
    {'key': 'Nitrojeni',    'label': 'Nitrojeni (N)',   'color': 0xFF1565C0},
    {'key': 'Fosfeti',      'label': 'Fosfeti (P)',     'color': 0xFF6A1B9A},
    {'key': 'Potasiamu',    'label': 'Potasiamu (K)',   'color': 0xFFC8860A},
    {'key': 'NPK',          'label': 'NPK/Mchanganyiko','color': 0xFF2E7D32},
    {'key': 'Kikaboni',     'label': 'Kikaboni',        'color': 0xFF4E342E},
    {'key': 'Virutubisho',  'label': 'Virutubisho',    'color': 0xFF00695C},
  ];

  List<Map<String, dynamic>> get _currentCategories =>
      _section == 0 ? _pesticideCategories : _fertilizerCategories;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
        length: _pesticideCategories.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _switchSection(int index) {
    _tabCtrl.dispose();
    setState(() {
      _section = index;
      _tabCtrl = TabController(
          length: _currentCategories.length, vsync: this);
      _tabCtrl.addListener(() => setState(() {}));
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  // ── Filtered list ────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filtered {
    final all =
        _section == 0 ? LocalData.pesticides : LocalData.fertilizers;
    final cats = _currentCategories;
    final catKey = cats[_tabCtrl.index]['key'] as String;
    final q = _searchQuery.toLowerCase();

    return all.where((item) {
      final matchCat = catKey == 'Zote' ||
          item['category'] == catKey;
      final matchSearch = q.isEmpty ||
          (item['brand_name'] ?? '').toString().toLowerCase().contains(q) ||
          (item['npk'] ?? item['active_ingredient'] ?? '')
              .toString()
              .toLowerCase()
              .contains(q) ||
          (item['crops'] ?? item['target_crops'] ?? '')
              .toString()
              .toLowerCase()
              .contains(q) ||
          (item['description_sw'] ?? '')
              .toString()
              .toLowerCase()
              .contains(q);
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Viuatilifu & Mbolea',
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // ── Top segment: Viuatilifu | Mbolea ──────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _SegmentBtn(
                          label: '🧪 Viuatilifu',
                          active: _section == 0,
                          onTap: () => _switchSection(0)),
                      _SegmentBtn(
                          label: '🌿 Mbolea',
                          active: _section == 1,
                          onTap: () => _switchSection(1)),
                    ],
                  ),
                ),
              ),
              // ── Category tabs ──────────────────────────────────────────
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                tabAlignment: TabAlignment.start,
                tabs: _currentCategories
                    .map((c) => Tab(text: c['label'] as String))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Source banner
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            color: AppColors.mint,
            child: Row(
              children: [
                const Icon(Icons.verified,
                    color: AppColors.leaf, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _section == 0
                        ? 'Chanzo: TFDA • TPRI Tanzania • Wizara ya Kilimo'
                        : 'Chanzo: TFRA Tanzania • Wizara ya Kilimo',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.leaf),
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: _section == 0
                    ? 'Tafuta dawa, wadudu, au zao...'
                    : 'Tafuta mbolea, NPK, au zao...',
                hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          // Count
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Text(
                  '${items.length} ${_section == 0 ? "dawa" : "mbolea"} zimepatikana',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: items.isEmpty
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
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => _section == 0
                        ? _PesticideCard(item: items[i])
                        : _FertilizerCard(item: items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Segment button ────────────────────────────────────────────────────────────

class _SegmentBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegmentBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
              fontWeight:
                  active ? FontWeight.bold : FontWeight.normal,
              color: active
                  ? AppColors.soil
                  : Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pesticide card ────────────────────────────────────────────────────────────

class _PesticideCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _PesticideCard({required this.item});

  static const _catColors = {
    'Insecticide': Color(0xFFB71C1C),
    'Fungicide':   Color(0xFF1A5C2E),
    'Herbicide':   Color(0xFFFF6F00),
    'Biopesticide':Color(0xFF0277BD),
  };

  static const _catIcons = {
    'Insecticide': Icons.bug_report,
    'Fungicide':   Icons.coronavirus,
    'Herbicide':   Icons.grass,
    'Biopesticide':Icons.eco,
  };

  static const _catLabels = {
    'Insecticide': 'Dawa ya Wadudu',
    'Fungicide':   'Dawa ya Ukungu',
    'Herbicide':   'Dawa ya Magugu',
    'Biopesticide':'Dawa ya Asili',
  };

  @override
  Widget build(BuildContext context) {
    final cat   = item['category'] as String? ?? 'Insecticide';
    final color = _catColors[cat] ?? AppColors.leaf;
    final icon  = _catIcons[cat]  ?? Icons.science;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(item['brand_name'] ?? '',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['active_ingredient'] ?? '',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(children: [
              _Badge(_catLabels[cat] ?? cat, color),
              if (item['tpri_registered'] == true) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified,
                    size: 13, color: AppColors.leaf),
                const Text(' TPRI',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.leaf)),
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
                _Row(Icons.bug_report, 'Wadudu/Magonjwa:',
                    item['target_pests'], color),
                _Row(Icons.grass, 'Mazao:',
                    item['target_crops'], color),
                _Row(Icons.water_drop, 'Kipimo (dumu 15L):',
                    item['dose_per_15L'], color),
                if (item['phi_days'] != null)
                  _Row(Icons.timer, 'Muda kabla kuvuna (PHI):',
                      '${item['phi_days']} siku', color),
                _Row(Icons.attach_money, 'Bei:',
                    item['price_range_tzs'] != null
                        ? 'TZS ${item['price_range_tzs']}'
                        : null,
                    color),
                _Row(Icons.factory, 'Mtengenezaji:',
                    item['manufacturer'], color),
                _InfoBox(item['description_sw'], AppColors.mint,
                    AppColors.leaf),
                _InfoBox(item['safety_sw'],
                    const Color(0xFFFFF8E1), const Color(0xFFFF6F00),
                    icon: Icons.warning_amber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fertilizer card ───────────────────────────────────────────────────────────

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
    final color = _catColors[cat] ?? AppColors.leaf;
    final icon  = _catIcons[cat]  ?? Icons.eco;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(item['brand_name'] ?? '',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NPK formula — prominent display
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
                child: Text(
                  item['npk'],
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace'),
                ),
              ),
            Row(children: [
              _Badge(_catLabels[cat] ?? cat, color),
              if (item['tfra_registered'] == true) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified,
                    size: 13, color: AppColors.leaf),
                const Text(' TFRA',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.leaf)),
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
                _Row(Icons.grass, 'Mazao:',
                    item['crops'], color),
                _Row(Icons.scale, 'Kipimo kwa ekari:',
                    item['dose_per_acre'], color),
                _Row(Icons.how_to_reg, 'Jinsi ya kutumia:',
                    item['application'], color),
                _Row(Icons.schedule, 'Wakati:',
                    item['timing'], color),
                _Row(Icons.attach_money, 'Bei takriban:',
                    item['price_range_tzs'] != null
                        ? 'TZS ${item['price_range_tzs']}'
                        : null,
                    color),
                _Row(Icons.factory, 'Mtengenezaji/Chanzo:',
                    item['manufacturer'], color),
                _InfoBox(item['description_sw'],
                    color.withValues(alpha: 0.06),
                    color),
                _InfoBox(item['warning_sw'],
                    const Color(0xFFFFF8E1),
                    const Color(0xFFFF6F00),
                    icon: Icons.warning_amber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

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
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text('$label ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: Text(value.toString(),
                style: const TextStyle(fontSize: 12)),
          ),
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
    if (text == null || text.toString().isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text.toString(),
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
