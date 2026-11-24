import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sebae/modules/assessment/models/question_type.dart';
import 'package:sebae/modules/assessment/services/assessment_structure_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssessmentStructureService', () {
    test('charge la structure de référence (10 thèmes, questions par thème)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = AssessmentStructureService();

      // Charge le vrai asset fourni (modèles de questions par thématique).
      final json = await File(
        'assets/assessment/assessment_structure.json',
      ).readAsString();
      await service.importStructure(json);

      expect(service.isLoaded, isTrue);
      final themes = service.getAllThemes();
      expect(themes.length, 10);
      expect(themes.first.title, 'Connaissance Technique');

      final totalQuestions =
          themes.fold<int>(0, (sum, t) => sum + t.questions.length);
      expect(totalQuestions, greaterThan(0));
    });

    test('CRUD thèmes : ajouter, modifier, supprimer', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = AssessmentStructureService();
      await service.init();

      final theme = await service.addTheme(
        title: 'Thématique test',
        description: 'Description test',
      );
      expect(service.getTheme(theme.id)?.title, 'Thématique test');

      final updated = await service.updateTheme(
        theme.id,
        title: 'Thématique modifiée',
      );
      expect(updated.title, 'Thématique modifiée');

      expect(await service.deleteTheme(theme.id), isTrue);
      expect(service.getTheme(theme.id), isNull);
    });

    test('CRUD questions avec types de réponse variés', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = AssessmentStructureService();
      await service.init();
      final theme = await service.addTheme(title: 'Thème Q');

      // Question à choix multiple avec nombre de réponses borné
      final multi = await service.addQuestion(
        themeId: theme.id,
        text: 'Quels services vendez-vous ?',
        type: QuestionType.multiselect,
        options: ['Maintenance', 'Audit', 'Formation'],
        minSelections: 1,
        maxSelections: 2,
      );
      expect(
        service.getTheme(theme.id)!.questions.single.maxSelections,
        2,
      );

      // Liste déroulante (choix unique)
      await service.addQuestion(
        themeId: theme.id,
        text: 'Niveau de confiance',
        type: QuestionType.select,
        options: ['Faible', 'Moyen', 'Élevé'],
      );

      // Texte libre
      await service.addQuestion(
        themeId: theme.id,
        text: 'Commentaires',
        type: QuestionType.text,
        required: true,
      );

      // Nombre
      await service.addQuestion(
        themeId: theme.id,
        text: 'Taux de conversion',
        type: QuestionType.number,
        min: 0,
        max: 100,
      );

      var questions = service.getTheme(theme.id)!.questions;
      expect(questions.length, 4);

      // Modification : change le type et le max de sélections
      await service.updateQuestion(
        questionId: multi.id,
        maxSelections: 3,
      );
      questions = service.getTheme(theme.id)!.questions;
      expect(
        questions.firstWhere((q) => q.id == multi.id).type,
        QuestionType.multiselect,
      );

      // Suppression
      await service.deleteQuestion(multi.id);
      expect(service.getTheme(theme.id)!.questions.length, 3);
    });
  });
}
