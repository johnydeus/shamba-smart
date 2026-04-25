import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/listing_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/satellite_provider.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file for API keys
  await dotenv.load(fileName: '.env');

  // Connect Supabase (used for AI diagnosis storage and other DB features)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialise providers
  final authProvider = AuthProvider();
  await authProvider.init();

  final listingProvider = ListingProvider();
  await listingProvider.init();

  final chatProvider = ChatProvider();
  await chatProvider.init();

  final satelliteProvider = SatelliteProvider();
  await satelliteProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: listingProvider),
        ChangeNotifierProvider.value(value: chatProvider),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider.value(value: satelliteProvider),
      ],
      child: const ShambaSmart(),
    ),
  );
}

class ShambaSmart extends StatelessWidget {
  const ShambaSmart({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shamba Smart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5C2E),
          primary: const Color(0xFF1A5C2E),
          secondary: const Color(0xFF2E8B57),
          surface: const Color(0xFFFDF6EE),
        ),
        scaffoldBackgroundColor: const Color(0xFFFDF6EE),

        // DM Sans as default body font
        textTheme: GoogleFonts.dmSansTextTheme(
          Theme.of(context).textTheme,
        ),

        cardTheme: const CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          elevation: 2,
          color: Color(0xFFFFFDF8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A5C2E),
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E1108),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// Decides whether to show home or login based on local auth session
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) {
      return const MainShell();
    } else {
      return const LoginScreen();
    }
  }
}
