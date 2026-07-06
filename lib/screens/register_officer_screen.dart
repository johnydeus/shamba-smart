import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/field_officer.dart';
import '../providers/auth_provider.dart';
import '../services/field_officer_service.dart';
import '../theme/app_theme.dart';

const _kRegions = [
  'Arusha', 'Dar es Salaam', 'Dodoma', 'Geita', 'Iringa', 'Kagera', 'Katavi',
  'Kigoma', 'Kilimanjaro', 'Lindi', 'Manyara', 'Mara', 'Mbeya', 'Morogoro',
  'Mtwara', 'Mwanza', 'Njombe', 'Pwani', 'Rukwa', 'Ruvuma', 'Shinyanga',
  'Simiyu', 'Singida', 'Songwe', 'Tabora', 'Tanga',
];

/// "Wasifu wa Mtaalamu" — an Afisa Kilimo creates / edits their own
/// field_officers row (verified=false, status='pending' set by the DB).
class RegisterOfficerScreen extends StatefulWidget {
  const RegisterOfficerScreen({super.key});

  @override
  State<RegisterOfficerScreen> createState() => _RegisterOfficerScreenState();
}

class _RegisterOfficerScreenState extends State<RegisterOfficerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _title = TextEditingController(text: 'Afisa Kilimo');
  final _wasifu = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _visitFee = TextEditingController();
  final _cropInput = TextEditingController();

  String _region = 'Morogoro';
  final List<String> _crops = [];

  bool _loading = true;
  bool _submitting = false;
  FieldOfficer? _existing;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final p = await FieldOfficerService.myProfile(user.id);
      if (p != null) {
        _existing = p;
        _fullName.text = p.fullName;
        _title.text = p.title;
        _region = _kRegions.contains(p.region) ? p.region : 'Morogoro';
        _wasifu.text = p.wasifu;
        _phone.text = p.phone ?? '';
        _whatsapp.text = p.whatsapp ?? '';
        _email.text = p.email ?? '';
        _visitFee.text = p.visitFeeTzs?.toString() ?? '';
        _crops.addAll(p.crops);
      } else if (user.displayName.isNotEmpty) {
        _fullName.text = user.displayName;
        if (user.region.isNotEmpty && _kRegions.contains(user.region)) {
          _region = user.region;
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [
      _fullName, _title, _wasifu, _phone, _whatsapp, _email, _visitFee, _cropInput
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCrop() {
    final v = _cropInput.text.trim();
    if (v.isEmpty) return;
    if (!_crops.contains(v)) setState(() => _crops.add(v));
    _cropInput.clear();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    final draft = FieldOfficer(
      id: _existing?.id ?? '',
      userId: user.id,
      fullName: _fullName.text.trim(),
      title: _title.text.trim().isEmpty ? 'Afisa Kilimo' : _title.text.trim(),
      region: _region,
      wasifu: _wasifu.text.trim(),
      crops: _crops,
      visitFeeTzs: int.tryParse(_visitFee.text.trim()),
      phone: _phone.text.trim(),
      whatsapp: _whatsapp.text.trim(),
      email: _email.text.trim(),
    );

    try {
      if (_existing != null) {
        await FieldOfficerService.update(draft, userId: user.id);
      } else {
        await FieldOfficerService.create(draft, userId: user.id);
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _existing = draft;
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Asante!'),
          content: const Text(
              'Wasifu wako uko hai na unasubiri uthibitisho wa Shamba Smart. '
              'Wakulima wataweza kukuona na kuwasiliana nawe.'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context); // dialog
                  Navigator.pop(context); // screen
                },
                child: const Text('Sawa')),
          ],
        ),
      );
    } catch (e) {
      debugPrint('RegisterOfficer submit error: $e');
      if (!mounted) return;
      setState(() => _submitting = false);
      // Include brief detail so a real failure (RLS, timeout) is
      // distinguishable from a network blip — a bare "jaribu tena" let a
      // failed registration pass as registered.
      final detail = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text('Imeshindwa kuhifadhi. Jaribu tena.\n'
            '(${detail.length > 90 ? detail.substring(0, 90) : detail})'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        title: Text(_existing != null ? 'Hariri Wasifu' : 'Jisajili kama Mtaalamu',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00695C)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_existing != null && !_existing!.verified)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Icon(Icons.hourglass_top,
                            size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                            child: Text('Wasifu wako unasubiri uthibitisho.',
                                style: TextStyle(fontSize: 12))),
                      ]),
                    ),
                  _field(_fullName, 'Jina kamili *', required: true),
                  const SizedBox(height: 12),
                  _field(_title, 'Cheo / Wadhifa *', required: true),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _region,
                    decoration: _dec('Mkoa *'),
                    items: _kRegions
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _region = v ?? _region),
                  ),
                  const SizedBox(height: 12),
                  _field(_wasifu, 'Wasifu (maelezo kuhusu wewe) *',
                      required: true, maxLines: 4),
                  const SizedBox(height: 12),
                  _field(_phone, 'Simu *',
                      required: true, keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(_whatsapp, 'WhatsApp *',
                      required: true, keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(_email, 'Barua pepe *',
                      required: true, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  // Crops tag input
                  Text('Mazao unayobobea',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _cropInput,
                        decoration: _dec('mf. Mahindi'),
                        onSubmitted: (_) => _addCrop(),
                      ),
                    ),
                    IconButton(
                        onPressed: _addCrop,
                        icon: const Icon(Icons.add_circle,
                            color: Color(0xFF00695C))),
                  ]),
                  if (_crops.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _crops
                            .map((c) => Chip(
                                  label: Text(c,
                                      style: const TextStyle(fontSize: 12)),
                                  onDeleted: () =>
                                      setState(() => _crops.remove(c)),
                                ))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _field(_visitFee, 'Ada ya ziara TZS (si lazima)',
                      keyboard: TextInputType.number),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00695C),
                          foregroundColor: Colors.white),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_existing != null ? 'Hifadhi' : 'Jisajili',
                              style: GoogleFonts.dmSans(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Wasifu mpya hukaguliwa na Shamba Smart kabla ya kupewa '
                      'alama ya uthibitisho.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      );

  Widget _field(TextEditingController c, String label,
      {bool required = false,
      int maxLines = 1,
      TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: _dec(label),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Jaza sehemu hii' : null
          : null,
    );
  }
}
