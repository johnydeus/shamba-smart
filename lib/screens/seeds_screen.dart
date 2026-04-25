import 'package:flutter/material.dart';
import '../services/data_sync_service.dart';
import '../services/local_data.dart';

// Crops available in the TOSCI seed database
const List<String> kSeedCrops = [
  'Mahindi',
  'Nyanya',
  'Maharagwe',
  'Mchele',
  'Muhogo',
  'Alizeti',
  'Pilipili hoho',
  'Vitunguu',
  'Viazi vitamu',
  'Ngano',
  'Mtama',
  'Choroko',
];

// Filter options for stress tolerance
const List<Map<String, dynamic>> kFilters = [
  {'key': 'all', 'label': 'Aina Zote', 'icon': Icons.apps},
  {'key': 'drought', 'label': 'Ukame', 'icon': Icons.wb_sunny},
  {'key': 'disease', 'label': 'Magonjwa', 'icon': Icons.coronavirus},
  {'key': 'pest', 'label': 'Wadudu', 'icon': Icons.bug_report},
  {'key': 'nutrient', 'label': 'Lishe Chache', 'icon': Icons.eco},
  {'key': 'high_yield', 'label': 'Tija Nyingi', 'icon': Icons.trending_up},
];

class SeedsScreen extends StatefulWidget {
  const SeedsScreen({super.key});

  @override
  State<SeedsScreen> createState() => _SeedsScreenState();
}

class _SeedsScreenState extends State<SeedsScreen> {
  String _selectedCrop = 'Mahindi';
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _varieties = [];
  bool _loading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVarieties();
  }

  // Load seeds: local data instantly, Claude updates in background
  Future<void> _loadVarieties() async {
    setState(() {
      _loading = true;
      _varieties = [];
    });

    // Step 1 — local TOSCI database loads instantly
    final local = LocalData.seedsFor(_selectedCrop);
    setState(() {
      _varieties = local;
      _loading = false;
    });

    // Step 2 — try Claude silently for extra varieties
    DataSyncService.fetchSeedVarieties(cropName: _selectedCrop).then((fresh) {
      if (fresh.isNotEmpty && mounted) {
        setState(() => _varieties = fresh);
      }
    });
  }

  // Filter varieties by selected stress/trait filter
  List<Map<String, dynamic>> get _filtered {
    var list = _varieties;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      list = list.where((v) {
        final name = (v['variety_name'] ?? '').toString().toLowerCase();
        final company = (v['company'] ?? '').toString().toLowerCase();
        final desc = (v['description_sw'] ?? '').toString().toLowerCase();
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || company.contains(q) || desc.contains(q);
      }).toList();
    }

    // Apply stress filter
    switch (_selectedFilter) {
      case 'drought':
        list = list
            .where((v) => v['drought_tolerance'] == 'high')
            .toList();
        break;
      case 'disease':
        list = list
            .where((v) =>
                (v['disease_resistance'] as List?)?.isNotEmpty == true)
            .toList();
        break;
      case 'pest':
        list = list
            .where((v) =>
                (v['pest_resistance'] as List?)?.isNotEmpty == true)
            .toList();
        break;
      case 'nutrient':
        list = list
            .where((v) => v['nutrient_efficiency'] == 'high')
            .toList();
        break;
      case 'high_yield':
        list = list.where((v) {
          final yield =
              double.tryParse(v['yield_potential_ton_ha']?.toString() ?? '0') ??
                  0;
          return yield >= 6.0;
        }).toList();
        list.sort((a, b) {
          final ya = double.tryParse(
                  a['yield_potential_ton_ha']?.toString() ?? '0') ??
              0;
          final yb = double.tryParse(
                  b['yield_potential_ton_ha']?.toString() ?? '0') ??
              0;
          return yb.compareTo(ya); // Highest yield first
        });
        break;
    }

    return list;
  }

  // Colour for drought tolerance badge
  Color _droughtColor(String? level) {
    switch (level) {
      case 'high':
        return const Color(0xFFB71C1C);
      case 'medium':
        return const Color(0xFFFF6F00);
      default:
        return const Color(0xFF0277BD);
    }
  }

  String _droughtLabel(String? level) {
    switch (level) {
      case 'high':
        return 'Ukame: Juu';
      case 'medium':
        return 'Ukame: Wastani';
      default:
        return 'Ukame: Chini';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mbegu za TOSCI — Tanzania'),
      ),
      body: Column(
        children: [
          // TOSCI source banner
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE8F5E9),
            child: const Row(
              children: [
                Icon(Icons.verified_user,
                    color: Color(0xFF1A5C2E), size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Chanzo: TOSCI • TARI • Wizara ya Kilimo Tanzania',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF1A5C2E)),
                  ),
                ),
              ],
            ),
          ),

          // Crop selector row
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              itemCount: kSeedCrops.length,
              itemBuilder: (context, i) {
                final crop = kSeedCrops[i];
                final selected = crop == _selectedCrop;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(crop),
                    selected: selected,
                    onSelected: (_) {
                      if (!selected) {
                        setState(() => _selectedCrop = crop);
                        _loadVarieties();
                      }
                    },
                    selectedColor: const Color(0xFF1A5C2E),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ),

          // Stress filter row
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              itemCount: kFilters.length,
              itemBuilder: (context, i) {
                final f = kFilters[i];
                final selected = f['key'] == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      f['icon'] as IconData,
                      size: 14,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF1A5C2E),
                    ),
                    label: Text(f['label'] as String),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedFilter = f['key']),
                    selectedColor: const Color(0xFF2E8B57),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 12,
                    ),
                    checkmarkColor: Colors.white,
                  ),
                );
              },
            ),
          ),

          // Search bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Tafuta aina ya mbegu...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Results count
          if (!_loading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${_filtered.length} aina zimepatikana kwa $_selectedCrop',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
            ),

          // Variety cards
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: Color(0xFF1A5C2E)),
                        SizedBox(height: 16),
                        Text(
                          'Inapakia mbegu kutoka TOSCI...',
                          style:
                              TextStyle(color: Color(0xFF9E9E9E)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hii inaweza kuchukua sekunde 10–15',
                          style: TextStyle(
                              color: Color(0xFF9E9E9E), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.grass,
                                size: 60,
                                color: Color(0xFF9E9E9E)),
                            const SizedBox(height: 12),
                            const Text(
                              'Hakuna mbegu zilizopatikana.',
                              style: TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Pakia Tena'),
                              onPressed: _loadVarieties,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          return _SeedCard(
                            variety: _filtered[i],
                            droughtColor: _droughtColor,
                            droughtLabel: _droughtLabel,
                          );
                        },
                      ),
          ),
        ],
      ),

      // Reload FAB
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A5C2E),
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text('Pakia Tena',
            style: TextStyle(color: Colors.white)),
        onPressed: _loadVarieties,
      ),
    );
  }
}

// Card for one seed variety — collapses to summary, expands to full detail
class _SeedCard extends StatelessWidget {
  final Map<String, dynamic> variety;
  final Color Function(String?) droughtColor;
  final String Function(String?) droughtLabel;

  const _SeedCard({
    required this.variety,
    required this.droughtColor,
    required this.droughtLabel,
  });

  @override
  Widget build(BuildContext context) {
    final drought = variety['drought_tolerance']?.toString();
    final dColor = droughtColor(drought);
    final yieldVal =
        variety['yield_potential_ton_ha']?.toString() ?? '—';
    final days = variety['maturity_days']?.toString() ?? '—';
    final category = variety['category'] ?? 'OPV';
    final tosciCertified = variety['tosci_certified'] == true;

    final diseaseList =
        (variety['disease_resistance'] as List?)?.cast<String>() ?? [];
    final pestList =
        (variety['pest_resistance'] as List?)?.cast<String>() ?? [];
    final regions =
        (variety['regions_recommended'] as List?)?.cast<String>() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        // ── Collapsed header ──────────────────────────────────────────
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F5E9),
          child: Text(
            (variety['variety_name'] ?? '?').toString().substring(0, 1),
            style: const TextStyle(
              color: Color(0xFF1A5C2E),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                variety['variety_name'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            if (tosciCertified)
              const Tooltip(
                message: 'Imeidhinishwa na TOSCI',
                child: Icon(Icons.verified,
                    color: Color(0xFF1A5C2E), size: 18),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              variety['company'] ?? '',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 6),
            // Badge row: category + drought + yield + days
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Badge(
                  label: category,
                  color: category == 'Hybrid'
                      ? const Color(0xFF6A1B9A)
                      : const Color(0xFF0277BD),
                ),
                _Badge(
                  label: droughtLabel(drought),
                  color: dColor,
                ),
                _Badge(
                  label: '$yieldVal t/ha',
                  color: const Color(0xFF1A5C2E),
                ),
                _Badge(
                  label: '$days siku',
                  color: const Color(0xFFFF6F00),
                ),
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

                // TOSCI certification number
                if ((variety['tosci_number'] ?? '').isNotEmpty)
                  _Row(
                    icon: Icons.badge,
                    label: 'Nambari ya TOSCI:',
                    value: variety['tosci_number'],
                  ),

                // Year released
                if (variety['year_released'] != null)
                  _Row(
                    icon: Icons.calendar_today,
                    label: 'Mwaka wa kutolewa:',
                    value: variety['year_released'].toString(),
                  ),

                // Planting spacing
                if ((variety['planting_spacing'] ?? '').isNotEmpty)
                  _Row(
                    icon: Icons.grid_on,
                    label: 'Nafasi ya kupanda:',
                    value: variety['planting_spacing'],
                  ),

                // Seed rate
                if (variety['seed_rate_kg_ha'] != null)
                  _Row(
                    icon: Icons.scale,
                    label: 'Mbegu kwa hekta:',
                    value: '${variety['seed_rate_kg_ha']} kg/ha',
                  ),

                // Altitude range
                if ((variety['altitude_range_m'] ?? '').isNotEmpty)
                  _Row(
                    icon: Icons.landscape,
                    label: 'Urefu wa ardhi:',
                    value:
                        '${variety['altitude_range_m']} mita juu ya usawa wa bahari',
                  ),

                // Soil types
                if ((variety['soil_types'] as List?)?.isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Aina ya Udongo:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children:
                        (variety['soil_types'] as List).map((s) {
                      return Chip(
                        label: Text(s.toString(),
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor:
                            const Color(0xFFE8F5E9),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],

                // Disease resistance
                if (diseaseList.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.coronavirus,
                          size: 16, color: Color(0xFF1A5C2E)),
                      SizedBox(width: 6),
                      Text(
                        'Inastahimili Magonjwa:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...diseaseList.map((d) => Padding(
                        padding:
                            const EdgeInsets.only(left: 22, bottom: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.check,
                                size: 14,
                                color: Color(0xFF1A5C2E)),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text(d,
                                    style: const TextStyle(
                                        fontSize: 13))),
                          ],
                        ),
                      )),
                ],

                // Pest resistance
                if (pestList.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.bug_report,
                          size: 16, color: Color(0xFFFF6F00)),
                      SizedBox(width: 6),
                      Text(
                        'Inastahimili Wadudu:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...pestList.map((p) => Padding(
                        padding:
                            const EdgeInsets.only(left: 22, bottom: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.check,
                                size: 14,
                                color: Color(0xFFFF6F00)),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text(p,
                                    style: const TextStyle(
                                        fontSize: 13))),
                          ],
                        ),
                      )),
                ],

                // Water stress rating
                if ((variety['water_stress_rating'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.water_drop,
                            color: Color(0xFF0277BD), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            variety['water_stress_rating'],
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0277BD)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Recommended regions
                if (regions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Mikoa inayopendekezwa:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: regions.map((r) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A5C2E)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          r,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1A5C2E)),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Swahili description
                if ((variety['description_sw'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      variety['description_sw'],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],

                // Best for (Swahili tip)
                if ((variety['best_for_sw'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb,
                            color: Color(0xFFFF6F00), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            variety['best_for_sw'],
                            style: const TextStyle(fontSize: 13),
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

// Small coloured badge widget
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

// One detail row in the expanded card
class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;

  const _Row(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF1A5C2E)),
          const SizedBox(width: 6),
          Text('$label ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: Text(value?.toString() ?? '',
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
