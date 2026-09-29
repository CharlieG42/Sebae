import 'package:flutter/material.dart';

/// Dialogue de sélection multiple avec cases à cocher.
///
/// Utilisation :
/// ```dart
/// final selectedIds = await showMultiSelectDialog<String>(
///   context: context,
///   title: 'Sélectionner des IV',
///   items: ivList.map((iv) => MultiSelectItem(iv.id, iv.name)).toList(),
///   initialSelected: selectedIvIds,
/// );
/// ```
class MultiSelectItem<T> {
  final T value;
  final String label;

  const MultiSelectItem(this.value, this.label);
}

/// Affiche un dialogue de sélection multiple et retourne la liste des valeurs sélectionnées.
Future<List<T>> showMultiSelectDialog<T>(
  BuildContext context, {
  required String title,
  required List<MultiSelectItem<T>> items,
  List<T> initialSelected = const [],
  String? emptyMessage,
}) async {
  final result = await showDialog<List<T>>(
    context: context,
    builder: (context) => _MultiSelectDialog<T>(
      title: title,
      items: items,
      initialSelected: initialSelected,
      emptyMessage: emptyMessage,
    ),
  );
  return result ?? [];
}

class _MultiSelectDialog<T> extends StatefulWidget {
  const _MultiSelectDialog({
    required this.title,
    required this.items,
    this.initialSelected = const [],
    this.emptyMessage,
  });

  final String title;
  final List<MultiSelectItem<T>> items;
  final List<T> initialSelected;
  final String? emptyMessage;

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late List<T> selectedItems;

  @override
  void initState() {
    super.initState();
    selectedItems = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.items.isEmpty
            ? Center(
                child: Text(
                  widget.emptyMessage ?? 'Aucun élément disponible',
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = selectedItems.contains(item.value);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          if (!selectedItems.contains(item.value)) {
                            selectedItems.add(item.value);
                          }
                        } else {
                          selectedItems.remove(item.value);
                        }
                      });
                    },
                    title: Text(item.label),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selectedItems),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Bouton qui ouvre un dialogue de sélection multiple.
/// Affiche les éléments sélectionnés sous forme de chips.
class MultiSelectButton<T> extends StatelessWidget {
  const MultiSelectButton({
    super.key,
    required this.title,
    required this.items,
    this.selectedItems = const [],
    this.onSelected,
    this.emptyText = 'Aucun',
    this.hintText,
  });

  final String title;
  final List<MultiSelectItem<T>> items;
  final List<T> selectedItems;
  final ValueChanged<List<T>>? onSelected;
  final String emptyText;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await showMultiSelectDialog<T>(
          context,
          title: title,
          items: items,
          initialSelected: selectedItems,
          emptyMessage: items.isEmpty ? 'Aucun élément disponible' : null,
        );
        if (onSelected != null) {
          onSelected!(result);
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          hintText: hintText,
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.expand_more, size: 18),
        ),
        child: _buildSelectedChips(context),
      ),
    );
  }

  Widget _buildSelectedChips(BuildContext context) {
    if (selectedItems.isEmpty) {
      return Text(
        emptyText,
        style: TextStyle(color: Theme.of(context).disabledColor),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: selectedItems
          .map((value) {
            final item = items.firstWhere(
              (item) => item.value == value,
              orElse: () => MultiSelectItem(value, 'Inconnu'),
            );
            return Chip(
              label: Text(item.label),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          })
          .toList(),
    );
  }
}
