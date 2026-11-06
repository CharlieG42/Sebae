import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_family.dart';
import '../models/technical_product.dart';
import '../models/validation_status.dart';
import '../services/technical_product_service.dart';

class TechnicalProductsHome extends StatefulWidget {
  final TechnicalProductService? service;
  const TechnicalProductsHome({super.key, this.service});

  @override
  State<TechnicalProductsHome> createState() => _TechnicalProductsHomeState();
}

class _TechnicalProductsHomeState extends State<TechnicalProductsHome> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ProductFamily? _selectedFamily;
  String? _selectedTag;
  String? _selectedApplication;
  ValidationStatus? _selectedStatus;
  ConfidenceLevel? _selectedConfidence;

  @override
  Widget build(BuildContext context) {
    final service = widget.service ?? context.watch<TechnicalProductService>();
    final products = service.searchAdvanced(
      query: _searchController.text,
      family: _selectedFamily,
      tag: _selectedTag,
      application: _selectedApplication,
      status: _selectedStatus,
      confidenceLevel: _selectedConfidence,
    );
    final families = ProductFamily.values;
    final tags = service.products
        .expand((product) => product.tags)
        .toSet()
        .toList();
    final applications = service.products
        .expand((product) => product.applications)
        .toSet()
        .toList();
    final statuses = ValidationStatus.values;
    final confidenceLevels = ConfidenceLevel.values;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits techniques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'À propos du module',
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un produit, une famille ou un mot-clé',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Famille dropdown
                  DropdownButton<ProductFamily?>(
                    value: _selectedFamily,
                    hint: const Text('Famille'),
                    items: [
                      const DropdownMenuItem<ProductFamily?>(
                        value: null,
                        child: Text('Toutes'),
                      ),
                      ...families.map(
                        (value) => DropdownMenuItem<ProductFamily?>(
                          value: value,
                          child: Text(value.displayName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedFamily = value);
                    },
                  ),
                  const SizedBox(width: 8),
                  
                  // Tag dropdown
                  DropdownButton<String?>(
                    value: _selectedTag,
                    hint: const Text('Tag'),
                    items: ['']
                        .followedBy(tags)
                        .map(
                          (value) => DropdownMenuItem<String?>(
                            value: value.isEmpty ? null : value,
                            child: Text(value.isEmpty ? 'Tous' : value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedTag = value);
                    },
                  ),
                  const SizedBox(width: 8),
                  
                  // Application dropdown
                  DropdownButton<String?>(
                    value: _selectedApplication,
                    hint: const Text('Usage'),
                    items: ['']
                        .followedBy(applications)
                        .map(
                          (value) => DropdownMenuItem<String?>(
                            value: value.isEmpty ? null : value,
                            child: Text(value.isEmpty ? 'Tous' : value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedApplication = value);
                    },
                  ),
                  const SizedBox(width: 8),
                  
                  // Status dropdown
                  DropdownButton<ValidationStatus?>(
                    value: _selectedStatus,
                    hint: const Text('Statut'),
                    items: [
                      const DropdownMenuItem<ValidationStatus?>(
                        value: null,
                        child: Text('Tous'),
                      ),
                      ...statuses.map(
                        (value) => DropdownMenuItem<ValidationStatus?>(
                          value: value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: value.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(value.displayName),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStatus = value);
                    },
                  ),
                  const SizedBox(width: 8),
                  
                  // Confidence level dropdown
                  DropdownButton<ConfidenceLevel?>(
                    value: _selectedConfidence,
                    hint: const Text('Confiance'),
                    items: [
                      const DropdownMenuItem<ConfidenceLevel?>(
                        value: null,
                        child: Text('Tous'),
                      ),
                      ...confidenceLevels.map(
                        (value) => DropdownMenuItem<ConfidenceLevel?>(
                          value: value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: value.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(value.displayName),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedConfidence = value);
                    },
                  ),
                  const SizedBox(width: 8),
                  
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _selectedFamily = null;
                        _selectedTag = null;
                        _selectedApplication = null;
                        _selectedStatus = null;
                        _selectedConfidence = null;
                      });
                    },
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Quick stats
            if (service.products.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                    label: 'Total',
                    value: service.products.length.toString(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _StatChip(
                    label: 'Validé',
                    value: service.validatedProducts.length.toString(),
                    color: Colors.green,
                  ),
                  _StatChip(
                    label: 'À revoir',
                    value: service.productsToReview.length.toString(),
                    color: Colors.orange,
                  ),
                  _StatChip(
                    label: 'Auto',
                    value: service.autoExtractedProducts.length.toString(),
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            Expanded(
              child: products.isEmpty
                  ? _EmptyState(
                      hasFilters: _selectedFamily != null ||
                          _selectedTag != null ||
                          _selectedApplication != null ||
                          _selectedStatus != null ||
                          _selectedConfidence != null ||
                          _searchController.text.isNotEmpty,
                    )
                  : ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _ProductCard(
                          product: product,
                          onEdit: () => _editProduct(context, product),
                          onDelete: () => _deleteProduct(context, product),
                          onValidate: () => _showValidationDialog(context, product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import',
            onPressed: () => _importPowerPoint(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('Importer PowerPoint'),
          ),
          const SizedBox(height: 8),
          if (service.products.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'stats',
              onPressed: () => _showStatisticsDialog(context, service),
              icon: const Icon(Icons.analytics),
              label: const Text('Statistiques'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
        ],
      ),
    );
  }

  Future<void> _importPowerPoint(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final service = widget.service ?? context.read<TechnicalProductService>();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['ppt', 'pptx'],
    );

    if (result.isEmpty) {
      return;
    }

    final file = result.first;
    final bytes = await file.readAsBytes();

    try {
      await service.importFromPowerPoint(
        sourceName: file.name,
        bytes: bytes,
      );

      messenger?.showSnackBar(
        SnackBar(content: Text('Fiche importée : ${file.name}')),
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text("Erreur lors de l'import : $e")),
      );
    }
  }

  Future<void> _showValidationDialog(BuildContext context, TechnicalProduct product) async {
    final service = widget.service ?? context.read<TechnicalProductService>();
    final result = await showDialog<ValidationStatus?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Valider la fiche : ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Statut actuel : ${product.validationStatus.displayName}'),
              const SizedBox(height: 16),
              const Text('Nouveau statut :'),
              const SizedBox(height: 8),
              ...ValidationStatus.values.map((status) => ListTile(
                    title: Text(status.displayName),
                    subtitle: Text(status.description),
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    trailing: product.validationStatus == status 
                        ? const Icon(Icons.check_circle, color: Colors.green) 
                        : null,
                    onTap: () => Navigator.of(dialogContext).pop(status),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await service.validateProduct(product.id, 'Utilisateur', result);
    }
  }

  Future<void> _showStatisticsDialog(BuildContext context, TechnicalProductService service) async {
    final families = ProductFamily.values;
    final statuses = ValidationStatus.values;
    final confidenceLevels = ConfidenceLevel.values;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Statistiques du module'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Par famille :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...families.map((family) {
                    final count = service.getProductsByFamily(family).length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text('${family.displayName}: '),
                          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text('Par statut :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...statuses.map((status) {
                    final products = service.products.where((p) => p.validationStatus == status).toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text('${status.displayName}: '),
                          Text('${products.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text('Par niveau de confiance :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...confidenceLevels.map((level) {
                    final products = service.getProductsByConfidence(level);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: level.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text('${level.displayName}: '),
                          Text('${products.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text('Score d\'extraction moyen :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    service.products.isEmpty 
                        ? 'Aucun produit' 
                        : '${(service.products.fold<int>(0, (sum, p) => sum + p.extractionScore) / service.products.length).toStringAsFixed(1)} / 100',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('À propos du module Produits techniques'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('''
Ce module permet de centraliser, organiser et exploiter les informations techniques des produits à partir de fichiers PowerPoint.

Fonctionnalités principales :
'''),
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Import de fichiers PowerPoint (.ppt, .pptx)'),
                      Text('• Extraction automatique des informations techniques'),
                      Text('• Catégorisation par famille de produits'),
                      Text('• Détection des applications, normes et métriques'),
                      Text('• Calcul du niveau de confiance de l\'extraction'),
                      Text('• Gestion des statuts de validation'),
                      Text('• Correction manuelle des fiches'),
                      Text('• Recherche et filtrage avancé'),
                      Text('• Statistiques et analyses'),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('''
Niveaux de confiance :
• Très élevée (90-100) : Extraction complète et fiable
• Élevée (70-89) : Bonne extraction avec quelques éléments
• Moyenne (50-69) : Extraction partielle
• Faible (30-49) : Peu d'informations extraites
• Très faible (0-29) : Extraction minimale

Statuts de validation :
• Auto-extrait : Importé automatiquement, non validé
• À revoir : Nécessite une validation manuelle
• Validé : Vérifié et approuvé
• Modifié : Modifié manuellement après extraction
'''),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editProduct(BuildContext context, TechnicalProduct product) async {
    final service = widget.service ?? context.read<TechnicalProductService>();
    final nameController = TextEditingController(text: product.name);
    final familyController = TextEditingController(text: product.productFamily.displayName);
    final summaryController = TextEditingController(text: product.summary);
    final tagsController = TextEditingController(
      text: product.tags.join(', '),
    );
    final applicationsController = TextEditingController(
      text: product.applications.join(', '),
    );
    final keyFactsController = TextEditingController(
      text: product.keyFacts.join('\n'),
    );
    final characteristicsController = TextEditingController(
      text: product.characteristics.join('\n'),
    );
    final standardsController = TextEditingController(
      text: product.standards.join(', '),
    );
    final metricsController = TextEditingController(
      text: product.metrics.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n'),
    );
    final notesController = TextEditingController(text: product.notes ?? '');

    ValidationStatus? selectedStatus = product.validationStatus;
    ConfidenceLevel? selectedConfidence = product.confidenceLevel;
    final validatorController = TextEditingController(text: product.validatorName ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Modifier : ${product.name}'),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom du produit'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProductFamily>(
                    initialValue: product.productFamily,
                    decoration: const InputDecoration(labelText: 'Famille'),
                    items: ProductFamily.values.map((family) {
                      return DropdownMenuItem<ProductFamily>(
                        value: family,
                        child: Text(family.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        familyController.text = value.displayName;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: summaryController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Résumé'),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Validation et Confiance',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ValidationStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Statut de validation'),
                    items: ValidationStatus.values.map((status) {
                      return DropdownMenuItem<ValidationStatus>(
                        value: status,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: status.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(status.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedStatus = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ConfidenceLevel>(
                    initialValue: selectedConfidence,
                    decoration: const InputDecoration(labelText: 'Niveau de confiance'),
                    items: ConfidenceLevel.values.map((level) {
                      return DropdownMenuItem<ConfidenceLevel>(
                        value: level,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: level.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(level.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedConfidence = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: validatorController,
                    decoration: const InputDecoration(labelText: 'Validateur'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Notes sur la fiche ou l\'extraction',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Correction manuelle et organisation',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (séparés par virgules / retours)',
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: applicationsController,
                    decoration: const InputDecoration(
                      labelText: 'Applications (séparées par virgules)',
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyFactsController,
                    decoration: const InputDecoration(
                      labelText: 'Informations clés (une ligne = un élément)',
                    ),
                    minLines: 4,
                    maxLines: 10,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: characteristicsController,
                    decoration: const InputDecoration(
                      labelText: 'Caractéristiques (une ligne = un élément)',
                    ),
                    minLines: 4,
                    maxLines: 10,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: standardsController,
                    decoration: const InputDecoration(
                      labelText: 'Normes (séparées par virgules)',
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: metricsController,
                    decoration: const InputDecoration(
                      labelText: 'Métriques (format: libellé: valeur, une ligne par item)',
                    ),
                    minLines: 4,
                    maxLines: 8,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // Update product
    product.name = nameController.text.trim();
    product.productFamily = ProductFamily.fromName(familyController.text.trim());
    product.summary = summaryController.text.trim();
    product.technicalSummary = product.summary;
    product.tags = _parseListField(tagsController.text);
    product.applications = _parseListField(applicationsController.text);
    product.keyFacts = _parseMultilineField(keyFactsController.text);
    product.characteristics = _parseMultilineField(characteristicsController.text);
    product.standards = _parseListField(standardsController.text);
    product.metrics = _parseMetricsField(metricsController.text);
    product.notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();
    
    // Update validation and confidence
    product.validationStatus = selectedStatus ?? product.validationStatus;
    product.confidenceLevel = selectedConfidence ?? product.confidenceLevel;
    product.validatorName = validatorController.text.trim().isEmpty ? null : validatorController.text.trim();

    await service.updateProduct(product);
  }

  Future<void> _deleteProduct(BuildContext context, TechnicalProduct product) async {
    final service = widget.service ?? context.read<TechnicalProductService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la fiche ?'),
        content: Text('Voulez-vous supprimer ${product.name} ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await service.deleteProduct(product.id);
    }
  }

  static List<String> _parseListField(String value) {
    return value
        .split(RegExp(r'[\n,;]'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  static List<String> _parseMultilineField(String value) {
    return value
        .split(RegExp(r'\r?\n'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  static Map<String, String> _parseMetricsField(String value) {
    final metrics = <String, String>{};

    for (final line in value.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final index = trimmed.indexOf(':');
      if (index <= 0) {
        continue;
      }

      final key = trimmed.substring(0, index).trim();
      final metricValue = trimmed.substring(index + 1).trim();
      if (key.isNotEmpty && metricValue.isNotEmpty) {
        metrics[key] = metricValue;
      }
    }

    return metrics;
  }
}

class _ProductCard extends StatelessWidget {
  final TechnicalProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onValidate;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          // Confidence level indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: product.confidenceColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              product.confidenceLevel.displayName,
                              style: TextStyle(
                                color: product.confidenceColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: product.statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              product.validationStatus.displayName,
                              style: TextStyle(
                                color: product.statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            product.productFamily.displayName,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          if (product.extractionScore > 0) ...[
                            const SizedBox(width: 16),
                            Text(
                              'Score: ${product.extractionScore}/100',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Modifier',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Valider',
                      onPressed: onValidate,
                      icon: const Icon(Icons.check_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(product.summary),
            const SizedBox(height: 12),
            if (product.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 12),
            if (product.applications.isNotEmpty) ...[
              Text(
                'Applications',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.applications
                    .map(
                      (application) => Chip(
                        label: Text(application),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .tertiaryContainer,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (product.keyFacts.isNotEmpty) ...[
              Text(
                'Informations clés',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: product.keyFacts
                    .map(
                      (fact) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(fact)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (product.metrics.isNotEmpty) ...[
              Text(
                'Métriques',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.metrics.entries
                    .map(
                      (entry) => Chip(
                        label: Text('${entry.key} : ${entry.value}'),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondaryContainer,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (product.standards.isNotEmpty) ...[
              Text(
                'Normes',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.standards
                    .map(
                      (standard) => Chip(
                        label: Text(standard),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (product.characteristics.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.characteristics
                      .map(
                        (characteristic) => Chip(
                          label: Text(characteristic),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                        ),
                      )
                      .toList(),
                ),
              ),
            if (product.notes != null && product.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(product.notes!),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.sourceFileName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${product.createdAt.day.toString().padLeft(2, '0')}/${product.createdAt.month.toString().padLeft(2, '0')}/${product.createdAt.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (product.extractedText.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Données brutes',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      product.extractedText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;

  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_books_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              hasFilters 
                  ? 'Aucun produit ne correspond aux critères de recherche' 
                  : 'Aucune fiche technique pour le moment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters 
                  ? 'Essayez de modifier les filtres pour obtenir des résultats' 
                  : 'Importez un PowerPoint pour créer une fiche technique et commencer à organiser les informations produit.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
