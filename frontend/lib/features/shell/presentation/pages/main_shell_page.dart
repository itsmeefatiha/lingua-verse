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
      context.read<LearningProvider>().fetchLanguages(
            preferredLanguageCode: targetLanguage,
          );
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
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        actions: [
          _TopStat(
            icon: Icons.bolt_rounded, 
            label: '${user?.totalXp ?? 0} XP',
            iconColor: Colors.orangeAccent, // Restored Orange Accent
          ),
          _TopStat(
            icon: Icons.local_fire_department_rounded,
            label: '${user?.streak ?? 0}',
            iconColor: Colors.redAccent, // Restored Red Accent
          ),
          const SizedBox(width: 12),
        ],
      ),
      extendBodyBehindAppBar: false,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _ShellBody(key: ValueKey(shell.index)),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 70, 
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700);
              }
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
            }),
          ),
          child: NavigationBar(
            elevation: 0,
            selectedIndex: shell.index,
            onDestinationSelected: shell.setIndex,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                label: 'Lessons',
              ),
              NavigationDestination(
                icon: Icon(Icons.view_in_ar_outlined),
                label: 'AR',
              ),
              NavigationDestination(
                icon: Icon(Icons.leaderboard_outlined),
                label: 'Leaderboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellBody extends StatelessWidget {
  const _ShellBody({super.key});

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
  const _TopStat({
    required this.icon, 
    required this.label, 
    this.iconColor, // Added optional color parameter
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Uses the provided iconColor, or falls back to theme secondary color
            Icon(icon, size: 16, color: iconColor ?? colorScheme.secondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}