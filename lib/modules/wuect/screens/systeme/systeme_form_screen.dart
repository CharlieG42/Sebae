import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../models/aide.dart';
import '../../models/systeme.dart';
import '../../models/pompe.dart';
import '../../services/database_service.dart';
import '../../utils/error_handler.dart';
import 'pompe_form_screen.dart';

class SystemeFormScreen extends StatefulWidget {
  final int projetId;
  final int? systemeId;
  final String? nomSysteme;

  const SystemeFormScreen({
    super.key,
    required this.projetId,
    this.systemeId,
    this.nomSysteme,
  });

  @override
  State<SystemeFormScreen> createState() => _SystemeFormScreenState();
}

class _SystemeFormScreenState extends State<SystemeFormScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _coutInvestissementController =
      TextEditingController();

  List<Pompe> _pompes = [];
  List<Aide> _aides = [];
  double _esTotal = 0.0; // Énergie spécifique totale précalculée
  bool _isLoading = true;
  bool _isNew = true;
  int? _systemeId;
  bool _systemeSaved = false; // Devient true une fois le système sauvegardé

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final bool isExistingSystem =
          widget.systemeId != null || _systemeId != null;

      if (widget.systemeId != null) {
        final systeme = await _db.getSystemeById(widget.systemeId!);
        if (systeme != null) {
          _systemeId = systeme.id;
          _nomController.text = systeme.nom;
          _coutInvestissementController.text = systeme.coutInvestissementTotal
              .toString();
          _aides = List<Aide>.from(systeme.aides);
        }
      } else if (_systemeId != null) {
        // Système nouvellement créé, charger ses données
        final systeme = await _db.getSystemeById(_systemeId!);
        if (systeme != null) {
          _nomController.text = systeme.nom;
          _coutInvestissementController.text = systeme.coutInvestissementTotal
              .toString();
          _aides = List<Aide>.from(systeme.aides);
        }
      } else {
        _nomController.text = widget.nomSysteme ?? '';
        _coutInvestissementController.text = '0.0';
        _aides = [];
      }

      if (_systemeId != null) {
        final pompes = await _db.getPompesBySystemeId(_systemeId!);
        final esTotal = _calculerEsTotalFromList(pompes);
        setState(() {
          _pompes = pompes;
          _esTotal = esTotal;
        });
      } else {
        setState(() {
          _pompes = [];
          _esTotal = 0.0;
        });
      }

      // Mettre à jour les flags après chargement
      _isNew = !isExistingSystem;
      _systemeSaved = isExistingSystem;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showSnackBar(
          context,
          'Erreur de chargement: $e',
          error: true,
        );
      }
    }
  }

  Future<void> _saveSysteme() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Calculer le coût total depuis les pompes
      final coutTotal = _calculerCoutInvestissementTotal();

      final systeme = Systeme(
        id: _systemeId,
        projetId: widget.projetId,
        nom: _nomController.text,
        coutInvestissementTotal: coutTotal,
        aides: _aides,
      );

      if (_isNew) {
        _systemeId = await _db.insertSysteme(systeme);
        if (mounted) {
          ErrorHandler.showSnackBar(
            context,
            'Système créé avec succès. Ajoutez des pompes maintenant.',
          );
        }
      } else {
        await _db.updateSysteme(systeme);
        if (mounted) {
          ErrorHandler.showSnackBar(context, 'Système mis à jour');
        }
      }

      // Rafraîchir les données après sauvegarde (pour mettre à jour _isNew, _systemeSaved, etc.)
      await _loadData();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showSnackBar(
          context,
          'Erreur de sauvegarde: $e',
          error: true,
        );
      }
    }
  }

  Future<void> _deletePompe(int pompeId) async {
    try {
      await _db.deletePompe(pompeId);
      if (mounted) {
        ErrorHandler.showSnackBar(context, 'Pompe supprimée avec succès');
        await _loadData();
        // Mettre à jour le coût total et l'Es total après suppression
        _updateCoutInvestissement();
        setState(() => _esTotal = _calculerEsTotalFromList(_pompes));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBar(
          context,
          'Erreur de suppression: $e',
          error: true,
        );
      }
    }
  }

  double _calculerCoutInvestissementTotal() {
    if (_pompes.isEmpty) return 0.0;
    return _pompes.fold(0.0, (sum, p) => sum + p.coutInvestissement);
  }

  // Calcul de l'Es total à partir d'une liste de pompes
  double _calculerEsTotalFromList(List<Pompe> pompes) {
    if (pompes.isEmpty) return 0.0;
    return pompes.fold(0.0, (sum, p) => sum + p.energieSpecifique);
  }

  // Utilise la valeur précalculée
  double _calculerEsTotal() {
    return _esTotal;
  }

  double get _totalAides => _aides.fold(0.0, (sum, aide) => sum + aide.montant);

  double get _coutNet => (_calculerCoutInvestissementTotal() - _totalAides)
      .clamp(0.0, double.infinity);

  void _updateCoutInvestissement() {
    final coutTotal = _calculerCoutInvestissementTotal();
    _coutInvestissementController.text = coutTotal.toStringAsFixed(2);
  }

  void _showAideDialog({Aide? aide, int? index}) {
    final montantController = TextEditingController(
      text: (aide?.montant ?? 0.0).toStringAsFixed(2),
    );
    final descriptionController = TextEditingController(
      text: aide?.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(aide == null ? 'Ajouter une aide' : 'Modifier l’aide'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: montantController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Montant (EUR)',
                    prefixIcon: Icon(Icons.monetization_on),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final montant =
                    double.tryParse(
                      montantController.text.replaceAll(',', '.'),
                    ) ??
                    0.0;
                final description = descriptionController.text.trim();

                if (description.isEmpty) {
                  ErrorHandler.showSnackBar(
                    context,
                    'La description de l’aide est obligatoire.',
                    error: true,
                  );
                  return;
                }

                if (montant <= 0) {
                  ErrorHandler.showSnackBar(
                    context,
                    'Le montant de l’aide doit être supérieur à 0.',
                    error: true,
                  );
                  return;
                }

                final nouvelAide = Aide(
                  nom: 'Aide ${index != null ? index + 1 : _aides.length + 1}',
                  montant: montant,
                  description: description,
                );

                setState(() {
                  if (index == null) {
                    _aides.add(nouvelAide);
                  } else {
                    _aides[index] = nouvelAide;
                  }
                });

                Navigator.pop(context, true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAideConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l’aide'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette aide ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _aides.removeAt(index));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndExit() async {
    // Sauvegarder le système avec le coût calculé
    if (_systemeId == null) {
      // Pas de système, on ne peut pas valider
      if (mounted) {
        ErrorHandler.showSnackBar(
          context,
          'Veuillez d\'abord créer le système',
          error: true,
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final coutTotal = _calculerCoutInvestissementTotal();

      final systeme = Systeme(
        id: _systemeId,
        projetId: widget.projetId,
        nom: _nomController.text,
        coutInvestissementTotal: coutTotal,
        aides: _aides,
      );

      await _db.updateSysteme(systeme);

      if (mounted) {
        // Retourner à la page précédente avec succès
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showSnackBar(context, 'Erreur: $e', error: true);
      }
    }
  }

  Future<void> _navigateToPompeForm(int? pompeId) async {
    // Vérifier qu'on a bien un système sauvegardé
    if (_systemeId == null) {
      ErrorHandler.showSnackBar(
        context,
        'Veuillez sauvegarder le système d\'abord',
        error: true,
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PompeFormScreen(systemeId: _systemeId!, pompeId: pompeId),
      ),
    );

    if (result == true) {
      await _loadData();
      // Mettre à jour le coût total et l'Es total après ajout/modification de pompe
      _updateCoutInvestissement();
      setState(() => _esTotal = _calculerEsTotalFromList(_pompes));
    }
  }

  void _showDeletePompeConfirmation(int pompeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la Pompe'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette pompe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePompe(pompeId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esTotal = _calculerEsTotal();
    final showValidateAndQuit = _systemeSaved;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Créer un Système' : 'Modifier le Système'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Quitter',
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nom du système
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du Système',
                        prefixIcon: Icon(Icons.settings),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: widget.nomSysteme != null && _isNew,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Coût d'investissement (calculé automatiquement, non modifiable)
                    TextFormField(
                      controller: _coutInvestissementController,
                      decoration: InputDecoration(
                        labelText: 'Coût d\'investissement Total (EUR)',
                        prefixIcon: const Icon(Icons.monetization_on),
                        border: const OutlineInputBorder(),
                        suffixText: 'EUR',
                        filled: true,
                        fillColor: Colors.grey[100],
                        helperText: _pompes.isNotEmpty
                            ? 'Calculé automatiquement depuis les pompes'
                            : 'Sauvegardez le système et ajoutez des pompes',
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: _totalAides.toStringAsFixed(2),
                      decoration: InputDecoration(
                        labelText:
                            'Montant total des aides / subventions (EUR)',
                        prefixIcon: const Icon(Icons.savings),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.green[50],
                        helperText: _aides.isEmpty
                            ? 'Aucune aide enregistrée pour ce système'
                            : 'Somme des aides prises en compte',
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: _coutNet.toStringAsFixed(2),
                      decoration: InputDecoration(
                        labelText: 'Coût net après aides (EUR)',
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.blue[50],
                        helperText: 'Investissement réellement pris en compte',
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Énergie Spécifique totale du système
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Énergie Spécifique Totale (Es)',
                        suffixText: 'kW/m3/h',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                        helperText: _pompes.isNotEmpty
                            ? 'Somme des Es des pompes'
                            : 'Ajoutez des pompes pour calculer',
                      ),
                      controller: TextEditingController(
                        text: esTotal.toStringAsFixed(4),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Aides / subventions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_aides.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Aucune aide ou subvention ajoutée. Utilisez le bouton ci-dessous pour ajouter une aide.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      )
                    else
                      ..._aides.asMap().entries.map((entry) {
                        final index = entry.key;
                        final aide = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              aide.description.isNotEmpty
                                  ? aide.description
                                  : 'Aide sans description',
                            ),
                            subtitle: Text(
                              'Montant: ${aide.montant.toStringAsFixed(2)} EUR',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _showAideDialog(aide: aide, index: index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _showDeleteAideConfirmation(index),
                                ),
                              ],
                            ),
                            onTap: () =>
                                _showAideDialog(aide: aide, index: index),
                          ),
                        );
                      }),

                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Ajouter une aide / subvention'),
                      onPressed: () => _showAideDialog(),
                    ),
                    const SizedBox(height: 24),

                    // Bouton principal : Créer/Mettre à jour OU Valider & Quitter
                    ElevatedButton.icon(
                      icon: showValidateAndQuit
                          ? const Icon(Icons.check)
                          : const Icon(Icons.save),
                      label: Text(
                        showValidateAndQuit
                            ? 'Valider & Quitter'
                            : (_isNew ? 'Créer le Système' : 'Mettre à jour'),
                      ),
                      onPressed: _isLoading
                          ? null
                          : (showValidateAndQuit
                                ? _validateAndExit
                                : _saveSysteme),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: showValidateAndQuit
                            ? Colors.green
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Divider(height: 24),
                    const SizedBox(height: 8),

                    // Liste des pompes
                    const Text(
                      'Pompes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_systemeId == null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _systemeSaved
                                ? 'Le système est créé. Ajoutez des pompes.'
                                : 'Sauvegardez le système d\'abord pour ajouter des pompes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontStyle: _systemeSaved
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    else if (_pompes.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Aucune pompe ajoutée. Appuyez sur + pour en ajouter une.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ..._pompes.map(
                        (pompe) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('${pompe.marque} ${pompe.modele}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Puissance: ${pompe.puissanceNominale} kW',
                                ),
                                Text('Débit: ${pompe.debit} m3/h'),
                                Text('HMT: ${pompe.hmt} mce'),
                                Text(
                                  'P1 Calculée: ${pompe.p1Calculee.toStringAsFixed(2)} kW',
                                ),
                                if (pompe.p1Estimee > 0 &&
                                    pompe.p1Estimee != pompe.p1Calculee)
                                  Text(
                                    'P1 Corrigée: ${pompe.p1Estimee.toStringAsFixed(2)} kW',
                                  ),
                                Text(
                                  'Es: ${pompe.energieSpecifique.toStringAsFixed(4)} kW/m3/h',
                                ),
                                Text('Coût: ${pompe.coutInvestissement} EUR'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _navigateToPompeForm(pompe.id),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _showDeletePompeConfirmation(pompe.id!),
                                ),
                              ],
                            ),
                            onTap: () => _navigateToPompeForm(pompe.id),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Bouton pour ajouter une pompe (uniquement si système sauvegardé)
                    if (_systemeSaved)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une Pompe'),
                        onPressed: () => _navigateToPompeForm(null),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _coutInvestissementController.dispose();
    super.dispose();
  }
}
