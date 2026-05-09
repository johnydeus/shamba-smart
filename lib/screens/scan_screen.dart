import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/plant_id_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import 'results_screen.dart';

// All Tanzania crops — Ministry of Agriculture, TAHA, TOSCI, TanzaniaInvest
const List<String> kCrops = [
  // Nafaka (Cereals)
  'Mahindi', 'Mchele', 'Ngano', 'Mtama', 'Uwele', 'Ulezi', 'Shayiri',
  // Mikunde (Legumes)
  'Maharagwe', 'Choroko', 'Karanga', 'Soya', 'Mbaazi', 'Kunde',
  // Mbogamboga (Vegetables)
  'Nyanya', 'Kabichi', 'Sukuma wiki', 'Vitunguu', 'Pilipili hoho',
  'Pilipili manga', 'Karoti', 'Bamia', 'Tango', 'Bilinganya',
  'Mchicha', 'Tikiti maji', 'Njegere', 'Maharage ya Kata',
  // Mazao ya Mizizi (Root crops)
  'Muhogo', 'Viazi vitamu', 'Viazi',
  // Matunda (Fruits)
  'Ndizi', 'Embe', 'Papai', 'Nanasi', 'Avokado', 'Marakuja',
  'Chungwa', 'Zabibu', 'Stroberri',
  // Mazao ya Biashara (Cash crops)
  'Pamba', 'Alizeti', 'Kahawa', 'Chai', 'Korosho', 'Miwa',
  'Katani', 'Tumbaku', 'Karafuu',
];

// The 4 scan categories the farmer can choose from
const _scanTypes = [
  {
    'key': 'ugonjwa',
    'label': 'Ugonjwa',
    'emoji': '🦠',
    'subtitle': 'Magonjwa ya jani',
    'color': 0xFF6A1B9A,
    'tip': 'Piga picha karibu na jani lililougua ili AI ione dalili vizuri.',
    'buttonLabel': 'Chunguza Ugonjwa',
    'appBarTitle': 'Gundua Ugonjwa',
  },
  {
    'key': 'wadudu',
    'label': 'Wadudu',
    'emoji': '🐛',
    'subtitle': 'Wadudu na uharibifu',
    'color': 0xFFE65100,
    'tip': 'Piga picha ya mdudu au uharibifu aliofanya kwenye mmea/jani.',
    'buttonLabel': 'Tambua Mdudu',
    'appBarTitle': 'Gundua Wadudu',
  },
  {
    'key': 'magugu',
    'label': 'Magugu',
    'emoji': '🌿',
    'subtitle': 'Tambua magugu',
    'color': 0xFF2E7D32,
    'tip': 'Piga picha ya mmea wote wa gugu — pamoja na majani na shina.',
    'buttonLabel': 'Tambua Gugu',
    'appBarTitle': 'Tambua Magugu',
  },
  {
    'key': 'tambua_mmea',
    'label': 'Mmea',
    'emoji': '🌳',
    'subtitle': 'Tambua aina ya mmea',
    'color': 0xFF00695C,
    'tip': 'Piga picha ya mmea mzima, jani, au tunda ili kujua ni aina gani.',
    'buttonLabel': 'Tambua Mmea',
    'appBarTitle': 'Tambua Mmea',
  },
];

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  String _selectedCrop = kCrops.first;
  String _selectedScanType = 'ugonjwa';
  bool _analysing = false;
  String _statusMessage = '';

  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic> get _currentType =>
      _scanTypes.firstWhere((t) => t['key'] == _selectedScanType);

  Color get _typeColor => Color(_currentType['color'] as int);

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (photo != null) setState(() => _selectedImage = File(photo.path));
  }

  Future<void> _pickFromGallery() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (photo != null) setState(() => _selectedImage = File(photo.path));
  }

  Future<void> _analysePhoto() async {
    if (_selectedImage == null || _analysing) return;

    setState(() {
      _analysing = true;
      _statusMessage = 'Inatuma picha kwa Plant.id AI...';
    });

    final result = await PlantIdService.analysePhoto(
      imageFile: _selectedImage!,
      cropName: _selectedCrop,
      scanType: _selectedScanType,
    );

    setState(() => _statusMessage = 'Inahifadhi matokeo...');

    await SupabaseService.saveDiagnosis(
      cropName: _selectedCrop,
      claudeResponse: result,
      photoPath: _selectedImage!.path,
    );

    setState(() => _analysing = false);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          diagnosis: result,
          imagePath: _selectedImage!.path,
          cropName: _selectedCrop,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text(
          _currentType['appBarTitle'] as String,
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _typeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Scan type selector ─────────────────────────────────────────
            _buildScanTypeSelector(),

            const SizedBox(height: 16),

            // ── Crop selector ──────────────────────────────────────────────
            Text('Chagua Zao:',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.soil)),
            const SizedBox(height: 8),
            // ignore: deprecated_member_use
            DropdownButtonFormField<String>(
              initialValue: _selectedCrop,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: _typeColor.withValues(alpha: 0.4))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: _typeColor.withValues(alpha: 0.4))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _typeColor, width: 2)),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: kCrops
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: GoogleFonts.dmSans(fontSize: 14))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCrop = val);
              },
            ),

            const SizedBox(height: 20),

            // ── Camera preview / tap area ──────────────────────────────────
            _buildCameraArea(),

            const SizedBox(height: 14),

            // ── Camera / Gallery buttons ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: _typeColor,
                    onTap: _takePhoto,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Picha Zilizopo',
                    color: _typeColor,
                    onTap: _pickFromGallery,
                    outlined: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Analyse button ─────────────────────────────────────────────
            if (_analysing)
              _buildLoadingWidget()
            else
              _buildAnalyseButton(),

            const SizedBox(height: 16),

            // ── Tip card ───────────────────────────────────────────────────
            _buildTipCard(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Scan type selector ────────────────────────────────────────────────────

  Widget _buildScanTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _scanTypes.map((type) {
            final isSelected = _selectedScanType == type['key'];
            final color = Color(type['color'] as int);
            return GestureDetector(
              onTap: () => setState(() {
                _selectedScanType = type['key'] as String;
                _selectedImage = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 88,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type['emoji'] as String,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 3),
                    Text(
                      type['label'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.mid,
                      ),
                    ),
                    Text(
                      type['subtitle'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        color: isSelected ? Colors.white70 : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Camera preview area ───────────────────────────────────────────────────

  Widget _buildCameraArea() {
    return GestureDetector(
      onTap: _takePhoto,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedImage != null
                ? _typeColor
                : _typeColor.withValues(alpha: 0.35),
            width: _selectedImage != null ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _typeColor.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _selectedImage == null
            ? _buildCameraPlaceholder()
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImage!, fit: BoxFit.cover),
                    // Overlay: tap to retake
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text('Badilisha',
                                style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Big camera icon with coloured circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _typeColor.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.camera_alt_rounded,
                    size: 56, color: _typeColor.withValues(alpha: 0.25)),
                Icon(Icons.camera_alt_rounded, size: 48, color: _typeColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Gusa Hapa Kupiga Picha',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _typeColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _currentType['subtitle'] as String,
          style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        // Mini camera/gallery pills at bottom of placeholder
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _miniPill(Icons.camera_alt_rounded, 'Kamera', _typeColor),
            const SizedBox(width: 10),
            _miniPill(Icons.photo_library_rounded, 'Matunzio', _typeColor,
                outlined: true),
          ],
        ),
      ],
    );
  }

  Widget _miniPill(IconData icon, String label, Color color,
      {bool outlined = false}) {
    return GestureDetector(
      onTap: outlined ? _pickFromGallery : _takePhoto,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: outlined ? color : Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: outlined ? color : Colors.white)),
          ],
        ),
      ),
    );
  }

  // ── Loading indicator ─────────────────────────────────────────────────────

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _typeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _typeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: _typeColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'AI Inachunguza Picha...',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                color: _typeColor,
                fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            _statusMessage,
            style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Analyse button ────────────────────────────────────────────────────────

  Widget _buildAnalyseButton() {
    final hasImage = _selectedImage != null;
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: hasImage ? _typeColor : Colors.grey.shade300,
          foregroundColor: hasImage ? Colors.white : Colors.grey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: hasImage ? 3 : 0,
        ),
        icon: Icon(
          _selectedScanType == 'ugonjwa'
              ? Icons.biotech
              : _selectedScanType == 'magugu'
                  ? Icons.grass
                  : Icons.pest_control,
          size: 24,
        ),
        label: Text(
          hasImage
              ? _currentType['buttonLabel'] as String
              : 'Piga Picha Kwanza',
          style: GoogleFonts.dmSans(
              fontSize: 17, fontWeight: FontWeight.bold),
        ),
        onPressed: hasImage ? _analysePhoto : null,
      ),
    );
  }

  // ── Tip card ──────────────────────────────────────────────────────────────

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _typeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: _typeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: _typeColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _currentType['tip'] as String,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.soil, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable action button ────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: outlined
          ? OutlinedButton.icon(
              icon: Icon(icon, size: 18),
              label: Text(label,
                  style:
                      GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          : ElevatedButton.icon(
              icon: Icon(icon, size: 18),
              label: Text(label,
                  style:
                      GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
    );
  }
}
