import 'package:flutter/material.dart';
import '../services/data_sync_service.dart';
import '../services/local_data.dart';

class PesticidesScreen extends StatefulWidget {
  const PesticidesScreen({super.key});

  @override
  State<PesticidesScreen> createState() => _PesticidesScreenState();
}

class _PesticidesScreenState extends State<PesticidesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _allPesticides = [];
  bool _loading = true;
  String _searchQuery = '';

  // Category tabs
  final List<String> _categories = [
    'Zote',
    'Insecticide',
    'Fungicide',
    'Herbicide',
    'Biopesticide',
  ];

  // Swahili labels for each category
  final Map<String, String> _categoryLabels = {
    'Zote': 'Zote',
    'Insecticide': 'Dawa za Wadudu',
    'Fungicide': 'Dawa za Ukungu',
    'Herbicide': 'Dawa za Magugu',
    'Biopesticide': 'Dawa za Asili',
  };

  // Colours for each category badge
  final Map<String, Color> _categoryColors = {
    'Insecticide': const Color(0xFFB71C1C),
    'Fungicide': const Color(0xFF1A5C2E),
    'Herbicide': const Color(0xFFFF6F00),
    'Biopesticide': const Color(0xFF0277BD),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load pesticides: local data instantly, Claude updates in background
  Future<void> _loadData() async {
    setState(() => _loading = true);

    // Step 1 — local data instantly
    setState(() {
      _allPesticides = LocalData.pesticides;
      _loading = false;
    });

    // Step 2 — try Claude silently in background
    DataSyncService.fetchPesticidesDatabase().then((fresh) {
      if (fresh.isNotEmpty && mounted) {
        setState(() => _allPesticides = fresh);
      }
    });
  }

  // Filter list by selected category and search text
  List<Map<String, dynamic>> get _filtered {
    final category = _categories[_tabController.index];
    return _allPesticides.where((p) {
      final matchesCategory =
          category == 'Zote' || p['category'] == category;
      final matchesSearch = _searchQuery.isEmpty ||
          (p['brand_name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (p['active_ingredient'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (p['target_pests'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dawa za Kilimo — Tanzania'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: _categories
              .map((c) => Tab(text: _categoryLabels[c] ?? c))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // Source info banner
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE8F5E9),
            child: const Row(
              children: [
                Icon(Icons.verified, color: Color(0xFF1A5C2E), size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Chanzo: TFDA • TPRI Tanzania • Wizara ya Kilimo',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF1A5C2E)),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Tafuta dawa, wadudu, au zao...',
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

          // Content
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
                          'Inapakia data kutoka TFDA / TPRI...',
                          style: TextStyle(color: Color(0xFF9E9E9E)),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 48, color: Color(0xFF9E9E9E)),
                            const SizedBox(height: 12),
                            const Text('Hakuna dawa iliyopatikana.',
                                style:
                                    TextStyle(color: Color(0xFF9E9E9E))),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Jaribu Tena'),
                              onPressed: _loadData,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          return _PesticideCard(
                            pesticide: _filtered[index],
                            categoryColors: _categoryColors,
                          );
                        },
                      ),
          ),
        ],
      ),

      // Refresh button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A5C2E),
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text('Sasisha',
            style: TextStyle(color: Colors.white)),
        onPressed: _loadData,
      ),
    );
  }
}

// Card widget for a single pesticide
class _PesticideCard extends StatelessWidget {
  final Map<String, dynamic> pesticide;
  final Map<String, Color> categoryColors;

  const _PesticideCard({
    required this.pesticide,
    required this.categoryColors,
  });

  @override
  Widget build(BuildContext context) {
    final category = pesticide['category'] ?? 'Insecticide';
    final color = categoryColors[category] ?? const Color(0xFF1A5C2E);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        // Collapsed view: brand name + category badge
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(_categoryIcon(category), color: color, size: 20),
        ),
        title: Text(
          pesticide['brand_name'] ?? '',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pesticide['active_ingredient'] ?? '',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _swahiliCategory(category),
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                if (pesticide['tpri_registered'] == true) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified,
                      size: 14, color: Color(0xFF1A5C2E)),
                  const Text(' TPRI',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF1A5C2E))),
                ],
              ],
            ),
          ],
        ),

        // Expanded view: full details
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),

                // Target pests
                if ((pesticide['target_pests'] ?? '').isNotEmpty)
                  _DetailRow(
                    icon: Icons.bug_report,
                    label: 'Wadudu / Magonjwa:',
                    value: pesticide['target_pests'],
                    color: color,
                  ),

                // Target crops
                if ((pesticide['target_crops'] ?? '').isNotEmpty)
                  _DetailRow(
                    icon: Icons.grass,
                    label: 'Mazao:',
                    value: pesticide['target_crops'],
                    color: color,
                  ),

                // Dose
                if ((pesticide['dose_per_15L'] ?? '').isNotEmpty)
                  _DetailRow(
                    icon: Icons.water_drop,
                    label: 'Kipimo kwa dumu la 15L:',
                    value: pesticide['dose_per_15L'],
                    color: color,
                  ),

                // PHI
                if (pesticide['phi_days'] != null)
                  _DetailRow(
                    icon: Icons.timer,
                    label: 'Muda wa kusubiri (PHI):',
                    value: '${pesticide['phi_days']} siku kabla ya kuvuna',
                    color: color,
                  ),

                // Price
                if ((pesticide['price_range_tzs'] ?? '').isNotEmpty)
                  _DetailRow(
                    icon: Icons.attach_money,
                    label: 'Bei takriban:',
                    value: 'TZS ${pesticide['price_range_tzs']}',
                    color: color,
                  ),

                // Manufacturer
                if ((pesticide['manufacturer'] ?? '').isNotEmpty)
                  _DetailRow(
                    icon: Icons.factory,
                    label: 'Mtengenezaji:',
                    value: pesticide['manufacturer'],
                    color: color,
                  ),

                // Description
                if ((pesticide['description_sw'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pesticide['description_sw'],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],

                // Safety warning
                if ((pesticide['safety_sw'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Color(0xFFFF6F00), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pesticide['safety_sw'],
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

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Fungicide':
        return Icons.coronavirus;
      case 'Herbicide':
        return Icons.grass;
      case 'Biopesticide':
        return Icons.eco;
      default:
        return Icons.bug_report;
    }
  }

  String _swahiliCategory(String category) {
    switch (category) {
      case 'Insecticide':
        return 'Dawa ya Wadudu';
      case 'Fungicide':
        return 'Dawa ya Ukungu';
      case 'Herbicide':
        return 'Dawa ya Magugu';
      case 'Biopesticide':
        return 'Dawa ya Asili';
      default:
        return category;
    }
  }
}

// One detail row inside the expanded card
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text('$label ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
