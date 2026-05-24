import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shamba_button.dart';
import '../widgets/shamba_card.dart';

const List<String> kSoilTypes = [
  'Mchanga (Sandy)',
  'Tifutifu (Loam)',
  'Udongo (Clay)',
];

const List<String> kIrrigationCrops = [
  'Mahindi', 'Nyanya', 'Maharagwe', 'Pilipili', 'Ndizi', 'Mchele',
];

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  final TextEditingController _acresController =
      TextEditingController(text: '1.0');
  String _selectedCrop = 'Mahindi';
  String _selectedSoil = 'Tifutifu (Loam)';
  Map<String, dynamic>? _plan;
  bool _loading = false;

  // Calculate daily water needs using a simple formula
  // Based on FAO ETo estimation for Tanzania
  void _calculatePlan() {
    final acres = double.tryParse(_acresController.text) ?? 1.0;

    // Base litres per acre per day (approximate for Tanzania conditions)
    double basePerAcre;
    switch (_selectedSoil) {
      case 'Mchanga (Sandy)':
        basePerAcre = 900; // Sandy soil needs more water
        break;
      case 'Udongo (Clay)':
        basePerAcre = 500; // Clay retains water longer
        break;
      default:
        basePerAcre = 700; // Loam is balanced
    }

    // Crop factor multipliers
    double cropFactor;
    switch (_selectedCrop) {
      case 'Nyanya':
        cropFactor = 1.15;
        break;
      case 'Maharagwe':
        cropFactor = 0.85;
        break;
      case 'Ndizi':
        cropFactor = 1.3;
        break;
      default:
        cropFactor = 1.0;
    }

    final dailyLitres = (basePerAcre * acres * cropFactor).roundToDouble();

    setState(() {
      _plan = {
        'crop': _selectedCrop,
        'soil': _selectedSoil,
        'acres': acres,
        'daily_litres': dailyLitres,
        'morning_litres': (dailyLitres * 0.6).round(),
        'evening_litres': (dailyLitres * 0.4).round(),
        'sessions_per_day': 2,
        'water_days': [true, false, true, false, true, false, true],
      };
    });
  }

  Future<void> _savePlan() async {
    if (_plan == null) return;
    setState(() => _loading = true);

    await SupabaseService.saveIrrigationPlan(
      cropName: _plan!['crop'],
      soilType: _plan!['soil'],
      farmAcres: _plan!['acres'],
      dailyLitres: _plan!['daily_litres'],
      scheduleJson: _plan!,
    );

    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mpango umehifadhiwa! ✅'),
          backgroundColor: AppColors.leaf,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: const Text('Mpango wa Umwagiliaji'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maelezo ya Shamba Lako',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A5C2E),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Acres input
                    TextField(
                      controller: _acresController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Ukubwa wa Shamba (Ekari)',
                        hintText: '1.0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixText: 'Ekari',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Crop selector
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCrop,
                      decoration: InputDecoration(
                        labelText: 'Zao',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: kIrrigationCrops
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCrop = val);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Soil type selector
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSoil,
                      decoration: InputDecoration(
                        labelText: 'Aina ya Udongo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: kSoilTypes
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSoil = val);
                      },
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.calculate),
                      label: const Text('Hesabu Maji'),
                      onPressed: _calculatePlan,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results card
            if (_plan != null) ...[
              ShambaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.water_drop_outlined,
                        color: AppColors.info, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      '${_plan!['daily_litres'].toInt()}',
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.info,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Lita kwa siku',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Ratiba ya Wiki',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final days = ['Jt', 'Jn', 'Jt', 'Al', 'Ij', 'Ij', 'Jp'];
                        final water = (_plan!['water_days'] as List)[i]
                            as bool;
                        return Column(
                          children: [
                            Text(days[i],
                                style: GoogleFonts.poppins(fontSize: 10)),
                            const SizedBox(height: 4),
                            Text(
                              water ? '💧' : '—',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    _PlanRow(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Asubuhi (6am)',
                      value: '${_plan!['morning_litres']} Lita',
                      color: AppColors.warning,
                    ),
                    const Divider(),
                    _PlanRow(
                      icon: Icons.nights_stay_outlined,
                      label: 'Jioni (6pm)',
                      value: '${_plan!['evening_litres']} Lita',
                      color: const Color(0xFF5C6BC0),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ShambaCard(
                      backgroundColor: AppColors.infoBg,
                      hasShadow: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bila umwagiliaji: hatari ya ukame',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.critical,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Na umwagiliaji: mavuno mazuri 🌾',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ShambaButton(
                      label: _loading ? 'Inahifadhi...' : 'Hifadhi Mpango',
                      icon: Icons.save_outlined,
                      onPressed: _loading ? null : _savePlan,
                      isLoading: _loading,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// One row in the irrigation plan results
class _PlanRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PlanRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 15)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
