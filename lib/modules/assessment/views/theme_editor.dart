import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/assessment_structure_service.dart';
import '../models/theme.dart' as assessment_theme;

/// Dialogue d'édition d'un thème
class ThemeEditorDialog extends StatefulWidget {
  final assessment_theme.Theme? theme;
  final VoidCallback onSaved;

  const ThemeEditorDialog({
    super.key,
    this.theme,
    required this.onSaved,
  });

  @override
  State<ThemeEditorDialog> createState() => _ThemeEditorDialogState();
}

class _ThemeEditorDialogState extends State<ThemeEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _orderController;

  @override
  void initState() {
    super.initState();
    
    _titleController = TextEditingController(
      text: widget.theme?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.theme?.description ?? '',
    );
    _orderController = TextEditingController(
      text: widget.theme?.order.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.theme == null;

    return AlertDialog(
      title: Text(isNew ? 'Ajouter un Thème' : 'Éditer le Thème'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  hintText: 'Ex: Connaissance Technique',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le titre est obligatoire';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Description du thème...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(
                  labelText: 'Ordre',
                  hintText: 'Position dans la liste',
                ),
                keyboardType: TextInputType.number,
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

            final service = Provider.of<AssessmentStructureService>(context, listen: false);

            try {
              if (isNew) {
                await service.addTheme(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  order: _orderController.text.isNotEmpty 
                      ? int.parse(_orderController.text) 
                      : null,
                );
              } else {
                await service.updateTheme(
                  widget.theme!.id,
                  title: _titleController.text,
                  description: _descriptionController.text,
                  order: _orderController.text.isNotEmpty 
                      ? int.parse(_orderController.text) 
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
}
