import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

const List<String> kRegions = [
  'Arusha', 'Dar es Salaam', 'Dodoma', 'Geita', 'Iringa',
  'Kagera', 'Katavi', 'Kigoma', 'Kilimanjaro', 'Lindi',
  'Manyara', 'Mara', 'Mbeya', 'Morogoro', 'Mtwara',
  'Mwanza', 'Njombe', 'Pwani', 'Rukwa', 'Ruvuma',
  'Shinyanga', 'Simiyu', 'Singida', 'Tabora', 'Tanga',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Step 1 = pick role, Step 2 = fill form
  int _step = 1;
  UserRole? _selectedRole;
  bool _loading = false;
  bool _passwordVisible = false;
  String _errorMessage = '';

  // Common controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _region = 'Morogoro';

  // Mkulima controllers
  final _farmSizeCtrl = TextEditingController();
  final _mainCropsCtrl = TextEditingController();

  // Duka controllers
  final _shopNameCtrl = TextEditingController();
  String _productType = 'all';

  // Muuzaji controllers
  final _businessNameCtrl = TextEditingController();
  final _cropsTradedCtrl = TextEditingController();

  // Mwekezaji
  String _investmentType = 'land_lease';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _farmSizeCtrl.dispose();
    _mainCropsCtrl.dispose();
    _shopNameCtrl.dispose();
    _businessNameCtrl.dispose();
    _cropsTradedCtrl.dispose();
    super.dispose();
  }

  // Role definition data for the picker cards
  List<Map<String, dynamic>> get _roles => [
        {
          'role': UserRole.mkulima,
          'emoji': '🌿',
          'title': 'Mkulima',
          'subtitle': 'Nalima mazao na kuuza',
          'color': const Color(0xFF2E7D32),
        },
        {
          'role': UserRole.duka,
          'emoji': '🏪',
          'title': 'Duka la Dawa',
          'subtitle': 'Nauza pembejeo za kilimo',
          'color': const Color(0xFF1565C0),
        },
        {
          'role': UserRole.muuzaji,
          'emoji': '📈',
          'title': 'Muuzaji/Dalali',
          'subtitle': 'Ninunua na kuuza mazao',
          'color': const Color(0xFF6A1B9A),
        },
        {
          'role': UserRole.mwekezaji,
          'emoji': '💼',
          'title': 'Mwekezaji',
          'subtitle': 'Nawekeza katika kilimo',
          'color': const Color(0xFFC8860A),
        },
      ];

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    final auth = context.read<AuthProvider>();

    final error = await auth.register(
      firstName: _firstNameCtrl.text,
      lastName: _lastNameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      region: _region,
      role: _selectedRole!,
      shopName: _selectedRole == UserRole.duka
          ? _shopNameCtrl.text.trim()
          : null,
      productType:
          _selectedRole == UserRole.duka ? _productType : null,
      businessName: _selectedRole == UserRole.muuzaji
          ? _businessNameCtrl.text.trim()
          : null,
      cropsTraded: _selectedRole == UserRole.muuzaji
          ? _cropsTradedCtrl.text.trim()
          : null,
      investmentType: _selectedRole == UserRole.mwekezaji
          ? _investmentType
          : null,
    );

    setState(() => _loading = false);

    if (error == null && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = error ?? 'Hitilafu isiyojulikana.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1108), Color(0xFF4A2C0E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white70),
                      onPressed: () {
                        if (_step == 2) {
                          setState(() {
                            _step = 1;
                            _selectedRole = null;
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        _step == 1
                            ? 'Chagua Aina Yako'
                            : 'Jaza Taarifa Zako',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Step indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Hatua $_step/2',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _step == 1 ? _buildRolePicker() : _buildForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: Role picker ──────────────────────────────────────────────────

  Widget _buildRolePicker() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Wewe ni nani katika kilimo?',
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),

          // 2×2 grid of role cards
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              children: _roles.map((r) {
                final role = r['role'] as UserRole;
                final selected = _selectedRole == role;
                final color = r['color'] as Color;

                return GestureDetector(
                  onTap: () => setState(() => _selectedRole = role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? color : Colors.white24,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(r['emoji'] as String,
                              style: const TextStyle(fontSize: 36)),
                          const SizedBox(height: 10),
                          Text(
                            r['title'] as String,
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            r['subtitle'] as String,
                            style: GoogleFonts.dmSans(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRole == null
                  ? null
                  : () => setState(() => _step = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8860A),
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Endelea →',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Registration form ─────────────────────────────────────────────

  Widget _buildForm() {
    final roleData = _roles.firstWhere(
        (r) => r['role'] == _selectedRole);
    final roleColor = roleData['color'] as Color;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role badge at top
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${roleData['emoji']}  ${roleData['title']}',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Common fields ──────────────────────────────────────────
          _field(_firstNameCtrl, 'Jina la Kwanza', Icons.person_outline),
          const SizedBox(height: 12),
          _field(_lastNameCtrl, 'Jina la Ukoo', Icons.person_outline),
          const SizedBox(height: 12),
          _field(_emailCtrl, 'Barua Pepe',
              Icons.email_outlined,
              type: TextInputType.emailAddress),
          const SizedBox(height: 12),

          // Region dropdown
          _dropdown(
            label: 'Mkoa',
            value: _region,
            items: kRegions,
            onChanged: (v) => setState(() => _region = v!),
          ),
          const SizedBox(height: 12),

          // Password
          TextField(
            controller: _passwordCtrl,
            obscureText: !_passwordVisible,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecor('Nywila (angalau herufi 6)',
                    Icons.lock_outline)
                .copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Role-specific fields ───────────────────────────────────
          // Note: mkulima farm data is collected after registration
          // via FarmsScreen to support multiple farms per farmer
          if (_selectedRole == UserRole.duka) ..._dukaFields(),
          if (_selectedRole == UserRole.muuzaji) ..._muuzajiFields(),
          if (_selectedRole == UserRole.mwekezaji) ..._mwekezajiFields(),

          // Error message
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Jisajili Sasa',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Role-specific field groups ─────────────────────────────────────────────


  List<Widget> _dukaFields() => [
        Text('Taarifa za Duka',
            style: GoogleFonts.dmSans(
                color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _field(_shopNameCtrl, 'Jina la Duka', Icons.store_outlined),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Aina ya Bidhaa',
          value: _productType,
          items: const [
            'all', 'pesticides', 'fertilizers', 'seeds', 'tools'
          ],
          itemLabels: const {
            'all': 'Bidhaa Zote',
            'pesticides': 'Dawa za Kilimo',
            'fertilizers': 'Mbolea',
            'seeds': 'Mbegu',
            'tools': 'Zana za Kilimo',
          },
          onChanged: (v) => setState(() => _productType = v!),
        ),
        const SizedBox(height: 12),
      ];

  List<Widget> _muuzajiFields() => [
        Text('Taarifa za Biashara',
            style: GoogleFonts.dmSans(
                color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _field(_businessNameCtrl, 'Jina la Biashara',
            Icons.business_outlined),
        const SizedBox(height: 12),
        _field(_cropsTradedCtrl,
            'Mazao Unayonunua (mfano: Mahindi, Maharage)',
            Icons.shopping_basket_outlined),
        const SizedBox(height: 12),
      ];

  List<Widget> _mwekezajiFields() => [
        Text('Aina ya Uwekezaji',
            style: GoogleFonts.dmSans(
                color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _dropdown(
          label: 'Aina ya Uwekezaji',
          value: _investmentType,
          items: const [
            'land_lease',
            'project_funding',
            'bulk_purchase',
            'infrastructure'
          ],
          itemLabels: const {
            'land_lease': 'Kukodisha Ardhi',
            'project_funding': 'Kufadhili Mradi',
            'bulk_purchase': 'Kununua Kwa Wingi',
            'infrastructure': 'Miundombinu ya Kilimo',
          },
          onChanged: (v) => setState(() => _investmentType = v!),
        ),
        const SizedBox(height: 12),
      ];

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecor(label, icon),
      );

  InputDecoration _inputDecor(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFC8860A), width: 1.5),
        ),
      );

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    Map<String, String>? itemLabels,
    required ValueChanged<String?> onChanged,
  }) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: const Color(0xFF2C1A0A),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: items
            .map((v) => DropdownMenuItem(
                  value: v,
                  child:
                      Text(itemLabels?[v] ?? v),
                ))
            .toList(),
        onChanged: onChanged,
      );
}
