import 'package:equatable/equatable.dart';
import 'theme.dart';
import 'question.dart';

/// Métadonnées de l'assessment
class AssessmentMetadata extends Equatable {
  /// Titre de l'assessment
  final String title;
  
  /// Description de l'assessment
  final String description;
  
  /// Version
  final String version;
  
  /// Date de création
  final DateTime created;
  
  /// Source des données
  final String source;

  const AssessmentMetadata({
    required this.title,
    required this.description,
    required this.version,
    required this.created,
    required this.source,
  });

  @override
  List<Object?> get props => [title, description, version, created, source];

  factory AssessmentMetadata.fromJson(Map<String, dynamic> json) {
    return AssessmentMetadata(
      title: json['title'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      created: DateTime.parse(json['created'] as String),
      source: json['source'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'version': version,
      'created': created.toIso8601String(),
      'source': source,
    };
  }

  @override
  String toString() => title;
}

/// Définition d'un type de réponse
class ResponseTypeDefinition extends Equatable {
  /// Description du type
  final String description;
  
  /// Règle de validation
  final String validation;

  const ResponseTypeDefinition({
    required this.description,
    required this.validation,
  });

  @override
  List<Object?> get props => [description, validation];

  factory ResponseTypeDefinition.fromJson(Map<String, dynamic> json) {
    return ResponseTypeDefinition(
      description: json['description'] as String,
      validation: json['validation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'validation': validation,
    };
  }
}

/// Structure complète de l'assessment
class AssessmentStructure extends Equatable {
  /// Métadonnées
  final AssessmentMetadata metadata;
  
  /// Liste des thèmes
  final List<Theme> themes;
  
  /// Définitions des types de réponses
  final Map<String, ResponseTypeDefinition> responseTypes;

  const AssessmentStructure({
    required this.metadata,
    required this.themes,
    required this.responseTypes,
  });

  @override
  List<Object?> get props => [metadata, themes, responseTypes];

  /// Créer une AssessmentStructure depuis un Map
  factory AssessmentStructure.fromJson(Map<String, dynamic> json) {
    return AssessmentStructure(
      metadata: AssessmentMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>
      ),
      themes: (json['themes'] as List)
          .map((t) => Theme.fromJson(t as Map<String, dynamic>))
          .toList(),
      responseTypes: (json['responseTypes'] as Map)
          .map(
            (key, value) => MapEntry(
              key as String,
              ResponseTypeDefinition.fromJson(value as Map<String, dynamic>),
            ),
          ),
    );
  }

  /// Convertir en Map pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'themes': themes.map((t) => t.toJson()).toList(),
      'responseTypes': responseTypes.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  /// Créer une copie avec des modifications
  AssessmentStructure copyWith({
    AssessmentMetadata? metadata,
    List<Theme>? themes,
    Map<String, ResponseTypeDefinition>? responseTypes,
  }) {
    return AssessmentStructure(
      metadata: metadata ?? this.metadata,
      themes: themes ?? this.themes,
      responseTypes: responseTypes ?? this.responseTypes,
    );
  }

  /// Obtenir un thème par son ID
  Theme? getTheme(String themeId) {
    try {
      return themes.firstWhere((t) => t.id == themeId);
    } catch (_) {
      return null;
    }
  }

  /// Obtenir tous les thèmes triés par ordre
  List<Theme> get sortedThemes {
    return [...themes]..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Obtenir une question par son ID (recherche dans tous les thèmes)
  Question? getQuestion(String questionId) {
    for (final theme in themes) {
      final question = theme.getQuestion(questionId);
      if (question != null) return question;
    }
    return null;
  }

  /// Obtenir toutes les questions
  List<Question> get allQuestions {
    return themes.expand((t) => t.questions).toList();
  }

  /// Obtenir le nombre total de questions
  int get totalQuestionCount => allQuestions.length;

  /// Obtenir le nombre total de thèmes
  int get themeCount => themes.length;

  /// Ajouter un thème
  AssessmentStructure addTheme(Theme theme) {
    final newThemes = List<Theme>.from(themes)..add(theme);
    return copyWith(themes: newThemes);
  }

  /// Supprimer un thème
  AssessmentStructure removeTheme(String themeId) {
    final newThemes = themes.where((t) => t.id != themeId).toList();
    return copyWith(themes: newThemes);
  }

  /// Mettre à jour un thème
  AssessmentStructure updateTheme(String themeId, Theme updatedTheme) {
    final newThemes = themes.map((t) {
      return t.id == themeId ? updatedTheme : t;
    }).toList();
    return copyWith(themes: newThemes);
  }

  /// Réorganiser les thèmes
  AssessmentStructure reorderThemes(List<String> newOrder) {
    final themeMap = {for (var t in themes) t.id: t};
    final newThemes = newOrder
        .map((id) => themeMap[id]!)
        .toList();
    return copyWith(themes: newThemes);
  }

  @override
  String toString() => metadata.title;
}
