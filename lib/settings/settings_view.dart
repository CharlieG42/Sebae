import 'package:flutter/material.dart';

import '../core/storage/hive_service.dart';

/// Paramètres de la plateforme Sebae.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Sebae'),
            subtitle: Text(
              'Plateforme modulaire d\'outils métier - v2.0.0\n'
              'Persistance locale : Hive (bases partagées entre modules).',
            ),
          ),
          FutureBuilder<String>(
            future: HiveService.hiveDataPath,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListTile(
                  leading: Icon(Icons.storage),
                  title: Text('Chemin des bases de données'),
                  subtitle: Text('Chargement...'),
                );
              }
              return ListTile(
                leading: Icon(Icons.storage),
                title: Text('Chemin des bases de données'),
                subtitle: Text(snapshot.data ?? 'Non disponible'),
              );
            },
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
