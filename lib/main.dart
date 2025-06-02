import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leetcode_ranking/custom_leaderboard.dart';
import 'package:leetcode_ranking/main_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:leetcode_ranking/leaderboard_page.dart';
import 'package:leetcode_ranking/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: '',
    anonKey: '',
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session != null && session.user != null) {
          return MainDashboard();
        } else {
          return LoginPage();
        }
      },
    );
  }
}
