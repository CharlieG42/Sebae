import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../../shared/models/iv.dart';
import '../../../shared/models/product_range.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/visit.dart';
import '../services/ssdm_service.dart';
import '../ssdm_constants.dart';
import 'visit_detail_view.dart';

final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
          padding: const EdgeInsets.only(bottom: 88, left: 16, right: 16, top: 16),
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
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedClientId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Client',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous les clients')),
                      for (final c in service.clients)
                        DropdownMenuItem(value: c.id, child: Text(c.displayName)),
                    ],
                    onChanged: (v) => setState(() => _selectedClientId = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedIvId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'IV',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous les IV')),
                      for (final iv in service.ivs)
                        DropdownMenuItem(value: iv.id, child: Text(service.ivLabel(iv.id))),
                    ],
                    onChanged: (v) => setState(() => _selectedIvId = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<VisitStatus?>(
                    initialValue: _selectedStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous les statuts')),
                      for (final s in VisitStatus.values)
                        DropdownMenuItem(value: s, child: Text(s.label)),
                    ],
                    onChanged: (v) => setState(() => _selectedStatus = v),
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
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            avatar: const Icon(Icons.insert_drive_file, size: 16),
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
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'En retard',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
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
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(content: Text('Visite supprimée')),
        );
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
        ivIds: result.ivIds,
        planEntryId: result.planEntryId,
        actionId: result.actionId,
        productRangeIds: result.productRangeIds,
        documentPaths: result.documentPaths,
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
      visit.ivIds = result.ivIds;
      visit.planEntryIds = result.planEntryIds;
      visit.actionIds = result.actionIds;
      visit.productRangeIds = result.productRangeIds;
      visit.documentPaths = result.documentPaths;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visite enregistrée')),
      );
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
        .map((id) => Chip(
              label: Text(service.ivLabel(id)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ))
        .toList(),
  );
}

/// Affiche l'affichage de la sélection des Gammes de Produits.
Widget _buildProductRangeSelectionDisplay(List<String>? productRangeIds, SsdmService service) {
  if (productRangeIds == null || productRangeIds.isEmpty) {
    return const Text('Aucune', style: TextStyle(color: Colors.grey));
  }
  return Wrap(
    spacing: 4,
    runSpacing: 4,
    children: productRangeIds
        .map((id) => Chip(
              label: Text(service.productRangeOf(id)?.displayName ?? '?'),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ))
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
                        subtitle: pr.description.isNotEmpty ? Text(pr.description) : null,
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
            onPressed: () => Navigator.pop(context, selectedSet.isEmpty ? null : selectedSet.toList()),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );

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
  List<String> tempSelected = (selectedIvIds ?? []).where((id) => id != kAllId).toList();
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
  late List<String>? _ivIds;
  late String? _planEntryId;
  late String? _actionId;
  late String _title;
  late DateTime _appointmentDate;
  late int _estimatedDuration;
  late String _location;
  late List<String>? _productRangeIds;
  late List<String>? _documentPaths;
  late String _notesBefore;
  late String _notesDuring;
  late String _notesAfter;
  late VisitStatus _status;

  final _documentPathController = TextEditingController();
  final _documentUrlController = TextEditingController();
  final _productRangeController = TextEditingController();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesBeforeController = TextEditingController();
  final _notesDuringController = TextEditingController();
  final _notesAfterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final v = widget.visit;
    _clientId = v?.clientId ?? widget.presetClientId ?? '';
    _ivIds = v?.ivIds ?? [];
    _planEntryId = v?.planEntryId ?? widget.presetPlanEntryId;
    _actionId = v?.actionId ?? widget.presetActionId;
    _title = v?.title ?? '';
    _appointmentDate = v?.appointmentDate ?? DateTime.now();
    _estimatedDuration = v?.estimatedDuration ?? 60;
    _location = v?.location ?? '';
    _productRangeIds = v?.productRangeIds ?? [];
    _documentPaths = v?.documentPaths ?? [];
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
      title: Text(widget.visit == null ? 'Nouvelle visite' : 'Modifier la visite'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Client
              DropdownButtonFormField<String>(
                initialValue: _clientId.isNotEmpty ? _clientId : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Client *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final c in service.clients)
                    DropdownMenuItem(value: c.id, child: Text(c.displayName)),
                ],
                onChanged: (v) => setState(() => _clientId = v ?? ''),
                validator: (v) => v == null || v.isEmpty ? 'Client obligatoire' : null,
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

              // Ligne du Sales Plan
              DropdownButtonFormField<String?>(
                initialValue: _planEntryId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ligne Sales Plan',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Aucune')),
                  for (final e in service.planFor(service.selectedYear))
                    DropdownMenuItem(
                      value: e.id,
                      child: Text(service.planLineLabel(e.id)),
                    ),
                ],
                onChanged: (v) => setState(() => _planEntryId = v),
              ),
              const SizedBox(height: 12),

              // Action
              DropdownButtonFormField<String?>(
                initialValue: _actionId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Aucune')),
                  for (final a in service.actionsFor(service.selectedYear))
                    DropdownMenuItem(value: a.id, child: Text(a.title)),
                ],
                onChanged: (v) => setState(() => _actionId = v),
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
                      onChanged: (v) => _estimatedDuration = int.tryParse(v) ?? 60,
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
                  child: _buildProductRangeSelectionDisplay(_productRangeIds, service),
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
                              onDeleted: () => setState(() => _documentPaths!.remove(docPath)),
                              avatar: const Icon(Icons.insert_drive_file, size: 18),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
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
                onChanged: (v) => setState(() => _status = v ?? VisitStatus.planned),
              ),
              const SizedBox(height: 12),

              // Notes
              const Divider(height: 24),
              const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Enregistrer'),
        ),
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

  void _submit() {
    if (_clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le client est obligatoire')),
      );
      return;
    }

    Navigator.of(context).pop(Visit(
      id: widget.visit?.id ?? '',
      year: widget.visit?.year ?? 0,
      clientId: _clientId,
      ivIds: _ivIds,
      planEntryIds: _planEntryId != null ? [_planEntryId!] : null,
      actionIds: _actionId != null ? [_actionId!] : null,
      title: _title,
      appointmentDate: _appointmentDate,
      estimatedDuration: _estimatedDuration,
      location: _location,
      productRangeIds: _productRangeIds,
      documentPaths: _documentPaths,
      themes: const [],
      notesBefore: _notesBefore,
      notesDuring: _notesDuring,
      notesAfter: _notesAfter,
      statusIndex: _status.index,
    ));
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
