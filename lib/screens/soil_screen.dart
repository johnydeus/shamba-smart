import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../features/soil/data/crop_requirement_service.dart';
import '../features/soil/data/soil_crop_matcher.dart';
import '../models/soil_data_model.dart';
import '../services/claude_service.dart';
import '../services/location_service.dart';
import '../services/soil_service.dart';
import '../theme/app_colors.dart';
import '../widgets/soil/crop_suitability_chart.dart';
import '../widgets/soil/soil_nutrient_chart.dart';

class SoilScreen extends StatefulWidget {
  // When opened from FarmDetailScreen, use the farm's pinned GPS
  final double? farmLat;
  final double? farmLng;
  final String? farmName;

  const SoilScreen({super.key, this.farmLat, this.farmLng, this.farmName});

  @override
  State<SoilScreen> createState() => _SoilScreenState();
}

class _SoilScreenState extends State<SoilScreen> {
  SoilDataModel? _soilData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFromCache = false;

  // Crop advisory state
  String? _advisoryText;
  bool _advisoryLoading = false;
  bool _advisoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    final cached = await SoilService.getCachedResult();
    if (cached != null && mounted) {
      setState(() {
        _soilData = cached;
        _isFromCache = true;
      });
    }
  }

  Future<void> _fetchSoilData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      double lat, lng;
      // Use farm's pinned GPS if provided, otherwise use device GPS
      if (widget.farmLat != null && widget.farmLng != null) {
        lat = widget.farmLat!;
        lng = widget.farmLng!;
      } else {
        final position = await LocationService.getCurrentLocation();
        lat = position.latitude;
        lng = position.longitude;
      }
      final data = await SoilService.getSoilData(lat, lng);
      await SoilService.cacheResult(data);
      if (mounted) {
        setState(() {
          _soilData = data;
          _isFromCache = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: Text(widget.farmName != null
            ? 'Udongo — ${widget.farmName}'
            : 'Udongo wa Shamba 🌱'),
        actions: [
          if (_soilData != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Pata data mpya',
              onPressed: _isLoading ? null : _fetchSoilData,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntroCard(),
            const SizedBox(height: 12),
            _buildLocationButton(),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              _buildLoading(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildError(),
            ],
            if (_soilData != null) ...[
              if (_isFromCache) ...[
                const SizedBox(height: 12),
                _buildCacheNotice(),
              ],
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 12),
              _buildPhCard(),
              const SizedBox(height: 12),
              _buildTextureCard(),
              const SizedBox(height: 12),
              _buildNutrientsCard(),
              const SizedBox(height: 12),
              _buildCropSuitabilityCard(),
              const SizedBox(height: 12),
              _buildRecommendationCard(),
              const SizedBox(height: 12),
              _buildAdvisoryCard(),
              const SizedBox(height: 16),
              _buildMap(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  // ── Intro card ────────────────────────────────────────────

  Widget _buildIntroCard() => Card(
        color: AppColors.leaf.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.leaf, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Gonga kitufe hapa chini kupata data za udongo wa shamba '
                  'lako kwa kutumia GPS yako. Data zinatoka SoilGrids (ISRIC) '
                  '— bure kabisa na sahihi.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );

  // ── Main fetch button ─────────────────────────────────────

  Widget _buildLocationButton() => ElevatedButton.icon(
        onPressed: _isLoading ? null : _fetchSoilData,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: Text(
          _isLoading ? 'Inatafuta GPS na data...' : 'Pata Data za Udongo',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ),
      );

  // ── Loading indicator ─────────────────────────────────────

  Widget _buildLoading() => const Column(
        children: [
          CircularProgressIndicator(color: AppColors.leaf),
          SizedBox(height: 12),
          Text(
            'Inapata GPS na data za udongo...\n(inaweza chukua sekunde 10–20)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );

  // ── Error card ────────────────────────────────────────────

  Widget _buildError() => Card(
        color: const Color(0xFFFFEBEE),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFB71C1C)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage ?? '',
                      style: const TextStyle(
                          color: Color(0xFFB71C1C), fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _fetchSoilData,
                icon: const Icon(Icons.refresh),
                label: const Text('Jaribu Tena'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB71C1C),
                  side: const BorderSide(color: Color(0xFFB71C1C)),
                ),
              ),
            ],
          ),
        ),
      );

  // ── Offline cache notice ──────────────────────────────────

  Widget _buildCacheNotice() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.offline_pin, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hizi ni data za mwisho zilizohifadhiwa (offline) — '
                '${DateFormat('dd/MM/yyyy HH:mm').format(_soilData!.timestamp)}',
                style: const TextStyle(fontSize: 12, color: Colors.brown),
              ),
            ),
          ],
        ),
      );

  // ── Location card ─────────────────────────────────────────

  Widget _buildLocationCard() => _SectionCard(
        title: 'Eneo la Shamba',
        icon: Icons.place,
        iconColor: const Color(0xFF1A5C2E),
        child: Column(
          children: [
            _InfoRow(
              Icons.navigation,
              'Latitudo',
              _soilData!.latitude.toStringAsFixed(6),
            ),
            _InfoRow(
              Icons.navigation_outlined,
              'Longitudo',
              _soilData!.longitude.toStringAsFixed(6),
            ),
            _InfoRow(
              Icons.location_city,
              'Mkoa',
              LocationService.regionFromCoords(
                  _soilData!.latitude, _soilData!.longitude),
            ),
          ],
        ),
      );

  // ── pH card ───────────────────────────────────────────────

  Widget _buildPhCard() {
    final ph = _soilData!.ph;
    final color = _phColor(ph);
    final label = _phLabel(ph);
    final emoji = _phEmoji(ph);

    return _SectionCard(
      title: 'pH ya Udongo',
      icon: Icons.science,
      iconColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                ph != null ? ph.toStringAsFixed(1) : '—',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$emoji $label',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: color)),
                    const SizedBox(height: 4),
                    Text(
                      _phAdvice(ph),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // pH scale bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(flex: 2, child: Container(color: Colors.red.shade300)),
                  Expanded(flex: 1, child: Container(color: Colors.orange.shade300)),
                  Expanded(flex: 2, child: Container(color: Colors.green.shade400)),
                  Expanded(flex: 1, child: Container(color: Colors.orange.shade300)),
                  Expanded(flex: 2, child: Container(color: Colors.red.shade300)),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('4.5', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('6.0', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('7.0', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('8.0', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _phColor(double? ph) {
    if (ph == null) return Colors.grey;
    if (ph < 5.5) return const Color(0xFFB71C1C);
    if (ph < 6.5) return Colors.orange.shade700;
    if (ph <= 7.0) return const Color(0xFF2E7D32);
    if (ph <= 7.5) return Colors.orange.shade700;
    return const Color(0xFFB71C1C);
  }

  String _phLabel(double? ph) {
    if (ph == null) return 'Haijulikani';
    if (ph < 5.5) return 'Tindikali Sana (Acidic)';
    if (ph < 6.5) return 'Tindikali Kidogo';
    if (ph <= 7.0) return 'Wastani Mzuri (Neutral)';
    if (ph <= 7.5) return 'Alkali Kidogo';
    return 'Alkali Sana';
  }

  String _phEmoji(double? ph) {
    if (ph == null) return '❓';
    if (ph < 5.5) return '🔴';
    if (ph < 6.5) return '🟡';
    if (ph <= 7.0) return '🟢';
    if (ph <= 7.5) return '🟡';
    return '🔴';
  }

  String _phAdvice(double? ph) {
    if (ph == null) return 'Data haijapatikana';
    if (ph < 5.5) return 'Ongeza chokaa (lime)';
    if (ph < 6.5) return 'Nzuri kwa mazao mengi';
    if (ph <= 7.0) return 'Bora kabisa — hakuna hatua';
    if (ph <= 7.5) return 'Angalia mbolea unayotumia';
    return 'Ongeza sulfuri kupunguza pH';
  }

  // ── Texture card ──────────────────────────────────────────

  Widget _buildTextureCard() {
    final sand = _soilData!.sand;
    final clay = _soilData!.clay;
    final silt = _soilData!.silt;
    final total = (sand ?? 0) + (clay ?? 0) + (silt ?? 0);
    final hasData = total > 0;

    return _SectionCard(
      title: 'Muundo wa Udongo (Texture)',
      icon: Icons.layers,
      iconColor: const Color(0xFF7A5C3A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _soilData!.textureClass,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 12),
          if (hasData) ...[
            // Stacked proportional bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    if ((sand ?? 0) > 0)
                      Expanded(
                        flex: ((sand ?? 0) / total * 100).round(),
                        child: Container(
                          color: const Color(0xFFFFD166),
                          alignment: Alignment.center,
                          child: sand! > 20
                              ? Text(
                                  '${sand.round()}%',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown),
                                )
                              : null,
                        ),
                      ),
                    if ((clay ?? 0) > 0)
                      Expanded(
                        flex: ((clay ?? 0) / total * 100).round(),
                        child: Container(
                          color: const Color(0xFF7A5C3A),
                          alignment: Alignment.center,
                          child: clay! > 20
                              ? Text(
                                  '${clay.round()}%',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                    if ((silt ?? 0) > 0)
                      Expanded(
                        flex: ((silt ?? 0) / total * 100).round(),
                        child: Container(
                          color: const Color(0xFF9E9E9E),
                          alignment: Alignment.center,
                          child: silt! > 20
                              ? Text(
                                  '${silt.round()}%',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Legend — Wrap prevents overflow on narrow screens
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _LegendDot(
                    color: const Color(0xFFFFD166),
                    label: 'Mchanga',
                    value: sand),
                _LegendDot(
                    color: const Color(0xFF7A5C3A),
                    label: 'Udongo',
                    value: clay),
                _LegendDot(
                    color: const Color(0xFF9E9E9E),
                    label: 'Laini',
                    value: silt),
              ],
            ),
          ] else
            const Text('Data ya muundo wa udongo haijapatikana',
                style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Nutrients card ────────────────────────────────────────

  Widget _buildNutrientsCard() => _SectionCard(
        title: 'Virutubisho vya Udongo',
        icon: Icons.eco,
        iconColor: AppColors.leaf,
        child: Column(
          children: [
            _NutrientRow(
              icon: Icons.grass,
              label: 'Nitrojeni (N)',
              value: _soilData!.nitrogen != null
                  ? '${_soilData!.nitrogen!.toStringAsFixed(2)} g/kg'
                  : 'Haijulikani',
              status: _nutrientStatus(_soilData!.nitrogen, 0.8, 1.5),
            ),
            const Divider(height: 20),
            _NutrientRow(
              icon: Icons.compost,
              label: 'Kaboni ya Udongo (SOC)',
              value: _soilData!.organicCarbon != null
                  ? '${_soilData!.organicCarbon!.toStringAsFixed(1)} g/kg'
                  : 'Haijulikani',
              status: _nutrientStatus(_soilData!.organicCarbon, 10, 20),
            ),
          ],
        ),
      );

  // Returns label + color based on low/medium/high thresholds
  (String, Color) _nutrientStatus(double? value, double low, double high) {
    if (value == null) return ('Haijulikani', Colors.grey);
    if (value < low) return ('Haitoshi — Ongeza mbolea', Colors.red.shade600);
    if (value < high) return ('Wastani', Colors.orange.shade600);
    return ('Nzuri', const Color(0xFF2E7D32));
  }

  // ── Crop suitability (Tanzania ECOCROP data) ──────────────

  Widget _buildCropSuitabilityCard() => _SectionCard(
        title: 'Mazao Yanayofaa kwa Udongo Huu',
        icon: Icons.bar_chart,
        iconColor: AppColors.leaf,
        child: FutureBuilder(
          future: CropRequirementService().fetchCrops(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            final region = LocationService.regionFromCoords(
              _soilData!.latitude,
              _soilData!.longitude,
            );
            final matches = SoilCropMatcher.match(
              soil: _soilData!,
              crops: snapshot.data!,
              farmerRegion: region,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SoilNutrientChart(soil: _soilData!),
                const SizedBox(height: 12),
                CropSuitabilityChart(matches: matches),
              ],
            );
          },
        ),
      );

  // ── Recommendation card ───────────────────────────────────

  Widget _buildRecommendationCard() => _SectionCard(
        title: 'Ushauri wa Kilimo',
        icon: Icons.tips_and_updates,
        iconColor: Colors.amber.shade700,
        child: Text(
          SoilService.getRecommendation(_soilData!),
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      );

  // ── AI Crop Advisory ─────────────────────────────────────

  Future<void> _fetchAdvisory() async {
    if (_soilData == null) return;
    setState(() { _advisoryLoading = true; _advisoryExpanded = true; });

    final region = LocationService.regionFromCoords(
        _soilData!.latitude, _soilData!.longitude);

    final text = await ClaudeService.getCropAdvisory(
      ph: _soilData!.ph ?? 6.5,
      texture: _soilData!.textureClass,
      nitrogen: _soilData!.nitrogen,
      organicCarbon: _soilData!.organicCarbon,
      region: region,
      lat: _soilData!.latitude,
      lng: _soilData!.longitude,
    );
    setState(() { _advisoryText = text; _advisoryLoading = false; });
  }

  Widget _buildAdvisoryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: const Color(0xFFF1F8E9),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.leaf.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🤖', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mshauri wa Mazao — AI',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.soil,
                          )),
                      Text('Kutumia data ya udongo wako',
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.mid)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!_advisoryExpanded) ...[
              // Prompt button
              ElevatedButton.icon(
                onPressed: _fetchAdvisory,
                icon: const Icon(Icons.agriculture_outlined, size: 18),
                label: const Text('Pata Ushauri wa Mazao Bora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.leaf,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Claude AI atakuambia: mazao bora, wakati wa kupanda, mvua, ratiba ya kulima na umwagiliaji — yote kutokana na data ya udongo wako.',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.mid, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ] else if (_advisoryLoading) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.leaf, strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text('Claude AI anaandaa ushauri wako...',
                      style: GoogleFonts.dmSans(
                          color: AppColors.leaf, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
            ] else if (_advisoryText != null) ...[
              const Divider(height: 20),
              Text(_advisoryText!,
                  style: GoogleFonts.dmSans(
                      fontSize: 13.5, height: 1.6, color: AppColors.ink)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _fetchAdvisory,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Pata Ushauri Mpya'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.leaf,
                  side: const BorderSide(color: AppColors.leaf),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── OpenStreetMap ─────────────────────────────────────────

  Widget _buildMap() => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 250,
          child: FlutterMap(
            options: MapOptions(
              // ignore: deprecated_member_use
              initialCenter: LatLng(_soilData!.latitude, _soilData!.longitude),
              // ignore: deprecated_member_use
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.shambasmart.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                        _soilData!.latitude, _soilData!.longitude),
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFFB71C1C),
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ── Reusable helper widgets ───────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text('$label: ', style: const TextStyle(color: Colors.grey)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final double? value;

  const _LegendDot(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(
            '$label${value != null ? ': ${value!.round()}%' : ''}',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      );
}

class _NutrientRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final (String, Color) status;

  const _NutrientRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.leaf, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(status.$1,
                    style: TextStyle(fontSize: 12, color: status.$2)),
              ],
            ),
          ),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      );
}
