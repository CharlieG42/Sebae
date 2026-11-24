import 'package:flutter/material.dart';
import 'services/assessment_structure_service.dart';
import 'services/user_assessment_service.dart';
import 'views/assessment_home.dart';
import 'views/assessment_editor.dart';
import 'views/assessment_form.dart';

/// Module Assessment pour l'application
/// 
/// Ce module permet de gérer:
/// - La structure de l'assessment (thèmes, questions)
/// - Les réponses des utilisateurs (IV)
/// - L'interface utilisateur pour créer et compléter les assessments
class AssessmentModule {
  /// Nom du module
  static const String name = 'assessment';

  /// Titre du module
  static const String title = 'Assessment IV';

  /// Description du module
  static const String description = 
    'Outil d\'évaluation des besoins, freins et opportunités pour les Ingénieurs des Ventes';

  /// Icône du module
  static const IconData icon = Icons.assessment;

  /// Couleur du module
  static const Color color = Colors.blue;

  /// Chemin de la route principale
  static const String route = '/assessment';

  /// Chemin de l'éditeur de structure
  static const String editorRoute = '/assessment/editor';

  /// Chemin du formulaire d'assessment
  static const String formRoute = '/assessment/form';

  /// Créer une instance du service de structure
  static AssessmentStructureService createStructureService() {
    return AssessmentStructureService();
  }

  /// Créer une instance du service des réponses
  static UserAssessmentService createAssessmentService(AssessmentStructureService structureService) {
    final service = UserAssessmentService();
    service.setStructureService(structureService);
    return service;
  }

  /// Initialisation du module (obsolète - utiliser MultiProvider)
  @Deprecated('Utiliser MultiProvider dans votre application')
  static Future<void> init() async {
    final structureService = createStructureService();
    final assessmentService = createAssessmentService(structureService);
    await structureService.init();
    await assessmentService.init();
  }

  /// Obtenir la route principale
  static Widget get home => const AssessmentHome();

  /// Obtenir les routes du module
  static Map<String, WidgetBuilder> get routes => {
    route: (context) => const AssessmentHome(),
    editorRoute: (context) => const AssessmentEditor(),
    formRoute: (context) => const AssessmentForm(),
  };

  /// Obtenir le widget de menu pour ce module
  static Widget buildMenuItem(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(description),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}
