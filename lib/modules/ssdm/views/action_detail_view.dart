import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sales_action.dart';
import '../services/ssdm_service.dart';

final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

/// Détail d'une action : mise à jour de l'avancement et historique.
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
          if (action.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(action.description),
          ],
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
