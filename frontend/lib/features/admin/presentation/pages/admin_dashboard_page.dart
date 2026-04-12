import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadStats(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (admin.isLoading && admin.stats == null)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (admin.error != null)
              Text(
                admin.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (admin.stats != null) ...[
              _StatGrid(stats: admin.stats!),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top users', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ...admin.stats!.topUsers.map(
                        (user) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(user.fullName),
                          subtitle: Text('${user.email} • ${user.currentLeague}'),
                          trailing: Text('${user.totalXp} XP'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total users', stats.totalUsers.toString()),
      ('Active users', stats.activeUsers.toString()),
      ('Students', stats.studentUsers.toString()),
      ('Teachers', stats.teacherUsers.toString()),
      ('Admins', stats.adminUsers.toString()),
      ('Total XP', stats.totalXpDistributed.toString()),
      ('Average XP', stats.averageXp.toStringAsFixed(1)),
      ('Leagues B/A/O', '${stats.bronzeUsers}/${stats.argentUsers}/${stats.orUsers}'),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.$1, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(item.$2, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        );
      },
    );
  }
}
