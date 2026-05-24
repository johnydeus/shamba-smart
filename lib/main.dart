import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/listing_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/satellite_provider.dart';
import 'providers/farm_provider.dart';
import 'providers/community_provider.dart';
import 'models/user_model.dart';
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
  // Initialize immediately if user is already logged in
  if (authProvider.isLoggedIn && authProvider.currentUser != null) {
    final u = authProvider.currentUser!;
    await chatProvider.init(u.id, u.displayName, u.role.name);
  }

  final satelliteProvider = SatelliteProvider();
  await satelliteProvider.init();

  final farmProvider = FarmProvider();
  if (authProvider.isLoggedIn && authProvider.currentUser != null) {
    await farmProvider.init(authProvider.currentUser!.id);
  }

  final communityProvider = CommunityProvider();
  await communityProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: listingProvider),
        ChangeNotifierProvider.value(value: chatProvider),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider.value(value: satelliteProvider),
        ChangeNotifierProvider.value(value: farmProvider),
        ChangeNotifierProvider.value(value: communityProvider),
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
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

// Decides whether to show home or login based on local auth session
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // When a new user logs in, initialise all per-user providers
    if (auth.isLoggedIn && auth.currentUser?.id != _lastUserId) {
      _lastUserId = auth.currentUser!.id;
      final user = auth.currentUser!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FarmProvider>().init(user.id);
        context.read<ChatProvider>().init(user.id, user.displayName, user.role.key);
        context.read<CommunityProvider>().loadPosts();
      });
    }

    if (!auth.isLoggedIn && _lastUserId != null) {
      _lastUserId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FarmProvider>().clear();
        context.read<ChatProvider>().clear();
      });
    }

    return auth.isLoggedIn ? const MainShell() : const LoginScreen();
  }
}
