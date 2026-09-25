import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/iv.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/sales_plan_entry.dart';
import '../services/ssdm_service.dart';
import 'action_detail_view.dart';

final _eur = NumberFormat.currency(locale: 'fr_FR', symbol: 'EUR');

/// Sales Plan de l'année : objectifs de CA par IV x groupe x type de clients.
///
/// Chaque axe accepte également la valeur "Tous" (ligne globale).
/// Chaque ligne peut porter des actions liées (bouton liste) et chaque
/// section IV propose l'ajout direct d'une ligne pour cet IV.
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
            'par groupe de clients et par type de clients.',
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
                  '${service.groupLabel(e.clientGroupId)} - '
                  '${service.typeLabel(e.clientTypeId)}',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cible : ${_eur.format(e.targetAmount)}'
                      '${e.realizedAmount > 0 ? ' - Réalisé : ${_eur.format(e.realizedAmount)}' : ''}',
                    ),
                    if (service.actionCountForPlan(e.id) > 0)
                      Text(
                        '${service.actionCountForPlan(e.id)} action(s) liée(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
      );
    } else {
      entry.ivId = result.ivId;
      entry.clientGroupId = result.clientGroupId;
      entry.clientTypeId = result.clientTypeId;
      entry.targetAmount = result.targetAmount;
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
  late String _ivId;
  late String _groupId;
  late String _typeId;
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _ivId = e?.ivId ?? widget.presetIvId ?? kAllId;
    _groupId = e?.clientGroupId ?? kAllId;
    _typeId = e?.clientTypeId ?? kAllId;
    _amount = TextEditingController(
      text: e == null ? '' : e.targetAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
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
    Navigator.of(context).pop(SalesPlanEntry(
      id: widget.entry?.id ?? '',
      year: widget.entry?.year ?? 0,
      ivId: _ivId,
      clientGroupId: _groupId,
      clientTypeId: _typeId,
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
          DropdownButtonFormField<String>(
            initialValue: _ivId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'IV'),
            items: [
              const DropdownMenuItem(value: kAllId, child: Text('Tous')),
              for (final iv in service.ivs)
                DropdownMenuItem(value: iv.id, child: Text(_ivDropdownLabel(iv))),
            ],
            onChanged: (v) => setState(() => _ivId = v ?? _ivId),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _groupId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Groupe de clients'),
            items: [
              const DropdownMenuItem(value: kAllId, child: Text('Tous')),
              for (final g in service.clientGroups)
                DropdownMenuItem(value: g.id, child: Text(g.name)),
            ],
            onChanged: (v) => setState(() => _groupId = v ?? _groupId),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _typeId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Type de clients'),
            items: [
              const DropdownMenuItem(value: kAllId, child: Text('Tous')),
              for (final t in service.clientTypes)
                DropdownMenuItem(value: t.id, child: Text(t.name)),
            ],
            onChanged: (v) => setState(() => _typeId = v ?? _typeId),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            autofocus: widget.entry == null,
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
              '${service.planLineLabel(entry.id)} - ${_eur.format(entry.targetAmount)}',
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
                          '${service.ivLabel(action.ivId)} - ${action.status.label} - ${action.progress} %',
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
      ivId: entry.ivId == kAllId ? null : entry.ivId,
      clientGroupId: entry.clientGroupId == kAllId ? null : entry.clientGroupId,
      clientTypeId: entry.clientTypeId == kAllId ? null : entry.clientTypeId,
      planEntryId: entry.id,
    );
    _newActionController.clear();
  }
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
