import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../../shared/models/iv.dart';
import '../../../shared/models/product_range.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/sales_action.dart';
import '../models/visit.dart';
import '../services/ssdm_service.dart';
import '../ssdm_constants.dart';
import 'visit_detail_view.dart';

final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

/// Classe locale pour gérer les tâches de suivi avec leur statut (terminée/non terminée).
class _FollowUpTask {
  final String text;
  final bool isCompleted;

  const _FollowUpTask({required this.text, this.isCompleted = false});

  /// Convertit en String pour le stockage (format: "text" ou "[DONE] text")
  String toStorageString() => isCompleted ? '[DONE] $text' : text;

  /// Crée depuis une String de stockage
  static _FollowUpTask fromStorageString(String stored) {
    if (stored.startsWith('[DONE] ')) {
      return _FollowUpTask(text: stored.substring(7), isCompleted: true);
    }
    return _FollowUpTask(text: stored);
  }
}

/// Vue des visites clients.
///
/// Affiche la liste des visites avec filtres et permet de :
/// - créer une nouvelle visite,
/// - modifier une visite existante,
/// - consulter les détails d'une visite,
/// - filtrer par client, IV, statut, date.
class VisitsView extends StatelessWidget {
  const VisitsView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();
    final year = service.selectedYear;

    if (year == null) {
      return const Center(child: Text('Sélectionnez une année.'));
    }

    final visits = service.visitsFor(year);

    if (visits.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'Aucune visite planifiée',
        message:
            'Ajoutez des visites clients pour suivre vos rendez-vous, '
            'Gammes de Produits à présenter et notes de suivi.',
        actionLabel: 'Nouvelle visite',
        onAction: () => showVisitDialog(context),
      );
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(
            bottom: 88,
            left: 16,
            right: 16,
            top: 16,
          ),
          children: [
            // Filtres
            _VisitFilters(),
            const SizedBox(height: 16),

            // Liste des visites
            ...visits.map((v) => _VisitCard(visit: v)),

            const SizedBox(height: 32),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'addVisit',
            onPressed: () => showVisitDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle visite'),
          ),
        ),
      ],
    );
  }
}

/// Cartes de filtres pour les visites.
class _VisitFilters extends StatefulWidget {
  @override
  State<_VisitFilters> createState() => _VisitFiltersState();
}

class _VisitFiltersState extends State<_VisitFilters> {
  String? _selectedClientId;
  String? _selectedIvId;
  VisitStatus? _selectedStatus;

  final _clientFilterController = TextEditingController();
  final _ivFilterController = TextEditingController();
  final _statusFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser les controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateControllers(context);
      }
    });
  }

  void _updateControllers(BuildContext context) {
    final service = context.read<SsdmService>();
    _clientFilterController.text = _selectedClientId != null
        ? service.clientLabel(_selectedClientId!)
        : '';
    _ivFilterController.text = _selectedIvId != null
        ? service.ivLabel(_selectedIvId!)
        : '';
    _statusFilterController.text = _selectedStatus != null
        ? _selectedStatus!.label
        : '';
  }

  @override
  void dispose() {
    _clientFilterController.dispose();
    _ivFilterController.dispose();
    _statusFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return ['', ...service.clients.map((c) => c.id)];
                      }
                      return service.clients
                          .where(
                            (c) => c.displayName.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          )
                          .map((c) => c.id)
                          .toList();
                    },
                    displayStringForOption: (String option) {
                      if (option.isEmpty) return 'Tous les clients';
                      return service.clientLabel(option);
                    },
                    fieldViewBuilder:
                        (
                          BuildContext context,
                          TextEditingController fieldTextEditingController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted,
                        ) {
                          fieldTextEditingController.text =
                              _clientFilterController.text;
                          return TextFormField(
                            controller: _clientFilterController,
                            focusNode: fieldFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Client',
                              border: OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (String value) =>
                                onFieldSubmitted(),
                          );
                        },
                    onSelected: (String selection) {
                      setState(() {
                        _selectedClientId = selection.isEmpty
                            ? null
                            : selection;
                        _clientFilterController.text = selection.isEmpty
                            ? ''
                            : service.clientLabel(selection);
                      });
                    },
                    optionsMaxHeight: 200,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return ['', ...service.ivs.map((iv) => iv.id)];
                      }
                      return service.ivs
                          .where(
                            (iv) => service
                                .ivLabel(iv.id)
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()),
                          )
                          .map((iv) => iv.id)
                          .toList();
                    },
                    displayStringForOption: (String option) {
                      if (option.isEmpty) return 'Tous les IV';
                      return service.ivLabel(option);
                    },
                    fieldViewBuilder:
                        (
                          BuildContext context,
                          TextEditingController fieldTextEditingController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted,
                        ) {
                          fieldTextEditingController.text =
                              _ivFilterController.text;
                          return TextFormField(
                            controller: _ivFilterController,
                            focusNode: fieldFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'IV',
                              border: OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (String value) =>
                                onFieldSubmitted(),
                          );
                        },
                    onSelected: (String selection) {
                      setState(() {
                        _selectedIvId = selection.isEmpty ? null : selection;
                        _ivFilterController.text = selection.isEmpty
                            ? ''
                            : service.ivLabel(selection);
                      });
                    },
                    optionsMaxHeight: 200,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return ['', ...VisitStatus.values.map((s) => s.name)];
                      }
                      return VisitStatus.values
                          .where(
                            (s) => s.label.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          )
                          .map((s) => s.name)
                          .toList();
                    },
                    displayStringForOption: (String option) {
                      if (option.isEmpty) return 'Tous les statuts';
                      final status = VisitStatus.values.firstWhere(
                        (s) => s.name == option,
                        orElse: () => VisitStatus.planned,
                      );
                      return status.label;
                    },
                    fieldViewBuilder:
                        (
                          BuildContext context,
                          TextEditingController fieldTextEditingController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted,
                        ) {
                          fieldTextEditingController.text =
                              _statusFilterController.text;
                          return TextFormField(
                            controller: _statusFilterController,
                            focusNode: fieldFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Statut',
                              border: OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (String value) =>
                                onFieldSubmitted(),
                          );
                        },
                    onSelected: (String selection) {
                      if (selection.isEmpty) {
                        setState(() {
                          _selectedStatus = null;
                          _statusFilterController.text = '';
                        });
                      } else {
                        final status = VisitStatus.values.firstWhere(
                          (s) => s.name == selection,
                          orElse: () => VisitStatus.planned,
                        );
                        setState(() {
                          _selectedStatus = status;
                          _statusFilterController.text = status.label;
                        });
                      }
                    },
                    optionsMaxHeight: 200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Appliquer'),
                  onPressed: () {
                    final service = context.read<SsdmService>();
                    final year = service.selectedYear;
                    if (year == null) return;

                    // Ici on pourrait filtrer, mais pour simplifier on laisse
                    // le filtrage se faire dans la liste directement
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedClientId = null;
                    _selectedIvId = null;
                    _selectedStatus = null;
                  }),
                  child: const Text('Effacer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'une visite dans la liste.
class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final service = context.read<SsdmService>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => VisitDetailView(visitId: visit.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      visit.title.isNotEmpty ? visit.title : 'Visite client',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _VisitStatusChip(status: visit.status),
                ],
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
                  const SizedBox(width: 16),
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      service.clientLabel(visit.clientId),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      service.ivIdsLabel(visit.ivIds),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (visit.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        visit.location,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (visit.hasProductRanges) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    const Icon(Icons.shopping_bag, size: 16),
                    const SizedBox(width: 4),
                    ...(visit.productRangeIds ?? []).map((id) {
                      final pr = service.productRangeOf(id);
                      return Chip(
                        label: Text(pr?.displayName ?? '?'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              if (visit.hasVisitFrame)
                Row(
                  children: [
                    const Icon(Icons.description, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Trame: ${service.visitFrameOf(visit.visitFrameId)?.name ?? '?'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              if (visit.hasDocuments)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        const Icon(Icons.attach_file, size: 16),
                        const SizedBox(width: 4),
                        ...(visit.documentPaths ?? []).map((docPath) {
                          final fileName = path.basename(docPath);
                          return Chip(
                            label: Text(fileName),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            avatar: const Icon(
                              Icons.insert_drive_file,
                              size: 16,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              if (visit.isLate)
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'En retard',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showVisitDialog(context, visit: visit),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteVisit(context, visit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteVisit(BuildContext context, Visit visit) async {
    final service = context.read<SsdmService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la visite'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la visite du ${_dateFormat.format(visit.appointmentDate)} ?',
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
      final scaffoldContext = context;
      await service.deleteVisit(visit);
      if (scaffoldContext.mounted) {
        ScaffoldMessenger.of(scaffoldContext)
            .showSnackBar(const SnackBar(content: Text('Visite supprimée')));
      }
    }
  }
}

/// Puce d'état de visite.
class _VisitStatusChip extends StatelessWidget {
  const _VisitStatusChip({required this.status});

  final VisitStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
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

/// Dialogue de création / modification d'une visite.
Future<void> showVisitDialog(
  BuildContext context, {
  Visit? visit,
  String? presetClientId,
  String? presetActionId,
  String? presetPlanEntryId,
  bool useRootNavigator = false,
}) async {
  final service = context.read<SsdmService>();

  if (service.clients.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Définissez au préalable des clients dans "Bases de données partagées".',
        ),
      ),
    );
    return;
  }

  final result = await showDialog<Visit?>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (_) => _VisitDialog(
      service: service,
      visit: visit,
      presetClientId: presetClientId,
      presetActionId: presetActionId,
      presetPlanEntryId: presetPlanEntryId,
    ),
  );

  if (result != null) {
    if (visit == null) {
      await service.addVisit(
        clientId: result.clientId,
        contactId: result.contactId,
        ivIds: result.ivIds,
        planEntryId: result.planEntryId,
        actionId: result.actionId,
        productRangeIds: result.productRangeIds,
        documentPaths: result.documentPaths,
        visitFrameId: result.visitFrameId,
        followUpTasks: result.followUpTasks,
        title: result.title,
        appointmentDate: result.appointmentDate,
        estimatedDuration: result.estimatedDuration,
        location: result.location,
        themes: const [],
        notesBefore: result.notesBefore,
        notesDuring: result.notesDuring,
        notesAfter: result.notesAfter,
        status: result.status,
      );
    } else {
      visit.clientId = result.clientId;
      visit.contactId = result.contactId;
      visit.ivIds = result.ivIds;
      visit.planEntryIds = result.planEntryIds;
      visit.actionIds = result.actionIds;
      visit.productRangeIds = result.productRangeIds;
      visit.documentPaths = result.documentPaths;
      visit.visitFrameId = result.visitFrameId;
      visit.followUpTasks = result.followUpTasks;
      visit.title = result.title;
      visit.appointmentDate = result.appointmentDate;
      visit.estimatedDuration = result.estimatedDuration;
      visit.location = result.location;
      visit.themes = const [];
      visit.notesBefore = result.notesBefore;
      visit.notesDuring = result.notesDuring;
      visit.notesAfter = result.notesAfter;
      visit.status = result.status;
      await service.updateVisit(visit);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Visite enregistrée')));
    }
  }
}

class _VisitDialog extends StatefulWidget {
  const _VisitDialog({
    required this.service,
    this.visit,
    this.presetClientId,
    this.presetActionId,
    this.presetPlanEntryId,
  });

  final SsdmService service;
  final Visit? visit;
  final String? presetClientId;
  final String? presetActionId;
  final String? presetPlanEntryId;

  @override
  State<_VisitDialog> createState() => _VisitDialogState();
}

/// Affiche l'affichage de la sélection des IV.
Widget _buildIvSelectionDisplay(List<String>? ivIds, SsdmService service) {
  if (ivIds == null || ivIds.isEmpty) {
    return const Text('Équipe', style: TextStyle(color: Colors.grey));
  }
  if (ivIds.contains(kAllId)) {
    return const Text('Tous les IV');
  }
  return Wrap(
    spacing: 4,
    runSpacing: 4,
    children: ivIds
        .map(
          (id) => Chip(
            label: Text(service.ivLabel(id)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        )
        .toList(),
  );
}

/// Affiche l'affichage de la sélection des Gammes de Produits.
Widget _buildProductRangeSelectionDisplay(
  List<String>? productRangeIds,
  SsdmService service,
) {
  if (productRangeIds == null || productRangeIds.isEmpty) {
    return const Text('Aucune', style: TextStyle(color: Colors.grey));
  }
  return Wrap(
    spacing: 4,
    runSpacing: 4,
    children: productRangeIds
        .map(
          (id) => Chip(
            label: Text(service.productRangeOf(id)?.displayName ?? '?'),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        )
        .toList(),
  );
}

/// Dialogue de sélection multiple de Gammes de Produits avec cases à cocher.
Future<List<String>?> _showProductRangeMultiSelectDialog(
  BuildContext context, {
  required List<String>? selectedIds,
  required List<ProductRange> availableProductRanges,
  required SsdmService service,
}) async {
  final selectedSet = (selectedIds ?? []).toSet();

  final result = await showDialog<List<String>?>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Sélectionner les Gammes de Produits'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final pr in availableProductRanges)
                      CheckboxListTile(
                        value: selectedSet.contains(pr.id),
                        title: Text(pr.displayName),
                        subtitle: pr.description.isNotEmpty
                            ? Text(pr.description)
                            : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedSet.add(pr.id);
                            } else {
                              selectedSet.remove(pr.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              selectedSet.isEmpty ? null : selectedSet.toList(),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );

  return result;
}

/// Affiche l'affichage de la sélection des lignes de Sales Plan.
Widget _buildPlanEntrySelectionDisplay(
  List<String>? planEntryIds,
  SsdmService service,
) {
  if (planEntryIds == null || planEntryIds.isEmpty) {
    return const Text('Aucune', style: TextStyle(color: Colors.grey));
  }
  return Wrap(
    spacing: 4,
    runSpacing: 4,
    children: planEntryIds
        .map(
          (id) => Chip(
            label: Text(service.planLineLabel(id)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        )
        .toList(),
  );
}

/// Dialogue de sélection multiple de lignes de Sales Plan avec recherche.
Future<List<String>?> _showPlanEntryMultiSelectDialog(
  BuildContext context, {
  required List<String>? selectedIds,
  required int year,
  required SsdmService service,
}) async {
  final selectedSet = (selectedIds ?? []).toSet();
  final TextEditingController searchController = TextEditingController();

  final result = await showDialog<List<String>?>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Sélectionner les lignes de Sales Plan'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de recherche
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Rechercher',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final e in service.planFor(year))
                      if (searchController.text.isEmpty ||
                          service
                              .planLineLabel(e.id)
                              .toLowerCase()
                              .contains(searchController.text.toLowerCase()))
                        CheckboxListTile(
                          value: selectedSet.contains(e.id),
                          title: Text(service.planLineLabel(e.id)),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedSet.add(e.id);
                              } else {
                                selectedSet.remove(e.id);
                              }
                            });
                          },
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              selectedSet.isEmpty ? null : selectedSet.toList(),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );

  searchController.dispose();
  return result;
}

/// Affiche l'affichage de la sélection des Actions.
Widget _buildActionSelectionDisplay(
  List<String>? actionIds,
  SsdmService service,
  int year,
) {
  if (actionIds == null || actionIds.isEmpty) {
    return const Text('Aucune', style: TextStyle(color: Colors.grey));
  }
  return Wrap(
    spacing: 4,
    runSpacing: 4,
    children: actionIds
        .map(
          (id) => Chip(
            label: Text(
              service
                  .actionsFor(year)
                  .firstWhere(
                    (a) => a.id == id,
                    orElse: () => SalesAction(
                      id: '',
                      year: 0,
                      title: 'Action inconnue',
                      description: '',
                      ivIds: [],
                      statusIndex: 0,
                      progress: 0,
                      createdAt: DateTime.now(),
                      history: [],
                    ),
                  )
                  .title,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        )
        .toList(),
  );
}

/// Dialogue de sélection multiple d'Actions avec recherche.
Future<List<String>?> _showActionMultiSelectDialog(
  BuildContext context, {
  required List<String>? selectedIds,
  required int year,
  required SsdmService service,
}) async {
  final selectedSet = (selectedIds ?? []).toSet();
  final TextEditingController searchController = TextEditingController();

  final result = await showDialog<List<String>?>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Sélectionner les Actions'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de recherche
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Rechercher',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final a in service.actionsFor(year))
                      if (searchController.text.isEmpty ||
                          a.title.toLowerCase().contains(
                            searchController.text.toLowerCase(),
                          ))
                        CheckboxListTile(
                          value: selectedSet.contains(a.id),
                          title: Text(a.title),
                          subtitle: a.description.isNotEmpty
                              ? Text(a.description)
                              : null,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedSet.add(a.id);
                              } else {
                                selectedSet.remove(a.id);
                              }
                            });
                          },
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              selectedSet.isEmpty ? null : selectedSet.toList(),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );

  searchController.dispose();
  return result;
}

/// Dialogue de sélection multiple d'IV avec cases à cocher pour les visites.
Future<List<String>?> _showIvMultiSelectDialogForVisits(
  BuildContext context, {
  required List<String>? selectedIvIds,
  required List<Iv> availableIvs,
  required SsdmService service,
}) async {
  final selectedSet = (selectedIvIds ?? []).toSet();
  final hasAllId = selectedSet.contains(kAllId);
  List<String> tempSelected = (selectedIvIds ?? [])
      .where((id) => id != kAllId)
      .toList();
  bool teamOnly = selectedSet.isEmpty || hasAllId;

  final result = await showDialog<List<String>?>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Sélectionner les IV'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Option "Équipe"
              CheckboxListTile(
                value: teamOnly,
                title: const Text('Équipe'),
                subtitle: const Text('Visite de toute l\'équipe'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      teamOnly = true;
                      tempSelected.clear();
                    } else {
                      teamOnly = false;
                    }
                  });
                },
              ),
              // Option "Tous les IV"
              CheckboxListTile(
                value: !teamOnly && tempSelected.length == availableIvs.length,
                title: const Text('Tous les IV'),
                subtitle: const Text('Visite pour tous les IV'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      teamOnly = false;
                      tempSelected = availableIvs.map((iv) => iv.id).toList();
                    } else {
                      tempSelected.clear();
                    }
                  });
                },
              ),
              const Divider(),
              const ListTile(
                title: Text('IV spécifiques'),
                subtitle: Text('Sélectionnez les IV concernés'),
              ),
              const SizedBox(height: 8),
              if (!teamOnly)
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableIvs.length,
                    itemBuilder: (context, index) {
                      final iv = availableIvs[index];
                      final isSelected = tempSelected.contains(iv.id);
                      return CheckboxListTile(
                        value: isSelected,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              if (!tempSelected.contains(iv.id)) {
                                tempSelected.add(iv.id);
                              }
                            } else {
                              tempSelected.remove(iv.id);
                            }
                          });
                        },
                        title: Text(service.ivLabel(iv.id)),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, selectedIvIds),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (teamOnly) {
                Navigator.pop(context, null);
              } else if (tempSelected.length == availableIvs.length) {
                Navigator.pop(context, [kAllId]);
              } else if (tempSelected.isNotEmpty) {
                Navigator.pop(context, tempSelected);
              } else {
                Navigator.pop(context, null);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );

  return result;
}

class _VisitDialogState extends State<_VisitDialog> {
  late String _clientId;
  late String? _contactId;
  late List<String>? _ivIds;
  late List<String>? _planEntryIds;
  late List<String>? _actionIds;
  late String _title;
  late DateTime _appointmentDate;
  late int _estimatedDuration;
  late String _location;
  late List<String>? _productRangeIds;
  late List<String>? _documentPaths;
  late String? _visitFrameId;
  late List<_FollowUpTask> _followUpTaskObjects;
  late String _notesBefore;
  late String _notesDuring;
  late String _notesAfter;
  late VisitStatus _status;

  final _documentPathController = TextEditingController();
  final _documentUrlController = TextEditingController();
  final _productRangeController = TextEditingController();
  final _followUpTaskController = TextEditingController();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesBeforeController = TextEditingController();
  final _notesDuringController = TextEditingController();
  final _notesAfterController = TextEditingController();

  // Controller pour le champ Client (sélection unique)
  final _clientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final v = widget.visit;
    _clientId = v?.clientId ?? widget.presetClientId ?? '';
    _contactId = v?.contactId;
    _ivIds = v?.ivIds ?? [];
    _planEntryIds =
        v?.planEntryIds ??
        (widget.presetPlanEntryId != null ? [widget.presetPlanEntryId!] : []);
    _actionIds =
        v?.actionIds ??
        (widget.presetActionId != null ? [widget.presetActionId!] : []);
    _title = v?.title ?? '';
    _appointmentDate = v?.appointmentDate ?? DateTime.now();
    _estimatedDuration = v?.estimatedDuration ?? 60;
    _location = v?.location ?? '';

    // Initialiser les controllers Autocomplete
    _clientController.text = _clientId.isNotEmpty
        ? widget.service.clientLabel(_clientId)
        : '';
    // Les controllers pour planEntryIds et actionIds ne sont plus nécessaires
    // car ce sont maintenant des sélections multiples avec dialogues
    _productRangeIds = v?.productRangeIds ?? [];
    _documentPaths = v?.documentPaths ?? [];
    _visitFrameId = v?.visitFrameId;
    _followUpTaskObjects = (v?.followUpTasks ?? [])
        .map((task) => _FollowUpTask.fromStorageString(task))
        .toList();
    _notesBefore = v?.notesBefore ?? '';
    _notesDuring = v?.notesDuring ?? '';
    _notesAfter = v?.notesAfter ?? '';
    _status = v?.status ?? VisitStatus.planned;

    _titleController.text = _title;
    _locationController.text = _location;
    _durationController.text = _estimatedDuration.toString();
    _notesBeforeController.text = _notesBefore;
    _notesDuringController.text = _notesDuring;
    _notesAfterController.text = _notesAfter;
  }

  @override
  void dispose() {
    _documentUrlController.dispose();
    _productRangeController.dispose();
    _followUpTaskController.dispose();
    _clientController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _notesBeforeController.dispose();
    _notesDuringController.dispose();
    _notesAfterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return AlertDialog(
      title: Text(
        widget.visit == null ? 'Nouvelle visite' : 'Modifier la visite',
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Client (base partagée)
              DropdownButtonFormField<String>(
                value: _clientId.isEmpty ? null : _clientId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Client *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Sélectionner un client'),
                  ),
                  for (final client in service.clients)
                    DropdownMenuItem<String>(
                      value: client.id,
                      child: Text(client.displayName),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _clientId = value ?? '';
                    if (_clientId.isEmpty) {
                      _contactId = null;
                      return;
                    }
                    if (_contactId != null &&
                        service.contactOf(_contactId)?.clientId != _clientId) {
                      _contactId = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              // Contact (base partagée)
              DropdownButtonFormField<String?>(
                value: _contactId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Contact',
                  border: OutlineInputBorder(),
                ),
                items: _clientId.isEmpty
                    ? const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sélectionnez d’abord un client'),
                        ),
                      ]
                    : [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Aucun contact'),
                        ),
                        for (final contact in service.contacts.where(
                          (c) => c.clientId == _clientId,
                        ))
                          DropdownMenuItem<String?>(
                            value: contact.id,
                            child: Text(contact.displayName),
                          ),
                      ],
                onChanged: _clientId.isEmpty
                    ? null
                    : (value) => setState(() => _contactId = value),
              ),
              const SizedBox(height: 12),

              // IV(s) - sélection avec cases à cocher
              InkWell(
                onTap: () async {
                  final selected = await _showIvMultiSelectDialogForVisits(
                    context,
                    selectedIvIds: _ivIds,
                    availableIvs: service.ivs.toList(),
                    service: service,
                  );
                  if (selected != null) {
                    setState(() => _ivIds = selected);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'IV(s)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.expand_more),
                  ),
                  child: _buildIvSelectionDisplay(_ivIds, service),
                ),
              ),
              const SizedBox(height: 12),

              // Lignes du Sales Plan - sélection multiple avec combobox
              InkWell(
                onTap: () async {
                  final selected = await _showPlanEntryMultiSelectDialog(
                    context,
                    selectedIds: _planEntryIds,
                    year: service.selectedYear!,
                    service: service,
                  );
                  if (selected != null) {
                    setState(() => _planEntryIds = selected);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Lignes Sales Plan',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.expand_more),
                  ),
                  child: _buildPlanEntrySelectionDisplay(
                    _planEntryIds,
                    service,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Actions - sélection multiple avec combobox
              InkWell(
                onTap: () async {
                  final selected = await _showActionMultiSelectDialog(
                    context,
                    selectedIds: _actionIds,
                    year: service.selectedYear!,
                    service: service,
                  );
                  if (selected != null) {
                    setState(() => _actionIds = selected);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Actions',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.expand_more),
                  ),
                  child: _buildActionSelectionDisplay(
                    _actionIds,
                    service,
                    service.selectedYear!,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Titre
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre / Objet',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _title = v,
              ),
              const SizedBox(height: 12),

              // Date et heure
              Row(
                children: [
                  Expanded(
                    child: _DateTimePicker(
                      dateTime: _appointmentDate,
                      onChanged: (d) => setState(() => _appointmentDate = d),
                      label: 'Date et heure du RDV *',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Durée (minutes)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          _estimatedDuration = int.tryParse(v) ?? 60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lieu
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lieu',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _location = v,
              ),
              const SizedBox(height: 12),

              // Gammes de Produits
              InkWell(
                onTap: () async {
                  final selected = await _showProductRangeMultiSelectDialog(
                    context,
                    selectedIds: _productRangeIds,
                    availableProductRanges: service.productRanges,
                    service: service,
                  );
                  if (selected != null) {
                    setState(() => _productRangeIds = selected);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Gammes de Produits',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.expand_more),
                  ),
                  child: _buildProductRangeSelectionDisplay(
                    _productRangeIds,
                    service,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Zone 1: Documents depuis le PC
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documents locaux',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _documentPathController,
                              decoration: const InputDecoration(
                                labelText: 'Ajouter un fichier depuis le PC',
                                border: OutlineInputBorder(),
                                hintText: 'C:\\Dossier\\mon-fichier.pdf',
                              ),
                              onSubmitted: (_) => _addDocumentFromPath(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: 'Ajouter le fichier',
                            onPressed: _addDocumentFromPath,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Zone 2: Documents par URL
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documents en ligne',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _documentUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Ajouter une URL de document',
                                border: OutlineInputBorder(),
                                hintText: 'https://... ou chemin réseau',
                              ),
                              onSubmitted: (_) => _addDocumentUrl(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_link),
                            tooltip: 'Ajouter URL',
                            onPressed: _addDocumentUrl,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Affichage des documents sélectionnés
              if (_documentPaths != null && _documentPaths!.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Documents associés à la visite',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _documentPaths!.map((docPath) {
                            final fileName = path.basename(docPath);
                            return Chip(
                              label: Text(fileName),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setState(
                                () => _documentPaths!.remove(docPath),
                              ),
                              avatar: const Icon(
                                Icons.insert_drive_file,
                                size: 18,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Trame de visite
              DropdownButtonFormField<String?>(
                initialValue: _visitFrameId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Trame de visite',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Aucune')),
                  for (final frame in service.visitFrames)
                    DropdownMenuItem(value: frame.id, child: Text(frame.name)),
                ],
                onChanged: (v) => setState(() => _visitFrameId = v),
              ),
              const SizedBox(height: 12),

              // Statut
              DropdownButtonFormField<VisitStatus>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Statut',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final s in VisitStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) =>
                    setState(() => _status = v ?? VisitStatus.planned),
              ),
              const SizedBox(height: 12),

              // Préparation & tâches de suivi
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parcours guidé de la visite',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Préparez le rendez-vous, notez les informations clés et formalisez le suivi à faire après la visite.',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _followUpTaskController,
                              decoration: const InputDecoration(
                                labelText: 'Tâche de suivi après le RDV',
                                border: OutlineInputBorder(),
                                hintText: 'Envoyer le devis, relancer, etc.',
                              ),
                              onSubmitted: (_) => _addFollowUpTask(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addFollowUpTask,
                            icon: const Icon(Icons.add_task),
                            tooltip: 'Ajouter une tâche de suivi',
                          ),
                        ],
                      ),
                      if (_followUpTaskObjects.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _followUpTaskObjects.map((task) {
                            return FilterChip(
                              label: Text(task.text),
                              selected: task.isCompleted,
                              onSelected: (selected) => setState(() {
                                final index = _followUpTaskObjects.indexOf(
                                  task,
                                );
                                _followUpTaskObjects[index] = _FollowUpTask(
                                  text: task.text,
                                  isCompleted: !task.isCompleted,
                                );
                              }),
                              avatar: task.isCompleted
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.green,
                                    )
                                  : null,
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setState(() {
                                _followUpTaskObjects.remove(task);
                              }),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Notes
              const Divider(height: 24),
              const Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesBeforeController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes avant le RDV',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (v) => _notesBefore = v,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesDuringController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes pendant le RDV',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (v) => _notesDuring = v,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesAfterController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes après le RDV / Suivi',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (v) => _notesAfter = v,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }

  void _addDocumentFromPath() {
    final filePath = _documentPathController.text.trim();
    if (filePath.isNotEmpty) {
      setState(() {
        _documentPaths = (_documentPaths ?? []).toList()..add(filePath);
        _documentPathController.clear();
      });
    }
  }

  void _addDocumentUrl() {
    final url = _documentUrlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _documentPaths = (_documentPaths ?? []).toList()..add(url);
        _documentUrlController.clear();
      });
    }
  }

  void _addFollowUpTask() {
    final task = _followUpTaskController.text.trim();
    if (task.isEmpty) return;
    setState(() {
      _followUpTaskObjects = [
        ..._followUpTaskObjects,
        _FollowUpTask(text: task),
      ];
      _followUpTaskController.clear();
    });
  }

  void _submit() {
    if (_clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le client est obligatoire')),
      );
      return;
    }

    Navigator.of(context).pop(
      Visit(
        id: widget.visit?.id ?? '',
        year: widget.visit?.year ?? 0,
        clientId: _clientId,
        contactId: _contactId,
        ivIds: _ivIds,
        planEntryIds: _planEntryIds,
        actionIds: _actionIds,
        title: _title,
        appointmentDate: _appointmentDate,
        estimatedDuration: _estimatedDuration,
        location: _location,
        productRangeIds: _productRangeIds,
        documentPaths: _documentPaths,
        visitFrameId: _visitFrameId,
        followUpTasks: _followUpTaskObjects
            .map((task) => task.toStorageString())
            .toList(),
        themes: const [],
        notesBefore: _notesBefore,
        notesDuring: _notesDuring,
        notesAfter: _notesAfter,
        statusIndex: _status.index,
      ),
    );
  }
}

/// Selecteur de date et heure personnalisé.
class _DateTimePicker extends StatefulWidget {
  const _DateTimePicker({
    required this.dateTime,
    required this.onChanged,
    required this.label,
  });

  final DateTime dateTime;
  final ValueChanged<DateTime> onChanged;
  final String label;

  @override
  State<_DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<_DateTimePicker> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.dateTime;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      controller: TextEditingController(
        text: _dateFormat.format(_selectedDateTime),
      ),
      onTap: () async {
        final pickerContext = context;
        final date = await showDatePicker(
          context: pickerContext,
          initialDate: _selectedDateTime,
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );

        if (date != null && pickerContext.mounted) {
          final time = await showTimePicker(
            context: pickerContext,
            initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
          );

          if (time != null) {
            setState(() {
              _selectedDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            });
            widget.onChanged(_selectedDateTime);
          }
        }
      },
    );
  }
}
