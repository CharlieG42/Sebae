// ignore_for_file: constant_identifier_names

/// Enumération des types de questions supportés par l'assessment
enum QuestionType {
  /// Réponse en texte libre
  text,
  
  /// Réponse numérique
  number,
  
  /// Réponse oui/non (booléen)
  boolean,
  
  /// Choix unique parmi plusieurs options
  select,
  
  /// Sélection multiple parmi plusieurs options
  multiselect,
  
  /// Cases à cocher (sélection multiple)
  checkbox,
  
  /// Échelle de notation (ex: 1-5, 1-10)
  scale,
  
  /// Classement des options par ordre d'importance
  ranking,
  
  /// Tableau avec colonnes et lignes
  table,
}

/// Extension pour convertir QuestionType en String et vice versa
extension QuestionTypeExtension on QuestionType {
  /// Convertir QuestionType en String
  String toJson() {
    return switch (this) {
      QuestionType.text => 'text',
      QuestionType.number => 'number',
      QuestionType.boolean => 'boolean',
      QuestionType.select => 'select',
      QuestionType.multiselect => 'multiselect',
      QuestionType.checkbox => 'checkbox',
      QuestionType.scale => 'scale',
      QuestionType.ranking => 'ranking',
      QuestionType.table => 'table',
    };
  }

  /// Convertir String en QuestionType
  static QuestionType fromJson(String value) {
    return switch (value.toLowerCase()) {
      'text' => QuestionType.text,
      'number' => QuestionType.number,
      'boolean' => QuestionType.boolean,
      'select' => QuestionType.select,
      'multiselect' => QuestionType.multiselect,
      'checkbox' => QuestionType.checkbox,
      'scale' => QuestionType.scale,
      'ranking' => QuestionType.ranking,
      'table' => QuestionType.table,
      _ => throw ArgumentError('Invalid question type: $value'),
    };
  }
}

/// Statut d'un assessment
enum AssessmentStatus {
  in_progress,
  completed,
  reviewed,
}

/// Extension pour AssessmentStatus
extension AssessmentStatusExtension on AssessmentStatus {
  String toJson() {
    return switch (this) {
      AssessmentStatus.in_progress => 'in_progress',
      AssessmentStatus.completed => 'completed',
      AssessmentStatus.reviewed => 'reviewed',
    };
  }

  static AssessmentStatus fromJson(String value) {
    return switch (value.toLowerCase()) {
      'in_progress' => AssessmentStatus.in_progress,
      'completed' => AssessmentStatus.completed,
      'reviewed' => AssessmentStatus.reviewed,
      _ => throw ArgumentError('Invalid assessment status: $value'),
    };
  }
}

/// Niveau de priorité
enum PriorityLevel {
  low,
  medium,
  high,
}

/// Extension pour PriorityLevel
extension PriorityLevelExtension on PriorityLevel {
  String toJson() {
    return switch (this) {
      PriorityLevel.low => 'low',
      PriorityLevel.medium => 'medium',
      PriorityLevel.high => 'high',
    };
  }

  static PriorityLevel fromJson(String value) {
    return switch (value.toLowerCase()) {
      'low' => PriorityLevel.low,
      'medium' => PriorityLevel.medium,
      'high' => PriorityLevel.high,
      _ => throw ArgumentError('Invalid priority level: $value'),
    };
  }

  String get displayName {
    return switch (this) {
      PriorityLevel.low => 'Basse',
      PriorityLevel.medium => 'Moyenne',
      PriorityLevel.high => 'Haute',
    };
  }
}
