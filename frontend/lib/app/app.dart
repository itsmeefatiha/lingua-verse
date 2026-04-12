import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/pages/splash_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import 'theme/app_theme.dart';

class LinguaVerseApp extends StatelessWidget {
  const LinguaVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LinguaVerse',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: auth.themeMode,
      home: const SplashScreen(),
    );
  }
}
