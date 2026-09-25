import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/empty_state.dart';
import '../services/ssdm_service.dart';
import 'action_detail_view.dart';

final _dateFmt = DateFormat('dd/MM/yyyy');

/// Liste des actions de l'année : équipe + actions spécifiques par IV.
class ActionsView extends StatelessWidget {
  const ActionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();
    final year = service.selectedYear;
    if (year == null) {
      return const Center(child: Text('Sélectionnez une année.'));
    }

    final actions = service.actionsFor(year);
    if (actions.isEmpty) {
      return EmptyState(
        icon: Icons.flag_outlined,
        title: 'Aucune action',
        message:
            'Créez des actions spécifiques ( rattachées à un IV ) ou '
            'des actions communes à l\'équipe.',
        actionLabel: 'Nouvelle action',
        onAction: () => showActionDialog(context),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            final iv = service.ivOf(action.ivId);
            return ListTile(
              leading: CircleAvatar(
                child: Icon(action.ivId == null ? Icons.groups : Icons.person),
              ),
              title: Text(action.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${iv?.name ?? 'Équipe'} - ${action.status.label}'),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: action.progress / 100,
                    minHeight: 6,
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: Text(
                action.dueDate == null ? '-' : _dateFmt.format(action.dueDate!),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ActionDetailView(actionId: action.id),
                ),
              ),
            );
          },
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

/// Dialogue de création d'une action.
Future<void> showActionDialog(BuildContext context) async {
  final service = context.read<SsdmService>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String? ivId; // null => équipe
  DateTime? dueDate;

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
              DropdownButtonFormField<String?>(
                initialValue: null,
                decoration: const InputDecoration(labelText: 'Responsable'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Équipe (commune)')),
                  for (final iv in service.ivs)
                    DropdownMenuItem(value: iv.id, child: Text(iv.name)),
                ],
                onChanged: (v) => setDialogState(() => ivId = v),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: dueDate ?? DateTime.now(),
                    firstDate: DateTime(service.selectedYear ?? DateTime.now().year, 1, 1),
                    lastDate: DateTime((service.selectedYear ?? DateTime.now().year) + 1, 12, 31),
                  );
                  if (picked != null) setDialogState(() => dueDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Échéance',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    dueDate == null ? 'Choisir une date' : _dateFmt.format(dueDate!),
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
      ivId: ivId,
      dueDate: dueDate,
    );
  }
  titleController.dispose();
  descriptionController.dispose();
}
