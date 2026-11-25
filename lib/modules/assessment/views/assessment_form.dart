import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/iv.dart';
import '../../../core/storage/box_names.dart';
import '../services/assessment_structure_service.dart';
import '../services/user_assessment_service.dart';
import '../models/theme.dart' as assessment_theme;
import '../models/question.dart';
import '../models/question_type.dart';
import '../models/answer.dart';
import '../widgets/question_widget.dart';

/// Formulaire pour compléter un assessment
class AssessmentForm extends StatefulWidget {
  final String? userId;
  final String? assessmentId;

  const AssessmentForm({
    super.key,
    this.userId,
    this.assessmentId,
  });

  @override
  State<AssessmentForm> createState() => _AssessmentFormState();
}

class _AssessmentFormState extends State<AssessmentForm> {
  String? _currentThemeId;
  String? _currentUserId;
  String? _currentAssessmentId;
  String _ivName = '';
  String? _selectedIvId;
  DateTime _assessmentDate = DateTime.now();
  List<Iv> _ivs = [];
  bool _isLoadingIVs = true;
  
  // Services (stocker pour éviter les context.read dans les callbacks)
  late AssessmentStructureService _structureService;
  late UserAssessmentService _assessmentService;
  
  // Pour les réponses temporaires (non encore sauvegardées)
  final Map<String, Answer> _tempAnswers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAssessment());
  }

  Future<void> _initAssessment() async {
    try {
      _structureService = Provider.of<AssessmentStructureService>(context, listen: false);
      _assessmentService = Provider.of<UserAssessmentService>(context, listen: false);
      
      final userService = _assessmentService;
      final structureService = _structureService;
      
      // Si aucun userId n'est fourni, en générer un
      _currentUserId = widget.userId ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      // Créer ou charger l'assessment
      if (widget.assessmentId != null) {
        // Charger l'assessment existant
        final assessment = await userService.loadAssessment(
          userId: _currentUserId!,
          assessmentId: widget.assessmentId!,
        );
        if (assessment != null) {
          _currentAssessmentId = assessment.assessmentId;
          _ivName = assessment.ivName;
          _assessmentDate = assessment.assessmentDate;
          // Charger les réponses existantes
          for (final themeResponse in assessment.themeResponses) {
            for (final questionResponse in themeResponse.responses) {
              final question = structureService.getQuestion(questionResponse.questionId);
              if (question != null) {
                _tempAnswers[questionResponse.questionId] = questionResponse.answer;
              }
            }
          }
        }
      }
      
      if (_currentAssessmentId == null) {
        // Créer un nouvel assessment
        final assessment = await userService.createAssessment(
          userId: _currentUserId!,
          ivName: _ivName,
          assessmentDate: _assessmentDate,
        );
        _currentAssessmentId = assessment.assessmentId;
      }
      
      // Initialiser le thème courant
      final themes = structureService.getAllThemes();
      if (themes.isNotEmpty) {
        setState(() {
          _currentThemeId = themes.first.id;
        });
      }
      
      // Charger la liste des IV depuis Hive
      await _loadIVs();
      
      // Si un nom d'IV est déjà défini, trouver son ID
      if (_ivName.isNotEmpty) {
        try {
          final iv = _ivs.firstWhere((iv) => iv.name == _ivName);
          _selectedIvId = iv.id;
        } catch (_) {
          // IV non trouvé, laisser _selectedIvId à null
        }
      }
      
      setState(() {
        _isLoadingIVs = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final structureService = Provider.of<AssessmentStructureService>(context);
    final assessmentService = Provider.of<UserAssessmentService>(context);
    
    if (structureService.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final themes = structureService.getAllThemes();
    
    if (themes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assessment')),
        body: const Center(
          child: Text('Aucun thème disponible. Veuillez configurer la structure.'),
        ),
      );
    }

    // Trouver le thème courant
    final currentTheme = structureService.getTheme(_currentThemeId ?? themes.first.id);
        
    return Scaffold(
      appBar: AppBar(
        title: Text(currentTheme?.title ?? 'Assessment'),
        actions: [
          // Indicateur de progression
          StreamBuilder<double>(
            stream: _getCompletionStream(assessmentService),
            builder: (context, snapshot) {
              final percentage = snapshot.data ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: _showStatsDialog,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${percentage.toStringAsFixed(0)}%'),
                      const SizedBox(width: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Sauvegarder',
            onPressed: _saveAll,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Terminer l\'assessment',
            onPressed: _showCompleteDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Informations de l'assessment (nom IV et date)
          _buildAssessmentInfoHeader(),
          const Divider(height: 1),
          
          // Navigation entre les thèmes
          _buildThemeNavigation(themes, currentTheme),
          const Divider(height: 1),
          
          // Contenu du thème
          Expanded(
            child: _buildThemeContent(context, currentTheme, assessmentService),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context, themes, currentTheme),
    );
  }

  /// Charger la liste des IV depuis Hive
  Future<void> _loadIVs() async {
    try {
      final ivBox = Hive.box<Iv>(BoxNames.ivs);
      _ivs = ivBox.values.where((iv) => iv.active).cast<Iv>().toList();
      
      // Trier par nom
      _ivs.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      debugPrint('Erreur lors du chargement des IV: $e');
      _ivs = [];
    }
  }

  /// Construit l'en-tête avec les informations de l'assessment
  Widget _buildAssessmentInfoHeader() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _isLoadingIVs
                      ? const SizedBox(
                          height: 56,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Nom de l\'IV',
                            hintText: 'Sélectionnez un IV',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedIvId,
                          items: _ivs.map((Iv iv) {
                            return DropdownMenuItem<String>(
                              value: iv.id,
                              child: Text(iv.name),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              try {
                                final selectedIv = _ivs.firstWhere(
                                  (iv) => iv.id == newValue,
                                );
                                setState(() {
                                  _selectedIvId = newValue;
                                  _ivName = selectedIv.name;
                                });
                                _saveAssessmentMetadata();
                              } catch (_) {
                                // IV non trouvé
                              }
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner un IV';
                            }
                            return null;
                          },
                        ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    '${_assessmentDate.day}/${_assessmentDate.month}/${_assessmentDate.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  onPressed: _selectDate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Sélectionner la date de l'assessment
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _assessmentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('fr'),
    );
    
    if (picked != null && picked != _assessmentDate) {
      setState(() {
        _assessmentDate = picked;
      });
      await _saveAssessmentMetadata();
    }
  }

  /// Sauvegarder les métadonnées de l'assessment (nom IV et date)
  Future<void> _saveAssessmentMetadata() async {
    if (_currentUserId == null || _currentAssessmentId == null) return;
    
    await _assessmentService.updateIvName(
      userId: _currentUserId!,
      assessmentId: _currentAssessmentId!,
      ivName: _ivName,
    );
    
    await _assessmentService.updateAssessmentDate(
      userId: _currentUserId!,
      assessmentId: _currentAssessmentId!,
      assessmentDate: _assessmentDate,
    );
  }

  /// Construit la navigation entre les thèmes
  Widget _buildThemeNavigation(List<assessment_theme.Theme> themes, assessment_theme.Theme? currentTheme) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        itemBuilder: (ctx, index) {
          final theme = themes[index];
          final isCurrent = theme.id == currentTheme?.id;
          
          // Obtenir le pourcentage de complétion pour ce thème
          final themeStats = _getThemeStats(theme);

          return GestureDetector(
            onTap: () => _selectTheme(theme.id, index),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 140,
                maxWidth: 200,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isCurrent 
                      ? Theme.of(ctx).primaryColor 
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        theme.title,
                        style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: double.infinity,
                      child: LinearProgressIndicator(
                        value: themeStats.completionPercentage / 100,
                        backgroundColor: Colors.grey[400],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCurrent ? Colors.white : Theme.of(ctx).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${themeStats.answeredCount}/${themeStats.totalQuestions}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.black,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construit le contenu du thème
  Widget _buildThemeContent(
    BuildContext context,
    assessment_theme.Theme? currentTheme,
    UserAssessmentService assessmentService,
  ) {
    if (currentTheme == null) {
      return const Center(child: Text('Thème non trouvé'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête du thème
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentTheme.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(currentTheme.description),
                  const SizedBox(height: 8),
                  Text(
                    '${currentTheme.questionCount} questions',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Questions du thème
          ...currentTheme.questions.map((question) {
            final existingAnswer = _tempAnswers[question.id];
            
            return QuestionWidget(
              key: ValueKey(question.id),
              question: question,
              initialAnswer: existingAnswer,
              onChanged: (answer) {
                _tempAnswers[question.id] = answer;
                _debouncedSave(question, answer);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Construit la navigation inférieure
  Widget _buildBottomNavigation(BuildContext context, List<assessment_theme.Theme> themes, assessment_theme.Theme? currentTheme) {
    final currentIndex = themes.indexWhere((t) => t.id == currentTheme?.id);
    
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: currentIndex > 0 ? () => _selectTheme(themes[currentIndex - 1].id, currentIndex - 1) : null,
            tooltip: 'Précédent',
          ),
          Text(
            '${currentIndex + 1}/${themes.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: currentIndex < themes.length - 1 ? () => _selectTheme(themes[currentIndex + 1].id, currentIndex + 1) : null,
            tooltip: 'Suivant',
          ),
        ],
      ),
    );
  }

  /// Sélectionner un thème
  void _selectTheme(String themeId, int index) {
    setState(() {
      _currentThemeId = themeId;
    });
  }

  /// Stream pour la complétion globale
  Stream<double> _getCompletionStream(UserAssessmentService service) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      
      final themes = _structureService.getAllThemes();
      int totalQuestions = 0;
      int answeredCount = 0;
      
      for (final theme in themes) {
        final stats = _getThemeStats(theme);
        totalQuestions += stats.totalQuestions;
        answeredCount += stats.answeredCount;
      }
      
      final percentage = totalQuestions > 0 
          ? (answeredCount / totalQuestions) * 100 
          : 0.0;
      
      yield percentage;
      
      // Arrêter le stream après un certain temps ou si l'assessment est terminé
      if (_currentUserId != null && _currentAssessmentId != null) {
        final status = await service.getAssessmentStatus(
          userId: _currentUserId!,
          assessmentId: _currentAssessmentId!,
        );
        if (status == AssessmentStatus.completed) {
          break;
        }
      }
    }
  }

  /// Statistiques pour un thème
  FormThemeStats _getThemeStats(assessment_theme.Theme theme) {
    final totalQuestions = theme.questions.length;
    final answeredCount = theme.questions
        .where((q) => _tempAnswers.containsKey(q.id))
        .length;
    
    return FormThemeStats(
      totalQuestions: totalQuestions,
      answeredCount: answeredCount,
      completionPercentage: totalQuestions > 0 
          ? (answeredCount / totalQuestions) * 100 
          : 0.0,
    );
  }

  /// Sauvegarder une réponse (avec délai pour éviter les sauvegardes trop fréquentes)
  Timer? _saveTimer;
  
  void _debouncedSave(Question question, Answer answer) {
    _saveTimer?.cancel();
    
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _saveResponse(question, answer);
    });
  }

  /// Sauvegarder une réponse
  Future<void> _saveResponse(Question question, Answer answer) async {
    if (_currentUserId == null || _currentAssessmentId == null) return;
    
    final theme = _structureService.getThemeByQuestion(question.id);
    
    if (theme == null) return;
    
    await _assessmentService.saveQuestionResponse(
      userId: _currentUserId!,
      assessmentId: _currentAssessmentId!,
      themeId: theme.id,
      questionId: question.id,
      answer: answer,
    );
  }

  /// Sauvegarder toutes les réponses
  Future<void> _saveAll() async {
    if (_currentUserId == null || _currentAssessmentId == null) return;
    
    // Sauvegarder les métadonnées d'abord
    await _saveAssessmentMetadata();
    
    // Sauvegarder toutes les réponses
    for (final entry in _tempAnswers.entries) {
      final questionId = entry.key;
      final answer = entry.value;
      
      final theme = _structureService.getThemeByQuestion(questionId);
      if (theme != null) {
        await _assessmentService.saveQuestionResponse(
          userId: _currentUserId!,
          assessmentId: _currentAssessmentId!,
          themeId: theme.id,
          questionId: questionId,
          answer: answer,
        );
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réponses et informations sauvegardées !')),
      );
    }
  }

  /// Affiche le dialogue pour terminer l'assessment
  Future<void> _showCompleteDialog() async {
    final themes = _structureService.getAllThemes();
    final totalQuestions = themes.fold(
      0,
      (sum, theme) => sum + theme.questions.length,
    );
    
    int answeredCount = 0;
    for (final theme in themes) {
      final stats = _getThemeStats(theme);
      answeredCount += stats.answeredCount;
    }
    
    final unansweredCount = totalQuestions - answeredCount;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer l\'Assessment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_ivName.isNotEmpty) ...[
              Text('Assessment pour: $_ivName', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            Text('Date: ${_assessmentDate.day}/${_assessmentDate.month}/${_assessmentDate.year}'),
            const SizedBox(height: 8),
            Text('Vous avez répondu à $answeredCount des $totalQuestions questions.'),
            if (unansweredCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$unansweredCount question(s) reste(nt) sans réponse.',
                style: const TextStyle(color: Colors.orange),
              ),
              const SizedBox(height: 8),
              const Text('Souhaitez-vous tout de même terminer ?'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terminer'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        await _saveAll();
        
        await _assessmentService.completeAssessment(
          userId: _currentUserId!,
          assessmentId: _currentAssessmentId!,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assessment terminé avec succès !')),
          );
          Navigator.pop(context);
        }
      }
    });
  }

  /// Affiche le dialogue des statistiques
  Future<void> _showStatsDialog() async {
    final themes = _structureService.getAllThemes();
    
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final theme in themes)
                ListTile(
                  title: Text(theme.title),
                  subtitle: Text('${_getThemeStats(theme).answeredCount}/${theme.questions.length} réponses'),
                  trailing: Text('${_getThemeStats(theme).completionPercentage.toStringAsFixed(0)}%'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

/// Extension pour obtenir le thème d'une question
extension AssessmentStructureExtensions on AssessmentStructureService {
  assessment_theme.Theme? getThemeByQuestion(String questionId) {
    for (final theme in getAllThemes()) {
      if (theme.hasQuestion(questionId)) {
        return theme;
      }
    }
    return null;
  }
}

/// Statistiques pour un thème
class FormThemeStats {
  final int totalQuestions;
  final int answeredCount;
  final double completionPercentage;

  FormThemeStats({
    required this.totalQuestions,
    required this.answeredCount,
    required this.completionPercentage,
  });
}
