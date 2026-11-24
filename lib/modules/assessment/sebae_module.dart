import 'package:flutter/material.dart';

import '../../core/module.dart';
import 'assessment_module.dart';
import 'views/assessment_home.dart';

const SebaeModule assessmentModule = SebaeModule(
  id: 'assessment',
  name: 'Assessment IV',
  description:
      'Évaluer les connaissances, les besoins et les compétences des '
      'Ingénieurs des Ventes : thématiques et questions '
      'personnalisables (choix multiple, texte libre, chiffres...).',
  icon: AssessmentModule.icon,
  builder: _buildAssessmentHome,
);

Widget _buildAssessmentHome(BuildContext context) =>
    const AssessmentHome();
