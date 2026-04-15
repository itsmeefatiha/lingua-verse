import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/pages/profile_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../gamification/presentation/pages/leaderboard_page.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../learning/presentation/pages/levels_dashboard_page.dart';
import '../../../learning/presentation/providers/learning_provider.dart';
import '../../../progress/presentation/pages/dashboard_page.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../providers/shell_provider.dart';
import 'unity_ar_placeholder.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetLanguage = context.read<AuthProvider>().user?.targetLanguage;
      context.read<LearningProvider>().fetchLanguages(preferredLanguageCode: targetLanguage);
      context.read<ProgressProvider>().loadDashboard();
      context.read<GamificationProvider>().loadLeaderboard();
      context.read<AuthProvider>().refreshMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellProvider>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        actions: [
          _TopStat(icon: Icons.bolt_rounded, label: '${user?.totalXp ?? 0} XP'),
          _TopStat(icon: Icons.local_fire_department_rounded, label: '${user?.streak ?? 0}'),
          _TopStat(icon: Icons.workspace_premium_rounded, label: 'Lv ${user?.level ?? 1}'),
          const SizedBox(width: 8),
        ],
      ),
      body: const AnimatedSwitcher(
        duration: Duration(milliseconds: 280),
        child: _ShellBody(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.index,
        onDestinationSelected: shell.setIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Lessons'),
          NavigationDestination(icon: Icon(Icons.view_in_ar_outlined), label: 'AR'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), label: 'Leaderboard'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ShellBody extends StatelessWidget {
  const _ShellBody();

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellProvider>();

    switch (shell.index) {
      case 0:
        return const DashboardPage();
      case 1:
        return const LevelsDashboardPage();
      case 2:
        return const UnityARPlaceholder();
      case 3:
        return const LeaderboardPage();
      case 4:
      default:
        return const ProfilePage();
    }
  }
}

class _TopStat extends StatelessWidget {
  const _TopStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }
}
