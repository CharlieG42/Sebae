import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'question_type.dart';

/// Modèle d'une question dans l'assessment
class Question extends Equatable {
  /// Identifiant unique de la question
  final String id;
  
  /// Texte de la question
  final String text;
  
  /// Type de la question
  final QuestionType type;
  
  /// Indique si la réponse est obligatoire
  final bool required;
  
  /// Ordre d'affichage dans le thème
  final int order;
  
  /// Placeholder pour les champs texte
  final String? placeholder;
  
  /// Longueur maximale pour les champs texte
  final int? maxLength;
  
  /// Valeur minimale pour les nombres
  final num? min;
  
  /// Valeur maximale pour les nombres
  final num? max;
  
  /// Options pour les questions de type select, multiselect, checkbox, ranking
  final List<String>? options;
  
  /// Nombre minimum de sélections pour multiselect/checkbox
  final int? minSelections;
  
  /// Nombre maximum de sélections pour multiselect/checkbox
  final int? maxSelections;
  
  /// Libellés pour les extrémités de l'échelle (ex: {1: "Faible", 5: "Excellent"})
  final Map<int, String>? labels;
  
  /// Label pour "vrai" dans les questions booléennes
  final String? trueLabel;
  
  /// Label pour "faux" dans les questions booléennes
  final String? falseLabel;
  
  /// Valeur par défaut pour select
  final String? defaultOption;
  
  /// Colonne du tableau pour les questions de type table
  final List<TableColumn>? columns;
  
  /// Lignes du tableau pour les questions de type table
  final List<Map<String, dynamic>>? rows;
  
  /// Autoriser l'ajout de lignes dans un tableau
  final bool allowAddRows;
  
  /// Autoriser la suppression de lignes dans un tableau
  final bool allowRemoveRows;

  Question({
    String? id,
    required this.text,
    required this.type,
    this.required = false,
    this.order = 1,
    this.placeholder,
    this.maxLength,
    this.min,
    this.max,
    this.options,
    this.minSelections,
    this.maxSelections,
    this.labels,
    this.trueLabel,
    this.falseLabel,
    this.defaultOption,
    this.columns,
    this.rows,
    this.allowAddRows = true,
    this.allowRemoveRows = true,
  }) : id = id ?? const Uuid().v4();

  @override
  List<Object?> get props => [
    id,
    text,
    type,
    required,
    order,
    placeholder,
    maxLength,
    min,
    max,
    options,
    minSelections,
    maxSelections,
    labels,
    trueLabel,
    falseLabel,
    defaultOption,
    columns,
    rows,
    allowAddRows,
    allowRemoveRows,
  ];

  /// Créer une Question depuis un Map
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String?,
      text: json['text'] as String,
      type: QuestionTypeExtension.fromJson(json['type'] as String),
      required: json['required'] as bool? ?? false,
      order: json['order'] as int? ?? 1,
      placeholder: json['placeholder'] as String?,
      maxLength: json['maxLength'] as int?,
      min: json['min'] as num?,
      max: json['max'] as num?,
      options: (json['options'] as List?)?.cast<String>(),
      minSelections: json['minSelections'] as int?,
      maxSelections: json['maxSelections'] as int?,
      labels: (json['labels'] as Map?)?.cast<int, String>(),
      trueLabel: json['trueLabel'] as String?,
      falseLabel: json['falseLabel'] as String?,
      defaultOption: json['defaultOption'] as String?,
      columns: (json['columns'] as List?)
          ?.map((c) => TableColumn.fromJson(c as Map<String, dynamic>))
          .toList(),
      rows: (json['rows'] as List?)?.cast<Map<String, dynamic>>(),
      allowAddRows: json['allowAddRows'] as bool? ?? true,
      allowRemoveRows: json['allowRemoveRows'] as bool? ?? true,
    );
  }

  /// Convertir en Map pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.toJson(),
      'required': required,
      'order': order,
      if (placeholder != null) 'placeholder': placeholder,
      if (maxLength != null) 'maxLength': maxLength,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (options != null) 'options': options,
      if (minSelections != null) 'minSelections': minSelections,
      if (maxSelections != null) 'maxSelections': maxSelections,
      if (labels != null) 'labels': labels,
      if (trueLabel != null) 'trueLabel': trueLabel,
      if (falseLabel != null) 'falseLabel': falseLabel,
      if (defaultOption != null) 'defaultOption': defaultOption,
      if (columns != null) 'columns': columns!.map((c) => c.toJson()).toList(),
      if (rows != null) 'rows': rows,
      'allowAddRows': allowAddRows,
      'allowRemoveRows': allowRemoveRows,
    };
  }

  /// Créer une copie avec des modifications
  Question copyWith({
    String? id,
    String? text,
    QuestionType? type,
    bool? required,
    int? order,
    String? placeholder,
    int? maxLength,
    num? min,
    num? max,
    List<String>? options,
    int? minSelections,
    int? maxSelections,
    Map<int, String>? labels,
    String? trueLabel,
    String? falseLabel,
    String? defaultOption,
    List<TableColumn>? columns,
    List<Map<String, dynamic>>? rows,
    bool? allowAddRows,
    bool? allowRemoveRows,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      required: required ?? this.required,
      order: order ?? this.order,
      placeholder: placeholder ?? this.placeholder,
      maxLength: maxLength ?? this.maxLength,
      min: min ?? this.min,
      max: max ?? this.max,
      options: options ?? this.options,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
      labels: labels ?? this.labels,
      trueLabel: trueLabel ?? this.trueLabel,
      falseLabel: falseLabel ?? this.falseLabel,
      defaultOption: defaultOption ?? this.defaultOption,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      allowAddRows: allowAddRows ?? this.allowAddRows,
      allowRemoveRows: allowRemoveRows ?? this.allowRemoveRows,
    );
  }

  @override
  String toString() => text;
}

/// Modèle d'une colonne de tableau
class TableColumn extends Equatable {
  /// Nom de la colonne
  final String name;
  
  /// Type de données de la colonne
  final QuestionType type;
  
  /// Options pour les colonnes de type select, multiselect, checkbox
  final List<String>? options;
  
  /// Indique si la colonne est obligatoire
  final bool required;

  const TableColumn({
    required this.name,
    required this.type,
    this.options,
    this.required = false,
  });

  @override
  List<Object?> get props => [name, type, options, required];

  factory TableColumn.fromJson(Map<String, dynamic> json) {
    return TableColumn(
      name: json['name'] as String,
      type: QuestionTypeExtension.fromJson(json['type'] as String),
      options: (json['options'] as List?)?.cast<String>(),
      required: json['required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.toJson(),
      if (options != null) 'options': options,
      'required': required,
    };
  }

  @override
  String toString() => name;
}
