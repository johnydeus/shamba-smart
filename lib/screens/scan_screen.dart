import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../features/scan/domain/scan_request.dart';
import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../routes/fade_slide_route.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shamba_button.dart';
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

// The 3 scan categories the farmer can choose from
const _scanTypes = [
  {
    'key': 'ugonjwa',
    'label': 'Ugonjwa',
    'emoji': '🦠',
    'subtitle': 'Magonjwa ya jani/mmea',
    'color': 0xFF6A1B9A,
    'tip': 'Piga picha karibu na jani lililougua ili AI ione dalili vizuri.',
    'buttonLabel': 'Chunguza Ugonjwa',
    'appBarTitle': 'Gundua Ugonjwa',
  },
  {
    'key': 'magugu',
    'label': 'Magugu',
    'emoji': '🌿',
    'subtitle': 'Tambua magugu shambani',
    'color': 0xFF2E7D32,
    'tip': 'Piga picha ya mmea wote wa gugu — pamoja na majani na shina.',
    'buttonLabel': 'Tambua Gugu',
    'appBarTitle': 'Tambua Magugu',
  },
  {
    'key': 'wadudu',
    'label': 'Wadudu',
    'emoji': '🐛',
    'subtitle': 'Wadudu na uharibifu wao',
    'color': 0xFFE65100,
    'tip': 'Piga picha ya mdudu au uharibifu aliofanya kwenye mmea/jani.',
    'buttonLabel': 'Tambua Mdudu',
    'appBarTitle': 'Gundua Wadudu',
  },
];

const Map<String, String> _cropEmojis = {
  'Mahindi': '🌽',
  'Mchele': '🍚',
  'Nyanya': '🍅',
  'Maharagwe': '🫘',
  'Ndizi': '🍌',
  'Muhogo': '🥔',
  'Pamba': '☁️',
  'Kahawa': '☕',
};

String _cropEmoji(String crop) => _cropEmojis[crop] ?? '🌱';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  String _selectedCrop = kCrops.first;
  String _selectedScanType = 'ugonjwa';
  bool _analysing = false;
  bool _tipsExpanded = false;
  String _statusMessage = '';

  final ImagePicker _picker = ImagePicker();
  late final AnimationController _bracketCtrl;

  Map<String, dynamic> get _currentType =>
      _scanTypes.firstWhere((t) => t['key'] == _selectedScanType);

  Color get _typeColor => Color(_currentType['color'] as int);

  @override
  void initState() {
    super.initState();
    _bracketCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bracketCtrl.dispose();
    super.dispose();
  }

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
    if (_selectedImage == null) return;
    HapticFeedback.mediumImpact();

    _bracketCtrl.stop();
    setState(() {
      _analysing = true;
      _statusMessage = 'Mkulima AI inachunguza picha...';
    });

    double? gpsLat;
    double? gpsLng;
    try {
      final pos = await LocationService.getCurrentLocation();
      gpsLat = pos.latitude;
      gpsLng = pos.longitude;
    } catch (_) {}

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final region = auth.currentUser?.region;
    final scanProvider = context.read<ScanProvider>();
    final result = await scanProvider.analyze(
      ScanRequest(
        imagePath: _selectedImage!.path,
        cropName: _selectedCrop,
        scanType: _selectedScanType,
        gpsLat: gpsLat,
        gpsLng: gpsLng,
        region: region,
      ),
    );

    if (!mounted) return;

    setState(() {
      _analysing = false;
      _statusMessage = '';
    });
    _bracketCtrl.repeat(reverse: true);

    if (result == null || (result.hasError && result.mkulimaResult == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result?.diagnosis['message'] as String? ??
                scanProvider.errorMessage ??
                'Uchunguzi umeshindwa. Jaribu tena.',
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      FadeSlideRoute(
        page: ResultsScreen(
          diagnosis: result.diagnosis,
          imagePath: _selectedImage!.path,
          cropName: _selectedCrop,
          mkulimaResult: result.mkulimaResult,
          cloudEnrichment: result.cloudEnrichment,
          scanSource: result.sourceLabel,
          queuedForEnrichment: result.queuedForEnrichment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_typeColor, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(_currentType['appBarTitle'] as String),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined),
            tooltip: 'Mwanga',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tumia mwanga wa jua au tochi ya simu'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Mkulima AI branding banner ─────────────────────────────────
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mkulima AI',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Inafanya kazi bila mtandao • Aina 34 za magonjwa',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB703).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              const Color(0xFFFFB703).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'v2',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFB703),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scan type selector ─────────────────────────────────────────
            _buildScanTypeSelector(),

            const SizedBox(height: 16),

            // ── Crop selector chips ────────────────────────────────────────
            Text(
              'Chagua Zao:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: kCrops.length,
                itemBuilder: (context, i) {
                  final crop = kCrops[i];
                  final selected = crop == _selectedCrop;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_cropEmoji(crop)),
                          const SizedBox(width: 4),
                          Text(crop),
                          if (selected) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check, size: 14),
                          ],
                        ],
                      ),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedCrop = crop),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? AppColors.white
                            : AppColors.textSecondary,
                      ),
                      checkmarkColor: Colors.transparent,
                      showCheckmark: false,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ── Camera preview / tap area ──────────────────────────────────
            _buildCameraArea(),

            const SizedBox(height: 8),

            // ── Shutter + gallery ──────────────────────────────────────────
            Center(child: _buildShutterButton()),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _analysing ? null : _pickFromGallery,
              icon: const Icon(Icons.folder_outlined),
              label: const Text('Au pakia picha 📁'),
            ),

            const SizedBox(height: 20),

            if (_analysing) _buildLoadingWidget() else _buildAnalyseButton(),

            const SizedBox(height: 16),
            _buildTipCard(),
            const SizedBox(height: 8),
            _buildExpandableTips(),

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
      child: Row(
        children: _scanTypes.map((type) {
          final isSelected = _selectedScanType == type['key'];
          final color = Color(type['color'] as int);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedScanType = type['key'] as String;
                _selectedImage = null; // clear image on type change
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type['emoji'] as String,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type['label'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.mid,
                      ),
                    ),
                    Text(
                      type['subtitle'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        color: isSelected
                            ? Colors.white70
                            : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
          color: _selectedImage != null
              ? AppColors.white
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: _selectedImage != null
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.35),
            width: _selectedImage != null ? 3 : 2,
          ),
          boxShadow: AppShadow.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl - 2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_selectedImage != null)
                Image.file(_selectedImage!, fit: BoxFit.cover),
              AnimatedBuilder(
                animation: _bracketCtrl,
                builder: (context, _) {
                  final pulse = 0.85 + 0.15 * _bracketCtrl.value;
                  return CustomPaint(
                    painter: _ViewfinderPainter(
                      color: AppColors.primaryLight
                          .withValues(alpha: pulse),
                    ),
                  );
                },
              ),
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Text(
                  'Lenga jani zima kwenye fremu',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedImage != null)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                        Text(
                          'Badilisha',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildShutterButton() {
    return _ShutterButton(
      analysing: _analysing,
      hasImage: _selectedImage != null,
      onTap: () {
        if (_selectedImage == null) {
          HapticFeedback.mediumImpact();
          _takePhoto();
        } else if (!_analysing) {
          HapticFeedback.mediumImpact();
          _analysePhoto();
        }
      },
    );
  }

  Widget _buildExpandableTips() {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => setState(() => _tipsExpanded = !_tipsExpanded),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vidokezo vya picha bora',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    _tipsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ],
              ),
              if (_tipsExpanded) ...[
                const SizedBox(height: 8),
                Text(
                  'Picha inayofaa: Mwanga mzuri, jani moja, karibu iwezekanavyo. Epuka picha zenye ukungu au giza.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
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
    return ShambaButton(
      label: hasImage
          ? _currentType['buttonLabel'] as String
          : 'Piga Picha Kwanza',
      icon: _selectedScanType == 'ugonjwa'
          ? Icons.biotech_outlined
          : _selectedScanType == 'magugu'
              ? Icons.grass_outlined
              : Icons.pest_control_outlined,
      onPressed: hasImage ? _analysePhoto : null,
      fullWidth: true,
      isLoading: _analysing,
    );
  }

  // ── Tip card ──────────────────────────────────────────────────────────────

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '💡 Picha inayofaa: Mwanga mzuri, jani moja, karibu iwezekanavyo',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color color;
  const _ViewfinderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const pad = 24.0;

    void corner(double x, double y, bool top, bool left) {
      final path = Path();
      if (top && left) {
        path.moveTo(x, y + len);
        path.lineTo(x, y);
        path.lineTo(x + len, y);
      } else if (top && !left) {
        path.moveTo(x - len, y);
        path.lineTo(x, y);
        path.lineTo(x, y + len);
      } else if (!top && left) {
        path.moveTo(x, y - len);
        path.lineTo(x, y);
        path.lineTo(x + len, y);
      } else {
        path.moveTo(x - len, y);
        path.lineTo(x, y);
        path.lineTo(x, y - len);
      }
      canvas.drawPath(path, paint);
    }

    corner(pad, pad, true, true);
    corner(size.width - pad, pad, true, false);
    corner(pad, size.height - pad, false, true);
    corner(size.width - pad, size.height - pad, false, false);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter old) =>
      old.color != color;
}

class _ShutterButton extends StatefulWidget {
  final bool analysing;
  final bool hasImage;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.analysing,
    required this.hasImage,
    required this.onTap,
  });

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.analysing ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 4),
            boxShadow: AppShadow.green,
          ),
          child: Center(
            child: widget.analysing
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.hasImage
                          ? Icons.biotech_outlined
                          : Icons.camera_alt_outlined,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

