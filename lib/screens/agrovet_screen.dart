import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/data_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_skeleton.dart';

const List<String> kRegions = [
  'Morogoro', 'Kilosa', 'Pwani', 'Arusha',
  'Iringa', 'Mbeya', 'Dodoma', 'Dar es Salaam',
  'Mwanza', 'Tanga', 'Kagera', 'Mara',
];

class AgrovetScreen extends StatefulWidget {
  const AgrovetScreen({super.key});

  @override
  State<AgrovetScreen> createState() => _AgrovetScreenState();
}

class _AgrovetScreenState extends State<AgrovetScreen> {
  String _selectedRegion = 'Morogoro';
  List<Map<String, dynamic>> _agrovets = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAgrovets();
  }

  Future<void> _loadAgrovets() async {
    setState(() => _loading = true);

    final results =
        await DataSyncService.fetchAgrovets(_selectedRegion);

    setState(() {
      _agrovets = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maduka ya Dawa za Kilimo'),
      ),
      body: Column(
        children: [
          // Source banner
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE8F5E9),
            child: const Row(
              children: [
                Icon(Icons.store, color: Color(0xFF1A5C2E), size: 16),
                SizedBox(width: 6),
                Text(
                  'Maduka yaliyohakikishwa Tanzania',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF1A5C2E)),
                ),
              ],
            ),
          ),

          // Region selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedRegion,
              decoration: InputDecoration(
                labelText: 'Chagua Mkoa',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: kRegions
                  .map((r) =>
                      DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedRegion = val);
                  _loadAgrovets();
                }
              },
            ),
          ),

          // List of agrovets
          Expanded(
            child: _loading
                ? ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: 5,
                    itemBuilder: (_, __) => const SkeletonCard(),
                  )
                : _agrovets.isEmpty
                    ? EmptyState(
                        emoji: '🏪',
                        title: 'Hakuna maduka',
                        subtitle: 'Hakuna maduka yaliyopatikana katika mkoa huu.',
                        buttonLabel: 'Jaribu Tena',
                        onButtonTap: _loadAgrovets,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12),
                        itemCount: _agrovets.length,
                        itemBuilder: (context, index) {
                          final shop = _agrovets[index];
                          final stock = shop['stock_status']
                                  ?.toString() ??
                              'available';
                          final distance =
                              shop['distance_km']?.toString();
                          final phone =
                              shop['phone']?.toString() ?? '';

                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppRadius.lg),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: const Icon(
                                      Icons.store_outlined,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                shop['shop_name'] ??
                                                    'Duka',
                                                style: GoogleFonts.poppins(
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            if (shop['verified'] == true)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primarySoft,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.verified_outlined,
                                                      color: AppColors.primary,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'Imethibitishwa',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (distance != null) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.infoBg,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.place_outlined,
                                                  size: 12,
                                                  color: AppColors.info,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$distance km',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: AppColors.info,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        _StockChip(status: stock),
                                        if ((shop['area'] ?? '')
                                            .isNotEmpty)
                                          Text(
                                            '${shop['area']}, ${shop['region'] ?? _selectedRegion}',
                                            style: const TextStyle(
                                                color: Color(
                                                    0xFF9E9E9E),
                                                fontSize: 13),
                                          ),
                                        if ((shop['products'] ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            shop['products'],
                                            style: const TextStyle(
                                                fontSize: 12),
                                          ),
                                        ],
                                        if ((shop['opening_hours'] ??
                                                '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.access_time,
                                                  size: 13,
                                                  color: Color(
                                                      0xFF9E9E9E)),
                                              const SizedBox(
                                                  width: 4),
                                              Text(
                                                shop['opening_hours'],
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(
                                                        0xFF9E9E9E)),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (phone.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: () => launchUrl(
                                              Uri.parse('tel:$phone'),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primarySoft,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.phone_outlined,
                                                    size: 16,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    phone,
                                                    style: GoogleFonts.poppins(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate(
                                  delay:
                                      Duration(milliseconds: index * 60))
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: 0.05, end: 0);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  final String status;
  const _StockChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status.toLowerCase()) {
      'unavailable' || 'haipatikani' => (
          'Haipatikani',
          AppColors.criticalBg,
          AppColors.critical
        ),
      'check' || 'angalia' => (
          'Angalia Stoo',
          AppColors.warningBg,
          AppColors.warning
        ),
      _ => ('Inapatikana', AppColors.successBg, AppColors.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
