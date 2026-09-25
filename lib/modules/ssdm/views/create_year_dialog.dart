import 'package:flutter/material.dart';

import '../services/ssdm_service.dart';
import 'package:provider/provider.dart';

/// Dialogue "Créer une nouvelle année".
///
/// C'est ici que sont définis l'année et son objectif de CA. Option :
/// reprendre les actions d'équipe (communes) de l'année precedente.
Future<void> showCreateYearDialog(BuildContext context) async {
  final service = context.read<SsdmService>();
  await showDialog<void>(
    context: context,
    builder: (_) => _CreateYearDialog(service: service),
  );
}

class _CreateYearDialog extends StatefulWidget {
  const _CreateYearDialog({required this.service});

  final SsdmService service;

  @override
  State<_CreateYearDialog> createState() => _CreateYearDialogState();
}

class _CreateYearDialogState extends State<_CreateYearDialog> {
  late final int _year;
  final _objectiveController = TextEditingController();
  bool _copyTeamActions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.service.yearList;
    _year = existing.isEmpty
        ? DateTime.now().year
        : existing.last + 1;
  }

  @override
  void dispose() {
    _objectiveController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final objective = double.tryParse(
      _objectiveController.text.replaceAll(',', '.'),
    );
    if (objective == null || objective <= 0) {
      setState(() => _error = 'Objectif de CA invalide.');
      return;
    }

    final service = widget.service;
    if (service.yearList.contains(_year)) {
      setState(() => _error = 'L\'année $_year existe déjà.');
      return;
    }

    final previous = service.yearList.lastWhere(
      (y) => y < _year,
      orElse: () => -1,
    );

    await service.createYear(
      _year,
      objective,
      copyTeamActions: _copyTeamActions && previous > 0,
      copyFromYear: previous > 0 ? previous : null,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final previous = widget.service.yearList
        .where((y) => y < _year)
        .toList();
    final lastYear = previous.isEmpty ? null : previous.last;

    return AlertDialog(
      title: const Text('Créer une nouvelle année'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Année : $_year',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _objectiveController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Objectif de CA (EUR)',
              border: OutlineInputBorder(),
              hintText: 'ex. 1000000',
            ),
          ),
          if (lastYear != null) ...[
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _copyTeamActions,
              onChanged: (v) => setState(() => _copyTeamActions = v ?? false),
              title: Text(
                'Reprendre les actions d\'équipe de $lastYear',
              ),
              subtitle: const Text(
                'Les actions communes (sans IV) sont recopiées, '
                'avancement remis à zéro.',
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
