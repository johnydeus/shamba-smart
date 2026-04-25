import 'package:flutter/material.dart';
import '../services/data_sync_service.dart';
import '../services/local_data.dart';

const List<String> kMarketCrops = [
  'Zote',
  'Mahindi',
  'Nyanya',
  'Maharagwe',
  'Pilipili hoho',
  'Ndizi',
  'Mchele',
  'Muhogo',
  'Pamba',
  'Alizeti',
  'Viazi vitamu',
  'Vitunguu',
];

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _selectedCrop = 'Zote';
  List<Map<String, dynamic>> _allPrices = [];
  bool _loading = true;
  String _lastUpdated = '';

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  // Load prices: show local data instantly, then try Claude in background
  Future<void> _loadPrices() async {
    setState(() => _loading = true);

    // Step 1 — show local data immediately (instant, no internet needed)
    final local = LocalData.marketPrices;
    setState(() {
      _allPrices = local;
      _loading = false;
      _lastUpdated =
          'Imesasishwa: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    });

    // Step 2 — try Claude in background for fresher prices (silent update)
    DataSyncService.fetchLiveMarketPrices().then((fresh) {
      if (fresh.isNotEmpty && mounted) {
        setState(() => _allPrices = fresh);
      }
    });
  }

  // Filter prices by selected crop
  List<Map<String, dynamic>> get _filtered {
    if (_selectedCrop == 'Zote') return _allPrices;
    return _allPrices
        .where((p) => p['crop_name'] == _selectedCrop)
        .toList();
  }

  // Map trend string to icon and colour
  Color _trendColor(String? trend) {
    switch (trend) {
      case 'inapanda':
        return const Color(0xFF1A5C2E);
      case 'inashuka':
        return const Color(0xFFB71C1C);
      default:
        return const Color(0xFFFF6F00);
    }
  }

  IconData _trendIcon(String? trend) {
    switch (trend) {
      case 'inapanda':
        return Icons.trending_up;
      case 'inashuka':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bei za Mazao Tanzania'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sasisha bei',
            onPressed: _loadPrices,
          ),
        ],
      ),
      body: Column(
        children: [
          // Source banner
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE8F5E9),
            child: Row(
              children: [
                const Icon(Icons.source, color: Color(0xFF1A5C2E), size: 16),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Chanzo: Wizara ya Kilimo • TanTrade • Masoko ya Tanzania',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF1A5C2E)),
                  ),
                ),
                if (_lastUpdated.isNotEmpty)
                  Text(
                    _lastUpdated,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF9E9E9E)),
                  ),
              ],
            ),
          ),

          // Crop filter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              itemCount: kMarketCrops.length,
              itemBuilder: (context, index) {
                final crop = kMarketCrops[index];
                final selected = crop == _selectedCrop;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(crop),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCrop = crop),
                    selectedColor: const Color(0xFF1A5C2E),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                    checkmarkColor: Colors.white,
                  ),
                );
              },
            ),
          ),

          // Price list
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
                          'Inapakua bei kutoka masokoni...',
                          style:
                              TextStyle(color: Color(0xFF9E9E9E)),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Hakuna bei zilizopatikana.',
                          style:
                              TextStyle(color: Color(0xFF9E9E9E)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final p = _filtered[index];
                          final trend = p['trend']?.toString();
                          final tColor = _trendColor(trend);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE8F5E9),
                                child: Text(
                                  (p['crop_name'] ?? '?')
                                      .toString()
                                      .substring(0, 1),
                                  style: const TextStyle(
                                    color: Color(0xFF1A5C2E),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                p['crop_name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['market_name'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 13),
                                  ),
                                  if ((p['source'] ?? '').isNotEmpty)
                                    Text(
                                      p['source'],
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9E9E9E)),
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'TZS ${p['price_tzs_kg']}/kg',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_trendIcon(trend),
                                          size: 14, color: tColor),
                                      const SizedBox(width: 2),
                                      Text(
                                        trend ?? 'imara',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: tColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
