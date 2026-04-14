import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import 'language_selection_page.dart';
import '../../../shell/presentation/pages/main_shell_page.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () async {
      if (!mounted) {
        return;
      }
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        await auth.refreshMe();
      }
      final isAdmin = auth.user?.role.toLowerCase() == 'admin';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => auth.isAuthenticated
              ? (isAdmin
                  ? const AdminDashboardPage()
                  : (auth.needsLanguageSelection
                      ? const LanguageSelectionPage()
                      : const MainShellPage()))
              : const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logoo.png',
          width: 170,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.language, size: 72, color: Colors.teal);
          },
        ),
      ),
    );
  }
}
