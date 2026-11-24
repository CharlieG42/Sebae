import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/assessment_structure_service.dart';
import '../models/theme.dart' as assessment_theme;
import '../models/question.dart';
import '../models/question_type.dart';
import 'theme_editor.dart';
import 'question_editor.dart';

/// Éditeur de la structure de l'assessment
class AssessmentEditor extends StatefulWidget {
  const AssessmentEditor({super.key});

  @override
  State<AssessmentEditor> createState() => _AssessmentEditorState();
}

class _AssessmentEditorState extends State<AssessmentEditor> {
  String? _selectedThemeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditeur de Structure'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un thème',
            onPressed: () => _showAddThemeDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.reorder),
            tooltip: 'Réorganiser les thèmes',
            onPressed: () => _showReorderThemesDialog(context),
          ),
        ],
      ),
      body: Consumer<AssessmentStructureService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final themes = service.getAllThemes();

          if (themes.isEmpty) {
            return const Center(
              child: Text('Aucun thème trouvé. Ajoutez-en un !'),
            );
          }

          return Row(
            children: [
              // Liste des thèmes (sidebar)
              SizedBox(
                width: 250,
                child: Card(
                  child: ListView.builder(
                    itemCount: themes.length,
                    itemBuilder: (context, index) {
                      final theme = themes[index] as assessment_theme.Theme;
                      final isSelected = _selectedThemeId == theme.id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        title: Text(theme.title),
                        subtitle: Text('${theme.questionCount} questions'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _editTheme(context, theme),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () => _deleteTheme(context, service, theme.id),
                            ),
                          ],
                        ),
                        onTap: () => setState(() => _selectedThemeId = theme.id),
                      );
                    },
                  ),
                ),
              ),
              const VerticalDivider(width: 1),

              // Contenu principal
              Expanded(
                child: _selectedThemeId == null
                    ? const Center(
                        child: Text('Sélectionnez un thème pour voir ses questions'),
                      )
                    : _buildThemeContent(context, service, _selectedThemeId!),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Construit le contenu pour un thème sélectionné
  Widget _buildThemeContent(
    BuildContext context,
    AssessmentStructureService service,
    String themeId,
  ) {
    final theme = service.getTheme(themeId) as assessment_theme.Theme?;
    
    if (theme == null) {
      return const Center(child: Text('Thème non trouvé'));
    }

    return Column(
      children: [
        // En-tête du thème
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        theme.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Ajouter une question',
                      onPressed: () => _showAddQuestionDialog(context, theme.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.reorder),
                      tooltip: 'Réorganiser les questions',
                      onPressed: () => _showReorderQuestionsDialog(context, theme),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(theme.description),
                const SizedBox(height: 8),
                Text(
                  '${theme.questionCount} questions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),

        // Liste des questions
        Expanded(
          child: ListView.builder(
            itemCount: theme.questions.length,
            itemBuilder: (context, index) {
              final question = theme.questions[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(question.text),
                  subtitle: Row(
                    children: [
                      Chip(
                        label: Text(question.type.toJson()),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (question.required) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: Colors.red, size: 16),
                        const Text('Obligatoire', style: TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _editQuestion(context, question),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => _deleteQuestion(context, service, question.id),
                      ),
                    ],
                  ),
                  onTap: () => _editQuestion(context, question),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Affiche la boîte de dialogue pour ajouter un thème
  Future<void> _showAddThemeDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un Thème'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  hintText: 'Ex: Connaissance Technique',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Description du thème...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le titre est obligatoire'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final service = Provider.of<AssessmentStructureService>(context, listen: false);
                await service.addTheme(
                  title: titleController.text,
                  description: descriptionController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  /// Affiche la boîte de dialogue pour réorganiser les thèmes
  Future<void> _showReorderThemesDialog(BuildContext context) async {
    final service = Provider.of<AssessmentStructureService>(context, listen: false);
    final themes = service.getAllThemes();

    // Créer une liste réorganisable
    final reorderableList = List<assessment_theme.Theme>.from(themes.map((t) => t as assessment_theme.Theme));

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Réorganiser les Thèmes'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ReorderableListView.builder(
              itemCount: reorderableList.length,
              itemBuilder: (context, index) {
                final theme = reorderableList[index];
                return ListTile(
                  key: Key(theme.id),
                  title: Text(theme.title),
                  trailing: const Icon(Icons.drag_handle),
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = reorderableList.removeAt(oldIndex);
                reorderableList.insert(newIndex, item);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newOrder = reorderableList.map((t) => t.id).toList();
                await service.reorderThemes(newOrder);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  /// Affiche la boîte de dialogue pour réorganiser les questions d'un thème
  Future<void> _showReorderQuestionsDialog(
    BuildContext context,
    assessment_theme.Theme theme,
  ) async {
    final service = Provider.of<AssessmentStructureService>(context, listen: false);
    final reorderableList = List<Question>.from(theme.questions);

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Réorganiser les Questions - ${theme.title}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ReorderableListView.builder(
              itemCount: reorderableList.length,
              itemBuilder: (context, index) {
                final question = reorderableList[index];
                return ListTile(
                  key: Key(question.id),
                  title: Text(question.text),
                  subtitle: Text(question.type.toJson()),
                  trailing: const Icon(Icons.drag_handle),
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = reorderableList.removeAt(oldIndex);
                reorderableList.insert(newIndex, item);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newOrder = reorderableList.map((q) => q.id).toList();
                await service.reorderQuestions(
                  themeId: theme.id,
                  newOrder: newOrder,
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  /// Affiche la boîte de dialogue pour ajouter une question
  Future<void> _showAddQuestionDialog(BuildContext context, String themeId) async {
    return showDialog<void>(
      context: context,
      builder: (context) => QuestionEditorDialog(
        themeId: themeId,
        onSaved: () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// Éditer un thème
  Future<void> _editTheme(BuildContext context, assessment_theme.Theme theme) async {
    return showDialog<void>(
      context: context,
      builder: (context) => ThemeEditorDialog(
        theme: theme,
        onSaved: () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// Éditer une question
  Future<void> _editQuestion(BuildContext context, Question question) async {
    return showDialog<void>(
      context: context,
      builder: (context) => QuestionEditorDialog(
        question: question,
        onSaved: () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// Supprimer un thème
  Future<void> _deleteTheme(
    BuildContext context,
    AssessmentStructureService service,
    String themeId,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le Thème'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce thème et toutes ses questions ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        await service.deleteTheme(themeId);
        // Si le thème supprimé était sélectionné, désélectionner
        if (_selectedThemeId == themeId) {
          setState(() => _selectedThemeId = null);
        }
      }
    });
  }

  /// Supprimer une question
  Future<void> _deleteQuestion(
    BuildContext context,
    AssessmentStructureService service,
    String questionId,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la Question'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette question ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        await service.deleteQuestion(questionId);
      }
    });
  }
}
