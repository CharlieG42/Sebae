import 'package:equatable/equatable.dart';
import 'question_type.dart';

/// Clase de base pour toutes les réponses
abstract class Answer extends Equatable {
  const Answer();

  /// Convertir en Map pour la sérialisation
  Map<String, dynamic> toJson();

  /// Créer une Answer depuis un Map
  static Answer fromJson(Map<String, dynamic> json, QuestionType type) {
    throw UnimplementedError();
  }

  /// Obtenir la valeur brute de la réponse
  dynamic get value;
}

/// Réponse texte
class TextAnswer extends Answer {
  @override
  final String value;

  const TextAnswer(this.value);

  @override
  List<Object?> get props => [value];

  @override
  Map<String, dynamic> toJson() => {'value': value};

  @override
  String toString() => value;
}

/// Réponse numérique
class NumberAnswer extends Answer {
  @override
  final num value;

  const NumberAnswer(this.value);

  @override
  List<Object?> get props => [value];

  @override
  Map<String, dynamic> toJson() => {'value': value};

  @override
  String toString() => value.toString();
}

/// Réponse booléenne
class BooleanAnswer extends Answer {
  @override
  final bool value;

  const BooleanAnswer(this.value);

  @override
  List<Object?> get props => [value];

  @override
  Map<String, dynamic> toJson() => {'value': value};

  @override
  String toString() => value.toString();
}

/// Réponse à choix unique
class SelectAnswer extends Answer {
  @override
  final String value;

  const SelectAnswer(this.value);

  @override
  List<Object?> get props => [value];

  @override
  Map<String, dynamic> toJson() => {'value': value};

  @override
  String toString() => value;
}

/// Réponse à sélection multiple
class MultiSelectAnswer extends Answer {
  @override
  final List<String> value;

  const MultiSelectAnswer(this.value);

  @override
  List<Object?> get props => [value];

  @override
  Map<String, dynamic> toJson() => {'value': value};

  @override
  String toString() => value.toString();
}

/// Réponse cases à cocher (similaire à MultiSelect mais sémantiquement différent)
class CheckboxAnswer extends Answer {
  @override
  final List<String> value;

  const CheckboxAnswer(this.value);

  @override
  List<Object?> get props => [value];

  @override
  Map<String, dynamic> toJson() => {'value': value};

  @override
  String toString() => value.toString();
}

/// Réponse sur une échelle
class ScaleAnswer extends Answer {
  @override
  final int value;

  const ScaleAnswer(this.value);

  @override
  List<Object?> get props => [value];

  @override
  Map<String, dynamic> toJson() => {'value': value};

  @override
  String toString() => value.toString();
}

/// Réponse de classement (option -> rang)
class RankingAnswer extends Answer {
  @override
  final Map<String, int> value; // option -> rank (1 = most important)

  const RankingAnswer(this.value);

  @override
  List<Object?> get props => [value];

  @override
  Map<String, dynamic> toJson() => {'value': value};

  @override
  String toString() => value.toString();

  /// Obtenir le classement sous forme de liste triée (du plus au moins important)
  List<String> get sortedOptions {
    final entries = value.entries.toList();
    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries.map((e) => e.key).toList();
  }
}

/// Réponse tableau (liste de lignes)
class TableAnswer extends Answer {
  @override
  final List<Map<String, dynamic>> value; // Chaque Map représente une ligne

  const TableAnswer(this.value);

  @override
  List<Object?> get props => [value];

  @override
  Map<String, dynamic> toJson() => {'value': value};

  @override
  String toString() => value.toString();
}

/// Fabrique pour créer des Answer depuis JSON
extension AnswerFactory on Answer {
  static Answer fromJson(Map<String, dynamic> json, QuestionType type) {
    final value = json['value'];
    
    return switch (type) {
      QuestionType.text => TextAnswer(value as String),
      QuestionType.number => NumberAnswer(value as num),
      QuestionType.boolean => BooleanAnswer(value as bool),
      QuestionType.select => SelectAnswer(value as String),
      QuestionType.multiselect => MultiSelectAnswer((value as List).cast<String>()),
      QuestionType.checkbox => CheckboxAnswer((value as List).cast<String>()),
      QuestionType.scale => ScaleAnswer(value as int),
      QuestionType.ranking => RankingAnswer((value as Map).cast<String, int>()),
      QuestionType.table => TableAnswer((value as List).cast<Map<String, dynamic>>()),
    };
  }
}
