import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/product_range.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/visit_frame.dart';
import '../services/ssdm_service.dart';

/// Vue de gestion des trames de visite (Visit Frames).
///
/// Permet de :
/// - créer de nouvelles trames de visite
/// - modifier des trames existantes
/// - supprimer des trames
/// - voir quelles visites utilisent une trame
class VisitFrameView extends StatelessWidget {
  const VisitFrameView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SsdmService>();
    final frames = service.visitFrames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trames de Visite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showFrameDialog(context),
            tooltip: 'Nouvelle trame',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (frames.isEmpty)
            EmptyState(
              icon: Icons.description_outlined,
              title: 'Aucune trame de visite',
              message:
                  'Créez des trames de visite pour standardiser vos rendez-vous. '
                  'Une trame peut inclure des Gammes de Produits et des documents supports.',
              actionLabel: 'Nouvelle trame',
              onAction: () => _showFrameDialog(context),
            )
          else
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...frames.map((frame) => _FrameCard(frame: frame)),
              ],
            ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'addFrame',
              onPressed: () => _showFrameDialog(context),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  void _showFrameDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _FrameDialog(),
    );
  }
}

/// Carte d'une trame de visite dans la liste.
class _FrameCard extends StatelessWidget {
  const _FrameCard({required this.frame});

  final VisitFrame frame;

  @override
  Widget build(BuildContext context) {
    final service = context.read<SsdmService>();
    final visitCount = service.visitCountForFrame(frame.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showFrameDetailDialog(context, frame),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      frame.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showFrameDialogForEdit(context, frame),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteFrame(context, frame),
                    tooltip: 'Supprimer',
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (frame.description.isNotEmpty)
                Text(
                  frame.description,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: 8),
              if (frame.hasProductRanges)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    const Icon(Icons.shopping_bag, size: 16),
                    const SizedBox(width: 4),
                    ...(frame.productRangeIds ?? []).map((id) {
                      final pr = service.productRangeOf(id);
                      return Chip(
                        label: Text(pr?.displayName ?? '?'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }),
                  ],
                ),
              const SizedBox(height: 8),
              if (frame.hasSupportDocuments)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    const Icon(Icons.insert_drive_file, size: 16),
                    const SizedBox(width: 4),
                    ...(frame.supportDocumentPaths ?? []).map((docPath) {
                      final fileName = path.basename(docPath);
                      return Chip(
                        label: Text(fileName),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        avatar: const Icon(Icons.insert_drive_file, size: 16),
                      );
                    }),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Créée le ${_formatDate(frame.createdAt)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (visitCount > 0)
                    Chip(
                      label: Text('$visitCount visite(s)'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      avatar: const Icon(Icons.check_circle, size: 16),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFrameDetailDialog(BuildContext context, VisitFrame frame) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(frame.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (frame.description.isNotEmpty) ...[
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(frame.description),
                const SizedBox(height: 12),
              ],
              if (frame.hasProductRanges) ...[
                const Text(
                  'Gammes de Produits',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (frame.productRangeIds ?? [])
                      .map((id) {
                        final service = context.read<SsdmService>();
                        final pr = service.productRangeOf(id);
                        return Chip(
                          label: Text(pr?.displayName ?? '?'),
                          avatar: const Icon(Icons.shopping_bag_outlined, size: 18),
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              if (frame.hasSupportDocuments) ...[
                const Text(
                  'Documents supports',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (frame.supportDocumentPaths ?? [])
                      .map((docPath) {
                        final fileName = path.basename(docPath);
                        return Chip(
                          label: Text(fileName),
                          avatar: const Icon(Icons.insert_drive_file, size: 18),
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteFrame(BuildContext context, VisitFrame frame) async {
    final service = context.read<SsdmService>();
    final visitCount = service.visitCountForFrame(frame.id);

    if (visitCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer la trame'),
          content: Text(
            'Cette trame est utilisée par $visitCount visite(s). '
            'Si vous la supprimez, les visites concernées ne seront plus associées à cette trame. '
            'Souhaitez-vous continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    final scaffoldContext = context;
    await service.deleteVisitFrame(frame);
    if (scaffoldContext.mounted) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(content: Text('Trame supprimée')),
      );
    }
  }

  void _showFrameDialogForEdit(BuildContext context, VisitFrame frame) {
    showDialog<void>(
      context: context,
      builder: (context) => _FrameDialog(frame: frame),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Dialogue de création/modification d'une trame de visite.
class _FrameDialog extends StatefulWidget {
  const _FrameDialog({this.frame});

  final VisitFrame? frame;

  @override
  State<_FrameDialog> createState() => _FrameDialogState();
}

class _FrameDialogState extends State<_FrameDialog> {
  late String _name;
  late String _description;
  late List<String>? _productRangeIds;
  late List<String>? _supportDocumentPaths;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _documentPathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final f = widget.frame;
    _name = f?.name ?? '';
    _description = f?.description ?? '';
    _productRangeIds = f?.productRangeIds ?? [];
    _supportDocumentPaths = f?.supportDocumentPaths ?? [];

    _nameController.text = _name;
    _descriptionController.text = _description;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _documentPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<SsdmService>();

    return AlertDialog(
      title: Text(widget.frame == null ? 'Nouvelle trame' : 'Modifier la trame'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nom
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                  hintText: 'ex. Visite client standard',
                ),
                onChanged: (v) => _name = v,
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Objectif ou description de la trame...',
                  alignLabelWithHint: true,
                ),
                onChanged: (v) => _description = v,
              ),
              const SizedBox(height: 12),

              // Gammes de Produits
              InkWell(
                onTap: () async {
                  final selected = await _showProductRangeMultiSelectDialog(
                    context,
                    selectedIds: _productRangeIds,
                    availableProductRanges: service.productRanges,
                  );
                  if (selected != null) {
                    setState(() => _productRangeIds = selected);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Gammes de Produits à présenter',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.expand_more),
                  ),
                  child: _buildProductRangeDisplay(_productRangeIds, service),
                ),
              ),
              const SizedBox(height: 12),

              // Documents supports - Ajout local
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documents supports locaux',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _documentPathController,
                              decoration: const InputDecoration(
                                labelText: 'Chemin du fichier',
                                border: OutlineInputBorder(),
                                hintText: 'C:\\Dossier\\presentation.pdf',
                              ),
                              onSubmitted: (_) => _addSupportDocument(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: 'Ajouter le fichier',
                            onPressed: _addSupportDocument,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Affichage des documents supports
              if (_supportDocumentPaths != null && _supportDocumentPaths!.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Documents supports sélectionnés',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _supportDocumentPaths!.map((docPath) {
                            final fileName = path.basename(docPath);
                            return Chip(
                              label: Text(fileName),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setState(() => _supportDocumentPaths!.remove(docPath)),
                              avatar: const Icon(Icons.insert_drive_file, size: 18),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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

  Widget _buildProductRangeDisplay(List<String>? productRangeIds, SsdmService service) {
    if (productRangeIds == null || productRangeIds.isEmpty) {
      return const Text('Aucune', style: TextStyle(color: Colors.grey));
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: productRangeIds
          .map((id) => Chip(
                label: Text(service.productRangeOf(id)?.displayName ?? '?'),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ))
          .toList(),
    );
  }

  /// Dialogue de sélection multiple de Gammes de Produits avec cases à cocher.
  Future<List<String>?> _showProductRangeMultiSelectDialog(
    BuildContext context, {
    required List<String>? selectedIds,
    required List<ProductRange> availableProductRanges,
  }) async {
    final selectedSet = (selectedIds ?? []).toSet();

    final result = await showDialog<List<String>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sélectionner les Gammes de Produits'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final pr in availableProductRanges)
                        CheckboxListTile(
                          value: selectedSet.contains(pr.id),
                          title: Text(pr.displayName),
                          subtitle: pr.description.isNotEmpty ? Text(pr.description) : null,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedSet.add(pr.id);
                              } else {
                                selectedSet.remove(pr.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedSet.isEmpty ? null : selectedSet.toList()),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  void _addSupportDocument() {
    final filePath = _documentPathController.text.trim();
    if (filePath.isNotEmpty) {
      setState(() {
        _supportDocumentPaths = (_supportDocumentPaths ?? []).toList()..add(filePath);
        _documentPathController.clear();
      });
    }
  }

  void _submit() {
    final service = context.read<SsdmService>();

    if (_name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est obligatoire')),
      );
      return;
    }

    final frame = VisitFrame(
      id: widget.frame?.id ?? const Uuid().v4(),
      name: _name,
      description: _description,
      productRangeIds: _productRangeIds?.isEmpty == true ? null : _productRangeIds,
      supportDocumentPaths: _supportDocumentPaths?.isEmpty == true ? null : _supportDocumentPaths,
      createdAt: widget.frame?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final scaffoldContext = context;
    if (widget.frame == null) {
      service.addVisitFrame(
        name: frame.name,
        description: frame.description,
        productRangeIds: frame.productRangeIds,
        supportDocumentPaths: frame.supportDocumentPaths,
      ).then((_) {
        if (scaffoldContext.mounted) {
          Navigator.of(scaffoldContext).pop();
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            const SnackBar(content: Text('Trame créée')),
          );
        }
      });
    } else {
      frame.id = widget.frame!.id;
      frame.createdAt = widget.frame!.createdAt;
      service.updateVisitFrame(frame).then((_) {
        if (scaffoldContext.mounted) {
          Navigator.of(scaffoldContext).pop();
          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            const SnackBar(content: Text('Trame mise à jour')),
          );
        }
      });
    }
  }
}
