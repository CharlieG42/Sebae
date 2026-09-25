import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/ssdm_service.dart';

final _eur = NumberFormat.currency(locale: 'fr_FR', symbol: 'EUR');

/// Objectif de CA de l'année sélectionnée (consultation + modification).
class ObjectiveView extends StatelessWidget {
  const ObjectiveView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();
    final year = service.currentYear;
    if (year == null) {
      return const Center(child: Text('Sélectionnez une année.'));
    }

    final planTotal = service.planTotal(year.year);
    final realized = service.realizedTotal(year.year);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Objectif de CA ${year.year}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_eur.format(year.caObjective),
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => _showEditDialog(context, service, year.caObjective),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier l\'objectif'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: 'Total du Sales Plan', value: _eur.format(planTotal)),
                _Row(
                  label: 'Couverture de l\'objectif',
                  value: year.caObjective > 0
                      ? '${(planTotal / year.caObjective * 100).toStringAsFixed(0)} %'
                      : '-',
                ),
                _Row(label: 'CA réalisé', value: _eur.format(realized)),
                _Row(
                  label: 'Atteinte du plan',
                  value: planTotal > 0
                      ? '${(realized / planTotal * 100).toStringAsFixed(0)} %'
                      : '-',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    SsdmService service,
    double current,
  ) async {
    final controller = TextEditingController(text: current.toStringAsFixed(0));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Objectif de CA'),
        content: TextFormField(
          controller: controller,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Montant (EUR)',
            border: OutlineInputBorder(),
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
    );
    if (confirmed == true) {
      final value =
          double.tryParse(controller.text.replaceAll(',', '.'));
      if (value != null && value > 0) {
        await service.updateCaObjective(value);
      }
    }
    controller.dispose();
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
