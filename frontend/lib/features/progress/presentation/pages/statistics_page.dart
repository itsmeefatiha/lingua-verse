import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/progress_provider.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final analytics = progress.analytics;
    final timeSpent = (analytics?.timeSpentByLanguage ?? const [])
        .map((entry) => entry.durationMinutes)
        .toList();
    final labels = (analytics?.timeSpentByLanguage ?? const [])
        .map((entry) => entry.languageCode.toUpperCase())
        .toList();
    final themes = analytics?.successRateByTheme ?? const [];

    if (progress.isLoading && analytics == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Statistics', style: Theme.of(context).textTheme.headlineSmall),
          if (progress.error != null) ...[
            const SizedBox(height: 8),
            Text(
              progress.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time spent (minutes / day)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(idx >= 0 && idx < labels.length ? labels[idx] : ''),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          timeSpent.length,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: timeSpent[i],
                                width: 18,
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (timeSpent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('No time tracking data yet.'),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: labels.map((label) => Chip(label: Text(label))).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Success rates by theme',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...themes.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(entry.theme),
                              const Spacer(),
                              Text('${(entry.successRate * 100).round()}%'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: entry.successRate,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (themes.isEmpty)
                    const Text('No theme success analytics yet.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final bytes = await context.read<ProgressProvider>().downloadPdfReport();
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    bytes == null
                        ? 'Failed to download PDF report from backend.'
                        : 'PDF downloaded in memory (${bytes.length} bytes).',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download report'),
          ),
        ],
      ),
    );
  }
}
