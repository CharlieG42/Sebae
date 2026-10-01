import 'package:flutter/material.dart';

import '../modules/ssdm/ssdm_module.dart';
import 'module.dart';
import '../modules/wuect/wuect_module.dart';

/// Registre des modules de la plateforme Sebae.
///
/// Pour ajouter un nouveau module, il suffit de le déclarer ici.
abstract final class ModuleRegistry {
  static List<SebaeModule> get all => [
        ssdmModule,
        wuectModule,
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
