import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialised = false;
  bool _speaking = false;

  Future<void> initialise() async {
    if (_initialised) return;
    try {
      // Try Swahili Tanzania first
      final langs = await _tts.getLanguages as List?;
      final hasSw = langs?.any((l) => l.toString().startsWith('sw')) ?? false;
      await _tts.setLanguage(hasSw ? 'sw-TZ' : 'sw');
      await _tts.setSpeechRate(0.8);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() => _speaking = false);
      _tts.setErrorHandler((msg) => _speaking = false);
      _initialised = true;
    } catch (e) {
      debugPrint('AudioService init error: $e');
    }
  }

  Future<void> speak(String text) async {
    await initialise();
    try {
      await _tts.stop();
      final clean = _cleanText(text);
      if (clean.isEmpty) return;
      _speaking = true;
      await _tts.speak(clean);
    } catch (e) {
      debugPrint('AudioService speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _speaking = false;
    } catch (_) {}
  }

  bool get isSpeaking => _speaking;

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s\.,!?\-:()]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

// Reusable speaker button widget
class SpeakerButton extends StatefulWidget {
  final String text;
  final Color? color;
  final double size;

  const SpeakerButton({
    super.key,
    required this.text,
    this.color,
    this.size = 22,
  });

  @override
  State<SpeakerButton> createState() => _SpeakerButtonState();
}

class _SpeakerButtonState extends State<SpeakerButton> {
  bool _playing = false;

  Future<void> _toggle() async {
    if (_playing) {
      await AudioService.instance.stop();
      if (mounted) setState(() => _playing = false);
    } else {
      if (mounted) setState(() => _playing = true);
      await AudioService.instance.speak(widget.text);
      // Give TTS time to finish; reset after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _playing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF1A5C2E);
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _playing ? Icons.stop_rounded : Icons.volume_up_rounded,
              color: color,
              size: widget.size,
            ),
            const SizedBox(width: 6),
            Text(
              _playing ? 'Simama' : 'Sikiliza 🔊',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
