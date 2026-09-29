import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/box_names.dart';
import '../../../shared/models/client.dart';
import '../../../shared/models/client_group.dart';
import '../../../shared/models/client_type.dart';
import '../../../shared/models/contact.dart';
import '../../../shared/models/iv.dart';
import '../../../shared/models/product_range.dart';
import '../models/action_step.dart';
import '../models/action_update.dart';
import '../models/sales_action.dart';
import '../models/sales_plan_entry.dart';
import '../models/ssdm_year.dart';
import '../models/visit.dart';
import '../models/visit_frame.dart';
import '../ssdm_constants.dart';

/// Indices des onglets du module SSDM (voir SsdmHome).
abstract final class SsdmTabs {
  static const dashboard = 0;
  static const objective = 1;
  static const plan = 2;
  static const actions = 3;
  static const visits = 4;
}

/// Service central du module SSDM.
///
/// Expose les années, le Sales Plan et les actions de l'année sélectionnée,
/// et notifie l'UI à chaque modification (ChangeNotifier + Provider).
///
/// Il porte aussi deux éléments de navigation :
/// - [tabController] : référencé par SsdmHome pour permettre aux vues de
///   changer d'onglet (ex. voir les actions liées à une ligne de plan) ;
///
/// - [planEntryFilter] : filtre courant de la vue Actions sur une ligne du
///   Sales Plan (null = pas de filtre).
///
/// Depuis la mise à jour, gère également les visites clients.
class SsdmService extends ChangeNotifier {
  static const _uuid = Uuid();

  final Box<SsdmYear> _years;
  final Box<SalesPlanEntry> _plan;
  final Box<SalesAction> _actions;
  final Box<Visit> _visits;
  final Box<VisitFrame> _visitFrames;
  final Box<Iv> _ivs;
  final Box<ClientGroup> _groups;
  final Box<ClientType> _types;
  final Box<Client> _clients;
  final Box<Contact> _contacts;
  final Box<ProductRange> _productRanges;

  int? _selectedYear;

  /// Contrôleur d'onglets référencé par SsdmHome (nav inter-vues).
  TabController? tabController;

  /// Filtre "ligne du plan" appliqué à la vue Actions.
  String? planEntryFilter;

  /// Filtre "action" appliqué à la vue Visites.
  String? actionFilter;

  /// Filtre "ligne du plan" appliqué à la vue Visites.
  String? planEntryFilterForVisits;

  SsdmService()
      : _years = Hive.box<SsdmYear>(BoxNames.ssdmYears),
        _plan = Hive.box<SalesPlanEntry>(BoxNames.ssdmPlan),
        _actions = Hive.box<SalesAction>(BoxNames.ssdmActions),
        _visits = Hive.box<Visit>(BoxNames.ssdmVisits),
        _visitFrames = Hive.box<VisitFrame>(BoxNames.ssdmVisitFrames),
        _ivs = Hive.box<Iv>(BoxNames.ivs),
        _groups = Hive.box<ClientGroup>(BoxNames.clientGroups),
        _types = Hive.box<ClientType>(BoxNames.clientTypes),
        _clients = Hive.box<Client>(BoxNames.clients),
        _contacts = Hive.box<Contact>(BoxNames.contacts),
        _productRanges = Hive.box<ProductRange>(BoxNames.productRanges);

  // ------------------------------------------------------------- Navigation

  void goToPlanTab() => tabController?.animateTo(SsdmTabs.plan);
  void goToActionsTab() => tabController?.animateTo(SsdmTabs.actions);
  void goToVisitsTab() => tabController?.animateTo(SsdmTabs.visits);

  /// Filtre la vue Actions sur une ligne du plan (null = aucun filtre).
  void filterActionsByPlan(String? planEntryId) {
    planEntryFilter = planEntryId;
    notifyListeners();
  }

  /// Filtre la vue Visites sur une action (null = aucun filtre).
  void filterVisitsByAction(String? actionId) {
    actionFilter = actionId;
    notifyListeners();
  }

  /// Filtre la vue Visites sur une ligne du plan (null = aucun filtre).
  void filterVisitsByPlanEntry(String? planEntryId) {
    planEntryFilterForVisits = planEntryId;
    notifyListeners();
  }

  // ------------------------------------------------------------------ Années

  List<int> get yearList => _years.values.map((y) => y.year).toList()..sort();

  int? get selectedYear => _selectedYear;

  SsdmYear? get currentYear =>
      _selectedYear == null ? null : _years.get(_selectedYear.toString());

  List<Iv> get ivs => _ivs.values.where((iv) => iv.active).toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  List<ClientGroup> get clientGroups => _groups.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  List<ClientType> get clientTypes => _types.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  // --- Nouveaux getters pour les données partagées ---

  List<Client> get clients => _clients.values.where((c) => c.active).toList()
    ..sort((a, b) => a.displayName.compareTo(b.displayName));

  List<Contact> get contacts => _contacts.values.where((c) => c.active).toList()
    ..sort((a, b) => a.displayName.compareTo(b.displayName));

  List<ProductRange> get productRanges =>
      _productRanges.values.where((pr) => pr.active).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

  // --------------------------------------------- Résolution des références ---
  // Les entités partagées sont référencées par leur champ `id` (UUID).
  // On ne peut pas utiliser box.get(id) car la clé Hive peut différer
  // (anciennes données créées avec box.add), donc on scanne les valeurs.

  Iv? ivOf(String? id) {
    if (id == null || id == kAllId) return null;
    for (final iv in _ivs.values) {
      if (iv.id == id) return iv;
    }
    return null;
  }

  ClientGroup? groupOf(String? id) {
    if (id == null || id == kAllId) return null;
    for (final g in _groups.values) {
      if (g.id == id) return g;
    }
    return null;
  }

  ClientType? typeOf(String? id) {
    if (id == null || id == kAllId) return null;
    for (final t in _types.values) {
      if (t.id == id) return t;
    }
    return null;
  }

  Client? clientOf(String? id) {
    if (id == null) return null;
    for (final c in _clients.values) {
      if (c.id == id) return c;
    }
    return null;
  }

  Contact? contactOf(String? id) {
    if (id == null) return null;
    for (final c in _contacts.values) {
      if (c.id == id) return c;
    }
    return null;
  }

  ProductRange? productRangeOf(String? id) {
    if (id == null) return null;
    for (final pr in _productRanges.values) {
      if (pr.id == id) return pr;
    }
    return null;
  }

  /// Libellé IV : trigramme + nom, "Tous" pour la sentinel, "?" si inconnu.
  String ivLabel(String? id) {
    if (id == null) return 'Équipe';
    if (id == kAllId) return 'Tous';
    final iv = ivOf(id);
    if (iv == null) return '?';
    return iv.trigramOrEmpty.isEmpty ? iv.name : '${iv.trigramOrEmpty} - ${iv.name}';
  }

  /// Libellé pour une liste d'IV.
  String ivIdsLabel(List<String>? ids) {
    if (ids == null || ids.isEmpty) return 'Équipe';
    if (ids.contains(kAllId)) return 'Tous';
    return ids.map((id) => ivLabel(id)).join(', ');
  }

  /// Libellé groupe de clients ("Tous" pour la sentinel).
  String groupLabel(String? id) =>
      id == kAllId ? 'Tous' : (groupOf(id)?.name ?? '?');

  /// Libellé type de clients ("Tous" pour la sentinel).
  String typeLabel(String? id) =>
      id == kAllId ? 'Tous' : (typeOf(id)?.name ?? '?');

  /// Libellé client.
  String clientLabel(String? id) => clientOf(id)?.displayName ?? '?';

  void selectYear(int? year) {
    _selectedYear = year;
    notifyListeners();
  }

  /// Crée une nouvelle année de gestion.
  ///
  /// [copyTeamActions] : si vrai, les actions d'équipe (communes, sans IV)
  /// de [copyFromYear] sont recopiées pour la nouvelle année (avancement
  /// remis à zéro). Les actions spécifiques à un IV ne sont pas recopiées.
  Future<void> createYear(
    int year,
    double caObjective, {
    bool copyTeamActions = false,
    int? copyFromYear,
  }) async {
    if (_years.containsKey(year.toString())) {
      throw StateError('L\'année $year existe déjà.');
    }
    await _years.put(year.toString(), SsdmYear(year: year, caObjective: caObjective));

    if (copyTeamActions && copyFromYear != null) {
      final teamActions = _actions.values.where(
        (a) => a.year == copyFromYear && (a.ivIds == null || a.ivIds!.isEmpty),
      );
      for (final source in teamActions) {
        final copy = _copyForNewYear(source, year);
        await _actions.put(copy.id, copy);
      }
    }

    _selectedYear = year;
    notifyListeners();
  }

  SalesAction _copyForNewYear(SalesAction source, int year) => SalesAction(
        id: _uuid.v4(),
        year: year,
        title: source.title,
        description: source.description,
        ivIds: source.ivIds,
        clientGroupId: source.clientGroupId,
        clientTypeId: source.clientTypeId,
        statusIndex: ActionStatus.planned.index,
        progress: 0,
        createdAt: DateTime.now(),
        history: [],
        planEntryId: source.planEntryId,
        revenueAmount: source.revenueAmount,
        // Les étapes sont recopiées, statuts remis à "à faire".
        steps: source.steps
            ?.map((s) => ActionStep(
                  id: _uuid.v4(),
                  label: s.label,
                  weight: s.weight,
                  statusIndex: ActionStepStatus.todo.index,
                  dueDate: s.dueDate != null
                      ? DateTime(s.dueDate!.year + (year - source.year),
                          s.dueDate!.month, s.dueDate!.day)
                      : null,
                ))
            .toList(),
      );

  Future<void> updateCaObjective(double caObjective) async {
    final year = currentYear;
    if (year == null) return;
    year.caObjective = caObjective;
    await year.save();
    notifyListeners();
  }

  // --------------------------------------------------------------- Sales Plan

  List<SalesPlanEntry> planFor(int? year, {String? ivId}) => _plan.values
      .where((e) => (year == null || e.year == year) && (ivId == null || e.ivId == ivId))
      .toList()
    ..sort((a, b) => a.ivId.compareTo(b.ivId));

  double planTotal(int year) => _plan.values
      .where((e) => e.year == year)
      .fold(0.0, (sum, e) => sum + e.targetAmount);

  double realizedTotal(int year) => _plan.values
      .where((e) => e.year == year)
      .fold(0.0, (sum, e) => sum + e.realizedAmount);

  /// Retrouve une ligne de plan par son id.
  SalesPlanEntry? planEntryOf(String? id) {
    if (id == null) return null;
    for (final e in _plan.values) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Libellé complet d'une ligne de plan : "Titre - IV - groupe - type".
  String planLineLabel(String planEntryId) {
    final e = planEntryOf(planEntryId);
    if (e == null) return '?';
    final titlePart = e.title.isNotEmpty ? '${e.title} - ' : '';
    return '$titlePart${ivLabel(e.ivId)} - ${groupLabel(e.clientGroupId)} - '
        '${typeLabel(e.clientTypeId)}';
  }

  /// Libellé court d'une ligne de plan (pour les axes du radar).
  String planLineShortLabel(String planEntryId) {
    final e = planEntryOf(planEntryId);
    if (e == null) return '?';
    final iv = ivOf(e.ivId);
    final ivPart = (iv?.trigramOrEmpty.isNotEmpty ?? false)
        ? iv!.trigramOrEmpty
        : (iv?.name ?? 'Tous');
    return '$ivPart - ${groupLabel(e.clientGroupId)}';
  }

  /// Total du Sales Plan par IV pour une année.
  ///
  /// Les lignes "Tous les IV" (sentinel [kAllId]) sont exclues de ce
  /// découpage (elles restent comptées dans [planTotal]).
  Map<String, double> planByIv(int year) {
    final result = <String, double>{};
    for (final e in _plan.values.where((e) => e.year == year && e.ivId != kAllId)) {
      result[e.ivId] = (result[e.ivId] ?? 0) + e.targetAmount;
    }
    return result;
  }

  /// CA réalisé par IV pour une année (hors lignes "Tous les IV").
  Map<String, double> realizedByIv(int year) {
    final result = <String, double>{};
    for (final e in _plan.values.where((e) => e.year == year && e.ivId != kAllId)) {
      result[e.ivId] = (result[e.ivId] ?? 0) + e.realizedAmount;
    }
    return result;
  }

  Future<void> addPlanEntry({
    required String ivId,
    required String clientGroupId,
    required String clientTypeId,
    required double targetAmount,
    String title = '',
  }) async {
    final year = _selectedYear;
    if (year == null) return;
    final entry = SalesPlanEntry(
      id: _uuid.v4(),
      year: year,
      title: title,
      ivId: ivId,
      clientGroupId: clientGroupId,
      clientTypeId: clientTypeId,
      targetAmount: targetAmount,
    );
    await _plan.put(entry.id, entry);
    notifyListeners();
  }

  Future<void> updatePlanEntry(SalesPlanEntry entry) async {
    await entry.save();
    notifyListeners();
  }

  Future<void> deletePlanEntry(SalesPlanEntry entry) async {
    // Détache les actions liées avant suppression de la ligne.
    for (final a in _actions.values.where((a) => a.planEntryId == entry.id)) {
      a.planEntryId = null;
      await a.save();
    }
    // Détache les visites liées avant suppression de la ligne.
    for (final v in _visits.values.where((v) => v.planEntryIds?.contains(entry.id) == true)) {
      v.planEntryIds?.remove(entry.id);
      if (v.planEntryIds?.isEmpty == true) {
        v.planEntryIds = null;
      }
      await v.save();
    }
    await entry.delete();
    if (planEntryFilter == entry.id) planEntryFilter = null;
    if (planEntryFilterForVisits == entry.id) planEntryFilterForVisits = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------ Actions

  List<SalesAction> actionsFor(int? year, {String? ivId, bool? teamOnly}) =>
      _actions.values
          .where((a) =>
              (year == null || a.year == year) &&
              (ivId == null || a.ivIds != null && a.ivIds!.contains(ivId)) &&
              (teamOnly == null || (a.ivIds == null || a.ivIds!.isEmpty) == teamOnly))
          .toList()
        ..sort((a, b) {
          final da = a.dueDate;
          final db = b.dueDate;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

  /// Actions pour un IV spécifique (ou plusieurs).
  List<SalesAction> actionsForIvs(int year, List<String>? ivIds) {
    if (ivIds == null || ivIds.isEmpty) {
      // Toutes les actions d'équipe
      return _actions.values
          .where((a) => a.year == year && (a.ivIds == null || a.ivIds!.isEmpty))
          .toList()
        ..sort((a, b) {
          final da = a.dueDate;
          final db = b.dueDate;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
    }
    return _actions.values
        .where((a) =>
            a.year == year &&
            a.ivIds != null &&
            a.ivIds!.any((id) => ivIds.contains(id)))
        .toList()
      ..sort((a, b) {
        final da = a.dueDate;
        final db = b.dueDate;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
  }

  /// Retrouve une action par son id (indépendamment de la clé de box).
  SalesAction? actionOf(String? id) {
    if (id == null) return null;
    for (final a in _actions.values) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Actions liées à une ligne du Sales Plan.
  List<SalesAction> actionsForPlan(String planEntryId) =>
      _actions.values.where((a) => a.planEntryId == planEntryId).toList()
        ..sort((a, b) {
          final da = a.dueDate;
          final db = b.dueDate;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

  /// Nombre d'actions liées à une ligne (pour les badges).
  int actionCountForPlan(String planEntryId) =>
      _actions.values.where((a) => a.planEntryId == planEntryId).length;

  /// Total du CA des actions pour une année.
  double actionsRevenueTotal(int year) => _actions.values
      .where((a) => a.year == year)
      .fold(0.0, (sum, a) => sum + a.revenueAmount);

  /// Total du CA des actions liées à une ligne du plan.
  double actionsRevenueForPlan(String planEntryId) => _actions.values
      .where((a) => a.planEntryId == planEntryId)
      .fold(0.0, (sum, a) => sum + a.revenueAmount);

  Future<void> addAction({
    required String title,
    String description = '',
    List<String>? ivIds,
    String? clientGroupId,
    String? clientTypeId,
    DateTime? dueDate,
    String? planEntryId,
    List<ActionStep>? steps,
    List<String>? stepLabels,
    double revenueAmount = 0,
  }) async {
    final year = _selectedYear;
    if (year == null) return;
    final builtSteps = steps ??
        stepLabels?.where((l) => l.trim().isNotEmpty)
            .map((l) => ActionStep(id: _uuid.v4(), label: l.trim()))
            .toList();
    final action = SalesAction(
      id: _uuid.v4(),
      year: year,
      title: title,
      description: description,
      ivIds: ivIds,
      clientGroupId: clientGroupId,
      clientTypeId: clientTypeId,
      dueDate: dueDate,
      planEntryId: planEntryId,
      steps: builtSteps,
      revenueAmount: revenueAmount,
    );
    if (action.hasSteps) _syncFromSteps(action, comment: 'Étapes définies');
    await _actions.put(action.id, action);
    notifyListeners();
  }

  Future<void> updateAction(SalesAction action) async {
    await action.save();
    notifyListeners();
  }

  Future<void> deleteAction(SalesAction action) async {
    // Détache les visites liées avant suppression de l'action.
    for (final v in _visits.values.where((v) => v.actionIds != null && v.actionIds!.contains(action.id))) {
      v.actionIds?.remove(action.id);
      if (v.actionIds?.isEmpty == true) {
        v.actionIds = null;
      }
      await v.save();
    }
    await action.delete();
    notifyListeners();
  }

  /// Lie / délie une action à une ligne du Sales Plan.
  Future<void> linkActionToPlan(SalesAction action, String? planEntryId) async {
    action.planEntryId = planEntryId;
    await action.save();
    notifyListeners();
  }

  /// Met à jour l'avancement d'une action et l'archive dans son historique.
  Future<void> updateProgress(SalesAction action, int progress, {String comment = ''}) async {
    action.logUpdate(progress, comment: comment);
    await action.save();
    notifyListeners();
  }

  /// Met à jour le CA d'une action.
  Future<void> updateActionRevenue(SalesAction action, double revenueAmount) async {
    action.revenueAmount = revenueAmount;
    await action.save();
    notifyListeners();
  }

  /// Avancement moyen des actions de l'année (0-100).
  double averageProgress(int year) {
    final actions = actionsFor(year);
    if (actions.isEmpty) return 0;
    return actions.fold(0.0, (sum, a) => sum + a.effectiveProgress) / actions.length;
  }

  // ------------------------------------------------------------------- Étapes

  /// Recalcule l'avancement et le statut d'une action à partir de ses étapes
  /// et archive le nouvel avancement dans l'historique.
  void _syncFromSteps(SalesAction action, {String comment = ''}) {
    final computed = action.computedProgress;
    if (computed < 0) return;
    action.progress = computed;
    final doneAll = action.activeSteps.isNotEmpty &&
        action.activeSteps.every((s) => s.status == ActionStepStatus.done);
    if (doneAll) {
      action.status = ActionStatus.done;
    } else if (action.activeSteps.any((s) => !s.status.isClosed)) {
      action.status = ActionStatus.inProgress;
    }
    action.history.add(ActionUpdate(
      date: DateTime.now(),
      progress: computed,
      comment: comment.isEmpty ? 'Avancement calculé depuis les étapes' : comment,
    ));
  }

  Future<void> addStep(
    SalesAction action, {
    required String label,
    int weight = 1,
    DateTime? dueDate,
  }) async {
    action.steps ??= <ActionStep>[];
    action.steps!.add(ActionStep(
      id: _uuid.v4(),
      label: label,
      weight: weight <= 0 ? 1 : weight,
      dueDate: dueDate,
    ));
    _syncFromSteps(action);
    await action.save();
    notifyListeners();
  }

  /// Change le statut d'une étape et resynchronise l'action.
  Future<void> setStepStatus(
    SalesAction action,
    ActionStep step,
    ActionStepStatus status, {
    String comment = '',
  }) async {
    step.status = status;
    _syncFromSteps(action, comment: comment);
    await action.save();
    notifyListeners();
  }

  /// Met à jour une étape (libellé, poids, échéance) et resynchronise.
  Future<void> updateStep(
    SalesAction action,
    ActionStep step, {
    String? label,
    int? weight,
    DateTime? dueDate,
  }) async {
    if (label != null && label.trim().isNotEmpty) step.label = label.trim();
    if (weight != null) step.weight = weight <= 0 ? 1 : weight;
    if (dueDate != null) step.dueDate = dueDate;
    _syncFromSteps(action);
    await action.save();
    notifyListeners();
  }

  Future<void> deleteStep(SalesAction action, ActionStep step) async {
    action.steps?.removeWhere((s) => s.id == step.id);
    if (action.hasSteps) {
      _syncFromSteps(action, comment: 'Étape supprimée');
    } else {
      // Plus d'étapes : retour à l'avancement manuel, inchangé.
    }
    await action.save();
    notifyListeners();
  }

  /// Déplace une étape (réordonnancement dans la liste).
  Future<void> moveStep(SalesAction action, int oldIndex, int newIndex) async {
    final steps = action.steps;
    if (steps == null || steps.isEmpty) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex < 0 || oldIndex >= steps.length) return;
    final step = steps.removeAt(oldIndex);
    steps.insert(newIndex.clamp(0, steps.length), step);
    await action.save();
    notifyListeners();
  }

  // -------------------------------------------------- Visites

  List<Visit> visitsFor(int? year, {String? clientId, String? ivId, String? actionId, String? planEntryId}) =>
      _visits.values
          .where((v) =>
              (year == null || v.year == year) &&
              (clientId == null || v.clientId == clientId) &&
              (ivId == null || v.ivIds != null && v.ivIds!.contains(ivId)) &&
              (actionId == null || v.actionIds != null && v.actionIds!.contains(actionId)) &&
              (planEntryId == null || v.planEntryIds != null && v.planEntryIds!.contains(planEntryId)))
          .toList()
        ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

  /// Retrouve une visite par son id.
  Visit? visitOf(String? id) {
    if (id == null) return null;
    for (final v in _visits.values) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Nombre de visites pour une action.
  int visitCountForAction(String actionId) =>
      _visits.values.where((v) => v.actionIds != null && v.actionIds!.contains(actionId)).length;

  /// Nombre de visites pour une ligne du plan.
  int visitCountForPlan(String planEntryId) =>
      _visits.values.where((v) => v.planEntryIds != null && v.planEntryIds!.contains(planEntryId)).length;

  Future<void> addVisit({
    required String clientId,
    List<String>? ivIds,
    String? planEntryId,
    String? actionId,
    List<String>? productRangeIds,
    List<String>? documentPaths,
    String title = '',
    required DateTime appointmentDate,
    int estimatedDuration = 60,
    String location = '',
    List<String> themes = const [],
    String notesBefore = '',
    String notesDuring = '',
    String notesAfter = '',
    VisitStatus status = VisitStatus.planned,
  }) async {
    final year = _selectedYear;
    if (year == null) return;
    final visit = Visit(
      id: _uuid.v4(),
      year: year,
      clientId: clientId,
      ivIds: ivIds,
      planEntryIds: planEntryId != null ? [planEntryId] : null,
      actionIds: actionId != null ? [actionId] : null,
      productRangeIds: productRangeIds,
      documentPaths: documentPaths,
      title: title,
      appointmentDate: appointmentDate,
      estimatedDuration: estimatedDuration,
      location: location,
      themes: themes,
      notesBefore: notesBefore,
      notesDuring: notesDuring,
      notesAfter: notesAfter,
      statusIndex: status.index,
    );
    await _visits.put(visit.id, visit);
    notifyListeners();
  }

  Future<void> updateVisit(Visit visit) async {
    visit.updatedAt = DateTime.now();
    await visit.save();
    notifyListeners();
  }

  Future<void> deleteVisit(Visit visit) async {
    await visit.delete();
    notifyListeners();
  }

  // -------------------------------------------------- Trames de Visite

  List<VisitFrame> get visitFrames => _visitFrames.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  /// Retrouve une trame de visite par son id.
  VisitFrame? visitFrameOf(String? id) {
    if (id == null) return null;
    for (final f in _visitFrames.values) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Nombre de visites utilisant une trame.
  int visitCountForFrame(String frameId) =>
      _visits.values.where((v) => v.visitFrameId == frameId).length;

  Future<void> addVisitFrame({
    required String name,
    String description = '',
    List<String>? productRangeIds,
    List<String>? supportDocumentPaths,
  }) async {
    final frame = VisitFrame(
      id: _uuid.v4(),
      name: name,
      description: description,
      productRangeIds: productRangeIds,
      supportDocumentPaths: supportDocumentPaths,
    );
    await _visitFrames.put(frame.id, frame);
    notifyListeners();
  }

  Future<void> updateVisitFrame(VisitFrame frame) async {
    frame.updatedAt = DateTime.now();
    await frame.save();
    notifyListeners();
  }

  Future<void> deleteVisitFrame(VisitFrame frame) async {
    // Détache la trame des visites qui l'utilisent
    for (final v in _visits.values.where((v) => v.visitFrameId == frame.id)) {
      v.visitFrameId = null;
      await v.save();
    }
    await frame.delete();
    notifyListeners();
  }

  /// Met à jour le statut d'une visite.
  Future<void> updateVisitStatus(Visit visit, VisitStatus status) async {
    visit.status = status;
    visit.updatedAt = DateTime.now();
    await visit.save();
    notifyListeners();
  }

  /// Met à jour les notes d'une visite.
  Future<void> updateVisitNotes(
    Visit visit, {
    String? notesBefore,
    String? notesDuring,
    String? notesAfter,
  }) async {
    if (notesBefore != null) visit.notesBefore = notesBefore;
    if (notesDuring != null) visit.notesDuring = notesDuring;
    if (notesAfter != null) visit.notesAfter = notesAfter;
    visit.updatedAt = DateTime.now();
    await visit.save();
    notifyListeners();
  }

  // -------------------------------------------------- Données pour le radar

  /// Avancement moyen des actions par IV pour une année (0-100).
  ///
  /// Ne prend en compte que les actions non annulées rattachées à un IV.
  /// Les actions d'équipe (sans IV) sont exclues de ce découpage.
  Map<String, double> progressByIv(int year) {
    final result = <String, List<int>>{};
    for (final a in _actions.values.where((a) =>
        a.year == year &&
        a.ivIds != null &&
        a.ivIds!.isNotEmpty &&
        a.ivIds!.first != kAllId &&
        a.status != ActionStatus.cancelled)) {
      for (final ivId in a.ivIds!) {
        result[ivId] = [...(result[ivId] ?? <int>[]), a.effectiveProgress];
      }
    }
    return result.map((id, values) =>
        MapEntry(id, values.fold(0.0, (s, v) => s + v) / values.length));
  }

  /// Avancement moyen des actions liées, par ligne du Sales Plan (0-100).
  ///
  /// Seules les lignes de [year] avec au moins une action non annulée
  /// apparaissent. Null pour une ligne sans actions.
  Map<String, double?> progressByPlan(int year) {
    final result = <String, double?>{};
    for (final entry in _plan.values.where((e) => e.year == year)) {
      final linked = _actions.values.where((a) =>
          a.planEntryId == entry.id && a.status != ActionStatus.cancelled);
      result[entry.id] = linked.isEmpty
          ? null
          : linked.fold(0.0, (s, a) => s + a.effectiveProgress) / linked.length;
    }
    return result;
  }

  // -------------------------------------------------- Gestion des données partagées

  // Clients

  Future<void> addClient({
    required String name,
    String shortName = '',
    String description = '',
    String address = '',
    String postalCode = '',
    String city = '',
    String country = '',
    String phone = '',
    String email = '',
    String website = '',
    String sector = '',
    double? annualRevenue,
    int? employeeCount,
    bool active = true,
  }) async {
    final client = Client(
      id: _uuid.v4(),
      name: name,
      shortName: shortName,
      description: description,
      address: address,
      postalCode: postalCode,
      city: city,
      country: country,
      phone: phone,
      email: email,
      website: website,
      sector: sector,
      annualRevenue: annualRevenue,
      employeeCount: employeeCount,
      active: active,
    );
    await _clients.put(client.id, client);
    notifyListeners();
  }

  Future<void> updateClient(Client client) async {
    client.updatedAt = DateTime.now();
    await client.save();
    notifyListeners();
  }

  Future<void> deleteClient(Client client) async {
    // Archiver les contacts du client avant suppression
    for (final c in _contacts.values.where((c) => c.clientId == client.id)) {
      c.active = false;
      await c.save();
    }
    await client.delete();
    notifyListeners();
  }

  // Contacts

  Future<void> addContact({
    required String clientId,
    required String firstName,
    required String lastName,
    String position = '',
    String phone = '',
    String mobile = '',
    String email = '',
    String notes = '',
    bool isPrimary = false,
    bool active = true,
  }) async {
    final contact = Contact(
      id: _uuid.v4(),
      clientId: clientId,
      firstName: firstName,
      lastName: lastName,
      position: position,
      phone: phone,
      mobile: mobile,
      email: email,
      notes: notes,
      isPrimary: isPrimary,
      active: active,
    );
    await _contacts.put(contact.id, contact);
    notifyListeners();
  }

  Future<void> updateContact(Contact contact) async {
    contact.updatedAt = DateTime.now();
    await contact.save();
    notifyListeners();
  }

  Future<void> deleteContact(Contact contact) async {
    await contact.delete();
    notifyListeners();
  }

  /// Contacts pour un client spécifique.
  List<Contact> contactsForClient(String clientId) =>
      _contacts.values.where((c) => c.clientId == clientId && c.active).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

  // Gamme de produits

  Future<void> addProductRange({
    required String name,
    String code = '',
    String description = '',
    String? parentId,
    double? averagePrice,
    double? averageMargin,
    bool active = true,
  }) async {
    final productRange = ProductRange(
      id: _uuid.v4(),
      name: name,
      code: code,
      description: description,
      parentId: parentId,
      averagePrice: averagePrice,
      averageMargin: averageMargin,
      active: active,
    );
    await _productRanges.put(productRange.id, productRange);
    notifyListeners();
  }

  Future<void> updateProductRange(ProductRange productRange) async {
    productRange.updatedAt = DateTime.now();
    await productRange.save();
    notifyListeners();
  }

  Future<void> deleteProductRange(ProductRange productRange) async {
    await productRange.delete();
    notifyListeners();
  }
}
