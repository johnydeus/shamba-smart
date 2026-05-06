import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'afisa_farm_detail_screen.dart';

class AfisaHubScreen extends StatefulWidget {
  const AfisaHubScreen({super.key});

  @override
  State<AfisaHubScreen> createState() => _AfisaHubScreenState();
}

class _AfisaHubScreenState extends State<AfisaHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _farms = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  static SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadFarms();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFarms() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load all farms from Supabase
      final farmRows = await _db
          .from('farms')
          .select()
          .order('created_at', ascending: false);

      final farmerIds = (farmRows as List)
          .map((r) => r['farmer_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      // Load farmer profiles for all those IDs
      Map<String, Map<String, dynamic>> profileMap = {};
      if (farmerIds.isNotEmpty) {
        final profileRows = await _db
            .from('profiles')
            .select('id, first_name, last_name, email, role, region')
            .inFilter('id', farmerIds);
        for (final p in profileRows as List) {
          profileMap[p['id'] as String] = Map<String, dynamic>.from(p);
        }
      }

      // Merge farm + farmer info
      final merged = <Map<String, dynamic>>[];
      for (final farm in farmRows) {
        final farmerId = farm['farmer_id'] as String? ?? '';
        final profile = profileMap[farmerId] ?? {};
        merged.add({
          ...Map<String, dynamic>.from(farm),
          'farmer_first_name': profile['first_name'] ?? 'Mkulima',
          'farmer_last_name':  profile['last_name']  ?? '',
          'farmer_role':       profile['role']        ?? 'mkulima',
          'farmer_region':     profile['region']      ?? '',
          'farmer_email':      profile['email']       ?? '',
        });
      }

      if (mounted) setState(() { _farms = merged; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _farms;
    final q = _search.toLowerCase();
    return _farms.where((f) {
      final name    = (f['name']              as String? ?? '').toLowerCase();
      final farmer  = ('${f['farmer_first_name']} ${f['farmer_last_name']}').toLowerCase();
      final region  = (f['region']            as String? ?? '').toLowerCase();
      final crops   = ((f['crops'] as List?)?.join(' ') ?? '').toLowerCase();
      return name.contains(q) || farmer.contains(q) ||
             region.contains(q) || crops.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _mappable =>
      _filtered.where((f) => f['gps_lat'] != null && f['gps_lng'] != null).toList();

  void _openFarm(Map<String, dynamic> farm) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => AfisaFarmDetailScreen(farmData: farm)));
  }

  @override
  Widget build(BuildContext context) {
    final afisa = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashibodi ya Afisa',
                style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            if (afisa?.district != null)
              Text('📍 ${afisa!.district}',
                  style: GoogleFonts.dmSans(
                      color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Onyesha upya',
            onPressed: _loadFarms,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tafuta shamba, mkulima au mkoa...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            })
                        : null,
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              TabBar(
                controller: _tabs,
                indicatorColor: AppColors.harvest,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(icon: const Icon(Icons.map_outlined, size: 18),
                      text: 'Ramani (${_mappable.length})'),
                  Tab(icon: const Icon(Icons.list_alt_outlined, size: 18),
                      text: 'Orodha (${_filtered.length})'),
                ],
              ),
            ],
          ),
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.leaf))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadFarms)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _MapTab(farms: _mappable, onTap: _openFarm),
                    _ListTab(farms: _filtered, onTap: _openFarm),
                  ],
                ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1: RAMANI
// ══════════════════════════════════════════════════════════════════════════════

class _MapTab extends StatelessWidget {
  final List<Map<String, dynamic>> farms;
  final ValueChanged<Map<String, dynamic>> onTap;
  const _MapTab({required this.farms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (farms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Hakuna mashamba yenye GPS',
                style: GoogleFonts.playfairDisplay(
                    color: AppColors.soil, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Wakulima waweke GPS kwanza',
                style: GoogleFonts.dmSans(color: AppColors.mid, fontSize: 13)),
          ],
        ),
      );
    }

    // Centre map on first farm
    final centre = LatLng(
      farms.first['gps_lat'] as double,
      farms.first['gps_lng'] as double,
    );

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            // ignore: deprecated_member_use
            initialCenter: centre,
            // ignore: deprecated_member_use
            initialZoom: 9,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.shamba.smart',
            ),
            MarkerLayer(
              markers: farms.map((farm) {
                final lat = farm['gps_lat'] as double;
                final lng = farm['gps_lng'] as double;
                final name = farm['name'] as String? ?? 'Shamba';
                final farmer =
                    '${farm['farmer_first_name']} ${farm['farmer_last_name']}'.trim();
                return Marker(
                  point: LatLng(lat, lng),
                  width: 180,
                  height: 56,
                  child: GestureDetector(
                    onTap: () => onTap(farm),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.leaf,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26, blurRadius: 4)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(name,
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                              Text(farmer,
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white70, fontSize: 9),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const Icon(Icons.location_on,
                            color: AppColors.leaf, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // Farm count badge
        Positioned(
          top: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.soil,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${farms.length} mashamba kwenye ramani',
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2: ORODHA
// ══════════════════════════════════════════════════════════════════════════════

class _ListTab extends StatelessWidget {
  final List<Map<String, dynamic>> farms;
  final ValueChanged<Map<String, dynamic>> onTap;
  const _ListTab({required this.farms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (farms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌾', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Hakuna mashamba',
                style: GoogleFonts.playfairDisplay(
                    color: AppColors.soil, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: farms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _FarmListCard(
          farm: farms[i], onTap: () => onTap(farms[i])),
    );
  }
}

class _FarmListCard extends StatelessWidget {
  final Map<String, dynamic> farm;
  final VoidCallback onTap;
  const _FarmListCard({required this.farm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name     = farm['name']   as String? ?? 'Shamba';
    final region   = farm['region'] as String? ?? '';
    final crops    = (farm['crops'] as List?)?.cast<String>() ?? [];
    final acres    = (farm['acres'] as num?)?.toDouble() ?? 0;
    final hasGps   = farm['gps_lat'] != null;
    final farmer   = '${farm['farmer_first_name'] ?? ''} ${farm['farmer_last_name'] ?? ''}'.trim();
    final role     = UserRoleX.fromKey(farm['farmer_role'] as String? ?? 'mkulima');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: AppColors.leaf.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: Text('🌾', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 12, color: AppColors.mid),
                        const SizedBox(width: 4),
                        Text(farmer.isEmpty ? 'Mkulima' : farmer,
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: AppColors.mid)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.roleColor(role)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(role.shortLabel,
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: AppColors.roleColor(role),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: AppColors.mid),
                        const SizedBox(width: 3),
                        Text(region,
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppColors.mid)),
                        const SizedBox(width: 8),
                        const Icon(Icons.straighten,
                            size: 12, color: AppColors.mid),
                        const SizedBox(width: 3),
                        Text('${acres.toStringAsFixed(1)} ekari',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppColors.mid)),
                        if (hasGps) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.gps_fixed,
                              size: 12, color: AppColors.leaf),
                        ],
                      ],
                    ),
                    if (crops.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(crops.take(3).join(' • '),
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.harvest,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.mid),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Hitilafu ya kupakia mashamba',
                  style: GoogleFonts.playfairDisplay(
                      color: AppColors.soil, fontSize: 16)),
              const SizedBox(height: 8),
              Text(error,
                  style: GoogleFonts.dmSans(
                      color: AppColors.mid, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Jaribu Tena'),
              ),
            ],
          ),
        ),
      );
}
