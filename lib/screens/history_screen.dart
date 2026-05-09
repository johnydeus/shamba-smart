import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import 'results_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await SupabaseService.getDiagnosisHistory();
    setState(() {
      _history = data;
      _loading = false;
    });
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Dakika ${diff.inMinutes} zilizopita';
    if (diff.inHours < 24) return 'Masaa ${diff.inHours} yaliyopita';
    if (diff.inDays < 7) return 'Siku ${diff.inDays} zilizopita';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Color _confidenceColor(dynamic conf) {
    final c = (conf as num?)?.toDouble() ?? 0;
    if (c >= 0.80) return const Color(0xFF2E8B57);
    if (c >= 0.60) return const Color(0xFFFF6F00);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text('Historia ya Uchunguzi',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A5C2E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 72, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Hakuna historia ya uchunguzi bado.',
                          style: GoogleFonts.dmSans(
                              color: Colors.grey[500], fontSize: 15)),
                      const SizedBox(height: 8),
                      Text('Piga picha ya mmea kuanza.',
                          style: GoogleFonts.dmSans(
                              color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loading = true);
                    await _load();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    separatorBuilder: (_, i2) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = _history[i];
                      final cropName = (item['crop_name'] as String?) ?? '';
                      final diseaseEn =
                          (item['disease_name_en'] as String?) ?? '';
                      final diseaseSw =
                          (item['disease_name_sw'] as String?) ?? diseaseEn;
                      final confidence = item['confidence'];
                      final photoUrl = item['photo_url'] as String?;
                      final createdAt = item['created_at'] as String?;
                      final fullDiagnosis =
                          item['claude_response'] as Map<String, dynamic>?;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: fullDiagnosis == null
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResultsScreen(
                                        diagnosis: fullDiagnosis,
                                        imagePath: '',
                                        cropName: cropName,
                                      ),
                                    ),
                                  ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Photo thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: photoUrl != null &&
                                          photoUrl.isNotEmpty
                                      ? Image.network(
                                          photoUrl,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx2, e2, s2) =>
                                              _placeholder(),
                                        )
                                      : _placeholder(),
                                ),
                                const SizedBox(width: 14),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        const Icon(Icons.eco,
                                            color: Color(0xFF1A5C2E),
                                            size: 13),
                                        const SizedBox(width: 4),
                                        Text(cropName,
                                            style: GoogleFonts.dmSans(
                                                color:
                                                    const Color(0xFF1A5C2E),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(
                                        diseaseSw.isNotEmpty
                                            ? diseaseSw
                                            : 'Hakuna tatizo',
                                        style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _confidenceColor(confidence)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${((confidence as num? ?? 0) * 100).round()}% uhakika',
                                            style: GoogleFonts.dmSans(
                                                fontSize: 11,
                                                color: _confidenceColor(
                                                    confidence),
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _timeAgo(createdAt),
                                          style: GoogleFonts.dmSans(
                                              fontSize: 11,
                                              color: Colors.grey[500]),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 70,
      height: 70,
      color: const Color(0xFFE8F5E9),
      child: const Icon(Icons.image_not_supported,
          color: Colors.grey, size: 28),
    );
  }
}
