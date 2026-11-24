# Module Assessment IV

Ce module permet de gérer les assessments pour les **Ingénieurs des Ventes (IV)** directement dans l'application Flutter.

## Structure du Module

```
lib/modules/assessment/
├── models/                  # Modèles de données
│   ├── question_type.dart   # Types de questions (enum)
│   ├── answer.dart          # Modèles des réponses
│   ├── question.dart        # Modèle d'une question
│   ├── theme.dart           # Modèle d'un thème
│   ├── assessment_structure.dart  # Structure complète
│   ├── user_assessment.dart # Assessment d'un utilisateur
│   └── index.dart           # Export des modèles
│
├── services/                # Services de gestion
│   ├── assessment_structure_service.dart  # Gestion de la structure
│   ├── user_assessment_service.dart        # Gestion des réponses
│   └── index.dart          # Export des services
│
├── views/                   # Vues (pages)
│   ├── assessment_home.dart    # Page principale
│   ├── assessment_editor.dart # Éditeur de structure
│   ├── theme_editor.dart       # Éditeur de thème
│   ├── question_editor.dart   # Éditeur de question
│   ├── assessment_form.dart   # Formulaire de réponse
│   └── index.dart            # Export des vues
│
├── widgets/                 # Widgets
│   └── question_widget.dart  # Widget pour afficher/répondre aux questions
│
├── assessment_module.dart   # Module principal
├── index.dart               # Export du module
└── README.md                # Documentation
```

## Installation

### 1. Ajouter les dépendances

Assurez-vous que votre `pubspec.yaml` contient les dépendances nécessaires :

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  shared_preferences: ^2.0.0
  uuid: ^3.0.0
  equatable: ^2.0.0
```

### 2. Créer le dossier des assets

Créez le dossier `assets/assessment/` et placez-y le fichier `assessment_structure.json` :

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/assessment/assessment_structure.json
```

### 3. Importer le module

Dans votre code Dart, importez le module :

```dart
import 'package:votre_app/modules/assessment/assessment_module.dart';
```

## Utilisation

### Initialisation

Dans votre `main.dart` ou dans l'initialisation de l'application :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le module Assessment
  await AssessmentModule.init();
  
  runApp(MyApp());
}
```

### Configuration des routes

Dans votre application, configurez les routes :

```dart
MaterialApp(
  routes: {
    ...AssessmentModule.routes,
  },
)
```

### Utilisation des services

#### Service de Structure

```dart
// Obtenir le service
final structureService = AssessmentStructureService();

// Initialiser
await structureService.init();

// Obtenir tous les thèmes
final themes = structureService.getAllThemes();

// Obtenir un thème spécifique
final theme = structureService.getTheme('theme_001');

// Ajouter un thème
final newTheme = await structureService.addTheme(
  title: 'Nouveau Thème',
  description: 'Description du thème',
);

// Modifier un thème
final updatedTheme = await structureService.updateTheme(
  'theme_001',
  title: 'Titre modifié',
);

// Supprimer un thème
final success = await structureService.deleteTheme('theme_001');

// Ajouter une question
final newQuestion = await structureService.addQuestion(
  themeId: 'theme_001',
  text: 'Nouvelle question ?',
  type: QuestionType.text,
);

// Modifier une question
final updatedQuestion = await structureService.updateQuestion(
  questionId: 'q_001_01',
  text: 'Question modifiée',
);

// Supprimer une question
final deleted = await structureService.deleteQuestion('q_001_01');
```

#### Service des Réponses Utilisateurs

```dart
// Obtenir le service
final assessmentService = UserAssessmentService();

// Initialiser
await assessmentService.init();

// Créer un assessment pour un utilisateur
final assessment = await assessmentService.createAssessment(
  userId: 'user_001',
);

// Sauvegarder une réponse
final success = await assessmentService.saveQuestionResponse(
  userId: 'user_001',
  assessmentId: assessment.assessmentId,
  themeId: 'theme_001',
  questionId: 'q_001_01',
  answer: TextAnswer('Ma réponse'),
);

// Obtenir une réponse
final response = await assessmentService.getQuestionResponse(
  userId: 'user_001',
  assessmentId: assessment.assessmentId,
  themeId: 'theme_001',
  questionId: 'q_001_01',
);

// Marquer comme terminé
final completed = await assessmentService.completeAssessment(
  userId: 'user_001',
  assessmentId: assessment.assessmentId,
);

// Obtenir le pourcentage de complétion
final percentage = await assessmentService.getCompletionPercentage(
  userId: 'user_001',
  assessmentId: assessment.assessmentId,
);

// Lister les assessments d'un utilisateur
final userAssessments = await assessmentService.listUserAssessments('user_001');

// Supprimer un assessment
final deleted = await assessmentService.deleteAssessment(
  userId: 'user_001',
  assessmentId: assessment.assessmentId,
);
```

## Types de Questions Supportés

| Type | Description | Widget Flutter | Classe Dart |
|------|-------------|----------------|-------------|
| `text` | Texte libre | `TextField` | `TextAnswer` |
| `number` | Nombre | `TextField` (number) | `NumberAnswer` |
| `boolean` | Oui/Non | `Radio` / `Switch` | `BooleanAnswer` |
| `select` | Choix unique | `DropdownButton` | `SelectAnswer` |
| `multiselect` | Sélection multiple | `CheckboxListTile` | `MultiSelectAnswer` |
| `checkbox` | Cases à cocher | `CheckboxListTile` | `CheckboxAnswer` |
| `scale` | Échelle (1-5, 1-10) | `Slider` | `ScaleAnswer` |
| `ranking` | Classement | `ReorderableListView` | `RankingAnswer` |
| `table` | Tableau | Custom widget | `TableAnswer` |

## Intégration dans l'application

### 1. Ajouter au Menu Principal

```dart
// Dans votre menu ou page d'accueil
ListTile(
  leading: Icon(AssessmentModule.icon, color: AssessmentModule.color),
  title: Text(AssessmentModule.title),
  subtitle: Text(AssessmentModule.description),
  onTap: () {
    Navigator.pushNamed(context, AssessmentModule.route);
  },
)
```

### 2. Utiliser dans un Provider

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AssessmentStructureService()),
    ChangeNotifierProvider(create: (_) => UserAssessmentService()),
  ],
  child: MyApp(),
)
```

### 3. Accéder aux services dans les widgets

```dart
Consumer<AssessmentStructureService>(
  builder: (context, service, child) {
    if (service.isLoading) {
      return CircularProgressIndicator();
    }
    
    final themes = service.getAllThemes();
    return ListView.builder(
      itemCount: themes.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(themes[index].title));
      },
    );
  },
)
```

## Personnalisation

### Ajouter un Thème

```dart
final newTheme = await assessmentStructureService.addTheme(
  title: 'Mon Nouveau Thème',
  description: 'Description du thème',
  order: 11,  // Optionnel
);
```

### Ajouter une Question

```dart
final newQuestion = await assessmentStructureService.addQuestion(
  themeId: 'theme_001',
  text: 'Quelle est votre préférence ?',
  type: QuestionType.select,
  options: ['Option 1', 'Option 2', 'Option 3'],
  required: true,
);
```

### Importer/Exporter la Structure

```dart
// Exporter
final jsonString = assessmentStructureService.exportStructure();

// Importer
assessmentStructureService.importStructure(jsonString);

// Importer depuis un fichier asset
assessmentStructureService.importFromAsset('assets/custom_assessment.json');
```

## Bonnes Pratiques

1. **Initialisation** : Toujours appeler `init()` avant d'utiliser les services
2. **ID Uniques** : Ne pas modifier manuellement les IDs des thèmes et questions
3. **Sauvegarde** : Les données sont sauvegardées automatiquement dans `SharedPreferences`
4. **Écoute des changements** : Utiliser `ChangeNotifier` pour écouter les modifications
5. **Gestion des erreurs** : Toujours vérifier que la structure est chargée avant d'accéder aux données

## Dépannage

### Problème : Structure non chargée

**Solution** : Vérifiez que vous avez appelé `init()` et attendez que `isLoading` soit `false`.

```dart
await service.init();
if (service.isLoaded) {
  // Utiliser le service
}
```

### Problème : Fichier asset non trouvé

**Solution** : Vérifiez que le fichier est bien dans `assets/assessment/` et que le `pubspec.yaml` contient :

```yaml
flutter:
  assets:
    - assets/assessment/
```

### Problème : Les modifications ne sont pas sauvegardées

**Solution** : Vérifiez que vous utilisez bien le service via `ChangeNotifierProvider` ou que vous appelez bien `notifyListeners()` après les modifications.

## Structure des Données

### Fichier JSON de la Structure

```json
{
  "metadata": {
    "title": "Assessment IV",
    "description": "...",
    "version": "1.0.0",
    "created": "2024-11-23T00:00:00.000Z",
    "source": "Questionnaires IV.pdf"
  },
  "themes": [
    {
      "id": "theme_001",
      "title": "Connaissance Technique",
      "description": "...",
      "order": 1,
      "questions": [
        {
          "id": "q_001_01",
          "text": "Sur quels équipements vous sentez-vous le moins à l'aise ?",
          "type": "checkbox",
          "options": ["Puissance", "Commande", "Mécanique"],
          "required": false,
          "order": 1
        }
      ]
    }
  ],
  "responseTypes": {}
}
```

## Contribuer

Pour contribuer à ce module :

1. Créez une nouvelle branche : `git checkout -b feature/assessment-nouvelle-fonctionnalite`
2. Faites vos modifications
3. Ajoutez des tests si nécessaire
4. Commitez vos changements : `git commit -m 'Ajout de la nouvelle fonctionnalité'`
5. Poussez vers la branche : `git push origin feature/assessment-nouvelle-fonctionnalite`
6. Ouvrez une Pull Request

## Licence

Ce module est distribué sous licence MIT.
