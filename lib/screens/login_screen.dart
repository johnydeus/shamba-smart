import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kGold        = Color(0xFFEAB308);   // yellow-500
const _kGoldBright  = Color(0xFFFACC15);   // yellow-400
const _kDark        = Color(0xFF111827);   // dark overlay base
const _kBgUrl       =
    'https://images.unsplash.com/photo-1625246333195-78d9c38ad449'
    '?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── State (unchanged from original) ────────────────────────────────────────
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading         = false;
  bool _passwordVisible = false;
  String _errorMessage  = '';

  // ── Button press animation ──────────────────────────────────────────────────
  bool _buttonPressed = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic (100% unchanged from original) ───────────────────────────────
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
    // On success, AuthGate in main.dart watches auth.isLoggedIn and
    // automatically swaps LoginScreen → MainShell. No Navigator push needed.
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: full-screen background image ──────────────────────────
          CachedNetworkImage(
            imageUrl: _kBgUrl,
            fit: BoxFit.cover,
            // Dark green fallback while image loads or on error
            placeholder: (_, _) => const ColoredBox(color: Color(0xFF0D1F0F)),
            errorWidget:  (_, _, _) => const ColoredBox(color: Color(0xFF0D1F0F)),
          ),

          // ── Dark overlay on top of image ───────────────────────────────────
          Container(color: _kDark.withValues(alpha: 0.60)),

          // ── Scrollable content ─────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LogoSection(),
                        const SizedBox(height: 36),
                        _GlassCard(
                          errorMessage: _errorMessage,
                          loading: _loading,
                          passwordVisible: _passwordVisible,
                          buttonPressed: _buttonPressed,
                          emailCtrl: _emailCtrl,
                          passwordCtrl: _passwordCtrl,
                          onTogglePassword: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                          onLogin: _login,
                          onButtonPressStart: () =>
                              setState(() => _buttonPressed = true),
                          onButtonPressEnd: () =>
                              setState(() => _buttonPressed = false),
                          onRegister: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo section ──────────────────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gold glowing circle with sprout icon
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kGold.withValues(alpha: 0.20),
            border: Border.all(
              color: _kGold.withValues(alpha: 0.50),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _kGold.withValues(alpha: 0.30),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.energy_savings_leaf,
            size: 48,
            color: _kGoldBright,
          ),
        ),
        const SizedBox(height: 16),

        // "Shamba Smart" in PlayfairDisplay serif
        Text(
          'Shamba Smart',
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // "DAKTARI WA SHAMBA LAKO" in gold caps
        Text(
          'DAKTARI WA SHAMBA LAKO',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kGoldBright,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

// ── Glassmorphism card ────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final String errorMessage;
  final bool loading;
  final bool passwordVisible;
  final bool buttonPressed;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onButtonPressStart;
  final VoidCallback onButtonPressEnd;
  final VoidCallback onRegister;

  const _GlassCard({
    required this.errorMessage,
    required this.loading,
    required this.passwordVisible,
    required this.buttonPressed,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onButtonPressStart,
    required this.onButtonPressEnd,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card title
              Text(
                'Ingia',
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Email field
              _GlassTextField(
                controller: emailCtrl,
                placeholder: 'Barua Pepe',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password field
              _GlassTextField(
                controller: passwordCtrl,
                placeholder: 'Nywila',
                prefixIcon: Icons.lock_outline,
                obscureText: !passwordVisible,
                onSubmitted: (_) => onLogin(),
                suffixIcon: IconButton(
                  icon: Icon(
                    passwordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.70),
                    size: 20,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),

              // Error message
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    errorMessage,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFFF8A80),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Gold login button with press animation
              GestureDetector(
                onTapDown: (_) => onButtonPressStart(),
                onTapUp: (_) {
                  onButtonPressEnd();
                  if (!loading) onLogin();
                },
                onTapCancel: onButtonPressEnd,
                child: AnimatedScale(
                  scale: buttonPressed ? 0.98 : 1.0,
                  duration: const Duration(milliseconds: 80),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: _kGold,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _kGold.withValues(alpha: 0.40),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: _kDark,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Ingia',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _kDark,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Register footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Huna akaunti? ',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: onRegister,
                    child: Text(
                      'Jisajili Sasa',
                      style: GoogleFonts.dmSans(
                        color: _kGoldBright,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom glass text field ───────────────────────────────────────────────────

class _GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _GlassTextField({
    required this.controller,
    required this.placeholder,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  State<_GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<_GlassTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      onSubmitted: widget.onSubmitted,
      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15),
      cursorColor: _kGoldBright,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        hintStyle: GoogleFonts.dmSans(
          color: Colors.white.withValues(alpha: 0.60),
          fontSize: 15,
        ),
        prefixIcon: Icon(
          widget.prefixIcon,
          color: Colors.white.withValues(alpha: 0.70),
          size: 20,
        ),
        suffixIcon: widget.suffixIcon,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.25),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _kGoldBright,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
