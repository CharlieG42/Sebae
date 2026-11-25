import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_assessment.dart';
import '../models/answer.dart';
import '../models/question_type.dart';
import 'assessment_structure_service.dart';

/// Service pour gérer les réponses des utilisateurs (IV)
/// 
/// Ce service permet de:
/// - Créer des assessments pour les IV
/// - Sauvegarder et charger les réponses
/// - Gérer le statut des assessments
/// - Calculer la progression
class UserAssessmentService extends ChangeNotifier {
  static const String _storagePrefix = 'user_assessment_';

  AssessmentStructureService? _structureService;

  /// Définir le service de structure (doit être appelé avant utilisation)
  void setStructureService(AssessmentStructureService service) {
    _structureService = service;
  }

  /// Initialisation du service
  Future<void> init() async {
    // Le service de structure doit être défini avant l'init
    if (_structureService != null) {
      await _structureService!.init();
    }
  }
  
  /// Obtenir le service de structure
  AssessmentStructureService get structureService {
    if (_structureService == null) {
      throw Exception('AssessmentStructureService non défini. Appeler setStructureService() d\'abord.');
    }
    return _structureService!;
  }

  // ============================================
  // GESTION DES ASSESSMENTS
  // ============================================

  /// Créer un nouvel assessment pour un utilisateur
  Future<UserAssessment> createAssessment({
    required String userId,
    String? assessmentId,
    String? ivName,
    DateTime? assessmentDate,
    AssessmentStatus status = AssessmentStatus.in_progress,
    String? notes,
  }) async {
    final assessment = UserAssessment(
      userId: userId,
      assessmentId: assessmentId,
      ivName: ivName,
      assessmentDate: assessmentDate,
      status: status,
      notes: notes,
    );

    await _saveAssessment(assessment);
    notifyListeners();

    return assessment;
  }

  /// Sauvegarder un assessment
  Future<void> _saveAssessment(UserAssessment assessment) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(assessment.toJson());
    await prefs.setString(
      '$_storagePrefix${assessment.userId}_${assessment.assessmentId}',
      jsonString,
    );
  }

  /// Charger un assessment
  Future<UserAssessment?> loadAssessment({
    required String userId,
    required String assessmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_storagePrefix${userId}_$assessmentId';
    final jsonString = prefs.getString(key);

    if (jsonString == null) return null;

    return UserAssessment.fromJson(
      jsonDecode(jsonString),
      structureService.getStructure(),
    );
  }

  /// Lister tous les assessments d'un utilisateur
  Future<List<UserAssessment>> listUserAssessments(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    final assessments = <UserAssessment>[];
    
    for (final key in keys) {
      if (key.startsWith('$_storagePrefix$userId')) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final assessment = UserAssessment.fromJson(
              jsonDecode(jsonString),
              structureService.getStructure(),
            );
            assessments.add(assessment);
          } catch (e) {
            debugPrint('Erreur lors du chargement de l\'assessment: $e');
          }
        }
      }
    }
    
    // Trier par date (plus récent en premier)
    assessments.sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
    
    return assessments;
  }

  /// Lister tous les assessments
  Future<List<UserAssessment>> listAllAssessments() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    final assessments = <UserAssessment>[];
    
    for (final key in keys) {
      if (key.startsWith(_storagePrefix)) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final assessment = UserAssessment.fromJson(
              jsonDecode(jsonString),
              structureService.getStructure(),
            );
            assessments.add(assessment);
          } catch (e) {
            debugPrint('Erreur lors du chargement de l\'assessment: $e');
          }
        }
      }
    }
    
    // Trier par date (plus récent en premier)
    assessments.sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
    
    return assessments;
  }

  /// Supprimer un assessment
  Future<bool> deleteAssessment({
    required String userId,
    required String assessmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_storagePrefix${userId}_$assessmentId';
    
    if (prefs.containsKey(key)) {
      await prefs.remove(key);
      notifyListeners();
      return true;
    }
    
    return false;
  }

  /// Supprimer tous les assessments d'un utilisateur
  Future<int> deleteAllUserAssessments(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    int deletedCount = 0;
    for (final key in keys) {
      if (key.startsWith('$_storagePrefix$userId')) {
        await prefs.remove(key);
        deletedCount++;
      }
    }
    
    if (deletedCount > 0) {
      notifyListeners();
    }
    
    return deletedCount;
  }

  // ============================================
  // GESTION DES RÉPONSES
  // ============================================

  /// Sauvegarder une réponse à une question
  Future<bool> saveQuestionResponse({
    required String userId,
    required String assessmentId,
    required String themeId,
    required String questionId,
    required Answer answer,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) {
      return false;
    }

    final response = QuestionResponse(
      questionId: questionId,
      answer: answer,
    );

    final updatedAssessment = assessment.setQuestionResponse(themeId, response);
    await _saveAssessment(updatedAssessment);
    notifyListeners();

    return true;
  }

  /// Obtenir la réponse à une question
  Future<QuestionResponse?> getQuestionResponse({
    required String userId,
    required String assessmentId,
    required String themeId,
    required String questionId,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    return assessment?.getQuestionResponse(themeId, questionId);
  }

  /// Vérifier si une question a été répondue
  Future<bool> hasQuestionResponse({
    required String userId,
    required String assessmentId,
    required String themeId,
    required String questionId,
  }) async {
    return (await getQuestionResponse(
      userId: userId,
      assessmentId: assessmentId,
      themeId: themeId,
      questionId: questionId,
    )) != null;
  }

  /// Supprimer une réponse
  Future<bool> deleteQuestionResponse({
    required String userId,
    required String assessmentId,
    required String themeId,
    required String questionId,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) {
      return false;
    }

    final updatedAssessment = assessment.removeQuestionResponse(themeId, questionId);
    await _saveAssessment(updatedAssessment);
    notifyListeners();

    return true;
  }

  // ============================================
  // GESTION DU STATUT
  // ============================================

  /// Marquer un assessment comme terminé
  Future<bool> completeAssessment({
    required String userId,
    required String assessmentId,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) {
      return false;
    }

    final updatedAssessment = assessment.markAsCompleted();
    await _saveAssessment(updatedAssessment);
    notifyListeners();

    return true;
  }

  /// Marquer un assessment comme en cours
  Future<bool> setAssessmentInProgress({
    required String userId,
    required String assessmentId,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) {
      return false;
    }

    final updatedAssessment = assessment.markAsInProgress();
    await _saveAssessment(updatedAssessment);
    notifyListeners();

    return true;
  }

  /// Marquer un assessment comme revu
  Future<bool> setAssessmentReviewed({
    required String userId,
    required String assessmentId,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) {
      return false;
    }

    final updatedAssessment = assessment.markAsReviewed();
    await _saveAssessment(updatedAssessment);
    notifyListeners();

    return true;
  }

  /// Obtenir le statut d'un assessment
  Future<AssessmentStatus?> getAssessmentStatus({
    required String userId,
    required String assessmentId,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    return assessment?.status;
  }

  // ============================================
  // STATISTIQUES ET PROGRESSION
  // ============================================

  /// Calculer le pourcentage de complétion d'un assessment
  Future<double> getCompletionPercentage({
    required String userId,
    required String assessmentId,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) return 0.0;

    final structure = structureService.getStructure();
    final totalQuestions = structure.allQuestions.length;
    
    if (totalQuestions == 0) return 100.0;

    int answeredCount = 0;
    for (final themeResponse in assessment.themeResponses) {
      answeredCount += themeResponse.responses.length;
    }

    return (answeredCount / totalQuestions) * 100;
  }

  /// Obtenir le nombre de questions répondues
  Future<int> getAnsweredQuestionCount({
    required String userId,
    required String assessmentId,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) return 0;

    int count = 0;
    for (final themeResponse in assessment.themeResponses) {
      count += themeResponse.responses.length;
    }
    return count;
  }

  /// Obtenir le nombre total de questions
  int getTotalQuestionCount() {
    return structureService.getStructure().allQuestions.length;
  }

  /// Obtenir les statistiques par thème
  Future<Map<String, ThemeStats>> getStatsByTheme({
    required String userId,
    required String assessmentId,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) return {};

    final structure = structureService.getStructure();
    final stats = <String, ThemeStats>{};

    for (final theme in structure.sortedThemes) {
      final themeResponse = assessment.getThemeResponse(theme.id);
      final answeredCount = themeResponse?.responses.length ?? 0;
      final totalQuestions = theme.questions.length;
      final percentage = totalQuestions > 0 
          ? (answeredCount / totalQuestions) * 100 
          : 0.0;

      stats[theme.id] = ThemeStats(
        themeId: theme.id,
        themeTitle: theme.title,
        totalQuestions: totalQuestions,
        answeredCount: answeredCount,
        completionPercentage: percentage,
      );
    }

    return stats;
  }

  // ============================================
  // MÉTHODES UTILITAIRES
  // ============================================

  /// Obtenir les réponses sous forme de Map structurée
  Future<Map<String, Map<String, dynamic>>> getAssessmentSummary({
    required String userId,
    required String assessmentId,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) return {};

    final summary = <String, Map<String, dynamic>>{};

    for (final themeResponse in assessment.themeResponses) {
      final themeId = themeResponse.themeId;
      final theme = structureService.getTheme(themeId);
      
      if (theme != null) {
        final themeSummary = <String, dynamic>{};
        
        for (final questionResponse in themeResponse.responses) {
          final question = theme.getQuestion(questionResponse.questionId);
          if (question != null) {
            themeSummary[question.id] = {
              'text': question.text,
              'type': question.type.toJson(),
              'answer': questionResponse.answer.toJson(),
              'lastModified': questionResponse.lastModified.toIso8601String(),
            };
          }
        }
        
        summary[themeId] = {
          'themeTitle': theme.title,
          'questions': themeSummary,
        };
      }
    }

    return summary;
  }

  /// Mettre à jour le nom de l'IV pour un assessment
  Future<bool> updateIvName({
    required String userId,
    required String assessmentId,
    required String ivName,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) {
      return false;
    }

    final updatedAssessment = assessment.setIvName(ivName);
    await _saveAssessment(updatedAssessment);
    notifyListeners();

    return true;
  }
  
  /// Mettre à jour la date de l'assessment
  Future<bool> updateAssessmentDate({
    required String userId,
    required String assessmentId,
    required DateTime assessmentDate,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) {
      return false;
    }

    final updatedAssessment = assessment.setAssessmentDate(assessmentDate);
    await _saveAssessment(updatedAssessment);
    notifyListeners();

    return true;
  }

  /// Exporter les réponses d'un assessment en JSON
  Future<String?> exportAssessment({
    required String userId,
    required String assessmentId,
  }) async {
    final assessment = await loadAssessment(
      userId: userId,
      assessmentId: assessmentId,
    );

    if (assessment == null) return null;

    return json.encode(assessment.toJson());
  }

  /// Importer un assessment depuis JSON
  Future<UserAssessment?> importAssessment(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString);
      final assessment = UserAssessment.fromJson(
        jsonData,
        structureService.getStructure(),
      );
      
      await _saveAssessment(assessment);
      notifyListeners();
      
      return assessment;
    } catch (e) {
      debugPrint('Erreur lors de l\'import: $e');
      return null;
    }
  }
}

/// Statistiques pour un thème
class ThemeStats {
  final String themeId;
  final String themeTitle;
  final int totalQuestions;
  final int answeredCount;
  final double completionPercentage;

  ThemeStats({
    required this.themeId,
    required this.themeTitle,
    required this.totalQuestions,
    required this.answeredCount,
    required this.completionPercentage,
  });
}
