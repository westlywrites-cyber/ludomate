import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: LudoMateApp()));
}

class LudoMateApp extends StatelessWidget {
  const LudoMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LudoMate',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
