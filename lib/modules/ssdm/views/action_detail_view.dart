import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/action_step.dart';
import '../models/sales_action.dart';
import '../services/ssdm_service.dart';

final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');
final _dayFmt = DateFormat('dd/MM/yyyy');
final _eur = NumberFormat.currency(locale: 'fr_FR', symbol: 'EUR');

/// Détail d'une action : étapes pondérées, avancement, historique et
/// liaison à une ligne du Sales Plan.
class ActionDetailView extends StatelessWidget {
  const ActionDetailView({super.key, required this.actionId});

  final String actionId;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();
    final action = service.actionOf(actionId);
    if (action == null) {
      // Action supprimée : retour.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => Navigator.of(context).maybePop());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final planEntries = service.planFor(action.year);

    return Scaffold(
      appBar: AppBar(
        title: Text(action.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Supprimer l\'action ?'),
                  content: Text(action.title),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await service.deleteAction(action);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${service.ivLabel(action.ivId)} - ${action.status.label}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (action.dueDate != null)
            Text('Échéance : ${_dateFmt.format(action.dueDate!)}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (action.isBlocked) _WarningChip(color: Colors.red, label: 'Bloquée', icon: Icons.block),
              if (action.isLate) _WarningChip(color: Colors.orange, label: 'En retard', icon: Icons.schedule),
            ],
          ),
          if (action.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(action.description),
          ],
          const Divider(height: 32),

          // --- Ligne du Sales Plan liée ---
          Text('Ligne du Sales Plan',
              style: Theme.of(context).textTheme.titleMedium),
          if (planEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                  'Aucune ligne de plan pour cette année : créez-en une dans l\'onglet Sales Plan.'),
            )
          else ...[
            DropdownButtonFormField<String?>(
              initialValue: action.planEntryId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Action liée à la ligne',
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Aucune ligne')),
                for (final e in planEntries)
                  DropdownMenuItem(
                    value: e.id,
                    child: Text(
                      '${service.planLineLabel(e.id)} (${_eur.format(e.targetAmount)})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => service.linkActionToPlan(action, v),
            ),
            if (action.planEntryId != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Voir dans l\'onglet Sales Plan'),
                  onPressed: () {
                    service.filterActionsByPlan(null);
                    Navigator.of(context).pop();
                    service.goToPlanTab();
                  },
                ),
              ),
            ],
          ],
          const Divider(height: 32),

          // --- Étapes pondérées ---
          _StepsSection(action: action),
          const Divider(height: 32),

          _ProgressSection(action: action),
          const Divider(height: 32),
          Text('Historique', style: Theme.of(context).textTheme.titleMedium),
          if (action.history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Aucune mise à jour pour le moment.'),
            )
          else
            for (final update in action.history.reversed)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 5,
                  backgroundColor: update.progress >= 100
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text('${update.progress} %'),
                subtitle: Text(_dateFmt.format(update.date)),
                trailing: update.comment.isEmpty ? null : Text(update.comment),
              ),
        ],
      ),
    );
  }
}

class _WarningChip extends StatelessWidget {
  const _WarningChip({required this.color, required this.label, required this.icon});

  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------- Étapes

/// Section d'édition des étapes pondérées d'une action.
class _StepsSection extends StatelessWidget {
  const _StepsSection({required this.action});

  final SalesAction action;

  @override
  Widget build(BuildContext context) {
    final service = context.read<SsdmService>();
    final steps = action.steps ?? const <ActionStep>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                action.hasSteps
                    ? 'Étapes (${action.doneStepCount}/${action.activeSteps.length} faites)'
                    : 'Étapes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              onPressed: () => _showStepDialog(context, service, action),
            ),
          ],
        ),
        if (!action.hasSteps)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
                'Définissez des étapes pondérées pour un avancement calculé '
                'automatiquement. Sans étape, l\'avancement reste manuel.'),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: steps.length,
            onReorder: (oldIndex, newIndex) =>
                service.moveStep(action, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final step = steps[index];
              return ListTile(
                key: ValueKey(step.id),
                dense: true,
                leading: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_indicator, size: 20),
                ),
                title: Row(
                  children: [
                    _StepStatusButton(
                      step: step,
                      onTap: () => _pickStepStatus(context, service, step),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(step.label,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Text('poids ${step.weight}'),
                    if (step.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          step.isLate ? 'en retard' : _dayFmt.format(step.dueDate!),
                          style: TextStyle(
                            color: step.isLate ? Colors.orange : null,
                            fontWeight: step.isLate ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      _showStepDialog(context, service, action, step: step);
                    } else if (v == 'delete') {
                      service.deleteStep(action, step);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _pickStepStatus(
      BuildContext context, SsdmService service, ActionStep step) async {
    final action = this.action;
    final status = await showDialog<ActionStepStatus>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(step.label),
        children: [
          for (final s in ActionStepStatus.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, s),
              child: Row(
                children: [
                  Icon(_statusIcon(s), color: _statusColor(s), size: 18),
                  const SizedBox(width: 12),
                  Text(s.label),
                ],
              ),
            ),
        ],
      ),
    );
    if (status != null) {
      await service.setStepStatus(
        action,
        step,
        status,
        comment: 'Étape "${step.label}" : ${status.label}',
      );
    }
  }

  Future<void> _showStepDialog(
    BuildContext context,
    SsdmService service,
    SalesAction action, {
    ActionStep? step,
  }) async {
    final labelController = TextEditingController(text: step?.label ?? '');
    int weight = step?.weight ?? 1;
    DateTime? dueDate = step?.dueDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(step == null ? 'Nouvelle étape' : 'Modifier l\'étape'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Libellé de l\'étape',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: weight,
                  decoration: const InputDecoration(
                      labelText: 'Poids dans l\'avancement'),
                  items: [
                    for (var w = 1; w <= 5; w++)
                      DropdownMenuItem(
                          value: w,
                          child: Text(w == 1 ? '1 (standard)' : '$w')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => weight = v ?? 1),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => dueDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Échéance (optionnelle)',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      dueDate == null ? 'Choisir une date' : _dayFmt.format(dueDate!),
                    ),
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
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && labelController.text.trim().isNotEmpty) {
      if (step == null) {
        await service.addStep(
          action,
          label: labelController.text.trim(),
          weight: weight,
          dueDate: dueDate,
        );
      } else {
        await service.updateStep(
          action,
          step,
          label: labelController.text,
          weight: weight,
          dueDate: dueDate,
        );
      }
    }
    labelController.dispose();
  }
}

class _StepStatusButton extends StatelessWidget {
  const _StepStatusButton({required this.step, required this.onTap});

  final ActionStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(step.status).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_statusIcon(step.status), size: 16, color: _statusColor(step.status)),
            const SizedBox(width: 6),
            Text(
              step.status.label,
              style: TextStyle(fontSize: 12, color: _statusColor(step.status)),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(ActionStepStatus status) {
  switch (status) {
    case ActionStepStatus.todo:
      return Colors.blueGrey;
    case ActionStepStatus.inProgress:
      return Colors.blue;
    case ActionStepStatus.done:
      return Colors.green;
    case ActionStepStatus.blocked:
      return Colors.red;
    case ActionStepStatus.cancelled:
      return Colors.grey;
  }
}

IconData _statusIcon(ActionStepStatus status) {
  switch (status) {
    case ActionStepStatus.todo:
      return Icons.radio_button_unchecked;
    case ActionStepStatus.inProgress:
      return Icons.adjust;
    case ActionStepStatus.done:
      return Icons.check_circle;
    case ActionStepStatus.blocked:
      return Icons.block;
    case ActionStepStatus.cancelled:
      return Icons.cancel_outlined;
  }
}

// ----------------------------------------------------------------- Avancement

class _ProgressSection extends StatefulWidget {
  const _ProgressSection({required this.action});

  final SalesAction action;

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  late double _value;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _value = widget.action.progress.toDouble();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<SsdmService>();

    // Action pilotée par étapes : avancement calculé, en lecture seule.
    if (widget.action.hasSteps) {
      final progress = widget.action.computedProgress;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Avancement : $progress %',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress / 100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculé automatiquement à partir des étapes pondérées '
            '(${widget.action.doneStepCount}/${widget.action.activeSteps.length} faites).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Avancement : ${_value.toStringAsFixed(0)} %',
            style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: _value,
          divisions: 20,
          label: '${_value.toStringAsFixed(0)} %',
          onChanged: (v) => setState(() => _value = v),
        ),
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(
            labelText: 'Commentaire (optionnel)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () async {
            await service.updateProgress(
              widget.action,
              _value.round(),
              comment: _commentController.text.trim(),
            );
            _commentController.clear();
          },
          icon: const Icon(Icons.check),
          label: const Text('Enregistrer l\'avancement'),
        ),
      ],
    );
  }
}
