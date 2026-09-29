import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../models/visit.dart';
import '../services/ssdm_service.dart';
import 'visits_view.dart';

final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

/// Vue de détail d'une visite.
///
/// Affiche toutes les informations d'une visite avec la possibilité de :
/// - modifier la visite,
/// - mettre à jour le statut,
/// - ajouter des notes.
class VisitDetailView extends StatelessWidget {
  const VisitDetailView({super.key, required this.visitId});

  final String visitId;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();
    final visit = service.visitOf(visitId);

    if (visit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visite introuvable')),
        body: const Center(child: Text('Cette visite n\'existe pas.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(visit.title.isNotEmpty ? visit.title : 'Détails de la visite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => showVisitDialog(context, visit: visit),
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteVisit(context, visit),
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.title.isNotEmpty ? visit.title : 'Visite client',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 4),
                              Text(_dateFormat.format(visit.appointmentDate)),
                              const SizedBox(width: 16),
                              const Icon(Icons.timer, size: 16),
                              const SizedBox(width: 4),
                              Text('${visit.estimatedDuration} min'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _VisitStatusChip(status: visit.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Client
            _DetailCard(
              icon: Icons.business,
              title: 'Client',
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(service.clientLabel(visit.clientId)),
                  subtitle: const Text('Nom du client'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // IV et rattachements
            _DetailCard(
              icon: Icons.people,
              title: 'Participants et rattachements',
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(service.ivIdsLabel(visit.ivIds)),
                  subtitle: const Text('IV responsable(s)'),
                ),
                if (visit.hasPlanEntries)
                  ListTile(
                    leading: const Icon(Icons.table_chart),
                    title: Text(visit.planEntryIds!.map((id) => service.planLineLabel(id)).join(', ')),
                    subtitle: const Text('Ligne(s) Sales Plan'),
                  ),
                if (visit.hasActions)
                  ListTile(
                    leading: const Icon(Icons.checklist),
                    title: Text(visit.actionIds!.map((id) => service.actionOf(id)?.title ?? 'Action $id').join(', ')),
                    subtitle: const Text('Action(s) associée(s)'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Trame de visite
            if (visit.hasVisitFrame)
              _DetailCard(
                icon: Icons.description,
                title: 'Trame de visite',
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(service.visitFrameOf(visit.visitFrameId)?.name ?? '?'),
                    subtitle: const Text('Trame associée'),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Localisation
            if (visit.location.isNotEmpty)
              _DetailCard(
                icon: Icons.location_on,
                title: 'Localisation',
                children: [
                  ListTile(
                    leading: const Icon(Icons.place),
                    title: Text(visit.location),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Gammes de Produits
            if (visit.hasProductRanges)
              _DetailCard(
                icon: Icons.shopping_bag,
                title: 'Gammes de Produits',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (visit.productRangeIds ?? [])
                          .map((id) {
                            final service = context.read<SsdmService>();
                            final pr = service.productRangeOf(id);
                            return Chip(
                              label: Text(pr?.displayName ?? '?'),
                              avatar: const Icon(Icons.shopping_bag_outlined, size: 18),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Documents joints
            if (visit.hasDocuments)
              _DetailCard(
                icon: Icons.attach_file,
                title: 'Documents joints',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (visit.documentPaths ?? [])
                          .map((docPath) {
                            final fileName = path.basename(docPath);
                            return Chip(
                              label: Text(fileName),
                              avatar: const Icon(Icons.insert_drive_file, size: 18),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Notes avant
            if (visit.notesBefore.isNotEmpty)
              _DetailCard(
                icon: Icons.note,
                title: 'Notes avant le RDV',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(visit.notesBefore),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Notes pendant
            if (visit.notesDuring.isNotEmpty)
              _DetailCard(
                icon: Icons.edit_note,
                title: 'Notes pendant le RDV',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(visit.notesDuring),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Notes après
            if (visit.notesAfter.isNotEmpty)
              _DetailCard(
                icon: Icons.follow_the_signs,
                title: 'Notes après le RDV / Suivi',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(visit.notesAfter),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Actions rapides
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions rapides',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Terminer'),
                          onPressed: () => _updateStatus(context, visit, VisitStatus.done),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Reporter'),
                          onPressed: () => _updateStatus(context, visit, VisitStatus.postponed),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text('Annuler'),
                          onPressed: () => _updateStatus(context, visit, VisitStatus.cancelled),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red)),
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Ajouter une note'),
                          onPressed: () => _showAddNoteDialog(context, visit),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Avertissement si en retard
            if (visit.isLate)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Cette visite est en retard !',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, Visit visit, VisitStatus newStatus) async {
    final service = context.read<SsdmService>();
    final confirmed = newStatus == VisitStatus.cancelled || newStatus == VisitStatus.postponed
        ? await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Confirmer ${newStatus.label}'),
              content: Text('Êtes-vous sûr de vouloir marquer cette visite comme ${newStatus.label.toLowerCase()} ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirmer'),
                ),
              ],
            ),
          )
        : true;

    if (confirmed == true) {
      await service.updateVisitStatus(visit, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visite marquée comme ${newStatus.label}')),
        );
      }
    }
  }

  Future<void> _deleteVisit(BuildContext context, Visit visit) async {
    final service = context.read<SsdmService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la visite'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement cette visite ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final navigatorContext = context;
      await service.deleteVisit(visit);
      Navigator.of(navigatorContext).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorContext.mounted) {
          ScaffoldMessenger.of(navigatorContext).showSnackBar(
            const SnackBar(content: Text('Visite supprimée')),
          );
        }
      });
    }
  }

  Future<void> _showAddNoteDialog(BuildContext context, Visit visit) async {
    final service = context.read<SsdmService>();
    final noteType = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('À quel moment souhaitez-vous ajouter cette note ?'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.note_outlined, color: Colors.blue),
              title: const Text('Avant le RDV'),
              onTap: () => Navigator.of(context).pop('before'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_outlined, color: Colors.orange),
              title: const Text('Pendant le RDV'),
              onTap: () => Navigator.of(context).pop('during'),
            ),
            ListTile(
              leading: const Icon(Icons.follow_the_signs_outlined, color: Colors.green),
              title: const Text('Après le RDV / Suivi'),
              onTap: () => Navigator.of(context).pop('after'),
            ),
          ],
        ),
      ),
    );

    if (noteType != null) {
      final controller = TextEditingController();
      final newNote = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Note ${noteType == 'before' ? 'avant' : noteType == 'during' ? 'pendant' : 'après'} le RDV'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Saisissez votre note',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      );

      if (newNote != null && newNote.trim().isNotEmpty) {
        final scaffoldContext = context;
        final notesBefore = noteType == 'before' ? '${visit.notesBefore}\n\n${newNote.trim()}' : visit.notesBefore;
        final notesDuring = noteType == 'during' ? '${visit.notesDuring}\n\n${newNote.trim()}' : visit.notesDuring;
        final notesAfter = noteType == 'after' ? '${visit.notesAfter}\n\n${newNote.trim()}' : visit.notesAfter;

        await service.updateVisitNotes(visit,
          notesBefore: notesBefore,
          notesDuring: notesDuring,
          notesAfter: notesAfter,
        );
        if (scaffoldContext.mounted) {
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            const SnackBar(content: Text('Note ajoutée')),
          );
        }
      }
    }
  }
}

/// Carte de détail réutilisable.
class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Puce d'état de visite (réutilisée de visits_view.dart).
class _VisitStatusChip extends StatelessWidget {
  const _VisitStatusChip({required this.status});

  final VisitStatus status;

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    switch (status) {
      case VisitStatus.planned:
        color = Colors.blue;
      case VisitStatus.confirmed:
        color = Colors.lightBlue;
      case VisitStatus.inProgress:
        color = Colors.orange;
      case VisitStatus.done:
        color = Colors.green;
      case VisitStatus.cancelled:
        color = Colors.red;
      case VisitStatus.postponed:
        color = Colors.purple;
    }

    return Chip(
      label: Text(status.label),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
