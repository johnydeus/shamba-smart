import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/agrovet_model.dart';
import '../providers/auth_provider.dart';
import '../services/agrovet_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

const _kRegions = [
  'Arusha', 'Dar es Salaam', 'Dodoma', 'Geita', 'Iringa', 'Kagera', 'Katavi',
  'Kigoma', 'Kilimanjaro', 'Lindi', 'Manyara', 'Mara', 'Mbeya', 'Morogoro',
  'Mtwara', 'Mwanza', 'Njombe', 'Pwani', 'Rukwa', 'Ruvuma', 'Shinyanga',
  'Simiyu', 'Singida', 'Songwe', 'Tabora', 'Tanga',
];

class RegisterAgrovetScreen extends StatefulWidget {
  const RegisterAgrovetScreen({super.key});

  @override
  State<RegisterAgrovetScreen> createState() => _RegisterAgrovetScreenState();
}

class _RegisterAgrovetScreenState extends State<RegisterAgrovetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _district = TextEditingController();
  final _ward = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();

  String _region = 'Morogoro';
  String _type = 'private';
  final Set<AgrovetCategory> _categories = {};
  double? _lat, _lng;
  bool _gpsBusy = false;
  bool _submitting = false;

  AgrovetModel? _existing;
  bool _loadingExisting = true;

  static const _allCategories = AgrovetCategory.values;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _existing = await AgrovetService.myListing(user.id);
    }
    if (mounted) setState(() => _loadingExisting = false);
  }

  @override
  void dispose() {
    for (final c in [_name, _district, _ward, _description, _phone, _whatsapp]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _grabGps() async {
    setState(() => _gpsBusy = true);
    final (lat, lng) = await LocationService.getLocationOrDefault();
    setState(() {
      _lat = lat;
      _lng = lng;
      _gpsBusy = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categories.isEmpty) {
      _snack('Chagua angalau aina moja ya bidhaa unazouza.');
      return;
    }
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    final draft = AgrovetModel(
      id: '',
      name: _name.text.trim(),
      type: _type,
      categories: _categories.map((c) => c.key).toList(),
      region: _region,
      district: _district.text.trim().isEmpty ? null : _district.text.trim(),
      ward: _ward.text.trim().isEmpty ? null : _ward.text.trim(),
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      latitude: _lat,
      longitude: _lng,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      whatsapp: _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
    );

    try {
      await AgrovetService.register(draft, ownerId: user.id);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _existing = draft;
      });
      _snack('Duka lako limesajiliwa! Linasubiri uthibitisho.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack('Imeshindwa kusajili. Jaribu tena.');
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('Sajili Duka Lako',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loadingExisting
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _existing != null
              ? _statusView()
              : _form(),
    );
  }

  Widget _statusView() {
    final pending = !_existing!.isVerified;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(pending ? Icons.hourglass_top : Icons.verified,
                size: 64,
                color: pending ? AppColors.warning : AppColors.primary),
            const SizedBox(height: 16),
            Text(_existing!.name,
                style: GoogleFonts.dmSans(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              pending
                  ? 'Duka lako linasubiri uthibitisho wa afisa. Litaonekana '
                      'kwa wakulima baada ya kuthibitishwa.'
                  : 'Duka lako limethibitishwa na linaonekana kwa wakulima.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_name, 'Jina la Duka *', required: true),
          const SizedBox(height: 12),
          Text('Aina ya duka', style: _labelStyle()),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ('private', 'Binafsi'),
              ('cooperative', 'Ushirika'),
              ('government', 'Serikali'),
            ].map((t) => ChoiceChip(
                  label: Text(t.$2),
                  selected: _type == t.$1,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color: _type == t.$1 ? Colors.white : AppColors.textSecondary,
                      fontSize: 12),
                  onSelected: (_) => setState(() => _type = t.$1),
                )).toList(),
          ),
          const SizedBox(height: 12),
          Text('Unauza nini? *', style: _labelStyle()),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _allCategories.map((c) {
              final on = _categories.contains(c);
              return FilterChip(
                label: Text('${c.emoji} ${c.labelSw}'),
                selected: on,
                selectedColor: AppColors.primarySoft,
                checkmarkColor: AppColors.primary,
                labelStyle: const TextStyle(fontSize: 12),
                onSelected: (_) => setState(() =>
                    on ? _categories.remove(c) : _categories.add(c)),
              );
            }).toList(),
          ),
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
          _field(_district, 'Wilaya'),
          const SizedBox(height: 12),
          _field(_ward, 'Kata'),
          const SizedBox(height: 12),
          _field(_description, 'Maelezo ya mahali (mf. "mkabala na soko la Kibaha")',
              maxLines: 2),
          const SizedBox(height: 12),
          _field(_phone, 'Namba ya simu *', required: true, keyboard: TextInputType.phone),
          const SizedBox(height: 12),
          _field(_whatsapp, 'WhatsApp (kama ni tofauti)', keyboard: TextInputType.phone),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _gpsBusy ? null : _grabGps,
            icon: _gpsBusy
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_lat != null ? Icons.check_circle : Icons.my_location,
                    size: 18,
                    color: _lat != null ? AppColors.success : AppColors.primary),
            label: Text(_lat != null
                ? 'Eneo limewekwa (si lazima)'
                : 'Weka eneo la GPS (si lazima)'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Sajili Duka',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Duka jipya linakaguliwa na afisa kabla ya kuonekana kwa wakulima.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.dmSans(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

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
