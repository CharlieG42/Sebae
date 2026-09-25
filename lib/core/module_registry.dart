import 'package:flutter/material.dart';

import '../../modules/ssdm/ssdm_module.dart';
import 'module.dart';

/// Registre des modules de la plateforme Sebae.
///
/// Pour ajouter un nouveau module, il suffit de le déclarer ici.
abstract final class ModuleRegistry {
  static List<SebaeModule> get all => [
        ssdmModule,
        const SebaeModule(
          id: 'wuect',
          name: 'WUECT',
          description:
              'Water Utility Engineering Calculation Tool - à venir. '
              'Partageras les bases de données communes avec Sebae.',
          icon: Icons.water_drop_outlined,
        ),
        const SebaeModule(
          id: 'maintenance',
          name: 'Contrat Maintenance',
          description: 'Gestion des contrats de maintenance - à venir.',
          icon: Icons.build_outlined,
        ),
        const SebaeModule(
          id: 'projects',
          name: 'Gestion de Projets',
          description: 'Pilotage de projets - priorité 2.',
          icon: Icons.folder_outlined,
        ),
      ];
}
