import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

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
        title: Text('Mpango wa Umwagiliaji',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mpango Wako wa Umwagiliaji:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A5C2E),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Daily total
                      _PlanRow(
                        icon: Icons.water_drop,
                        label: 'Maji Kwa Siku',
                        value: '${_plan!['daily_litres'].toInt()} Lita',
                        color: const Color(0xFF0277BD),
                      ),
                      const Divider(),

                      // Morning session
                      _PlanRow(
                        icon: Icons.wb_sunny,
                        label: 'Asubuhi (6am)',
                        value: '${_plan!['morning_litres']} Lita',
                        color: const Color(0xFFFF6F00),
                      ),
                      const Divider(),

                      // Evening session
                      _PlanRow(
                        icon: Icons.nights_stay,
                        label: 'Jioni (6pm)',
                        value: '${_plan!['evening_litres']} Lita',
                        color: const Color(0xFF5C6BC0),
                      ),

                      const SizedBox(height: 16),

                      // Save button
                      ElevatedButton.icon(
                        icon: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                            _loading ? 'Inahifadhi...' : 'Hifadhi Mpango'),
                        onPressed: _loading ? null : _savePlan,
                      ),
                    ],
                  ),
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
