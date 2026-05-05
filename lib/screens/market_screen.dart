import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/data_sync_service.dart';
import '../services/local_data.dart';
import 'messages_screen.dart';

const _kLastPriceUpdate = 'market_last_update';

const List<String> kMarketCrops = [
  'Zote', 'Mahindi', 'Nyanya', 'Maharagwe', 'Pilipili hoho',
  'Ndizi', 'Mchele', 'Muhogo', 'Pamba', 'Alizeti',
  'Viazi vitamu', 'Vitunguu', 'Karoti', 'Kabichi',
  'Sukuma wiki', 'Embe', 'Avokado', 'Kahawa', 'Korosho',
  'Karanga', 'Soya', 'Viazi',
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
  Timer? _dailyTimer;

  @override
  void initState() {
    super.initState();
    _loadPrices();
    // Re-check prices every hour while the screen is open
    _dailyTimer = Timer.periodic(const Duration(hours: 1), (_) => _loadPrices());
  }

  @override
  void dispose() {
    _dailyTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrices({bool forceRefresh = false}) async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString(_kLastPriceUpdate) ?? '';
    final today = _todayKey();
    final isFresh = lastUpdate == today && !forceRefresh;

    // Show local data immediately
    setState(() {
      _allPrices = LocalData.marketPrices;
      _loading = false;
      _lastUpdated = isFresh
          ? 'Imesasishwa leo ✓'
          : 'Inasasisha bei za leo...';
    });

    if (!isFresh) {
      // Fetch fresh prices from Claude in background
      DataSyncService.fetchLiveMarketPrices().then((fresh) async {
        if (fresh.isNotEmpty && mounted) {
          await prefs.setString(_kLastPriceUpdate, today);
          setState(() {
            _allPrices = fresh;
            _lastUpdated =
                'Imesasishwa leo ${TimeOfDay.now().format(context)} ✓';
          });
        } else if (mounted) {
          setState(() => _lastUpdated = 'Bei za hifadhi (hakuna mtandao)');
        }
      });
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedCrop == 'Zote') return _allPrices;
    return _allPrices.where((p) => p['crop_name'] == _selectedCrop).toList();
  }

  Color _trendColor(String? t) => switch (t) {
        'inapanda' => const Color(0xFF1A5C2E),
        'inashuka' => const Color(0xFFB71C1C),
        _ => const Color(0xFFFF6F00),
      };

  IconData _trendIcon(String? t) => switch (t) {
        'inapanda' => Icons.trending_up,
        'inashuka' => Icons.trending_down,
        _ => Icons.trending_flat,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bei za Mazao Tanzania'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sasisha bei sasa',
            onPressed: () => _loadPrices(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Source + last-updated banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE8F5E9),
            child: Row(
              children: [
                const Icon(Icons.source, color: Color(0xFF1A5C2E), size: 16),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Chanzo: Wizara ya Kilimo • TanTrade • Masoko ya Tanzania',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1A5C2E)),
                  ),
                ),
                if (_lastUpdated.isNotEmpty)
                  Text(_lastUpdated,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),

          // "Pata Muuzaji" CTA banner
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MessagesScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF1B4332),
              child: Row(
                children: [
                  const Icon(Icons.people_outline,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tafuta wakulima / wafanyabiashara wa zao unalotaka',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),

          // Crop filter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: kMarketCrops.length,
              itemBuilder: (context, i) {
                final crop = kMarketCrops[i];
                final sel = crop == _selectedCrop;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(crop),
                    selected: sel,
                    onSelected: (_) => setState(() => _selectedCrop = crop),
                    selectedColor: const Color(0xFF1A5C2E),
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : Colors.black87,
                        fontSize: 13),
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
                        CircularProgressIndicator(color: Color(0xFF1A5C2E)),
                        SizedBox(height: 16),
                        Text('Inapakua bei kutoka masokoni...',
                            style: TextStyle(color: Color(0xFF9E9E9E))),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('Hakuna bei zilizopatikana.',
                            style: TextStyle(color: Color(0xFF9E9E9E))))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) =>
                            _PriceCard(
                              price: _filtered[i],
                              trendColor: _trendColor,
                              trendIcon: _trendIcon,
                            ),
                      ),
          ),
        ],
      ),

      // FAB: Post your own price / find a seller
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B4332),
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text('Wasiliana na Wakulima',
            style: TextStyle(color: Colors.white, fontSize: 13)),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MessagesScreen())),
      ),
    );
  }
}

// ── Price card with contact button ───────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final Map<String, dynamic> price;
  final Color Function(String?) trendColor;
  final IconData Function(String?) trendIcon;

  const _PriceCard({
    required this.price,
    required this.trendColor,
    required this.trendIcon,
  });

  @override
  Widget build(BuildContext context) {
    final trend   = price['trend']?.toString();
    final tColor  = trendColor(trend);
    final cropName = price['crop_name'] as String? ?? '';
    final market   = price['market_name'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Crop avatar
            CircleAvatar(
              backgroundColor: const Color(0xFFE8F5E9),
              radius: 22,
              child: Text(
                cropName.isNotEmpty ? cropName[0] : '?',
                style: const TextStyle(
                    color: Color(0xFF1A5C2E),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),

            // Crop name + market
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cropName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(market,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  if ((price['source'] ?? '').isNotEmpty)
                    Text(price['source'].toString(),
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF9E9E9E))),
                ],
              ),
            ),

            // Price + trend
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TZS ${price['price_tzs_kg']}/kg',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tColor,
                      fontSize: 13),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon(trend), size: 13, color: tColor),
                    const SizedBox(width: 2),
                    Text(trend ?? 'imara',
                        style: TextStyle(fontSize: 10, color: tColor)),
                  ],
                ),
                const SizedBox(height: 6),
                // Contact button
                GestureDetector(
                  onTap: () => _openChat(context, cropName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4332),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Wasiliana',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context, String cropName) {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingia kwanza ili uwasiliane na wakulima.')),
      );
      return;
    }

    if (!chat.isReady) {
      // Navigate to the directory tab of messages screen to find farmers of this crop
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MessagesScreen()));
      return;
    }

    // Navigate to user directory so they can pick a seller for this crop
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tafuta mkulima wa $cropName kwenye orodha ya watumiaji.'),
        action: SnackBarAction(
          label: 'Nenda',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MessagesScreen())),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
