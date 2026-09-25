import 'package:flutter/material.dart';

import '../../../core/module.dart';
import 'views/ssdm_home.dart';

/// Déclaration du module SSDM (Service Sales Dev Management).
///
/// Pilotage annuel du business :
/// - Objectif de CA par année,
/// - Sales Plan par IV, groupe de clients et type de clients,
/// - Actions spécifiques (par IV) ou communes (équipe), avec suivi
///   d'avancement et visualisation graphique.
const SebaeModule ssdmModule = SebaeModule(
  id: 'ssdm',
  name: 'SSDM',
  description:
      'Service Sales Dev Management - objectifs de CA, sales plan '
      'et suivi des actions par année.',
  icon: Icons.trending_up,
  builder: _buildSsdmHome,
);

Widget _buildSsdmHome(BuildContext context) => const SsdmHome();
