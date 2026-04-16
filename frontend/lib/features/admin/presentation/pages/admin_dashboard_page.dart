import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_dashboard_provider.dart';

const Color _primaryTeal = Color(0xFF00D1C1);
const Color _secondaryPurple = Color(0xFF6B5BD8);

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
      context.read<AdminDashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminDashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminDashboardProvider>().load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Welcome back !',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Here is your dashboard overview for today.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 18),
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
              _PopularLanguagesCard(stats: admin.stats!),
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
      ('Avg time spent', '${stats.averageTimeSpentMinutes.toStringAsFixed(1)} min'),
      ('Active users', stats.activeUsers.toString()),
      ('Average XP', stats.averageXp.toStringAsFixed(1)),
      ('Bronze users', stats.bronzeUsers.toString()),
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

class _PopularLanguagesCard extends StatelessWidget {
  const _PopularLanguagesCard({required this.stats});

  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    final bars = stats.popularLanguages as List<dynamic>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Most Popular Target Languages', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: bars.isEmpty
                  ? const Center(child: Text('No activity yet'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _maxY(bars),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 38)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= bars.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text((bars[index].languageCode as String).toUpperCase(), style: const TextStyle(fontSize: 11)),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          bars.length,
                          (index) {
                            final entry = bars[index];
                            final barColor = index.isEven ? _primaryTeal : _secondaryPurple;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: (entry.durationMinutes as num).toDouble(),
                                  width: 18,
                                  borderRadius: BorderRadius.circular(8),
                                  color: barColor,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _maxY(List<dynamic> bars) {
    final values = bars.map((entry) => (entry.durationMinutes as num).toDouble()).toList();
    final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    return maxValue <= 0 ? 1.0 : maxValue * 1.2;
  }
}
