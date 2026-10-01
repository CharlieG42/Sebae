import 'package:flutter/material.dart';
import '../../core/module.dart';
import 'screens/projet/projet_list_screen.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';

/// Déclaration du module WUECT (Water Utility Engineering Calculation Tool).
///
/// Comparatifs énergétiques entre systèmes de pompage : projets, systèmes
/// (Ancien / Nouveau), pompes, résultats sur 10 ans, export PDF / DOCX.
///
/// Le module consomme les bases partagées de Sebae : les IV (`shared_ivs`)
/// et les contacts (`shared_contacts`) sont référencés par UUID.
const SebaeModule wuectModule = SebaeModule(
  id: 'wuect',
  name: 'WUECT',
  description:
      'Comparatifs énergétiques entre systèmes de pompage - projets, '
      'systèmes, pompes, ROI et exports PDF / Word.',
  icon: Icons.water_drop_outlined,
  builder: _buildWuectHome,
);

Widget _buildWuectHome(BuildContext context) {
  DatabaseService.init();
  SettingsService.instance.ensureInitialized();
  return const ProjetListScreen();
}
