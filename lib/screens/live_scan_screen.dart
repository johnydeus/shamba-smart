import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../features/scan/domain/scan_request.dart';
import '../providers/live_scan_provider.dart';
import '../providers/scan_provider.dart';
import '../routes/fade_slide_route.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../config/crops.dart' show kCrops;
import 'results_screen.dart';

/// Full-screen live-inference scanner.
///
/// Architecture:
/// 1. [LiveScanProvider] is created locally (screen-scoped) so camera
///    resources are guaranteed to be released when this screen is disposed.
/// 2. [WidgetsBindingObserver] stops the stream on background and
///    restarts it on foreground — CRITICAL for battery and camera hardware.
/// 3. "Chunguza Zaidi" takes a still, runs the full ScanProvider pipeline
///    (MkulimaAI + Claude), then navigates to ResultsScreen.
class LiveScanScreen extends StatefulWidget {
  const LiveScanScreen({super.key});

  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen>
    with WidgetsBindingObserver {
  // Screen-scoped provider — not in global tree.
  final _provider = LiveScanProvider();

  String _selectedCrop = kCrops.first;
  bool _analysing = false; // true while running full ScanProvider analysis

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start after first frame so the build context is ready.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _provider.startScanning());
    _provider.addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _provider.removeListener(_onProviderUpdate);
    _provider.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _provider.stopScanning();
      case AppLifecycleState.resumed:
        if (!_provider.isScanning && !_provider.isInitialising) {
          _provider.resumeScanning();
        }
      default:
        break;
    }
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Captures a still, runs full analysis, navigates to ResultsScreen.
  Future<void> _deepAnalysis() async {
    if (_analysing) return;
    HapticFeedback.mediumImpact();

    setState(() => _analysing = true);

    final imagePath = await _provider.captureAndStop();
    if (!mounted) return;

    if (imagePath == null) {
      setState(() => _analysing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Haikuweza kupiga picha. Jaribu tena.'),
        ),
      );
      _provider.resumeScanning();
      return;
    }

    // Get GPS for enriched diagnosis.
    double? gpsLat, gpsLng;
    try {
      final pos = await LocationService.getCurrentLocation();
      gpsLat = pos.latitude;
      gpsLng = pos.longitude;
    } catch (_) {}

    if (!mounted) return;

    final scanProvider = context.read<ScanProvider>();
    final result = await scanProvider.analyze(
      ScanRequest(
        imagePath: imagePath,
        cropName: _selectedCrop,
        scanType: 'ugonjwa',
        gpsLat: gpsLat,
        gpsLng: gpsLng,
      ),
    );

    if (!mounted) return;
    setState(() => _analysing = false);

    if (result == null ||
        (result.hasError && result.mkulimaResult == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            scanProvider.errorMessage ?? 'Uchunguzi umeshindwa. Jaribu tena.',
          ),
        ),
      );
      _provider.resumeScanning();
      return;
    }

    // Navigate: pushReplacement releases the camera controller cleanly.
    Navigator.pushReplacement(
      context,
      FadeSlideRoute(
        page: ResultsScreen(
          diagnosis: result.diagnosis,
          imagePath: imagePath,
          cropName: _selectedCrop,
          mkulimaResult: result.mkulimaResult,
          cloudEnrichment: result.cloudEnrichment,
          scanSource: result.sourceLabel,
          queuedForEnrichment: result.queuedForEnrichment,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LiveScanProvider>.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_provider.initError != null) return _buildErrorState();
    if (_provider.isInitialising ||
        _provider.cameraController == null ||
        !(_provider.cameraController!.value.isInitialized)) {
      return _buildLoadingState();
    }
    return _buildCameraView();
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Inaanzisha kamera...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              _provider.initError ?? 'Hitilafu ya kamera',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _provider.startScanning();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text('Jaribu Tena'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Rudi',
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main camera view ──────────────────────────────────────────────────────
  Widget _buildCameraView() {
    final ctrl = _provider.cameraController!;
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Full-screen camera preview ──────────────────────────────────
        _buildCameraPreview(ctrl),

        // ── Scanning frame overlay ──────────────────────────────────────
        const _ScanFrameOverlay(),

        // ── Top bar ────────────────────────────────────────────────────
        _buildTopBar(),

        // ── Crop selector ───────────────────────────────────────────────
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: _buildCropStrip(),
        ),

        // ── Result card (slides up when stable label found) ─────────────
        if (_provider.stableLabel != null && !_analysing)
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: _buildResultCard(),
          ),

        // ── Analysis loading overlay ────────────────────────────────────
        if (_analysing) _buildAnalysingOverlay(),
      ],
    );
  }

  Widget _buildCameraPreview(CameraController ctrl) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          // preview size is reported in landscape; swap for portrait
          width: ctrl.value.previewSize?.height ?? 720,
          height: ctrl.value.previewSize?.width ?? 1280,
          child: CameraPreview(ctrl),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final ms = _provider.avgInferenceMs.round();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.75),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Skani ya Moja kwa Moja',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Inference-time badge.
                if (ms > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _msColor(ms).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${ms}ms',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _msColor(int ms) {
    if (ms < 150) return const Color(0xFF2E7D32); // fast — green
    if (ms < 300) return const Color(0xFFE65100); // medium — orange
    return const Color(0xFFC62828); // slow — red
  }

  // ── Crop selector strip ───────────────────────────────────────────────────
  Widget _buildCropStrip() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kCrops.length,
        itemBuilder: (_, i) {
          final crop = kCrops[i];
          final selected = crop == _selectedCrop;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCrop = crop),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  crop,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Result card ───────────────────────────────────────────────────────────
  Widget _buildResultCard() {
    final label = _provider.stableLabel!;
    final conf = _provider.stableConfidence;
    final isHealthy = _provider.stableKey?.toLowerCase().contains('healthy') == true;
    final cardColor = isHealthy
        ? const Color(0xFF1B5E20)
        : conf > 0.75
            ? const Color(0xFFB71C1C)
            : const Color(0xFFE65100);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Disease name + confidence badge row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(conf * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Confidence bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: conf,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(cardColor),
              ),
            ),
            const SizedBox(height: 14),

            // Actions row
            Row(
              children: [
                // Crop indicator
                Text(
                  '🌱 $_selectedCrop',
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // Deep analysis CTA
                ElevatedButton.icon(
                  onPressed: _deepAnalysis,
                  icon: const Icon(Icons.biotech_outlined, size: 16),
                  label: Text(
                    'Chunguza Zaidi',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }

  // ── Analysis loading overlay ──────────────────────────────────────────────
  Widget _buildAnalysingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mkulima AI inachunguza...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Viewfinder overlay
// ─────────────────────────────────────────────────────────────────────────────

class _ScanFrameOverlay extends StatefulWidget {
  const _ScanFrameOverlay();

  @override
  State<_ScanFrameOverlay> createState() => _ScanFrameOverlayState();
}

class _ScanFrameOverlayState extends State<_ScanFrameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final alpha = 0.6 + 0.4 * _ctrl.value;
        return CustomPaint(
          painter: _FramePainter(
            color:
                AppColors.primaryLight.withValues(alpha: alpha),
          ),
        );
      },
    );
  }
}

class _FramePainter extends CustomPainter {
  final Color color;
  const _FramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const frameW = 0.65;
    const frameH = 0.45;
    const len = 24.0;

    final left = size.width * (1 - frameW) / 2;
    final right = size.width * (1 + frameW) / 2;
    final top = size.height * (1 - frameH) / 2;
    final bottom = size.height * (1 + frameH) / 2;

    void corner(double x, double y, bool tl, bool tr) {
      final path = Path();
      if (tl) {
        path.moveTo(x, y + len);
        path.lineTo(x, y);
        path.lineTo(x + len, y);
      } else if (tr) {
        path.moveTo(x - len, y);
        path.lineTo(x, y);
        path.lineTo(x, y + len);
      } else if (!tl && !tr) {
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

    corner(left, top, true, false);
    corner(right, top, false, true);
    corner(left, bottom, false, false);
    corner(right, bottom, false, false);
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => old.color != color;
}
