import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_content_provider.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_user_provider.dart';
import 'admin_content_management_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_profile_page.dart';
import 'admin_user_management_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _index = 0;
  bool _loaded = false;

  final _pages = const [
    AdminDashboardPage(),
    AdminContentManagementPage(),
    AdminUserManagementPage(),
    AdminProfilePage(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDashboardProvider>().load();
      context.read<AdminContentProvider>().loadLanguages();
      context.read<AdminUserProvider>().loadUsers();
      context.read<AuthProvider>().refreshMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Row(
            children: [
              _AdminRail(
                selectedIndex: _index,
                onDestinationSelected: (value) => setState(() => _index = value),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _pages[_index]),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.folder_open_outlined), label: 'Content'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _AdminRail extends StatelessWidget {
  const _AdminRail({required this.selectedIndex, required this.onDestinationSelected});

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.white,
      leading: const Padding(
        padding: EdgeInsets.only(top: 24, bottom: 24),
        child: Text(
          'LinguaVerse\nAdmin',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.folder_open_outlined), selectedIcon: Icon(Icons.folder_open), label: Text('Content')),
        NavigationRailDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: Text('Users')),
        NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
      ],
    );
  }
}
