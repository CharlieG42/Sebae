import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sales_action.dart';
import '../services/ssdm_service.dart';
import 'create_year_dialog.dart';

final _eur = NumberFormat.compactCurrency(locale: 'fr_FR', symbol: 'EUR');

/// Dashboard de pilotage : objectif vs plan vs réalisé, avancement des actions.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();
    final year = service.selectedYear;
    if (year == null) {
      return const Center(child: Text('Sélectionnez une année.'));
    }

    final objective = service.currentYear?.caObjective ?? 0;
    final planTotal = service.planTotal(year);
    final realized = service.realizedTotal(year);
    final avgProgress = service.averageProgress(year);
    final actions = service.actionsFor(year);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fabNewYearDashboard',
        onPressed: () => showCreateYearDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle année'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Cartes de synthèse ---
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Objectif CA',
                  value: _eur.format(objective),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Sales Plan',
                  value: _eur.format(planTotal),
                  subtitle: objective > 0
                      ? 'Couverture : ${(planTotal / objective * 100).toStringAsFixed(0)} %'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'CA réalisé',
                  value: _eur.format(realized),
                  subtitle: planTotal > 0
                      ? 'Atteinte : ${(realized / planTotal * 100).toStringAsFixed(0)} %'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Avancement moyen des actions',
                  value: '${avgProgress.toStringAsFixed(0)} %',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Actions',
                  value:
                      '${actions.where((a) => a.status == ActionStatus.done).length} / ${actions.length}',
                  subtitle: 'terminées / total',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Graphique : plan vs réalisé par IV ---
          if (service.ivs.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Plan par IV - cible vs réalisé',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 260,
                      child: _PlanByIvChart(service: service, year: year),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _LegendDot(color: Theme.of(context).colorScheme.primary, label: 'Cible'),
                        const SizedBox(width: 16),
                        _LegendDot(color: Theme.of(context).colorScheme.tertiary, label: 'Réalisé'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // --- Avancement des actions ---
          if (actions.isNotEmpty) ...[
            Text('Avancement des actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...actions.take(10).map((a) {
              return ListTile(
                leading: _StatusDot(progress: a.progress),
                title: Text(a.title),
                subtitle: Text(service.ivLabel(a.ivId)),
                trailing: Text('${a.progress} %'),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, this.subtitle});

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final color = progress >= 100
        ? Colors.green
        : progress > 0
            ? Colors.orange
            : Colors.grey;
    return CircleAvatar(radius: 6, backgroundColor: color);
  }
}

class _PlanByIvChart extends StatelessWidget {
  const _PlanByIvChart({required this.service, required this.year});

  final SsdmService service;
  final int year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ivs = service.ivs;
    final planByIv = service.planByIv(year);
    final realizedByIv = service.realizedByIv(year);

    final groups = <BarChartGroupData>[
      for (var i = 0; i < ivs.length; i++)
        BarChartGroupData(
          x: i,
          barsSpace: 8,
          barRods: [
            BarChartRodData(
              toY: planByIv[ivs[i].id] ?? 0,
              color: theme.colorScheme.primary,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: realizedByIv[ivs[i].id] ?? 0,
              color: theme.colorScheme.tertiary,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: groups,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) =>
                  SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      ivs[value.toInt()].shortLabel,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
            ),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
