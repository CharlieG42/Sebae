import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/iv.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/sales_action.dart';
import '../models/visit.dart';
import '../services/ssdm_service.dart';
import '../ssdm_constants.dart';
import 'action_detail_view.dart';
import 'visit_detail_view.dart';
import 'visits_view.dart';

final _dateFmt = DateFormat('dd/MM/yyyy');
final _eur = NumberFormat.currency(locale: 'fr_FR', symbol: 'EUR');

/// Liste des actions de l'année : équipe + actions spécifiques par IV.
///
/// Supporte le filtrage sur une ligne du Sales Plan (chip "Filtre") posé
/// depuis la vue Sales Plan.
class ActionsView extends StatelessWidget {
  const ActionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();
    final year = service.selectedYear;
    if (year == null) {
      return const Center(child: Text('Sélectionnez une année.'));
    }

    final filter = service.planEntryFilter;
    final allActions = service.actionsFor(year);
    final actions = filter == null
        ? allActions
        : allActions.where((a) => a.planEntryId == filter).toList();

    final header = filter != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                avatar: const Icon(Icons.filter_alt, size: 18),
                label: Text(
                  'Ligne : ${service.planLineLabel(filter)}',
                  overflow: TextOverflow.ellipsis,
                ),
                onDeleted: () => service.filterActionsByPlan(null),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          )
        : null;

    if (actions.isEmpty) {
      return Column(
        children: [
          ...(header != null ? [header] : []),
          Expanded(
            child: EmptyState(
              icon: Icons.flag_outlined,
              title: filter == null ? 'Aucune action' : 'Aucune action liée',
              message: filter == null
                  ? 'Créez des actions spécifiques (attachées à un ou plusieurs IV) ou '
                      'des actions communes à l\'équipe.'
                  : 'Aucune action n\'est liée à cette ligne du Sales Plan. '
                      'Utilisez le bouton checklist d\'une ligne de plan pour en lier.',
              actionLabel: 'Nouvelle action',
              onAction: () => showActionDialog(context),
            ),
          ),
        ],
      );
    }

    // Total du CA des actions affichées
    final totalRevenue = actions.fold(0.0, (sum, a) => sum + a.revenueAmount);

    return Stack(
      children: [
        Column(
          children: [
            ...(header != null ? [header] : []),
            // Total CA
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Total CA estimé : '),
                  Text(
                    _eur.format(totalRevenue),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return _ActionCard(action: action);
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'addAction',
            onPressed: () => showActionDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Action'),
          ),
        ),
      ],
    );
  }
}

/// Carte d'une action dans la liste.
class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final SalesAction action;

  @override
  Widget build(BuildContext context) {
    final service = context.read<SsdmService>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ActionDetailView(actionId: action.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      action.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  // Badge du nombre de visites liées
                  _VisitsBadgeButton(
                    count: service.visitCountForAction(action.id),
                    onPressed: () => _showActionVisitsDialog(context, action),
                  ),
                  const SizedBox(width: 4),
                  // Statut de l'action
                  _ActionStatusChip(status: action.status),
                ],
              ),
              const SizedBox(height: 8),
              // IV(s) responsable(s)
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      service.ivIdsLabel(action.ivIds),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // CA de l'action
                  Row(
                    children: [
                      const Icon(Icons.euro, size: 16),
                      const SizedBox(width: 2),
                      Text(_eur.format(action.revenueAmount)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Ligne du Sales Plan si liée
              if (action.planEntryId != null)
                Row(
                  children: [
                    const Icon(Icons.table_chart, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        service.planLineLabel(action.planEntryId!),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              // Barre de progression et détails
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: action.effectiveProgress / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      action.effectiveProgress >= 100
                          ? Colors.green
                          : action.effectiveProgress > 0
                              ? Colors.orange
                              : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${action.effectiveProgress}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (action.dueDate != null)
                        Text(
                          _dateFmt.format(action.dueDate!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  if (action.hasSteps || action.isBlocked || action.isLate)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 10,
                        children: [
                          if (action.hasSteps)
                            Text(
                              '${action.doneStepCount}/${action.activeSteps.length} étapes',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (action.isBlocked)
                            const Text(
                              'Bloquée',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                            ),
                          if (action.isLate)
                            const Text(
                              'En retard',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showActionVisitsDialog(BuildContext context, SalesAction action) async {
    final service = context.read<SsdmService>();
    final visits = service.visitsFor(service.selectedYear, actionId: action.id);

    if (visits.isEmpty) {
      // Proposer de créer une visite
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aucune visite liée'),
          content: Text(
            'Aucune visite n\'est liée à l\'action "${action.title}".\n\nSouhaitez-vous en créer une ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Créer une visite'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        Navigator.of(context).pop();
        // Utiliser WidgetsBinding pour s'assurer que le contexte est valide
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showVisitDialog(context, presetActionId: action.id);
          }
        });
      }
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Visites liées à cette action'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action.title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final visit in visits)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: _VisitStatusChip(status: visit.status),
                        title: Text(
                          visit.title.isNotEmpty ? visit.title :
                          'Visite du ${DateFormat('dd/MM/yyyy').format(visit.appointmentDate)}',
                        ),
                        subtitle: Text(
                          '${service.clientLabel(visit.clientId)} - ${service.ivIdsLabel(visit.ivIds)}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Délier',
                          icon: const Icon(Icons.link_off, size: 18),
                          onPressed: () {
                            visit.actionIds = null;
                            service.updateVisit(visit);
                            Navigator.of(context).pop();
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => VisitDetailView(visitId: visit.id),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Voir dans l\'onglet Visites'),
                  onPressed: () {
                    service.filterVisitsByAction(action.id);
                    Navigator.of(context).pop();
                    service.goToVisitsTab();
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

/// Bouton d'accès aux visites liées, avec badge de nombre.
class _VisitsBadgeButton extends StatelessWidget {
  const _VisitsBadgeButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Visites liées à cette action',
          icon: const Icon(Icons.calendar_today),
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Puce d'état d'action.
class _ActionStatusChip extends StatelessWidget {
  const _ActionStatusChip({required this.status});

  final ActionStatus status;

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    switch (status) {
      case ActionStatus.planned:
        color = Colors.blue;
      case ActionStatus.inProgress:
        color = Colors.orange;
      case ActionStatus.done:
        color = Colors.green;
      case ActionStatus.cancelled:
        color = Colors.red;
    }

    return Chip(
      label: Text(status.label),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Puce d'état de visite (pour la liste des visites dans le dialogue).
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Affiche l'affichage de la sélection des IV.
Widget _buildIvSelectionDisplay(List<String>? ivIds, SsdmService service) {
  if (ivIds == null || ivIds.isEmpty) {
    return const Text('Équipe (commune à tous)', style: TextStyle(color: Colors.grey));
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

/// Dialogue de sélection multiple d'IV avec cases à cocher.
/// Retourne la liste des IDs d'IV sélectionnés, null pour Équipe, ou [kAllId] pour Tous.
Future<List<String>?> _showIvMultiSelectDialog(
  BuildContext context, {
  required List<String>? selectedIvIds,
  required List<Iv> availableIvs,
  required SsdmService service,
}) async {
  // Pré-sélection des IV
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
                title: const Text('Équipe (commune à tous)'),
                subtitle: const Text('Action visible par toute l\'équipe'),
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
                subtitle: const Text('Action visible par tous les IV'),
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
              // Option "IV spécifiques"
              const ListTile(
                title: Text('IV spécifiques'),
                subtitle: Text('Sélectionnez les IV concernés'),
              ),
              const SizedBox(height: 8),
              // Liste des IV avec cases à cocher
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
              // Retourner null pour Équipe, [kAllId] pour Tous, ou la liste pour spécifiques
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

/// Dialogue de création d'une action.
Future<void> showActionDialog(BuildContext context) async {
  final service = context.read<SsdmService>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final stepsController = TextEditingController();
  final revenueController = TextEditingController();
  List<String>? ivIds; // null ou vide => équipe
  DateTime? dueDate;
  String? planEntryId;

  final planEntries = service.planFor(service.selectedYear);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Nouvelle action'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Chiffre d'affaires
              TextField(
                controller: revenueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'CA estimé (EUR)',
                  border: OutlineInputBorder(),
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 12),
              // IV(s) responsable(s) - sélection avec cases à cocher
              InkWell(
                onTap: () async {
                  final selected = await _showIvMultiSelectDialog(
                    context,
                    selectedIvIds: ivIds,
                    availableIvs: service.ivs.toList(),
                    service: service,
                  );
                  if (selected != null) {
                    setDialogState(() => ivIds = selected);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Responsable(s)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.expand_more),
                  ),
                  child: _buildIvSelectionDisplay(ivIds, service),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: dueDate ?? DateTime.now(),
                    firstDate: DateTime(
                        service.selectedYear ?? DateTime.now().year, 1, 1),
                    lastDate: DateTime(
                        (service.selectedYear ?? DateTime.now().year) + 1,
                        12, 31),
                  );
                  if (picked != null) setDialogState(() => dueDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Échéance',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    dueDate == null
                        ? 'Choisir une date'
                        : _dateFmt.format(dueDate!),
                  ),
                ),
              ),
              if (planEntries.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ligne du Sales Plan (optionnel)',
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Aucune ligne')),
                    for (final e in planEntries)
                      DropdownMenuItem(
                        value: e.id,
                        child: Text(
                          service.planLineLabel(e.id),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setDialogState(() => planEntryId = v),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: stepsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Étapes (une par ligne, optionnel)',
                  hintText: 'Ex :\nQualifier les 20 comptes\nEnvoyer les offres\nSigner',
                  border: OutlineInputBorder(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Avec des étapes, l\'avancement est calculé automatiquement '
                  'au fil de leur réalisation.',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    ),
  );

  if (confirmed == true && titleController.text.trim().isNotEmpty) {
    await service.addAction(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      ivIds: ivIds,
      dueDate: dueDate,
      planEntryId: planEntryId,
      stepLabels: stepsController.text.split('\n'),
      revenueAmount: double.tryParse(revenueController.text.replaceAll(',', '.')) ?? 0,
    );
  }
  titleController.dispose();
  descriptionController.dispose();
  stepsController.dispose();
  revenueController.dispose();
}
