import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/answer.dart';
import '../models/question_type.dart';

/// Widget pour afficher et répondre à une question
class QuestionWidget extends StatefulWidget {
  final Question question;
  final Answer? initialAnswer;
  final ValueChanged<Answer> onChanged;

  const QuestionWidget({
    super.key,
    required this.question,
    this.initialAnswer,
    required this.onChanged,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  Answer? _currentAnswer;

  @override
  void initState() {
    super.initState();
    _currentAnswer = widget.initialAnswer;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Texte de la question
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.question.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.question.required) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Colors.red, size: 16),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Champ de réponse selon le type
            _buildAnswerField(context),
          ],
        ),
      ),
    );
  }

  /// Construit le champ de réponse en fonction du type de question
  Widget _buildAnswerField(BuildContext context) {
    switch (widget.question.type) {
      case QuestionType.text:
        return _buildTextField();
      case QuestionType.number:
        return _buildNumberField();
      case QuestionType.boolean:
        return _buildBooleanField();
      case QuestionType.select:
        return _buildSelectField();
      case QuestionType.multiselect:
      case QuestionType.checkbox:
        return _buildCheckboxField();
      case QuestionType.scale:
        return _buildScaleField();
      case QuestionType.ranking:
        return _buildRankingField();
      case QuestionType.table:
        return _buildTableField();
    }
  }

  /// Champ de texte
  Widget _buildTextField() {
    final initialValue = _currentAnswer is TextAnswer 
        ? (_currentAnswer as TextAnswer).value 
        : '';

    return TextFormField(
      initialValue: initialValue,
      maxLength: widget.question.maxLength,
      decoration: InputDecoration(
        labelText: widget.question.placeholder,
        border: const OutlineInputBorder(),
        hintText: widget.question.placeholder,
      ),
      maxLines: widget.question.maxLength != null && widget.question.maxLength! > 100 
          ? 5 
          : null,
      onChanged: (value) {
        _currentAnswer = TextAnswer(value);
        widget.onChanged(_currentAnswer!);
      },
    );
  }

  /// Champ numérique
  Widget _buildNumberField() {
    final initialValue = _currentAnswer is NumberAnswer 
        ? (_currentAnswer as NumberAnswer).value.toString() 
        : '';

    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: 'Valeur',
        border: const OutlineInputBorder(),
        hintText: widget.question.min != null && widget.question.max != null
            ? 'Entre ${widget.question.min} et ${widget.question.max}'
            : null,
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        if (value.isNotEmpty) {
          _currentAnswer = NumberAnswer(num.parse(value));
          widget.onChanged(_currentAnswer!);
        }
      },
    );
  }

  /// Champ booléen (Oui/Non)
  Widget _buildBooleanField() {
    final initialValue = _currentAnswer is BooleanAnswer 
        ? (_currentAnswer as BooleanAnswer).value 
        : false;

    final trueLabel = widget.question.trueLabel ?? 'Oui';
    final falseLabel = widget.question.falseLabel ?? 'Non';

    return Row(
      children: [
        Expanded(
          child: RadioListTile<bool>(
            title: Text(trueLabel),
            value: true,
            groupValue: initialValue,
            onChanged: (value) {
              setState(() {
                _currentAnswer = BooleanAnswer(value ?? false);
                widget.onChanged(_currentAnswer!);
              });
            },
          ),
        ),
        Expanded(
          child: RadioListTile<bool>(
            title: Text(falseLabel),
            value: false,
            groupValue: initialValue,
            onChanged: (value) {
              setState(() {
                _currentAnswer = BooleanAnswer(value ?? false);
                widget.onChanged(_currentAnswer!);
              });
            },
          ),
        ),
      ],
    );
  }

  /// Champ de sélection unique
  Widget _buildSelectField() {
    final initialValue = _currentAnswer is SelectAnswer 
        ? (_currentAnswer as SelectAnswer).value 
        : null;

    final options = widget.question.options ?? [];

    if (options.isEmpty) {
      return const Text('Aucune option disponible');
    }

    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: const InputDecoration(
        labelText: 'Sélectionnez une option',
        border: OutlineInputBorder(),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _currentAnswer = SelectAnswer(value);
          widget.onChanged(_currentAnswer!);
        }
      },
    );
  }

  /// Champ cases à cocher / sélection multiple
  Widget _buildCheckboxField() {
    final initialValues = _currentAnswer is CheckboxAnswer || 
                           _currentAnswer is MultiSelectAnswer
        ? (_currentAnswer as dynamic).value as List<String>? 
        : [];

    final options = widget.question.options ?? [];

    if (options.isEmpty) {
      return const Text('Aucune option disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((option) {
        final isSelected = initialValues?.contains(option) ?? false;
        
        return CheckboxListTile(
          title: Text(option),
          value: isSelected,
          onChanged: (value) {
            setState(() {
              final newValues = List<String>.from(initialValues ?? []);
              if (value == true) {
                newValues.add(option);
              } else {
                newValues.remove(option);
              }
              
              _currentAnswer = widget.question.type == QuestionType.checkbox
                  ? CheckboxAnswer(newValues)
                  : MultiSelectAnswer(newValues);
              widget.onChanged(_currentAnswer!);
            });
          },
        );
      }).toList(),
    );
  }

  /// Champ échelle de notation
  Widget _buildScaleField() {
    final initialValue = _currentAnswer is ScaleAnswer 
        ? (_currentAnswer as ScaleAnswer).value 
        : null;

    final min = widget.question.min ?? 1;
    final max = widget.question.max ?? 5;
    final labels = widget.question.labels;

    // Si aucune valeur initiale, utiliser la valeur min
    final currentValue = initialValue ?? min;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Slider(
          value: currentValue.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min).toInt(),
          label: labels?[currentValue] ?? currentValue.toString(),
          onChanged: (value) {
            setState(() {
              _currentAnswer = ScaleAnswer(value.toInt());
              widget.onChanged(_currentAnswer!);
            });
          },
        ),
        // Afficher les libellés
        if (labels != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.entries.map((entry) {
              return Text(
                entry.value,
                style: const TextStyle(fontSize: 12),
              );
            }).toList(),
          ),
        ],
        // Valeur actuelle
        Text(
          'Valeur: $currentValue',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// Champ de classement
  Widget _buildRankingField() {
    final initialRankings = _currentAnswer is RankingAnswer 
        ? (_currentAnswer as RankingAnswer).value 
        : {};

    final options = widget.question.options ?? [];

    if (options.isEmpty) {
      return const Text('Aucune option disponible');
    }

    // Créer une liste de tuples (option, rank) triée par rank
    final rankedOptions = <(String, int)>[];
    for (final option in options) {
      final rank = initialRankings[option] ?? 0;
      rankedOptions.add((option, rank));
    }

    // Trier par rank (1 = plus important)
    rankedOptions.sort((a, b) => a.$2.compareTo(b.$2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Classer par ordre d\'importance (1 = le plus important)',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          itemCount: rankedOptions.length,
          itemBuilder: (context, index) {
            final (option, rank) = rankedOptions[index];
            
            return ListTile(
              key: Key(option),
              title: Text(option),
              trailing: SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: rank == 0 ? '' : rank.toString(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      final newRank = int.tryParse(value) ?? 0;
                      rankedOptions[index] = (option, newRank);
                      
                      // Mettre à jour la réponse
                      final newRankings = <String, int>{};
                      for (final (opt, r) in rankedOptions) {
                        if (r > 0) newRankings[opt] = r;
                      }
                      
                      _currentAnswer = RankingAnswer(newRankings);
                      widget.onChanged(_currentAnswer!);
                    });
                  },
                ),
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = rankedOptions.removeAt(oldIndex);
              rankedOptions.insert(newIndex, item);
              
              // Mettre à jour les ranks
              for (int i = 0; i < rankedOptions.length; i++) {
                final (option, _) = rankedOptions[i];
                rankedOptions[i] = (option, i + 1);
              }
              
              // Mettre à jour la réponse
              final newRankings = <String, int>{};
              for (final (opt, r) in rankedOptions) {
                newRankings[opt] = r;
              }
              
              _currentAnswer = RankingAnswer(newRankings);
              widget.onChanged(_currentAnswer!);
            });
          },
        ),
      ],
    );
  }

  /// Champ tableau
  Widget _buildTableField() {
    final initialRows = _currentAnswer is TableAnswer 
        ? (_currentAnswer as TableAnswer).value 
        : [];

    final columns = widget.question.columns ?? [];

    if (columns.isEmpty) {
      return const Text('Aucune colonne définie');
    }

    // Créer une liste modifiable des lignes
    final rows = List<Map<String, dynamic>>.from(initialRows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // En-tête du tableau
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            border: Border.all(color: Colors.grey),
          ),
          child: Row(
            children: columns.map((column) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    column.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Lignes du tableau
        Column(
          children: rows.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final row = entry.value;
            
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.only(top: 4),
              child: Row(
                children: columns.asMap().entries.map((colEntry) {
                  final colIndex = colEntry.key;
                  final column = colEntry.value;
                  final cellKey = column.name;
                  final cellValue = row[cellKey];
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildTableCell(column, cellValue, (newValue) {
                        setState(() {
                          row[cellKey] = newValue;
                          rows[rowIndex] = row;
                          _currentAnswer = TableAnswer(List.from(rows));
                          widget.onChanged(_currentAnswer!);
                        });
                      }),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
        
        // Bouton pour ajouter une ligne
        if (widget.question.allowAddRows) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une ligne'),
            onPressed: () {
              setState(() {
                final newRow = <String, dynamic>{};
                for (final column in columns) {
                  newRow[column.name] = null;
                }
                rows.add(newRow);
                _currentAnswer = TableAnswer(List.from(rows));
                widget.onChanged(_currentAnswer!);
              });
            },
          ),
        ],
      ],
    );
  }

  /// Construit une cellule de tableau en fonction du type de colonne
  Widget _buildTableCell(
    TableColumn column,
    dynamic value,
    ValueChanged<dynamic> onChanged,
  ) {
    switch (column.type) {
      case QuestionType.text:
        return TextFormField(
          initialValue: value as String? ?? '',
          onChanged: (newValue) => onChanged(newValue),
          decoration: const InputDecoration(isDense: true),
        );
      case QuestionType.number:
        return TextFormField(
          initialValue: value?.toString() ?? '',
          keyboardType: TextInputType.number,
          onChanged: (newValue) => onChanged(num.tryParse(newValue) ?? 0),
          decoration: const InputDecoration(isDense: true),
        );
      case QuestionType.boolean:
        return Switch(
          value: value as bool? ?? false,
          onChanged: (newValue) => onChanged(newValue),
        );
      case QuestionType.select:
        final options = column.options ?? [];
        return DropdownButtonFormField<String>(
          initialValue: value as String?,
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (newValue) => onChanged(newValue),
          isDense: true,
        );
      case QuestionType.checkbox:
      case QuestionType.multiselect:
        final options = column.options ?? [];
        final selectedValues = (value as List<String>?) ?? [];
        return Column(
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return CheckboxListTile(
              title: Text(option),
              value: isSelected,
              onChanged: (newValue) {
                if (newValue == true) {
                  selectedValues.add(option);
                } else {
                  selectedValues.remove(option);
                }
                onChanged(List.from(selectedValues));
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        );
      default:
        return Text(value?.toString() ?? '');
    }
  }
}
