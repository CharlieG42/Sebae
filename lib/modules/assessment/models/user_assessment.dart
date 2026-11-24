import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'answer.dart';
import 'assessment_structure.dart';
import 'question_type.dart';

/// Réponse à une question spécifique
class QuestionResponse extends Equatable {
  /// ID de la question
  final String questionId;
  
  /// Réponse donnée
  final Answer answer;
  
  /// Date de dernière modification
  final DateTime lastModified;

  QuestionResponse({
    required this.questionId,
    required this.answer,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  @override
  List<Object?> get props => [questionId, answer, lastModified];

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    // On ne peut pas désérialiser Answer sans connaître le type de question
    // Cette méthode sera appelée avec le type de question
    final questionId = json['questionId'] as String;
    final lastModified = DateTime.parse(json['lastModified'] as String);
    
    // Pour la désérialisation complète, utiliser fromJsonWithType
    return QuestionResponse(
      questionId: questionId,
      answer: TextAnswer(''), // Placeholder - sera remplacé
      lastModified: lastModified,
    );
  }

  /// Désérialisation avec le type de question
  static QuestionResponse fromJsonWithType(
    Map<String, dynamic> json, 
    QuestionType questionType
  ) {
    return QuestionResponse(
      questionId: json['questionId'] as String,
      answer: Answer.fromJson(
        json['answer'] as Map<String, dynamic>, 
        questionType
      ),
      lastModified: DateTime.parse(json['lastModified'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answer': answer.toJson(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  QuestionResponse copyWith({
    String? questionId,
    Answer? answer,
    DateTime? lastModified,
  }) {
    return QuestionResponse(
      questionId: questionId ?? this.questionId,
      answer: answer ?? this.answer,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  String toString() => 'QuestionResponse($questionId)';
}

/// Réponses d'un thème
class ThemeResponse extends Equatable {
  /// ID du thème
  final String themeId;
  
  /// Réponses aux questions du thème
  final List<QuestionResponse> responses;

  const ThemeResponse({
    required this.themeId,
    this.responses = const [],
  });

  @override
  List<Object?> get props => [themeId, responses];

  factory ThemeResponse.fromJson(
    Map<String, dynamic> json, 
    AssessmentStructure structure
  ) {
    final themeId = json['themeId'] as String;
    final responsesJson = json['responses'] as List? ?? [];
    
    final responses = <QuestionResponse>[];
    for (final responseJson in responsesJson) {
      final questionId = responseJson['questionId'] as String;
      final question = structure.getQuestion(questionId);
      
      if (question != null) {
        responses.add(
          QuestionResponse.fromJsonWithType(
            responseJson as Map<String, dynamic>,
            question.type
          )
        );
      }
    }
    
    return ThemeResponse(
      themeId: themeId,
      responses: responses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeId': themeId,
      'responses': responses.map((r) => r.toJson()).toList(),
    };
  }

  ThemeResponse copyWith({
    String? themeId,
    List<QuestionResponse>? responses,
  }) {
    return ThemeResponse(
      themeId: themeId ?? this.themeId,
      responses: responses ?? this.responses,
    );
  }

  /// Obtenir la réponse à une question spécifique
  QuestionResponse? getResponse(String questionId) {
    try {
      return responses.firstWhere((r) => r.questionId == questionId);
    } catch (_) {
      return null;
    }
  }

  /// Vérifier si une question a été répondue
  bool hasResponse(String questionId) {
    return responses.any((r) => r.questionId == questionId);
  }

  /// Ajouter ou mettre à jour une réponse
  ThemeResponse setResponse(QuestionResponse response) {
    final existingIndex = responses.indexWhere(
      (r) => r.questionId == response.questionId
    );
    
    if (existingIndex >= 0) {
      final newResponses = List<QuestionResponse>.from(responses);
      newResponses[existingIndex] = response;
      return copyWith(responses: newResponses);
    } else {
      final newResponses = List<QuestionResponse>.from(responses)..add(response);
      return copyWith(responses: newResponses);
    }
  }

  /// Supprimer une réponse
  ThemeResponse removeResponse(String questionId) {
    final newResponses = responses.where(
      (r) => r.questionId != questionId
    ).toList();
    return copyWith(responses: newResponses);
  }

  @override
  String toString() => 'ThemeResponse($themeId, ${responses.length} responses)';
}

/// Assessment complet d'un utilisateur
// Le statut, les réponses et les notes évoluent pendant l'assessment :
// la contrainte d'immuabilité de [Equatable] ne s'applique pas ici.
// ignore: must_be_immutable
class UserAssessment extends Equatable {
  /// ID de l'utilisateur (IV)
  final String userId;
  
  /// ID de l'assessment
  final String assessmentId;
  
  /// Date de création
  final DateTime date;
  
  /// Statut de l'assessment
  AssessmentStatus status;
  
  /// Réponses par thème
  List<ThemeResponse> themeResponses;
  
  /// Notes supplémentaires
  String? notes;

  UserAssessment({
    String? assessmentId,
    required this.userId,
    DateTime? date,
    this.status = AssessmentStatus.in_progress,
    this.themeResponses = const [],
    this.notes,
  }) : assessmentId = assessmentId ?? const Uuid().v4(),
       date = date ?? DateTime.now();

  @override
  List<Object?> get props => [
    userId,
    assessmentId,
    date,
    status,
    themeResponses,
    notes,
  ];

  factory UserAssessment.fromJson(
    Map<String, dynamic> json, 
    AssessmentStructure structure
  ) {
    final themeResponsesJson = json['themeResponses'] as List? ?? [];
    
    final themeResponses = <ThemeResponse>[];
    for (final trJson in themeResponsesJson) {
      themeResponses.add(
        ThemeResponse.fromJson(
          trJson as Map<String, dynamic>,
          structure
        )
      );
    }
    
    return UserAssessment(
      assessmentId: json['assessmentId'] as String?,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      status: AssessmentStatusExtension.fromJson(json['status'] as String),
      themeResponses: themeResponses,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'assessmentId': assessmentId,
      'date': date.toIso8601String(),
      'status': status.toJson(),
      'themeResponses': themeResponses.map((tr) => tr.toJson()).toList(),
      if (notes != null) 'notes': notes,
    };
  }

  UserAssessment copyWith({
    String? userId,
    String? assessmentId,
    DateTime? date,
    AssessmentStatus? status,
    List<ThemeResponse>? themeResponses,
    String? notes,
  }) {
    return UserAssessment(
      assessmentId: assessmentId ?? this.assessmentId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      status: status ?? this.status,
      themeResponses: themeResponses ?? this.themeResponses,
      notes: notes ?? this.notes,
    );
  }

  /// Obtenir les réponses pour un thème spécifique
  ThemeResponse? getThemeResponse(String themeId) {
    try {
      return themeResponses.firstWhere((tr) => tr.themeId == themeId);
    } catch (_) {
      return null;
    }
  }

  /// Obtenir la réponse à une question spécifique
  QuestionResponse? getQuestionResponse(String themeId, String questionId) {
    final themeResponse = getThemeResponse(themeId);
    return themeResponse?.getResponse(questionId);
  }

  /// Vérifier si une question a été répondue
  bool hasQuestionResponse(String themeId, String questionId) {
    final themeResponse = getThemeResponse(themeId);
    return themeResponse?.hasResponse(questionId) ?? false;
  }

  /// Ajouter ou mettre à jour une réponse
  UserAssessment setQuestionResponse(
    String themeId,
    QuestionResponse response
  ) {
    final existingIndex = themeResponses.indexWhere(
      (tr) => tr.themeId == themeId
    );
    
    final updatedThemeResponse = existingIndex >= 0
        ? themeResponses[existingIndex].setResponse(response)
        : ThemeResponse(themeId: themeId, responses: [response]);
    
    final newThemeResponses = List<ThemeResponse>.from(themeResponses);
    if (existingIndex >= 0) {
      newThemeResponses[existingIndex] = updatedThemeResponse;
    } else {
      newThemeResponses.add(updatedThemeResponse);
    }
    
    return copyWith(themeResponses: newThemeResponses);
  }

  /// Supprimer une réponse
  UserAssessment removeQuestionResponse(String themeId, String questionId) {
    final existingIndex = themeResponses.indexWhere(
      (tr) => tr.themeId == themeId
    );
    
    if (existingIndex < 0) return this;
    
    final updatedThemeResponse = themeResponses[existingIndex].removeResponse(questionId);
    
    // Si plus de réponses, supprimer le ThemeResponse
    final newThemeResponses = List<ThemeResponse>.from(themeResponses);
    if (updatedThemeResponse.responses.isEmpty) {
      newThemeResponses.removeAt(existingIndex);
    } else {
      newThemeResponses[existingIndex] = updatedThemeResponse;
    }
    
    return copyWith(themeResponses: newThemeResponses);
  }

  /// Marquer comme terminé
  UserAssessment markAsCompleted() {
    return copyWith(status: AssessmentStatus.completed);
  }

  /// Marquer comme en cours
  UserAssessment markAsInProgress() {
    return copyWith(status: AssessmentStatus.in_progress);
  }

  /// Marquer comme revu
  UserAssessment markAsReviewed() {
    return copyWith(status: AssessmentStatus.reviewed);
  }

  /// Vérifier si l'assessment est terminé
  bool get isCompleted => status == AssessmentStatus.completed;

  /// Vérifier si l'assessment est en cours
  bool get isInProgress => status == AssessmentStatus.in_progress;

  /// Vérifier si l'assessment est revu
  bool get isReviewed => status == AssessmentStatus.reviewed;

  /// Obtenir le nombre total de réponses
  int get totalResponseCount {
    return themeResponses.fold(
      0,
      (sum, tr) => sum + tr.responses.length
    );
  }

  /// Obtenir le pourcentage de complétion
  double get completionPercentage {
    // Cette méthode nécessite la structure de l'assessment pour connaître
    // le nombre total de questions
    return 0.0;
  }

  @override
  String toString() => 'UserAssessment($userId, $assessmentId, $status)';
}
