import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/empty_state.dart';
import '../services/ssdm_service.dart';
import 'actions_view.dart';
import 'create_year_dialog.dart';
import 'dashboard_view.dart';
import 'objective_view.dart';
import 'plan_view.dart';

/// Écran principal du module SSDM.
///
/// Une année doit être sélectionnée pour accéder au pilotage
/// (objectif de CA, sales plan, actions).
///
/// Le bouton "Nouvelle année" est volontairement réservé aux onglets
/// Dashboard et Objectif CA (voir ces vues) : il ne se superpose plus
/// aux autres contenus.
class SsdmHome extends StatefulWidget {
  const SsdmHome({super.key});

  @override
  State<SsdmHome> createState() => _SsdmHomeState();
}

class _SsdmHomeState extends State<SsdmHome>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  SsdmService? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<SsdmService>();
    if (service != _service) {
      _service = service;
      _tabController?.dispose();
      _tabController = TabController(length: 4, vsync: this);
      service.tabController = _tabController;
    }
  }

  @override
  void dispose() {
    _service?.tabController = null;
    _tabController?.dispose();
    super.dispose();
  }

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

    final controller = _tabController!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSDM'),
        actions: [
          YearSelector(years: years, service: service),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          isScrollable: true,
          controller: controller,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Objectif CA'),
            Tab(text: 'Sales Plan'),
            Tab(text: 'Actions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller,
        children: const [
          DashboardView(),
          ObjectiveView(),
          PlanView(),
          ActionsView(),
        ],
      ),
    );
  }
}

class YearSelector extends StatelessWidget {
  const YearSelector({super.key, required this.years, required this.service});

  final List<int> years;
  final SsdmService service;

  @override
  Widget build(BuildContext context) {
    final selected = service.selectedYear ?? years.last;
    if (service.selectedYear != selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        service.selectYear(selected);
      });
    }
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
