import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/farm_model.dart';
import '../providers/farm_provider.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import 'register_screen.dart' show kRegions;

// Common Tanzania crops for chip selection
const List<String> kCropOptions = [
  'Mahindi', 'Nyanya', 'Maharagwe', 'Pilipili hoho', 'Ndizi',
  'Mchele', 'Muhogo', 'Pamba', 'Alizeti', 'Viazi vitamu',
  'Vitunguu', 'Mtama', 'Uwele', 'Karoti', 'Kabichi',
  'Parachichi', 'Embe', 'Kahawa', 'Chai', 'Bia',
];

class AddFarmScreen extends StatefulWidget {
  final String farmerId;
  final FarmModel? editFarm; // non-null when editing existing farm

  const AddFarmScreen({
    super.key,
    required this.farmerId,
    this.editFarm,
  });

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final _nameCtrl = TextEditingController();
  final _acresCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _customCropCtrl = TextEditingController();

  String _region = 'Morogoro';
  double? _gpsLat;
  double? _gpsLng;
  final Set<String> _selectedCrops = {};
  bool _gpsLoading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill when editing
    if (widget.editFarm != null) {
      final f = widget.editFarm!;
      _nameCtrl.text = f.name;
      _acresCtrl.text = f.acres.toString();
      _notesCtrl.text = f.notes ?? '';
      _region = f.region;
      _gpsLat = f.gpsLat;
      _gpsLng = f.gpsLng;
      _selectedCrops.addAll(f.crops);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _acresCtrl.dispose();
    _notesCtrl.dispose();
    _customCropCtrl.dispose();
    super.dispose();
  }

  Future<void> _getGps() async {
    setState(() {
      _gpsLoading = true;
      _error = null;
    });
    try {
      final pos = await LocationService.getCurrentLocation();
      setState(() {
        _gpsLat = pos.latitude;
        _gpsLng = pos.longitude;
        // Auto-set region from coordinates
        _region = LocationService.regionFromCoords(pos.latitude, pos.longitude)
            .split(' ').first
            .split('/').first
            .trim();
      });
    } catch (e) {
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _gpsLoading = false);
    }
  }

  void _addCustomCrop() {
    final crop = _customCropCtrl.text.trim();
    if (crop.isEmpty) return;
    setState(() {
      _selectedCrops.add(crop);
      _customCropCtrl.clear();
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Tafadhali weka jina la shamba.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final provider = context.read<FarmProvider>();
    final acres = double.tryParse(_acresCtrl.text) ?? 1.0;

    if (widget.editFarm != null) {
      await provider.updateFarm(widget.editFarm!.copyWith(
        name: name,
        gpsLat: _gpsLat,
        gpsLng: _gpsLng,
        acres: acres,
        crops: _selectedCrops.toList(),
        region: _region,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
    } else {
      await provider.addFarm(FarmModel.create(
        farmerId: widget.farmerId,
        name: name,
        gpsLat: _gpsLat,
        gpsLng: _gpsLng,
        acres: acres,
        crops: _selectedCrops.toList(),
        region: _region,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editFarm != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: Text(isEdit ? 'Hariri Shamba' : 'Ongeza Shamba Jipya'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Farm name
            _label('Jina la Shamba *'),
            TextField(
              controller: _nameCtrl,
              decoration: _decor(
                  'mfano: Shamba la Kilosa, Shamba la Nyumbani',
                  Icons.landscape_outlined),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // GPS location
            _label('Eneo la GPS'),
            _gpsLat != null
                ? _gpsSuccess()
                : OutlinedButton.icon(
                    onPressed: _gpsLoading ? null : _getGps,
                    icon: _gpsLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(_gpsLoading
                        ? 'Inatafuta GPS...'
                        : 'Tumia GPS Yangu Sasa'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppColors.leaf),
                      foregroundColor: AppColors.leaf,
                    ),
                  ),
            const SizedBox(height: 16),

            // Farm size + region row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Ukubwa (Ekari)'),
                      TextField(
                        controller: _acresCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: _decor('1.0', Icons.straighten),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Mkoa'),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: kRegions.contains(_region) ? _region : 'Morogoro',
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.black12),
                          ),
                        ),
                        items: kRegions
                            .map((r) => DropdownMenuItem(
                                value: r, child: Text(r, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _region = v ?? _region),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Crop selection
            _label('Mazao unayolima'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCropOptions
                  .map((crop) => FilterChip(
                        label: Text(crop,
                            style: const TextStyle(fontSize: 12)),
                        selected: _selectedCrops.contains(crop),
                        onSelected: (v) => setState(() => v
                            ? _selectedCrops.add(crop)
                            : _selectedCrops.remove(crop)),
                        selectedColor:
                            AppColors.leaf.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.leaf,
                        side: BorderSide(
                          color: _selectedCrops.contains(crop)
                              ? AppColors.leaf
                              : Colors.black12,
                        ),
                        labelStyle: TextStyle(
                          color: _selectedCrops.contains(crop)
                              ? AppColors.leaf
                              : Colors.black87,
                          fontWeight: _selectedCrops.contains(crop)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),

            // Custom crop input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customCropCtrl,
                    decoration: _decor(
                        'Ongeza zao lingine...', Icons.add_circle_outline),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _addCustomCrop(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addCustomCrop,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.leaf),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            _label('Maelezo ya ziada (hiari)'),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: _decor(
                  'mfano: Shamba lina mfumo wa umwagiliaji...',
                  Icons.notes),
            ),
            const SizedBox(height: 16),

            // Error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!,
                    style: TextStyle(color: Colors.red.shade700)),
              ),

            // Save button
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(
                _saving
                    ? 'Inahifadhi...'
                    : (isEdit ? 'Hifadhi Mabadiliko' : 'Hifadhi Shamba'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _gpsSuccess() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.leaf, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GPS imewekwa ✓',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.leaf,
                          fontSize: 13)),
                  Text(
                    '${_gpsLat!.toStringAsFixed(5)}, ${_gpsLng!.toStringAsFixed(5)}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _getGps,
              child: const Text('Badilisha',
                  style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600, fontSize: 13)),
      );

  InputDecoration _decor(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.leaf, width: 1.5),
        ),
      );
}
