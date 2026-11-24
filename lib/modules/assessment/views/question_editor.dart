import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../models/question_type.dart';
import '../models/theme.dart' as assessment_theme;
import '../services/assessment_structure_service.dart';

/// Dialogue d'édition d'une question
class QuestionEditorDialog extends StatefulWidget {
  final Question? question;
  final String? themeId;
  final VoidCallback onSaved;

  const QuestionEditorDialog({
    super.key,
    this.question,
    this.themeId,
    required this.onSaved,
  });

  @override
  State<QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<QuestionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late QuestionType _type;
  late TextEditingController _textController;
  late TextEditingController _placeholderController;
  late TextEditingController _maxLengthController;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late TextEditingController _orderController;
  late bool _required;
  
  // Pour les types avec options
  final List<TextEditingController> _optionControllers = [];
  
  // Pour les labels d'échelle
  final Map<int, TextEditingController> _labelControllers = {};
  final List<int> _scaleValues = [];

  @override
  void initState() {
    super.initState();
    
    // Initialiser avec les valeurs existantes ou par défaut
    _type = widget.question?.type ?? QuestionType.text;
    _textController = TextEditingController(text: widget.question?.text ?? '');
    _placeholderController = TextEditingController(text: widget.question?.placeholder ?? '');
    _maxLengthController = TextEditingController(text: widget.question?.maxLength?.toString() ?? '');
    _minController = TextEditingController(text: widget.question?.min?.toString() ?? '');
    _maxController = TextEditingController(text: widget.question?.max?.toString() ?? '');
    _orderController = TextEditingController(text: widget.question?.order.toString() ?? '');
    _required = widget.question?.required ?? false;
    
    // Initialiser les options
    if (widget.question?.options != null) {
      for (final option in widget.question!.options!) {
        _optionControllers.add(TextEditingController(text: option));
      }
    } else {
      _optionControllers.add(TextEditingController());
    }
    
    // Initialiser les labels pour l'échelle
    if (widget.question?.labels != null) {
      for (final entry in widget.question!.labels!.entries) {
        _labelControllers[entry.key] = TextEditingController(text: entry.value);
        _scaleValues.add(entry.key);
      }
    }
    
    // Si c'est une échelle mais qu'il n'y a pas de labels, ajouter les valeurs min/max
    if (_type == QuestionType.scale && _scaleValues.isEmpty) {
      final min = (widget.question?.min ?? 1).toInt();
      final max = (widget.question?.max ?? 5).toInt();
      for (int i = min; i <= max; i++) {
        _scaleValues.add(i);
        _labelControllers[i] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _placeholderController.dispose();
    _maxLengthController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _orderController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    for (final controller in _labelControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.question == null;
    final hasTheme = widget.themeId != null || widget.question != null;

    return AlertDialog(
      title: Text(isNew ? 'Ajouter une Question' : 'Éditer la Question'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type de question
              DropdownButtonFormField<QuestionType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type *',
                ),
                items: QuestionType.values.map((type) {
                  return DropdownMenuItem<QuestionType>(
                    value: type,
                    child: Text(_getTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _type = value!);
                },
              ),
              const SizedBox(height: 12),

              // Texte de la question
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Texte *',
                  hintText: 'Ex: Sur quels équipements vous sentez-vous à l\'aise ?',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le texte est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Options pour les types qui en nécessitent
              if (_needsOptions(_type)) ...[
                const Text(
                  'Options',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._optionControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            setState(() {
                              controller.dispose();
                              _optionControllers.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une option'),
                  onPressed: () {
                    setState(() {
                      _optionControllers.add(TextEditingController());
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Paramètres pour l'échelle
              if (_type == QuestionType.scale) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minController,
                        decoration: const InputDecoration(
                          labelText: 'Valeur min',
                          hintText: '1',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxController,
                        decoration: const InputDecoration(
                          labelText: 'Valeur max',
                          hintText: '5',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Labels pour l\'échelle',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _scaleValues.map((value) {
                    final controller = _labelControllers[value]!;
                    return SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: value.toString(),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Placeholder pour text
              if (_type == QuestionType.text) ...[
                TextFormField(
                  controller: _placeholderController,
                  decoration: const InputDecoration(
                    labelText: 'Placeholder',
                    hintText: 'Ex: Entrer votre réponse ici...',
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Max length pour text
              if (_type == QuestionType.text) ...[
                TextFormField(
                  controller: _maxLengthController,
                  decoration: const InputDecoration(
                    labelText: 'Longueur max',
                    hintText: 'Ex: 500',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
              ],

              // Ordre
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(
                  labelText: 'Ordre',
                  hintText: 'Position dans le thème',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              // Obligatoire
              SwitchListTile(
                title: const Text('Obligatoire'),
                value: _required,
                onChanged: (value) => setState(() => _required = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            if (_needsOptions(_type) && _optionControllers.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez ajouter au moins une option'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final service = Provider.of<AssessmentStructureService>(context, listen: false);

            try {
              // Collecter les options
              final options = _optionControllers
                  .map((c) => c.text)
                  .where((text) => text.isNotEmpty)
                  .toList();

              // Collecter les labels pour l'échelle
              Map<int, String>? labels;
              if (_type == QuestionType.scale) {
                labels = {};
                for (final value in _scaleValues) {
                  final controller = _labelControllers[value];
                  if (controller != null && controller.text.isNotEmpty) {
                    labels[value] = controller.text;
                  }
                }
              }

              // Créer ou mettre à jour la question
              if (isNew) {
                if (!hasTheme) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aucun thème sélectionné'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await service.addQuestion(
                  themeId: widget.themeId!,
                  text: _textController.text,
                  type: _type,
                  required: _required,
                  order: _orderController.text.isNotEmpty 
                      ? int.parse(_orderController.text) 
                      : null,
                  options: options.isNotEmpty ? options : null,
                  min: _minController.text.isNotEmpty 
                      ? num.parse(_minController.text) 
                      : null,
                  max: _maxController.text.isNotEmpty 
                      ? num.parse(_maxController.text) 
                      : null,
                  labels: labels?.isNotEmpty == true ? labels : null,
                  placeholder: _placeholderController.text.isNotEmpty 
                      ? _placeholderController.text 
                      : null,
                  maxLength: _maxLengthController.text.isNotEmpty 
                      ? int.parse(_maxLengthController.text) 
                      : null,
                );
              } else {
                await service.updateQuestion(
                  questionId: widget.question!.id,
                  text: _textController.text,
                  type: _type,
                  required: _required,
                  order: _orderController.text.isNotEmpty 
                      ? int.parse(_orderController.text) 
                      : null,
                  options: options.isNotEmpty ? options : null,
                  min: _minController.text.isNotEmpty 
                      ? num.parse(_minController.text) 
                      : null,
                  max: _maxController.text.isNotEmpty 
                      ? num.parse(_maxController.text) 
                      : null,
                  labels: labels?.isNotEmpty == true ? labels : null,
                  placeholder: _placeholderController.text.isNotEmpty 
                      ? _placeholderController.text 
                      : null,
                  maxLength: _maxLengthController.text.isNotEmpty 
                      ? int.parse(_maxLengthController.text) 
                      : null,
                );
              }

              widget.onSaved();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Text(isNew ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }

  /// Obtenir le label pour un type de question
  String _getTypeLabel(QuestionType type) {
    return switch (type) {
      QuestionType.text => 'Texte libre',
      QuestionType.number => 'Nombre',
      QuestionType.boolean => 'Oui/Non',
      QuestionType.select => 'Choix unique',
      QuestionType.multiselect => 'Sélection multiple',
      QuestionType.checkbox => 'Cases à cocher',
      QuestionType.scale => 'Échelle',
      QuestionType.ranking => 'Classement',
      QuestionType.table => 'Tableau',
    };
  }

  /// Vérifier si le type nécessite des options
  bool _needsOptions(QuestionType type) {
    return switch (type) {
      QuestionType.select ||
      QuestionType.multiselect ||
      QuestionType.checkbox ||
      QuestionType.ranking => true,
      _ => false,
    };
  }
}
