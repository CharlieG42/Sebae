import 'package:flutter/material.dart';

/// Paramètres de la plateforme Sebae.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Sebae'),
            subtitle: Text(
              'Plateforme modulaire d\'outils métier - v2.0.0\n'
              'Persistance locale : Hive (bases partagées entre modules).',
            ),
          ),
          ListTile(
            leading: Icon(Icons.extension_outlined),
            title: Text('Modules disponibles'),
            subtitle: Text('SSDM (Service Sales Dev Management)'),
          ),
          ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Modules à venir'),
            subtitle: Text(
              'WUECT (integration + bases partagées), '
              'Contrat Maintenance, Gestion de Projets.',
            ),
          ),
        ],
      ),
    );
  }
}
