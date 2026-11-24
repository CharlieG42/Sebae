import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sebae/modules/assessment/assessment_module.dart';
import 'package:sebae/modules/assessment/services/assessment_structure_service.dart';
import 'package:sebae/modules/assessment/services/user_assessment_service.dart';
import 'package:sebae/modules/assessment/views/assessment_editor.dart';
import 'package:sebae/modules/assessment/views/assessment_home.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AssessmentHome est rendue et ouvre l\'éditeur de structure',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final structureService = AssessmentModule.createStructureService();
    await structureService.init();
    final userService =
        AssessmentModule.createAssessmentService(structureService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AssessmentStructureService>.value(
            value: structureService,
          ),
          ChangeNotifierProvider<UserAssessmentService>.value(
            value: userService,
          ),
        ],
        child: const MaterialApp(home: AssessmentHome()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assessment IV'), findsWidgets);

    // Le bouton "Gérer la Structure" doit ouvrir l'éditeur sans lever
    // d'erreur de route (routes non déclarées dans MaterialApp).
    await tester.tap(find.text('Gérer la Structure'));
    await tester.pumpAndSettle();
    expect(find.byType(AssessmentEditor), findsOneWidget);

    // Referme la page pour ne pas laisser de route active après le test.
    await tester.pageBack();
    await tester.pumpAndSettle();
  });
}
