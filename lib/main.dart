import 'package:flutter/material.dart';
import 'package:leetcode_ranking/leaderboard_page.dart';
import 'package:flutter/services.dart';
import 'package:leetcode_ranking/login_page.dart';
import 'package:leetcode_ranking/registeration_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(),
      home: LoginPage(),
    );
  }
}
