import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agrovet_model.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'find_agrovets_screen.dart';

// ── IPM Decision Tree Screen ──────────────────────────────────────────────────

class IpmBody extends StatefulWidget {
  const IpmBody({super.key});

  @override
  State<IpmBody> createState() => _IpmBodyState();
}

class _IpmBodyState extends State<IpmBody> {
  int _step = 0;
  String? _crop;
  String? _pest;
  double? _count;
  String? _decision;
  bool _saving = false;

  // AI advice (constrained to currently-approved Tanzania pesticides via the
  // ipm-advisor Edge Function). We NEVER show the old hardcoded pesticide names.
  bool _adviceLoading = false;
  String? _aiAdvice;

  static const _crops = ['Mahindi', 'Nyanya', 'Maharagwe', 'Pilipili', 'Ndizi', 'Mchele', 'Muhogo'];

  static const _pestsByCrop = <String, List<String>>{
    'Mahindi': ['Fall Armyworm (Viwavi)', 'Stem Borer (Borer)', 'Aphids (Chawa)', 'Nyuklia za Kuvu'],
    'Nyanya': ['Whitefly (Inzi Nyeupe)', 'Red Spider Mite (Buibui)', 'Tuta absoluta', 'Magonjwa ya Ukungu'],
    'Maharagwe': ['Bean Fly (Inzi ya Haragwe)', 'Pod Borer (Borer wa Ganda)', 'Aphids (Chawa)'],
    'Pilipili': ['Whitefly', 'Thrips', 'Aphids'],
    'Ndizi': ['Weevil (Ngongolo)', 'Sigatoka', 'Fusarium'],
    'Mchele': ['Stink Bug', 'Rice Blast', 'Leaf Folder'],
    'Muhogo': ['Whitefly', 'Mealybug', 'Cassava Mosaic'],
  };

  // TPRI economic thresholds: [pest, crop, threshold value, unit description, action recommendation]
  static const _thresholds = <String, Map<String, dynamic>>{
    'Fall Armyworm (Viwawi)_Mahindi': {
      'threshold': 1.0, 'unit': 'mayai kwa mimea 100',
      'recommendation': 'Pulizia dawa: Emamectin benzoate 1g/L au Spinosad. Dozi: 50ml/15L.',
    },
    'Stem Borer (Borer)_Mahindi': {
      'threshold': 10.0, 'unit': '% ya mimea ina "deadheart"',
      'recommendation': 'Weka granules za carbofuran kwenye mzizi wa mmea.',
    },
    'Aphids (Chawa)_Mahindi': {
      'threshold': 200.0, 'unit': 'chawa kwa mmea',
      'recommendation': 'Pulizia Dimethoate 40EC, 30ml/15L au imidacloprid.',
    },
    'Whitefly (Inzi Nyeupe)_Nyanya': {
      'threshold': 4.0, 'unit': 'inzi wazima kwa jani',
      'recommendation': 'Pulizia Imidacloprid 200SL, 10ml/15L.',
    },
    'Red Spider Mite (Buibui)_Nyanya': {
      'threshold': 30.0, 'unit': '% ya jani iliyoharibiwa',
      'recommendation': 'Pulizia Abamectin 1.8EC, 10ml/15L au mafuta ya neem.',
    },
    'Tuta absoluta_Nyanya': {
      'threshold': 1.0, 'unit': 'machimbo kwa majani 10',
      'recommendation': 'Tumia mtego wa pheromone na pulizia Spinosad.',
    },
    'Bean Fly (Inzi ya Haragwe)_Maharagwe': {
      'threshold': 10.0, 'unit': '% ya miche iliyoathirika',
      'recommendation': 'Pulizia dawa haraka: Dimethoate 30ml/15L.',
    },
    'Pod Borer (Borer wa Ganda)_Maharagwe': {
      'threshold': 5.0, 'unit': '% ya maganda yaliyoathirika',
      'recommendation': 'Pulizia Emamectin benzoate au Chlorpyrifos.',
    },
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProgress(),
          const SizedBox(height: 20),
          _buildStep(),
        ],
      ),
    );
  }

  Widget _buildProgress() {

    final steps = ['Zao', 'Wadudu', 'Hesabu', 'Uamuzi'];
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i < _step;
        final active = i == _step;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0) Expanded(child: Container(height: 2,
                    color: done ? AppColors.primary : Colors.grey.shade200)),
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: done || active ? AppColors.primary : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: done
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text('${i+1}', style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: active ? Colors.white : Colors.grey))),
                  ),
                  if (i < steps.length - 1) Expanded(child: Container(height: 2,
                    color: done ? AppColors.primary : Colors.grey.shade200)),
                ],
              ),
              const SizedBox(height: 4),
              Text(steps[i], style: GoogleFonts.poppins(
                fontSize: 10,
                color: active ? AppColors.primary : Colors.grey,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildCropStep();
      case 1: return _buildPestStep();
      case 2: return _buildCountStep();
      case 3: return _buildDecisionStep();
      default: return const SizedBox();
    }
  }

  Widget _buildCropStep() {
    return _StepCard(
      title: '🌱 Ni Zao Gani?',
      subtitle: 'Chagua zao unalolima',
      child: Wrap(
        spacing: 10, runSpacing: 10,
        children: _crops.map((c) => _CropChip(
          label: c,
          selected: _crop == c,
          onTap: () {
            setState(() { _crop = c; _pest = null; _step = 1; });
          },
        )).toList(),
      ),
    );
  }

  Widget _buildPestStep() {
    final pests = _pestsByCrop[_crop] ?? [];
    return Column(
      children: [
        _StepCard(
          title: '🐛 Umeona Nini?',
          subtitle: 'Chagua tatizo unaloliona shambani',
          child: Column(
            children: pests.map((p) => _PestOption(
              label: p,
              selected: _pest == p,
              onTap: () => setState(() { _pest = p; _step = 2; }),
            )).toList(),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() => _step = 0),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Rudi Nyuma'),
        ),
      ],
    );
  }

  Widget _buildCountStep() {
    return Column(
      children: [
        _StepCard(
          title: '🔢 Hesabu / Kiwango',
          subtitle: 'Andika idadi uliyohesabu',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Andika nambari...',
                  suffixText: _getUnit(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _count = double.tryParse(v)),
              ),
              const SizedBox(height: 12),
              Text(_getCountHint(),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: OutlinedButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Rudi'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _count == null ? null : _calculateDecision,
              child: const Text('Hesabu'),
            )),
          ],
        ),
      ],
    );
  }

  String _getUnit() {
    final key = '${_pest}_$_crop';
    final t = _thresholds[key];
    return t?['unit'] ?? '';
  }

  String _getCountHint() {
    final key = '${_pest}_$_crop';
    final t = _thresholds[key];
    final threshold = t?['threshold'] as double? ?? 5.0;
    return 'Kikomo: $threshold ${t?['unit'] ?? ''}';
  }

  void _calculateDecision() {
    final key = '${_pest}_$_crop';
    final t = _thresholds[key];
    final threshold = (t?['threshold'] as double?) ?? 5.0;
    // NOTE: we deliberately no longer read t['recommendation'] — those legacy
    // strings contained hardcoded pesticide names that may now be banned. The
    // chemical recommendation comes only from the constrained ipm-advisor.

    final count = _count ?? 0;
    String decision;

    if (count < threshold * 0.7) {
      decision = 'no_spray';
    } else if (count < threshold) {
      decision = 'monitor';
    } else {
      decision = 'spray';
    }

    setState(() {
      _decision = decision;
      _aiAdvice = null;
      _step = 3;
    });

    // Only fetch a chemical recommendation past the economic threshold, and
    // always via the constrained advisor (never the hardcoded names).
    if (decision == 'spray') _fetchAdvice();
  }

  // Calls the ipm-advisor Edge Function, which injects ONLY currently-approved
  // Tanzania pesticides into the AI prompt. Falls back to a safe, non-chemical
  // message on any error — never invents or shows a banned pesticide.
  Future<void> _fetchAdvice() async {
    setState(() => _adviceLoading = true);
    try {
      final res = await Supabase.instance.client.functions
          .invoke('ipm-advisor', body: {
            'crop': _crop,
            'pest': _pest,
            'severity': 'juu',
          })
          .timeout(const Duration(seconds: 20));
      final data = res.data as Map<String, dynamic>?;
      final advice = data?['advice'] as String?;
      if (advice != null && advice.trim().isNotEmpty) {
        if (mounted) setState(() => _aiAdvice = advice.trim());
      } else {
        throw Exception('empty advice');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _aiAdvice =
            'Wadudu wamevuka kikomo. Tumia njia za kilimo na kibaiolojia kwanza. '
            'Kwa dawa iliyothibitishwa, tafadhali shauriana na Afisa Kilimo au '
            'duka la pembejeo lililothibitishwa karibu nawe — hatuwezi kupendekeza '
            'dawa bila kuthibitisha usalama wake.');
      }
    } finally {
      if (mounted) setState(() => _adviceLoading = false);
    }
  }

  Widget _buildDecisionStep() {
    final isNoSpray = _decision == 'no_spray';
    final isMonitor = _decision == 'monitor';
    final isSpray = _decision == 'spray';

    final Color bgColor = isNoSpray
        ? const Color(0xFF2E7D32)
        : isMonitor
            ? const Color(0xFFE65100)
            : const Color(0xFFB71C1C);

    final String title = isNoSpray
        ? '🟢 USIPULIZIE'
        : isMonitor
            ? '🟡 FUATILIA KWA MAKINI'
            : '🔴 PULIZIA LEO';

    final String subtitle = isNoSpray
        ? 'Wadudu wako chini ya kikomo cha uchumi'
        : isMonitor
            ? 'Wadudu wanakaribia kikomo — angalia kila siku 3'
            : 'Kikomo kimepitiwa — chukua hatua haraka';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Details card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bgColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Zao', value: _crop ?? ''),
              _DetailRow(label: 'Wadudu', value: _pest ?? ''),
              _DetailRow(label: 'Hesabu', value: '${_count ?? 0} ${_getUnit()}'),
              const Divider(height: 20),
              if (isSpray) ...[
                Text('🌿 Ushauri wa IPM:',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                if (_adviceLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Inaandaa ushauri salama...'),
                      ],
                    ),
                  )
                else
                  Text(_aiAdvice ?? '',
                      style: GoogleFonts.poppins(fontSize: 13, height: 1.5)),
                const SizedBox(height: 12),
                // Link approved-pesticide buyers to the verified agrovet directory.
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FindAgrovetsScreen(
                            initialCategory: AgrovetCategory.pesticides),
                      ),
                    ),
                    icon: const Icon(Icons.storefront, size: 18),
                    label: const Text('Maduka ya dawa karibu nawe'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dawa zinazopendekezwa ni zilizothibitishwa na TPHPA pekee.',
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: AppColors.textTertiary),
                ),
              ] else if (isMonitor) ...[
                Text('📅 Angalia tena baada ya siku 3',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13,
                        color: const Color(0xFFE65100))),
              ] else ...[
                Text('✅ Angalia tena baada ya siku 7',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13,
                        color: const Color(0xFF2E7D32))),
                const SizedBox(height: 4),
                Text('Wacha wadudu wadogo wafanye kazi (biological control)',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveRecord,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Inahifadhi...' : 'Hifadhi Rekodi'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _step = 0; _crop = null; _pest = null;
                  _count = null; _decision = null;
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('Anza Upya'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveRecord() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id;
      double? lat, lng;
      try {
        final pos = await LocationService.getCurrentLocation();
        lat = pos.latitude; lng = pos.longitude;
      } catch (_) {}

      await Supabase.instance.client.from('ipm_records').insert({
        'farmer_id': userId,
        'crop_name': _crop,
        'pest_observed': _pest,
        'pest_count': _count,
        'decision': _decision,
        'action_taken': _aiAdvice, // constrained IPM advice (null if non-spray)
        'gps_lat': lat,
        'gps_lng': lng,
        'observed_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Rekodi imehifadhiwa!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hitilafu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _StepCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.poppins(
              fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CropChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CropChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87)),
      ),
    );
  }
}

class _PestOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PestOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.bug_report_outlined, size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 13))),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class IpmScreen extends StatelessWidget {
  const IpmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Mwongozo wa IPM'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const IpmBody(),
    );
  }
}
