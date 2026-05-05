import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading         = false;
  bool _passwordVisible = false;
  String _errorMessage  = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Weka barua pepe yako.');
      return;
    }
    if (_passwordCtrl.text.isEmpty) {
      setState(() => _errorMessage = 'Weka nywila yako.');
      return;
    }

    setState(() { _loading = true; _errorMessage = ''; });

    final error = await context
        .read<AuthProvider>()
        .login(_emailCtrl.text, _passwordCtrl.text);

    setState(() => _loading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    }
    // On success, AuthGate in main.dart watches auth.isLoggedIn and automatically
    // swaps LoginScreen → MainShell. No manual Navigator push needed.
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8860A).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC8860A), width: 2),
                    ),
                    child: const Center(
                      child: Text('🌿', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Shamba Smart',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 6),
                  Text('Daktari wa Shamba Lako',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: const Color(0xFFC8860A))),
                  const SizedBox(height: 40),

                  // Login card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Ingia',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),

                        // ── Email field ─────────────────────────────────────
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decor(
                            'Barua Pepe',
                            'mfano@gmail.com',
                            Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Password field ──────────────────────────────────
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: !_passwordVisible,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => _login(),
                          decoration: _decor(
                            'Nywila',
                            '••••••',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white38,
                              ),
                              onPressed: () => setState(
                                  () => _passwordVisible = !_passwordVisible),
                            ),
                          ),
                        ),

                        // Error
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_errorMessage,
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 13),
                                textAlign: TextAlign.center),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Login button
                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC8860A),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text('Ingia',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  )),
                        ),

                        const SizedBox(height: 16),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Huna akaunti? ',
                                style: GoogleFonts.dmSans(
                                    color: Colors.white54)),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              ),
                              child: Text(
                                'Jisajili Sasa',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFFC8860A),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: const Color(0xFFC8860A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decor(String label, String hint, IconData icon) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white38),
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
}
