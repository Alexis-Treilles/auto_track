import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'providers/app_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'http://192.168.1.30:54321',
    anonKey: 'REMPLACER_PAR_CLE_ANON',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const AutoTrackApp(),
    ),
  );
}

class AutoTrackApp extends StatelessWidget {
  const AutoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoTrack',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (mounted) {
        if (session != null) {
          context.read<AppProvider>().loadVehicles();
        } else {
          context.read<AppProvider>().clear();
        }
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const MainShell();
    }
    return const AuthScreen();
  }
}
