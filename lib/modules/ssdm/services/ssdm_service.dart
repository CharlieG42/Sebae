import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/box_names.dart';
import '../../../shared/models/client_group.dart';
import '../../../shared/models/client_type.dart';
import '../../../shared/models/iv.dart';
import '../models/action_update.dart';
import '../models/sales_action.dart';
import '../models/sales_plan_entry.dart';
import '../models/ssdm_year.dart';

/// Service central du module SSDM.
///
/// Expose les années, le Sales Plan et les actions de l'année sélectionnée,
/// et notifie l'UI à chaque modification (ChangeNotifier + Provider).
class SsdmService extends ChangeNotifier {
  static const _uuid = Uuid();

  final Box<SsdmYear> _years;
  final Box<SalesPlanEntry> _plan;
  final Box<SalesAction> _actions;
  final Box<Iv> _ivs;
  final Box<ClientGroup> _groups;
  final Box<ClientType> _types;

  int? _selectedYear;

  SsdmService()
      : _years = Hive.box<SsdmYear>(BoxNames.ssdmYears),
        _plan = Hive.box<SalesPlanEntry>(BoxNames.ssdmPlan),
        _actions = Hive.box<SalesAction>(BoxNames.ssdmActions),
        _ivs = Hive.box<Iv>(BoxNames.ivs),
        _groups = Hive.box<ClientGroup>(BoxNames.clientGroups),
        _types = Hive.box<ClientType>(BoxNames.clientTypes);

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

  Iv? ivOf(String? id) => id == null ? null : _ivs.get(id);
  ClientGroup? groupOf(String? id) => id == null ? null : _groups.get(id);
  ClientType? typeOf(String? id) => id == null ? null : _types.get(id);

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
        (a) => a.year == copyFromYear && a.ivId == null,
      );
      for (final source in teamActions) {
        await _actions.add(_copyForNewYear(source, year));
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
        ivId: source.ivId,
        clientGroupId: source.clientGroupId,
        clientTypeId: source.clientTypeId,
        statusIndex: ActionStatus.planned.index,
        progress: 0,
        createdAt: DateTime.now(),
        history: [],
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

  /// Total du Sales Plan par IV pour une année.
  Map<String, double> planByIv(int year) {
    final result = <String, double>{};
    for (final e in _plan.values.where((e) => e.year == year)) {
      result[e.ivId] = (result[e.ivId] ?? 0) + e.targetAmount;
    }
    return result;
  }

  /// CA réalisé par IV pour une année.
  Map<String, double> realizedByIv(int year) {
    final result = <String, double>{};
    for (final e in _plan.values.where((e) => e.year == year)) {
      result[e.ivId] = (result[e.ivId] ?? 0) + e.realizedAmount;
    }
    return result;
  }

  Future<void> addPlanEntry({
    required String ivId,
    required String clientGroupId,
    required String clientTypeId,
    required double targetAmount,
  }) async {
    final year = _selectedYear;
    if (year == null) return;
    await _plan.add(SalesPlanEntry(
      id: _uuid.v4(),
      year: year,
      ivId: ivId,
      clientGroupId: clientGroupId,
      clientTypeId: clientTypeId,
      targetAmount: targetAmount,
    ));
    notifyListeners();
  }

  Future<void> updatePlanEntry(SalesPlanEntry entry) async {
    await entry.save();
    notifyListeners();
  }

  Future<void> deletePlanEntry(SalesPlanEntry entry) async {
    await entry.delete();
    notifyListeners();
  }

  // ------------------------------------------------------------------ Actions

  List<SalesAction> actionsFor(int? year, {String? ivId, bool? teamOnly}) =>
      _actions.values
          .where((a) =>
              (year == null || a.year == year) &&
              (ivId == null || a.ivId == ivId) &&
              (teamOnly == null || (a.ivId == null) == teamOnly))
          .toList()
        ..sort((a, b) {
          final da = a.dueDate;
          final db = b.dueDate;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

  Future<void> addAction({
    required String title,
    String description = '',
    String? ivId,
    String? clientGroupId,
    String? clientTypeId,
    DateTime? dueDate,
  }) async {
    final year = _selectedYear;
    if (year == null) return;
    await _actions.add(SalesAction(
      id: _uuid.v4(),
      year: year,
      title: title,
      description: description,
      ivId: ivId,
      clientGroupId: clientGroupId,
      clientTypeId: clientTypeId,
      dueDate: dueDate,
    ));
    notifyListeners();
  }

  Future<void> updateAction(SalesAction action) async {
    await action.save();
    notifyListeners();
  }

  Future<void> deleteAction(SalesAction action) async {
    await action.delete();
    notifyListeners();
  }

  /// Met à jour l'avancement d'une action et l'archive dans son historique.
  Future<void> updateProgress(SalesAction action, int progress, {String comment = ''}) async {
    action.logUpdate(progress, comment: comment);
    await action.save();
    notifyListeners();
  }

  /// Avancement moyen des actions de l'année (0-100).
  double averageProgress(int year) {
    final actions = actionsFor(year);
    if (actions.isEmpty) return 0;
    return actions.fold(0.0, (sum, a) => sum + a.progress) / actions.length;
  }
}
