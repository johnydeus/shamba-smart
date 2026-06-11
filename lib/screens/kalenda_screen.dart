import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/crop_calendar_data.dart';
import '../data/crop_production_data.dart';
import '../providers/auth_provider.dart';
import '../services/kanda_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/government_badge.dart';

// "Kalenda ya Kilimo" — personalised month-by-month farming calendar based on
// the official Ministry of Agriculture calendar for the farmer's region.
class KalendaScreen extends StatefulWidget {
  const KalendaScreen({super.key});

  @override
  State<KalendaScreen> createState() => _KalendaScreenState();
}

class _KalendaScreenState extends State<KalendaScreen> {
  bool _loading = true;
  String _region = 'Morogoro';
  final Set<String> _selectedCrops = {'Mahindi'};

  static const _monthNames = [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
  ];
  static const _monthShort = [
    'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (lat, lng) = await LocationService.getLocationOrDefault();
      _region = KandaService.getRegionFromCoordinates(lat, lng);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Kalenda Yangu ya Kilimo')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '📅 Mkoa wa $_region — Mwaka ${now.year}',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const GovernmentBadge(),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Crop selector ──
                _cropSelector(),
                const SizedBox(height: 16),

                // ── Legend ──
                _legend(),
                const SizedBox(height: 12),

                // ── 12-month calendar ──
                ..._selectedCrops.map(_cropCalendarCard),
                const SizedBox(height: 16),

                // ── Current month detail ──
                _currentMonthCard(now),
                const SizedBox(height: 16),

                // ── Next 3 months ──
                _next3MonthsCard(now),
                const GovernmentSourceFooter(),
              ],
            ),
    );
  }

  Widget _cropSelector() {
    final crops = CropCalendarData.cropNames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chagua mazao yako:',
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: crops.length,
            separatorBuilder: (context, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final crop = crops[i];
              final selected = _selectedCrops.contains(crop);
              return FilterChip(
                avatar: Text(CropProductionData.emojiFor(crop),
                    style: const TextStyle(fontSize: 13)),
                label: Text(crop),
                selected: selected,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondary),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedCrops.add(crop);
                    } else if (_selectedCrops.length > 1) {
                      _selectedCrops.remove(crop);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: CropCalendarData.activityTypes.entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(e.value['color'] as int),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(e.value['jina'] as String,
                style: GoogleFonts.poppins(
                    fontSize: 10.5, color: AppColors.textSecondary)),
          ],
        );
      }).toList(),
    );
  }

  // ── 12-month grid for one crop ─────────────────────────────────────────────
  Widget _cropCalendarCard(String crop) {
    final entry = CropCalendarData.entryFor(crop, _region);
    if (entry == null) return const SizedBox.shrink();
    final acts = (entry['activities'] as Map).cast<String, dynamic>();
    final nowMonth = DateTime.now().month;
    final actKeys = CropCalendarData.activityTypes.keys
        .where((k) => acts.containsKey(k))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${CropProductionData.emojiFor(crop)} $crop',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              if (entry['kundi'] != null) ...[
                const SizedBox(width: 8),
                Text('(${entry['kundi']})',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textTertiary)),
              ],
            ],
          ),
          if (entry['maelezo'] != null)
            Text(entry['maelezo'] as String,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 10),
          // Month header row
          Row(
            children: [
              const SizedBox(width: 70),
              ...List.generate(12, (i) {
                final isNow = i + 1 == nowMonth;
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        _monthShort[i].substring(0, 1),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: isNow
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isNow
                                ? AppColors.critical
                                : AppColors.textTertiary),
                      ),
                      if (isNow)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.critical,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),
          // Activity rows
          ...actKeys.map((act) {
            final months = (acts[act] as List).cast<int>();
            final meta = CropCalendarData.activityTypes[act]!;
            final color = Color(meta['color'] as int);
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      meta['jina'] as String,
                      style: GoogleFonts.poppins(fontSize: 9.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...List.generate(12, (i) {
                    final active = months.contains(i + 1);
                    return Expanded(
                      child: Container(
                        height: 16,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: active
                              ? color
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Current month detail ───────────────────────────────────────────────────
  Widget _currentMonthCard(DateTime now) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SASA HIVI — ${_monthNames[now.month - 1]} ${now.year}',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          const SizedBox(height: 10),
          ..._selectedCrops.map((crop) {
            final entry = CropCalendarData.entryFor(crop, _region);
            final acts =
                (entry?['activities'] as Map?)?.cast<String, dynamic>() ??
                    {};
            final due = <String>[];
            final next = <String>[];
            acts.forEach((act, months) {
              final m = (months as List).cast<int>();
              if (m.contains(now.month)) due.add(act);
              if (m.contains(now.month % 12 + 1)) next.add(act);
            });
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${CropProductionData.emojiFor(crop)} $crop:',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  if (due.isEmpty && next.isEmpty)
                    Text('  Hakuna shughuli kuu mwezi huu',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white70)),
                  ...due.map((a) => _activityLine(a, 'HARAKA',
                      AppColors.critical, 'Fanya mwezi huu')),
                  ...next
                      .where((a) => !due.contains(a))
                      .map((a) => _activityLine(a, 'KARIBU',
                          const Color(0xFFF9A825), 'Mwezi ujao')),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.notifications_active, size: 18),
                  label: const Text('Weka Ukumbusho',
                      style: TextStyle(fontSize: 13)),
                  onPressed: _saveReminders,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityLine(
      String act, String urgency, Color color, String note) {
    final meta = CropCalendarData.activityTypes[act]!;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Text(meta['emoji'] as String,
              style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${meta['jina']} — $note',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.white),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(urgency,
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Next 3 months preview ──────────────────────────────────────────────────
  Widget _next3MonthsCard(DateTime now) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Unachohitaji kufanya — miezi 3 ijayo',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...List.generate(3, (offset) {
            final m = (now.month + offset) % 12 + 1;
            final lines = <String>[];
            for (final crop in _selectedCrops) {
              final entry = CropCalendarData.entryFor(crop, _region);
              final acts = (entry?['activities'] as Map?)
                      ?.cast<String, dynamic>() ??
                  {};
              final due = <String>[];
              acts.forEach((act, months) {
                if ((months as List).contains(m)) {
                  due.add(CropCalendarData.activityTypes[act]!['jina']
                      as String);
                }
              });
              if (due.isNotEmpty) {
                lines.add(
                    '${CropProductionData.emojiFor(crop)} $crop: ${due.join(', ')}');
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_monthNames[m - 1],
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  if (lines.isEmpty)
                    Text('  Hakuna shughuli kuu',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textTertiary)),
                  ...lines.map((l) => Text('  $l',
                      style: GoogleFonts.poppins(fontSize: 12))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Saves this month's due activities to the farm diary as reminders
  Future<void> _saveReminders() async {
    final now = DateTime.now();
    final userId = context.read<AuthProvider>().currentUser?.id;
    final db = Supabase.instance.client;
    int saved = 0;
    try {
      for (final crop in _selectedCrops) {
        final entry = CropCalendarData.entryFor(crop, _region);
        final acts =
            (entry?['activities'] as Map?)?.cast<String, dynamic>() ?? {};
        for (final e in acts.entries) {
          if (!(e.value as List).contains(now.month)) continue;
          final actName =
              CropCalendarData.activityTypes[e.key]!['jina'] as String;
          await db.from('farm_events').insert({
            'farmer_id': userId,
            'event_type': 'ukumbusho',
            'event_date': now.toIso8601String(),
            'crop_name': crop,
            'description': 'Ukumbusho: $actName — $crop '
                '(${_monthNames[now.month - 1]})',
            'notes': 'Kalenda ya Kilimo — Wizara ya Kilimo 2022',
            'created_at': now.toIso8601String(),
          });
          saved++;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(saved > 0
              ? '✅ Vikumbusho $saved vimehifadhiwa kwenye Diari yako'
              : 'Hakuna shughuli za kukumbushwa mwezi huu'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hitilafu ya kuhifadhi: $e'),
        ));
      }
    }
  }
}
