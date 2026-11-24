import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'question.dart';

/// Modèle d'un thème dans l'assessment
class Theme extends Equatable {
  /// Identifiant unique du thème
  final String id;
  
  /// Titre du thème
  final String title;
  
  /// Description du thème
  final String description;
  
  /// Ordre d'affichage
  final int order;
  
  /// Liste des questions du thème
  final List<Question> questions;

  Theme({
    String? id,
    required this.title,
    this.description = '',
    this.order = 1,
    this.questions = const [],
  }) : id = id ?? const Uuid().v4();

  @override
  List<Object?> get props => [id, title, description, order, questions];

  /// Créer un Theme depuis un Map
  factory Theme.fromJson(Map<String, dynamic> json) {
    return Theme(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      order: json['order'] as int? ?? 1,
      questions: (json['questions'] as List?)
          ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Convertir en Map pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  /// Créer une copie avec des modifications
  Theme copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    List<Question>? questions,
  }) {
    return Theme(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      questions: questions ?? this.questions,
    );
  }

  /// Obtenir le nombre de questions
  int get questionCount => questions.length;

  /// Obtenir toutes les questions obligatoires
  List<Question> get requiredQuestions => 
    questions.where((q) => q.required).toList();

  /// Vérifier si le thème a des questions
  bool get hasQuestions => questions.isNotEmpty;

  /// Ajouter une question au thème
  Theme addQuestion(Question question) {
    final newQuestions = List<Question>.from(questions)..add(question);
    return copyWith(questions: newQuestions);
  }

  /// Supprimer une question du thème
  Theme removeQuestion(String questionId) {
    final newQuestions = questions.where((q) => q.id != questionId).toList();
    return copyWith(questions: newQuestions);
  }

  /// Mettre à jour une question du thème
  Theme updateQuestion(String questionId, Question updatedQuestion) {
    final newQuestions = questions.map((q) {
      return q.id == questionId ? updatedQuestion : q;
    }).toList();
    return copyWith(questions: newQuestions);
  }

  /// Réorganiser les questions
  Theme reorderQuestions(List<String> newOrder) {
    final questionMap = {for (var q in questions) q.id: q};
    final newQuestions = newOrder
        .map((id) => questionMap[id]!)
        .toList();
    return copyWith(questions: newQuestions);
  }

  /// Obtenir une question par son ID
  Question? getQuestion(String questionId) {
    try {
      return questions.firstWhere((q) => q.id == questionId);
    } catch (_) {
      return null;
    }
  }

  /// Vérifier si une question existe dans le thème
  bool hasQuestion(String questionId) {
    return questions.any((q) => q.id == questionId);
  }

  @override
  String toString() => title;
}
