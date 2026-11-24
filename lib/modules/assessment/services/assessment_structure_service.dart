import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/assessment_structure.dart';
import '../models/theme.dart';
import '../models/question.dart';
import '../models/question_type.dart';

/// Service pour gérer la structure de l'assessment
/// 
/// Ce service permet de:
/// - Charger et sauvegarder la structure
/// - Ajouter, modifier, supprimer des thèmes
/// - Ajouter, modifier, supprimer des questions
/// - Réorganiser les thèmes et questions
class AssessmentStructureService extends ChangeNotifier {
  static const String _storageKey = 'assessment_structure';
  static const String _defaultAssetPath = 'assets/assessment/assessment_structure.json';

  AssessmentStructure? _structure;
  bool _isLoading = false;
  String? _error;

  /// Structure actuelle
  AssessmentStructure? get structure => _structure;

  /// Indique si le chargement est en cours
  bool get isLoading => _isLoading;

  /// Dernière erreur rencontrée
  String? get error => _error;

  /// Vérifie si la structure est chargée
  bool get isLoaded => _structure != null;

  /// Initialisation du service
  Future<void> init({String? assetPath}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Essayer de charger depuis le storage local
      await _loadFromStorage();
      
      // Si pas trouvé, charger depuis les assets
      if (_structure == null) {
        await _loadFromAsset(assetPath ?? _defaultAssetPath);
      }
      
      // Si toujours pas chargé, créer une structure par défaut
      _structure ??= _createDefaultStructure();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Erreur lors du chargement: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Charger depuis le storage local
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString != null) {
      _structure = AssessmentStructure.fromJson(jsonDecode(jsonString));
    }
  }

  /// Charger depuis un fichier asset
  Future<void> _loadFromAsset(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      _structure = AssessmentStructure.fromJson(jsonDecode(jsonString));
    } catch (e) {
      // Si le fichier n'existe pas, on ignore simplement
      // Ne pas utiliser debugPrint pour éviter les erreurs en production
    }
  }

  /// Sauvegarder dans le storage local
  Future<void> _saveToStorage() async {
    if (_structure == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_structure!.toJson());
    await prefs.setString(_storageKey, jsonString);
  }

  /// Créer une structure par défaut
  AssessmentStructure _createDefaultStructure() {
    return AssessmentStructure(
      metadata: AssessmentMetadata(
        title: 'Assessment IV',
        description: 'Assessment des besoins, freins et opportunités pour les Ingénieurs des Ventes',
        version: '1.0.0',
        created: DateTime.now(),
        source: 'default',
      ),
      themes: [],
      responseTypes: {
        'text': ResponseTypeDefinition(
          description: 'Réponse en texte libre',
          validation: 'string',
        ),
        'number': ResponseTypeDefinition(
          description: 'Réponse numérique',
          validation: 'number',
        ),
        'boolean': ResponseTypeDefinition(
          description: 'Réponse oui/non',
          validation: 'boolean',
        ),
        'select': ResponseTypeDefinition(
          description: 'Choix unique',
          validation: 'string',
        ),
        'multiselect': ResponseTypeDefinition(
          description: 'Sélection multiple',
          validation: 'array',
        ),
        'checkbox': ResponseTypeDefinition(
          description: 'Cases à cocher',
          validation: 'array',
        ),
        'scale': ResponseTypeDefinition(
          description: 'Échelle de notation',
          validation: 'number',
        ),
        'ranking': ResponseTypeDefinition(
          description: 'Classement',
          validation: 'object',
        ),
        'table': ResponseTypeDefinition(
          description: 'Tableau',
          validation: 'array',
        ),
      },
    );
  }

  /// Obtenir la structure actuelle
  AssessmentStructure getStructure() {
    if (_structure == null) {
      throw Exception('Structure non chargée. Appeler init() d\'abord.');
    }
    return _structure!;
  }

  // ============================================
  // GESTION DES THÈMES
  // ============================================

  /// Obtenir tous les thèmes
  List<Theme> getAllThemes() {
    return getStructure().sortedThemes;
  }

  /// Obtenir un thème par son ID
  Theme? getTheme(String themeId) {
    return getStructure().getTheme(themeId);
  }

  /// Ajouter un thème
  Future<Theme> addTheme({
    required String title,
    String description = '',
    int? order,
  }) async {
    if (_structure == null) {
      throw Exception('Structure non chargée');
    }

    final newTheme = Theme(
      title: title,
      description: description,
      order: order ?? _structure!.themeCount + 1,
    );

    _structure = _structure!.addTheme(newTheme);
    await _saveToStorage();
    notifyListeners();

    return newTheme;
  }

  /// Modifier un thème
  Future<Theme> updateTheme(String themeId, {
    String? title,
    String? description,
    int? order,
  }) async {
    if (_structure == null) {
      throw Exception('Structure non chargée');
    }

    final theme = getTheme(themeId);
    if (theme == null) {
      throw Exception('Thème non trouvé: $themeId');
    }

    final updatedTheme = theme.copyWith(
      title: title ?? theme.title,
      description: description ?? theme.description,
      order: order ?? theme.order,
    );

    _structure = _structure!.updateTheme(themeId, updatedTheme);
    await _saveToStorage();
    notifyListeners();

    return updatedTheme;
  }

  /// Supprimer un thème
  Future<bool> deleteTheme(String themeId) async {
    if (_structure == null) {
      throw Exception('Structure non chargée');
    }

    if (!getStructure().themes.any((t) => t.id == themeId)) {
      return false;
    }

    _structure = _structure!.removeTheme(themeId);
    await _saveToStorage();
    notifyListeners();

    return true;
  }

  /// Réorganiser les thèmes
  Future<bool> reorderThemes(List<String> newOrder) async {
    if (_structure == null) {
      throw Exception('Structure non chargée');
    }

    // Vérifier que tous les IDs existent
    final existingIds = getStructure().themes.map((t) => t.id).toSet();
    for (final id in newOrder) {
      if (!existingIds.contains(id)) {
        return false;
      }
    }

    _structure = _structure!.reorderThemes(newOrder);
    await _saveToStorage();
    notifyListeners();

    return true;
  }

  // ============================================
  // GESTION DES QUESTIONS
  // ============================================

  /// Obtenir toutes les questions d'un thème
  List<Question> getQuestionsByTheme(String themeId) {
    final theme = getTheme(themeId);
    return theme?.questions ?? [];
  }

  /// Obtenir une question par son ID
  Question? getQuestion(String questionId) {
    return getStructure().getQuestion(questionId);
  }

  /// Ajouter une question à un thème
  Future<Question> addQuestion({
    required String themeId,
    required String text,
    required QuestionType type,
    bool required = false,
    int? order,
    List<String>? options,
    num? min,
    num? max,
    Map<int, String>? labels,
    List<TableColumn>? columns,
    List<Map<String, dynamic>>? rows,
    String? placeholder,
    int? maxLength,
    String? trueLabel,
    String? falseLabel,
    String? defaultOption,
    int? minSelections,
    int? maxSelections,
  }) async {
    if (_structure == null) {
      throw Exception('Structure non chargée');
    }

    final theme = getTheme(themeId);
    if (theme == null) {
      throw Exception('Thème non trouvé: $themeId');
    }

    final newQuestion = Question(
      text: text,
      type: type,
      required: required,
      order: order ?? theme.questionCount + 1,
      options: options,
      min: min,
      max: max,
      labels: labels,
      columns: columns,
      rows: rows,
      placeholder: placeholder,
      maxLength: maxLength,
      trueLabel: trueLabel,
      falseLabel: falseLabel,
      defaultOption: defaultOption,
      minSelections: minSelections,
      maxSelections: maxSelections,
    );

    final updatedTheme = theme.addQuestion(newQuestion);
    _structure = _structure!.updateTheme(themeId, updatedTheme);
    await _saveToStorage();
    notifyListeners();

    return newQuestion;
  }

  /// Modifier une question
  Future<Question> updateQuestion({
    required String questionId,
    String? text,
    QuestionType? type,
    bool? required,
    int? order,
    List<String>? options,
    num? min,
    num? max,
    Map<int, String>? labels,
    List<TableColumn>? columns,
    List<Map<String, dynamic>>? rows,
    String? placeholder,
    int? maxLength,
    String? trueLabel,
    String? falseLabel,
    String? defaultOption,
    int? minSelections,
    int? maxSelections,
  }) async {
    if (_structure == null) {
      throw Exception('Structure non chargée');
    }

    final question = getQuestion(questionId);
    if (question == null) {
      throw Exception('Question non trouvée: $questionId');
    }

    final updatedQuestion = question.copyWith(
      text: text ?? question.text,
      type: type ?? question.type,
      required: required ?? question.required,
      order: order ?? question.order,
      options: options ?? question.options,
      min: min ?? question.min,
      max: max ?? question.max,
      labels: labels ?? question.labels,
      columns: columns ?? question.columns,
      rows: rows ?? question.rows,
      placeholder: placeholder ?? question.placeholder,
      maxLength: maxLength ?? question.maxLength,
      trueLabel: trueLabel ?? question.trueLabel,
      falseLabel: falseLabel ?? question.falseLabel,
      defaultOption: defaultOption ?? question.defaultOption,
      minSelections: minSelections ?? question.minSelections,
      maxSelections: maxSelections ?? question.maxSelections,
    );

    // Trouver le thème qui contient la question
    for (final theme in getStructure().themes) {
      if (theme.hasQuestion(questionId)) {
        final updatedTheme = theme.updateQuestion(questionId, updatedQuestion);
        _structure = _structure!.updateTheme(theme.id, updatedTheme);
        break;
      }
    }

    await _saveToStorage();
    notifyListeners();

    return updatedQuestion;
  }

  /// Supprimer une question
  Future<bool> deleteQuestion(String questionId) async {
    if (_structure == null) {
      throw Exception('Structure non chargée');
    }

    // Trouver le thème qui contient la question
    for (final theme in getStructure().themes) {
      if (theme.hasQuestion(questionId)) {
        final updatedTheme = theme.removeQuestion(questionId);
        _structure = _structure!.updateTheme(theme.id, updatedTheme);
        await _saveToStorage();
        notifyListeners();
        return true;
      }
    }

    return false;
  }

  /// Réorganiser les questions d'un thème
  Future<bool> reorderQuestions({
    required String themeId,
    required List<String> newOrder,
  }) async {
    if (_structure == null) {
      throw Exception('Structure non chargée');
    }

    final theme = getTheme(themeId);
    if (theme == null) {
      return false;
    }

    // Vérifier que tous les IDs existent
    final existingIds = theme.questions.map((q) => q.id).toSet();
    for (final id in newOrder) {
      if (!existingIds.contains(id)) {
        return false;
      }
    }

    final updatedTheme = theme.reorderQuestions(newOrder);
    _structure = _structure!.updateTheme(themeId, updatedTheme);
    await _saveToStorage();
    notifyListeners();

    return true;
  }

  // ============================================
  // GESTION DES MÉTADONNÉES
  // ============================================

  /// Obtenir les métadonnées
  AssessmentMetadata getMetadata() {
    return getStructure().metadata;
  }

  /// Mettre à jour les métadonnées
  Future<AssessmentMetadata> updateMetadata({
    String? title,
    String? description,
    String? version,
    String? source,
  }) async {
    if (_structure == null) {
      throw Exception('Structure non chargée');
    }

    final currentMetadata = getStructure().metadata;
    final updatedMetadata = AssessmentMetadata(
      title: title ?? currentMetadata.title,
      description: description ?? currentMetadata.description,
      version: version ?? currentMetadata.version,
      created: currentMetadata.created,
      source: source ?? currentMetadata.source,
    );

    _structure = _structure!.copyWith(metadata: updatedMetadata);
    await _saveToStorage();
    notifyListeners();

    return updatedMetadata;
  }

  // ============================================
  // EXPORT/IMPORT
  // ============================================

  /// Exporter la structure en JSON
  String exportStructure() {
    return json.encode(getStructure().toJson());
  }

  /// Importer une structure depuis JSON
  Future<void> importStructure(String jsonString) async {
    _structure = AssessmentStructure.fromJson(jsonDecode(jsonString));
    await _saveToStorage();
    notifyListeners();
  }

  /// Importer depuis un fichier asset
  Future<void> importFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    await importStructure(jsonString);
  }

  /// Réinitialiser avec la structure par défaut
  Future<void> resetToDefault() async {
    _structure = _createDefaultStructure();
    await _saveToStorage();
    notifyListeners();
  }
}
