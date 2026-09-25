import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/empty_state.dart';
import '../services/ssdm_service.dart';
import 'actions_view.dart';
import 'create_year_dialog.dart';
import 'dashboard_view.dart';
import 'objective_view.dart';
import 'plan_view.dart';

/// Écran principal du module SSDM.
///
/// Une année doit être sélectionnée pour acceder au pilotage
/// (objectif de CA, sales plan, actions).
class SsdmHome extends StatelessWidget {
  const SsdmHome({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();
    final years = service.yearList;

    if (years.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('SSDM')),
        body: EmptyState(
          icon: Icons.event_available_outlined,
          title: 'Aucune année créée',
          message:
              'Commencez par créer une année de gestion pour définir '
              'l\'objectif de CA, le sales plan et les actions.',
          actionLabel: 'Créer une nouvelle année',
          onAction: () => showCreateYearDialog(context),
        ),
      );
    }

    final selected = service.selectedYear ?? years.last;
    if (service.selectedYear != selected) {
      // Premiere ouverture : selectionne la dernière année par défaut.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        service.selectYear(selected);
      });
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SSDM'),
          actions: [
            YearSelector(years: years, selected: selected),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: 'Dashboard'),
              Tab(text: 'Objectif CA'),
              Tab(text: 'Sales Plan'),
              Tab(text: 'Actions'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showCreateYearDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle année'),
        ),
        body: const TabBarView(
          children: [
            DashboardView(),
            ObjectiveView(),
            PlanView(),
            ActionsView(),
          ],
        ),
      ),
    );
  }
}

class YearSelector extends StatelessWidget {
  const YearSelector({super.key, required this.years, required this.selected});

  final List<int> years;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final service = context.read<SsdmService>();
    return DropdownButton<int>(
      value: selected,
      underline: const SizedBox.shrink(),
      items: [
        for (final y in years)
          DropdownMenuItem(value: y, child: Text(y.toString())),
      ],
      onChanged: (value) => service.selectYear(value),
    );
  }
}
