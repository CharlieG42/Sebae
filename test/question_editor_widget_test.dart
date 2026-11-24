import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sebae/modules/assessment/assessment_module.dart';
import 'package:sebae/modules/assessment/services/assessment_structure_service.dart';
import 'package:sebae/modules/assessment/views/question_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('L\'éditeur de question expose le nombre de réponses autorisées',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final structureService = AssessmentModule.createStructureService();
    await structureService.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<AssessmentStructureService>.value(
        value: structureService,
        child: const MaterialApp(home: QuestionEditorHarness()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    // Par défaut (texte libre) : pas de champ de sélections.
    expect(find.text('Sélections max'), findsNothing);

    // Passe en type "Sélection multiple" (choix multiple).
    await tester.tap(find.text('Texte libre').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sélection multiple').last);
    await tester.pumpAndSettle();

    // Les bornes de sélections apparaissent, avec les options.
    expect(find.text('Sélections min'), findsOneWidget);
    expect(find.text('Sélections max'), findsOneWidget);
    expect(find.text('Ajouter une option'), findsOneWidget);
  });
}

/// Harnais simple pour ouvrir le dialogue d'édition de question.
class QuestionEditorHarness extends StatelessWidget {
  const QuestionEditorHarness({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => QuestionEditorDialog(
                themeId: 'test-theme',
                onSaved: () {},
              ),
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
  }
}
