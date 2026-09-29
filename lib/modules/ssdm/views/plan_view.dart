import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/iv.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/sales_plan_entry.dart';
import '../models/visit.dart';
import '../services/ssdm_service.dart';
import '../ssdm_constants.dart';
import 'action_detail_view.dart';
import 'visit_detail_view.dart';
import 'visits_view.dart';

final _eur = NumberFormat.currency(locale: 'fr_FR', symbol: 'EUR');

/// Sales Plan de l'année : objectifs de CA par IV x groupe x type de clients.
///
/// Chaque axe accepte également la valeur "Tous" (ligne globale).
/// Chaque ligne peut porter des actions liées (bouton liste) et des visites,
/// et chaque section IV propose l'ajout direct d'une ligne pour cet IV.
class PlanView extends StatelessWidget {
  const PlanView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();
    final year = service.selectedYear;
    if (year == null) {
      return const Center(child: Text('Sélectionnez une année.'));
    }

    final entries = service.planFor(year);
    final objective = service.currentYear?.caObjective ?? 0;
    final total = service.planTotal(year);

    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.table_chart_outlined,
        title: 'Sales Plan vide',
        message:
            'Ajoutez des lignes de plan : un objectif de CA par IV, '
            'par groupe de clients et par type de clients, avec un titre personnalisé.',
        actionLabel: 'Ajouter une ligne',
        onAction: () => showPlanEntryDialog(context),
      );
    }

    // Regroupement par IV (les lignes "Tous" forment leur propre section).
    final byIv = <String, List<SalesPlanEntry>>{};
    for (final e in entries) {
      byIv.putIfAbsent(e.ivId, () => []).add(e);
    }
    final ivKeys = byIv.keys.toList()
      ..sort((a, b) {
        // Section "Tous" en dernier.
        if (a == kAllId) return 1;
        if (b == kAllId) return -1;
        return service.ivLabel(a).compareTo(service.ivLabel(b));
      });

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 88, left: 16, right: 16, top: 16),
          children: [
            for (final ivId in ivKeys)
              ..._ivSection(context, service, ivId, byIv[ivId]!),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total du plan'),
                Text(_eur.format(total),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Text(
              objective > 0
                  ? 'Couverture de l\'objectif : ${(total / objective * 100).toStringAsFixed(0)} %'
                  : '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'addPlanEntry',
            onPressed: () => showPlanEntryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ligne de plan'),
          ),
        ),
      ],
    );
  }

  List<Widget> _ivSection(
    BuildContext context,
    SsdmService service,
    String ivId,
    List<SalesPlanEntry> entries,
  ) {
    final ivTotal = entries.fold(0.0, (sum, e) => sum + e.targetAmount);
    final actionTotal = entries.fold(0.0, (sum, e) => sum + service.actionsRevenueForPlan(e.id));
    final visitTotal = entries.fold<int>(0, (sum, e) => sum + service.visitCountForPlan(e.id));
    
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                service.ivLabel(ivId),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(_eur.format(ivTotal),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 4),
            // Actions liées à cet IV
            if (actionTotal > 0)
              Row(
                children: [
                  const Icon(Icons.euro, size: 16),
                  const SizedBox(width: 2),
                  Text(_eur.format(actionTotal)),
                  const SizedBox(width: 8),
                ],
              ),
            // Visites liées à cet IV
            if (visitTotal > 0)
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 2),
                  Text('$visitTotal'),
                  const SizedBox(width: 8),
                ],
              ),
            // Ajout d'une ligne directement pré-remplie pour cet IV.
            IconButton(
              tooltip: 'Ajouter une ligne pour ${service.ivLabel(ivId)}',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () =>
                  showPlanEntryDialog(context, presetIvId: ivId),
            ),
          ],
        ),
      ),
      Card(
        child: Column(
          children: [
            for (final e in entries)
              ListTile(
                title: Text(
                  e.title.isNotEmpty 
                      ? e.title 
                      : '${service.groupLabel(e.clientGroupId)} - ${service.typeLabel(e.clientTypeId)}',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cible : ${_eur.format(e.targetAmount)}'
                      '${e.realizedAmount > 0 ? ' - Réalisé : ${_eur.format(e.realizedAmount)}' : ''}',
                    ),
                    if (service.actionCountForPlan(e.id) > 0 || service.visitCountForPlan(e.id) > 0)
                      Row(
                        children: [
                          if (service.actionCountForPlan(e.id) > 0)
                            Text(
                              '${service.actionCountForPlan(e.id)} action(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          if (service.actionCountForPlan(e.id) > 0 && service.visitCountForPlan(e.id) > 0)
                            const Text(' - '),
                          if (service.visitCountForPlan(e.id) > 0)
                            Text(
                              '${service.visitCountForPlan(e.id)} visite(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Visites liées à cette ligne.
                    _VisitsBadgeButton(
                      count: service.visitCountForPlan(e.id),
                      onPressed: () =>
                          _showPlanEntryVisitsDialog(context, e),
                    ),
                    // Actions liées à cette ligne.
                    _ActionsBadgeButton(
                      count: service.actionCountForPlan(e.id),
                      onPressed: () =>
                          showPlanEntryActionsDialog(context, e),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => showPlanEntryDialog(context, entry: e),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => service.deletePlanEntry(e),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
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
          tooltip: 'Visites liées à cette ligne',
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
                color: Theme.of(context).colorScheme.secondary,
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

/// Bouton d'accès aux actions liées, avec badge de nombre.
class _ActionsBadgeButton extends StatelessWidget {
  const _ActionsBadgeButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Actions liées à cette ligne',
          icon: const Icon(Icons.checklist),
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
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

/// Dialogue "Visites liées à une ligne de plan".
Future<void> _showPlanEntryVisitsDialog(
  BuildContext context,
  SalesPlanEntry entry,
) async {
  final service = context.read<SsdmService>();
  final visits = service.visitsFor(service.selectedYear, planEntryId: entry.id);

  if (visits.isEmpty) {
    // Si aucune visite, proposer d'en créer une directement
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aucune visite liée'),
        content: Text(
          'Aucune visite n\'est liée à la ligne "${entry.title.isNotEmpty ? entry.title : service.planLineLabel(entry.id)}".\n\nSouhaitez-vous en créer une ?',
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

    if (confirmed == true) {
      final navigatorContext = context;
      Navigator.of(navigatorContext).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showVisitDialog(navigatorContext, presetPlanEntryId: entry.id, useRootNavigator: true);
      });
    }
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Visites de la ligne'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title.isNotEmpty ? entry.title : service.planLineLabel(entry.id),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            // Liste des visites
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
                          visit.planEntryIds = null;
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

            const Divider(height: 24),

            // Création rapide d'une visite liée
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle visite pour cette ligne'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      showVisitDialog(context, presetPlanEntryId: entry.id);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Navigation vers l'onglet Visites
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Voir dans l\'onglet Visites'),
                onPressed: () {
                  service.filterVisitsByPlanEntry(entry.id);
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

/// Libellé d'un IV pour les listes déroulantes.
String _ivDropdownLabel(Iv iv) => iv.trigramOrEmpty.isEmpty
    ? iv.name
    : '${iv.trigramOrEmpty} - ${iv.name}';

/// Dialogue de création / modification d'une ligne de plan.
///
/// Chaque axe propose en première position l'option "Tous" (ligne globale).
/// [presetIvId] présélectionne l'IV (ajout depuis une section IV).
Future<void> showPlanEntryDialog(
  BuildContext context, {
  SalesPlanEntry? entry,
  String? presetIvId,
}) async {
  final service = context.read<SsdmService>();
  if (service.ivs.isEmpty ||
      service.clientGroups.isEmpty ||
      service.clientTypes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Définissez au préalable des IV, groupes et types de clients '
          'dans "Bases de données partagées".',
        ),
      ),
    );
    return;
  }

  final result = await showDialog<SalesPlanEntry?>(
    context: context,
    builder: (_) => _PlanEntryDialog(
      service: service,
      entry: entry,
      presetIvId: presetIvId,
    ),
  );

  if (result != null) {
    if (entry == null) {
      await service.addPlanEntry(
        ivId: result.ivId,
        clientGroupId: result.clientGroupId,
        clientTypeId: result.clientTypeId,
        targetAmount: result.targetAmount,
        title: result.title,
      );
    } else {
      entry.ivId = result.ivId;
      entry.clientGroupId = result.clientGroupId;
      entry.clientTypeId = result.clientTypeId;
      entry.targetAmount = result.targetAmount;
      entry.title = result.title;
      await service.updatePlanEntry(entry);
    }
  }
}

class _PlanEntryDialog extends StatefulWidget {
  const _PlanEntryDialog({
    required this.service,
    this.entry,
    this.presetIvId,
  });

  final SsdmService service;
  final SalesPlanEntry? entry;
  final String? presetIvId;

  @override
  State<_PlanEntryDialog> createState() => _PlanEntryDialogState();
}

class _PlanEntryDialogState extends State<_PlanEntryDialog> {
  late List<String> _selectedIvIds;
  late List<String> _selectedGroupIds;
  late List<String> _selectedTypeIds;
  late final TextEditingController _amount;
  late final TextEditingController _title;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    // Pour compatibilité : si ivIds existe, on l'utilise, sinon on convertit ivId en liste
    _selectedIvIds = e?.ivIds ?? (e != null && e.ivId.isNotEmpty ? [e.ivId] : []);
    _selectedGroupIds = e?.clientGroupIds ?? (e != null && e.clientGroupId.isNotEmpty ? [e.clientGroupId] : []);
    _selectedTypeIds = e?.clientTypeIds ?? (e != null && e.clientTypeId.isNotEmpty ? [e.clientTypeId] : []);
    
    // Si présélection par presetIvId
    if (widget.presetIvId != null && _selectedIvIds.isEmpty) {
      _selectedIvIds = [widget.presetIvId!];
    }
    
    _amount = TextEditingController(
      text: e == null ? '' : e.targetAmount.toStringAsFixed(0),
    );
    _title = TextEditingController(
      text: e?.title ?? '',
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    super.dispose();
  }

  void _submit() {
    final amount =
        double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide.')),
      );
      return;
    }
    
    // Pour compatibilité, on garde les anciens champs avec le premier élément
    final ivId = _selectedIvIds.isNotEmpty ? _selectedIvIds.first : kAllId;
    final clientGroupId = _selectedGroupIds.isNotEmpty ? _selectedGroupIds.first : kAllId;
    final clientTypeId = _selectedTypeIds.isNotEmpty ? _selectedTypeIds.first : kAllId;
    
    Navigator.of(context).pop(SalesPlanEntry(
      id: widget.entry?.id ?? '',
      year: widget.entry?.year ?? 0,
      title: _title.text.trim(),
      ivId: ivId,
      ivIds: _selectedIvIds.isEmpty ? null : _selectedIvIds,
      clientGroupId: clientGroupId,
      clientGroupIds: _selectedGroupIds.isEmpty ? null : _selectedGroupIds,
      clientTypeId: clientTypeId,
      clientTypeIds: _selectedTypeIds.isEmpty ? null : _selectedTypeIds,
      targetAmount: amount,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    return AlertDialog(
      title: Text(widget.entry == null ? 'Nouvelle ligne de plan' : 'Modifier la ligne'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre
          TextField(
            controller: _title,
            autofocus: widget.entry == null,
            decoration: const InputDecoration(
              labelText: 'Titre (optionnel)',
              border: OutlineInputBorder(),
              hintText: 'Ex: Développement secteur Nord, Fidélisation clients existants...',
            ),
          ),
          const SizedBox(height: 12),
          // IV avec sélection multiple par cases à cocher
          InkWell(
            onTap: () async {
              final selected = await _showIvMultiSelectDialog(
                context,
                selectedIds: _selectedIvIds,
                service: service,
              );
              if (selected != null) {
                setState(() => _selectedIvIds = selected);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'IV(s)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.expand_more),
              ),
              child: _buildIvSelectionDisplay(_selectedIvIds, service),
            ),
          ),
          const SizedBox(height: 12),
          // Groupe de clients avec sélection multiple par cases à cocher
          InkWell(
            onTap: () async {
              final selected = await _showClientGroupMultiSelectDialog(
                context,
                selectedIds: _selectedGroupIds,
                service: service,
              );
              if (selected != null) {
                setState(() => _selectedGroupIds = selected);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Groupe(s) de clients',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.expand_more),
              ),
              child: _buildClientGroupSelectionDisplay(_selectedGroupIds, service),
            ),
          ),
          const SizedBox(height: 12),
          // Type de clients avec sélection multiple par cases à cocher
          InkWell(
            onTap: () async {
              final selected = await _showClientTypeMultiSelectDialog(
                context,
                selectedIds: _selectedTypeIds,
                service: service,
              );
              if (selected != null) {
                setState(() => _selectedTypeIds = selected);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Type(s) de clients',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.expand_more),
              ),
              child: _buildClientTypeSelectionDisplay(_selectedTypeIds, service),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Objectif de CA (EUR)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
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
}

/// Dialogue "Actions liées à une ligne de plan".
///
/// Permet de :
/// - voir les actions liées et ouvrir leur détail,
/// - créer une action liée (pré-remplie avec l'IV/groupe/type de la ligne),
/// - associer une action existante de l'année,
/// - délier une action,
/// - basculer vers l'onglet Actions filtré sur cette ligne.
Future<void> showPlanEntryActionsDialog(
  BuildContext context,
  SalesPlanEntry entry,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _PlanEntryActionsDialog(entry: entry),
  );
}

class _PlanEntryActionsDialog extends StatefulWidget {
  const _PlanEntryActionsDialog({required this.entry});

  final SalesPlanEntry entry;

  @override
  State<_PlanEntryActionsDialog> createState() =>
      _PlanEntryActionsDialogState();
}

class _PlanEntryActionsDialogState extends State<_PlanEntryActionsDialog> {
  final _newActionController = TextEditingController();

  @override
  void dispose() {
    _newActionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();
    final entry = widget.entry;
    final linked = service.actionsForPlan(entry.id);

    // Actions de l'année non liées à une ligne (candidates à l'association).
    final year = entry.year;
    final candidates = service
        .actionsFor(year)
        .where((a) => a.planEntryId == null)
        .toList();

    return AlertDialog(
      title: const Text('Actions de la ligne'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.title.isNotEmpty ? entry.title : service.planLineLabel(entry.id)} - ${_eur.format(entry.targetAmount)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            // --- Actions liées ---
            if (linked.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucune action liée pour le moment.'),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final action in linked)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: _MiniStatusDot(progress: action.effectiveProgress),
                        title: Text(action.title),
                        subtitle: Text(
                          '${service.ivIdsLabel(action.ivIds)} - ${action.status.label} - ${action.effectiveProgress} % - ${_eur.format(action.revenueAmount)}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Délier',
                          icon: const Icon(Icons.link_off, size: 18),
                          onPressed: () =>
                              service.linkActionToPlan(action, null),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ActionDetailView(actionId: action.id),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

            const Divider(height: 24),

            // --- Création rapide d'une action liée ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newActionController,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Nouvelle action pour cette ligne',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _createLinkedAction(),
                  ),
                ),
                IconButton(
                  tooltip: 'Créer et lier',
                  icon: const Icon(Icons.add_task),
                  onPressed: _createLinkedAction,
                ),
              ],
            ),

            // --- Association d'une action existante ---
            if (candidates.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Associer une action existante',
                ),
                items: [
                  for (final a in candidates)
                    DropdownMenuItem(
                      value: a.id,
                      child: Text(
                        a.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) async {
                  if (id == null) return;
                  final action = service.actionOf(id);
                  if (action != null) {
                    await service.linkActionToPlan(action, entry.id);
                  }
                },
              ),
            ],

            const SizedBox(height: 16),
            // --- Navigation vers l'onglet Actions ---
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Voir dans l\'onglet Actions'),
                onPressed: () {
                  service.filterActionsByPlan(entry.id);
                  Navigator.of(context).pop();
                  service.goToActionsTab();
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
    );
  }

  Future<void> _createLinkedAction() async {
    final service = context.read<SsdmService>();
    final title = _newActionController.text.trim();
    if (title.isEmpty) return;
    final entry = widget.entry;
    await service.addAction(
      title: title,
      ivIds: entry.ivId == kAllId ? null : [entry.ivId],
      clientGroupId: entry.clientGroupId == kAllId ? null : entry.clientGroupId,
      clientTypeId: entry.clientTypeId == kAllId ? null : entry.clientTypeId,
      planEntryId: entry.id,
    );
    _newActionController.clear();
  }
}

// Dialogues de sélection pour le Sales Plan

/// Affiche l'affichage de la sélection des IV pour le Sales Plan.
Widget _buildIvSelectionDisplay(List<String>? ivIds, SsdmService service) {
  if (ivIds == null || ivIds.isEmpty) {
    return const Text('Aucun', style: TextStyle(color: Colors.grey));
  }
  if (ivIds.contains(kAllId)) {
    return const Text('Tous les IV');
  }
  if (ivIds.length == 1) {
    return Text(_ivDropdownLabel(service.ivOf(ivIds.first) ?? service.ivs.firstWhere((iv) => iv.id == ivIds.first, orElse: () => service.ivs.first)));
  }
  return Text('${ivIds.length} IV sélectionnés');
}

/// Affiche l'affichage de la sélection des Groupes de clients pour le Sales Plan.
Widget _buildClientGroupSelectionDisplay(List<String>? groupIds, SsdmService service) {
  if (groupIds == null || groupIds.isEmpty) {
    return const Text('Aucun', style: TextStyle(color: Colors.grey));
  }
  if (groupIds.length == 1) {
    return Text(service.groupOf(groupIds.first)?.name ?? groupIds.first);
  }
  return Text('${groupIds.length} groupes sélectionnés');
}

/// Affiche l'affichage de la sélection des Types de clients pour le Sales Plan.
Widget _buildClientTypeSelectionDisplay(List<String>? typeIds, SsdmService service) {
  if (typeIds == null || typeIds.isEmpty) {
    return const Text('Aucun', style: TextStyle(color: Colors.grey));
  }
  if (typeIds.length == 1) {
    return Text(service.typeOf(typeIds.first)?.name ?? typeIds.first);
  }
  return Text('${typeIds.length} types sélectionnés');
}

/// Dialogue de sélection multiple d'IV avec cases à cocher pour le Sales Plan.
Future<List<String>?> _showIvMultiSelectDialog(
  BuildContext context, {
  required List<String> selectedIds,
  required SsdmService service,
}) async {
  final selectedSet = selectedIds.toSet();
  
  return await showDialog<List<String>>(
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
              // Option "Tous"
              CheckboxListTile(
                value: selectedSet.contains(kAllId),
                title: const Text('Tous les IV'),
                subtitle: const Text('Sélectionner/désélectionner tous'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selectedSet.clear();
                      selectedSet.add(kAllId);
                    } else {
                      selectedSet.remove(kAllId);
                    }
                  });
                },
              ),
              const Divider(),
              // Liste des IV
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final iv in service.ivs)
                      CheckboxListTile(
                        value: selectedSet.contains(iv.id),
                        title: Text(_ivDropdownLabel(iv)),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedSet.add(iv.id);
                              selectedSet.remove(kAllId); // Désélectionner "Tous" si on sélectionne un IV spécifique
                            } else {
                              selectedSet.remove(iv.id);
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
            onPressed: () => Navigator.pop(context, selectedIds),
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
}

/// Dialogue de sélection multiple de Groupes de clients avec cases à cocher pour le Sales Plan.
Future<List<String>?> _showClientGroupMultiSelectDialog(
  BuildContext context, {
  required List<String> selectedIds,
  required SsdmService service,
}) async {
  final selectedSet = selectedIds.toSet();
  
  return await showDialog<List<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Sélectionner les Groupes de clients'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Option "Tous"
              CheckboxListTile(
                value: selectedSet.contains(kAllId),
                title: const Text('Tous les groupes'),
                subtitle: const Text('Sélectionner/désélectionner tous'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selectedSet.clear();
                      selectedSet.add(kAllId);
                    } else {
                      selectedSet.remove(kAllId);
                    }
                  });
                },
              ),
              const Divider(),
              // Liste des groupes
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final g in service.clientGroups)
                      CheckboxListTile(
                        value: selectedSet.contains(g.id),
                        title: Text(g.name),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedSet.add(g.id);
                              selectedSet.remove(kAllId);
                            } else {
                              selectedSet.remove(g.id);
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
            onPressed: () => Navigator.pop(context, selectedIds),
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
}

/// Dialogue de sélection multiple de Types de clients avec cases à cocher pour le Sales Plan.
Future<List<String>?> _showClientTypeMultiSelectDialog(
  BuildContext context, {
  required List<String> selectedIds,
  required SsdmService service,
}) async {
  final selectedSet = selectedIds.toSet();
  
  return await showDialog<List<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Sélectionner les Types de clients'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Option "Tous"
              CheckboxListTile(
                value: selectedSet.contains(kAllId),
                title: const Text('Tous les types'),
                subtitle: const Text('Sélectionner/désélectionner tous'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selectedSet.clear();
                      selectedSet.add(kAllId);
                    } else {
                      selectedSet.remove(kAllId);
                    }
                  });
                },
              ),
              const Divider(),
              // Liste des types
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in service.clientTypes)
                      CheckboxListTile(
                        value: selectedSet.contains(t.id),
                        title: Text(t.name),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedSet.add(t.id);
                              selectedSet.remove(kAllId);
                            } else {
                              selectedSet.remove(t.id);
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
            onPressed: () => Navigator.pop(context, selectedIds),
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
}

class _MiniStatusDot extends StatelessWidget {
  const _MiniStatusDot({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final color = progress >= 100
        ? Colors.green
        : progress > 0
            ? Colors.orange
            : Colors.grey;
    return CircleAvatar(radius: 5, backgroundColor: color);
  }
}
