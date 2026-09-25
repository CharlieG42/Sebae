import 'package:flutter/material.dart';

import '../core/module_registry.dart';
import '../data/data_home.dart';
import '../settings/settings_view.dart';

/// Coque de navigation principale : Modules / Bases partagées / Paramètres.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;

    final destinations = const [
      NavigationRailDestination(
        icon: Icon(Icons.apps_outlined),
        selectedIcon: Icon(Icons.apps),
        label: Text('Modules'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.storage_outlined),
        selectedIcon: Icon(Icons.storage),
        label: Text('Bases partagées'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Paramètres'),
      ),
    ];

    final pages = const [
      _ModulesPage(),
      DataHome(),
      SettingsView(),
    ];

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: destinations,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'Modules',
          ),
          NavigationDestination(
            icon: Icon(Icons.storage_outlined),
            selectedIcon: Icon(Icons.storage),
            label: 'Bases partagées',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

/// Page listant les modules de la plateforme.
class _ModulesPage extends StatelessWidget {
  const _ModulesPage();

  @override
  Widget build(BuildContext context) {
    final modules = ModuleRegistry.all;
    return Scaffold(
      appBar: AppBar(title: const Text('Sebae')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final module in modules)
            Card(
              child: ListTile(
                leading: Icon(
                  module.icon ?? Icons.extension_outlined,
                  size: 32,
                ),
                title: Text(module.name),
                subtitle: Text(module.description),
                enabled: module.available,
                trailing: module.available
                    ? const Icon(Icons.chevron_right)
                    : const Text('a venir'),
                onTap: module.available == true
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: module.builder!,
                          ),
                        )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
