import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/audio_service.dart';
import '../services/claude_service.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class FertiliserPrescriptionScreen extends StatefulWidget {
  const FertiliserPrescriptionScreen({super.key});

  @override
  State<FertiliserPrescriptionScreen> createState() =>
      _FertiliserPrescriptionScreenState();
}

class _FertiliserPrescriptionScreenState
    extends State<FertiliserPrescriptionScreen> {
  String _selectedCrop = 'Mahindi';
  String _selectedStage = 'Kupanda';
  String _farmSize = '2';
  bool _aiLoading = false;
  String? _aiPrescription;

  static const _crops = ['Mahindi', 'Nyanya', 'Maharagwe', 'Pilipili', 'Mchele', 'Muhogo'];
  static const _stages = ['Kupanda', 'Mche', 'Ukuaji', 'Maua', 'Kuzaa'];

  // Fertiliser recommendations per crop (kg/acre)
  static const _baseRecs = <String, Map<String, dynamic>>{
    'Mahindi': {
      'basal': {'DAP': 50, 'cost': 45000},
      'top1': {'Urea': 30, 'weeks': 4, 'cost': 24000},
      'top2': {'Urea': 30, 'weeks': 8, 'cost': 24000},
    },
    'Nyanya': {
      'basal': {'DAP': 60, 'cost': 54000},
      'top1': {'CAN': 40, 'weeks': 3, 'cost': 28000},
      'top2': {'NPK_17': 50, 'weeks': 7, 'cost': 40000},
    },
    'Maharagwe': {
      'basal': {'DAP': 30, 'cost': 27000},
      'top1': {'CAN': 20, 'weeks': 4, 'cost': 14000},
      'top2': null,
    },
    'Pilipili': {
      'basal': {'DAP': 55, 'cost': 49500},
      'top1': {'CAN': 35, 'weeks': 4, 'cost': 24500},
      'top2': {'CAN': 35, 'weeks': 8, 'cost': 24500},
    },
    'Mchele': {
      'basal': {'DAP': 45, 'cost': 40500},
      'top1': {'Urea': 35, 'weeks': 3, 'cost': 28000},
      'top2': {'Urea': 35, 'weeks': 6, 'cost': 28000},
    },
    'Muhogo': {
      'basal': {'NPK_17': 40, 'cost': 32000},
      'top1': {'Urea': 25, 'weeks': 6, 'cost': 20000},
      'top2': null,
    },
  };

  Future<void> _getAiPrescription() async {
    setState(() { _aiLoading = true; _aiPrescription = null; });
    try {
      final acres = double.tryParse(_farmSize) ?? 2.0;
      final rec = _baseRecs[_selectedCrop];
      final basal = rec?['basal'] as Map? ?? {};
      final top1 = rec?['top1'] as Map? ?? {};

      final prompt = '''Toa maelekezo ya mbolea kwa mkulima wa Tanzania.
Zao: $_selectedCrop, Awamu: $_selectedStage
Ukubwa wa shamba: $acres ekari
Mbolea ya msingi inayopendekezwa: ${basal.keys.join(', ')} (${basal.values.join('kg/ekari')})
Mbolea ya juu inayopendekezwa: ${top1.keys.join(', ')} (${top1.values.join('kg/ekari')})

Jibu kwa Kiswahili. Toa:
1. Jadweli la mbolea kwa kila wiki
2. Jinsi ya kutumia mbolea
3. Onyo muhimu (overdose, underwatering n.k.)
4. Bei ya jumla ya takriban kwa TZS
5. Jinsi ya kuokoa pesa (vikundi vya wakulima n.k.)''';

      final resp = await ClaudeService.askFarmingQuestion(
          question: prompt,
          cropContext: _selectedCrop,
          regionContext: 'Tanzania');
      if (mounted) setState(() => _aiPrescription = resp);
    } catch (e) {
      if (mounted) setState(() => _aiPrescription = 'Hitilafu: $e');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _save() async {
    try {
      final auth = context.read<AuthProvider>();
      final acres = double.tryParse(_farmSize) ?? 2.0;
      final rec = _baseRecs[_selectedCrop];
      final total = _calcTotal(acres);
      await Supabase.instance.client.from('fertiliser_prescriptions').insert({
        'farmer_id': auth.currentUser?.id,
        'crop_name': _selectedCrop,
        'growth_stage': _selectedStage,
        'zone_prescriptions': rec,
        'total_cost_tzs': total,
        'ai_recommendation': _aiPrescription,
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Imehifadhiwa!')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e')),
      );
    }
  }

  int _calcTotal(double acres) {
    final rec = _baseRecs[_selectedCrop];
    if (rec == null) return 0;
    int total = 0;
    for (final k in ['basal', 'top1', 'top2']) {
      final v = rec[k] as Map?;
      if (v != null) {
        final cost = (v['cost'] as int?) ?? 0;
        total += (cost * acres).round();
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final acres = double.tryParse(_farmSize) ?? 2.0;
    final total = _calcTotal(acres);
    final totalFormatted = total.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Dawa ya Mbolea'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _save,
            tooltip: 'Hifadhi',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const Text('💊', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mpango wa Mbolea',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text('Imehesabiwa kwa data ya udongo na setilaiti',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 11)),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 20),

            // Crop & stage selectors
            Text('Zao', style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _crops.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel = _crops[i] == _selectedCrop;
                  return _Chip(
                    label: _crops[i], selected: sel,
                    onTap: () => setState(() => _selectedCrop = _crops[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Text('Awamu ya Ukuaji', style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _stages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel = _stages[i] == _selectedStage;
                  return _Chip(
                    label: _stages[i], selected: sel,
                    onTap: () => setState(() => _selectedStage = _stages[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Text('Ukubwa wa Shamba (ekari)',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: _farmSize)
                ..selection = TextSelection.collapsed(offset: _farmSize.length),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Mfano: 2.5',
                suffixText: 'ekari',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _farmSize = v),
            ),
            const SizedBox(height: 20),

            // Prescription table
            Text('Jedwali la Mbolea',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            _buildPrescriptionTable(acres),
            const SizedBox(height: 16),

            // Total cost
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gharama ya Jumla',
                        style: GoogleFonts.poppins(
                            color: AppColors.primary, fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    Text('TZS $totalFormatted',
                        style: GoogleFonts.poppins(
                            fontSize: 22, fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    Text('kwa $acres ekari za $_selectedCrop',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey)),
                  ],
                )),
                const Icon(Icons.savings_outlined, color: AppColors.primary, size: 36),
              ]),
            ),
            const SizedBox(height: 16),

            // AI prescription button
            ElevatedButton.icon(
              onPressed: _aiLoading ? null : _getAiPrescription,
              icon: _aiLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.psychology_outlined),
              label: Text(_aiLoading ? 'AI inafikiria...' : 'Pata Mpango wa Kina wa AI 🤖'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),

            if (_aiPrescription != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  boxShadow: AppShadow.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('🤖', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text('Ushauri wa AI',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const Spacer(),
                      SpeakerButton(text: _aiPrescription!),
                    ]),
                    const SizedBox(height: 12),
                    Text(_aiPrescription!,
                        style: GoogleFonts.poppins(fontSize: 13, height: 1.6)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionTable(double acres) {
    final rec = _baseRecs[_selectedCrop];
    if (rec == null) return const SizedBox();

    final rows = <Map<String, dynamic>>[];
    final basal = rec['basal'] as Map?;
    final top1 = rec['top1'] as Map?;
    final top2 = rec['top2'] as Map?;

    if (basal != null) {
      final name = basal.keys.first.toString().replaceAll('_', ' ');
      final qty = (basal[basal.keys.first] as int) * acres;
      final cost = ((basal['cost'] as int) * acres).round();
      rows.add({'wakati': 'Kupanda (Wiki 0)', 'dawa': name,
        'kilo': qty.toStringAsFixed(0), 'cost': cost});
    }
    if (top1 != null) {
      final name = top1.keys.first.toString().replaceAll('_', ' ');
      final qty = (top1[top1.keys.first] as int) * acres;
      final cost = ((top1['cost'] as int) * acres).round();
      final weeks = top1['weeks'] ?? 4;
      rows.add({'wakati': 'Wiki $weeks', 'dawa': name,
        'kilo': qty.toStringAsFixed(0), 'cost': cost});
    }
    if (top2 != null) {
      final name = top2.keys.first.toString().replaceAll('_', ' ');
      final qty = (top2[top2.keys.first] as int) * acres;
      final cost = ((top2['cost'] as int) * acres).round();
      final weeks = top2['weeks'] ?? 8;
      rows.add({'wakati': 'Wiki $weeks', 'dawa': name,
        'kilo': qty.toStringAsFixed(0), 'cost': cost});
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A5C2E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(children: [
              Expanded(child: Text('Wakati', style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(child: Text('Mbolea', style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
              Text('Kilo', style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Text('TZS', style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          // Rows
          ...rows.asMap().entries.map((e) {
            final even = e.key.isEven;
            final r = e.value;
            final costStr = (r['cost'] as int).toString()
                .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: even ? Colors.white : AppColors.primarySoft.withValues(alpha: 0.3),
              child: Row(children: [
                Expanded(child: Text(r['wakati'] as String,
                    style: GoogleFonts.poppins(fontSize: 12))),
                Expanded(child: Text(r['dawa'] as String,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
                Text('${r['kilo']} kg',
                    style: GoogleFonts.poppins(fontSize: 12)),
                const SizedBox(width: 8),
                Text(costStr,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
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
