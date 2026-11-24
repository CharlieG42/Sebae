import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../assessment_module.dart';
import '../services/assessment_structure_service.dart';
import '../services/user_assessment_service.dart';
import 'assessment_editor.dart';
import 'assessment_form.dart';

/// Page principale du module Assessment
class AssessmentHome extends StatefulWidget {
  const AssessmentHome({super.key});

  @override
  State<AssessmentHome> createState() => _AssessmentHomeState();
}

class _AssessmentHomeState extends State<AssessmentHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assessment IV'),
            const Text('Gestion des évaluations', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Consumer2<
        AssessmentStructureService,
        UserAssessmentService
      >(
        builder: (context, structureService, assessmentService, child) {
          if (structureService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          AssessmentModule.icon,
                          size: 48,
                          color: AssessmentModule.color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AssessmentModule.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AssessmentModule.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Statistiques
                if (structureService.isLoaded) ...[
                  _buildStatsCard(context, structureService),
                  const SizedBox(height: 24),
                ],

                // Options principales
                const Text(
                  'Que souhaitez-vous faire ?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Bouton: Créer un nouvel assessment
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AssessmentForm(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un nouvel Assessment'),
                ),
                const SizedBox(height: 12),

                // Bouton: Voir mes assessments
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers la liste des assessments
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Mes Assessments'),
                ),
                const SizedBox(height: 12),

                // Bouton: Gérer la structure (admin)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AssessmentEditor(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Gérer la Structure'),
                ),
                const SizedBox(height: 12),

                // Bouton: Importer depuis JSON
                OutlinedButton.icon(
                  onPressed: () => _showImportDialog(context, structureService),
                  icon: const Icon(Icons.upload),
                  label: const Text('Importer une Structure'),
                ),
                const SizedBox(height: 12),

                // Bouton: Exporter la structure
                OutlinedButton.icon(
                  onPressed: () => _showExportDialog(context, structureService),
                  icon: const Icon(Icons.download),
                  label: const Text('Exporter la Structure'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Construit la carte des statistiques
  Widget _buildStatsCard(
    BuildContext context,
    AssessmentStructureService structureService
  ) {
    final structure = structureService.getStructure();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  context,
                  'Thèmes',
                  '${structure.themeCount}',
                  Icons.category,
                ),
                _buildStatItem(
                  context,
                  'Questions',
                  '${structure.totalQuestionCount}',
                  Icons.question_answer,
                ),
                _buildStatItem(
                  context,
                  'Types',
                  '${structure.responseTypes.length}',
                  Icons.list,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un item de statistique
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Affiche la boîte de dialogue d'import
  Future<void> _showImportDialog(
    BuildContext context,
    AssessmentStructureService structureService,
  ) async {
    final jsonController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importer une Structure'),
          content: TextField(
            controller: jsonController,
            decoration: const InputDecoration(
              labelText: 'JSON de la structure',
              hintText: 'Collez le JSON ici...',
            ),
            maxLines: 10,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await structureService.importStructure(jsonController.text);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Structure importée avec succès !'),
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Importer'),
            ),
          ],
        );
      },
    );
  }

  /// Affiche la boîte de dialogue d'export
  Future<void> _showExportDialog(
    BuildContext context,
    AssessmentStructureService structureService,
  ) async {
    final jsonString = structureService.exportStructure();

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exporter la Structure'),
          content: SizedBox(
            width: double.maxFinite,
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Copier dans le presse-papier
                Clipboard.setData(ClipboardData(text: jsonString));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('JSON copié dans le presse-papier !'),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copier'),
            ),
          ],
        );
      },
    );
  }
}
