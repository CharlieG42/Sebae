import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive/hive.dart';

import '../../../core/storage/box_names.dart';
import '../../../shared/models/contact.dart';
import '../../../shared/models/iv.dart';
import '../models/pompe.dart';
import '../models/projet.dart';
import '../models/systeme.dart';

/// Noms des boxes Hive du module WUECT.
abstract final class WuectBoxNames {
  static const String projets = 'wuect_projets';
  static const String systemes = 'wuect_systemes';
  static const String pompes = 'wuect_pompes';
}

/// Service d'accès aux données du module WUECT.
///
/// Les entités propres à WUECT (projets, systèmes, pompes) vivent dans des
/// boxes `wuect_*` du répertoire de données Hive de Sebae. Les contacts et
/// les IV sont des entités partagées : ils sont lus/écrits directement dans
/// les boxes `shared_contacts` et `shared_ivs` (gérées aussi par l'écran
/// « Bases de données partagées » de Sebae).
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();

  // Boxes du module
  late final Box<Projet> _projetsBox;
  late final Box<Systeme> _systemesBox;
  late final Box<Pompe> _pompesBox;

  // Boxes partagées Sebae
  late final Box<Contact> _contactsBox;
  late final Box<Iv> _ivsBox;

  DatabaseService._init();

  /// Les boxes (partagées et module) sont ouvertes par [HiveService.init]
  /// au démarrage de Sebae. Cette méthode ne fait que récupérer les
  /// références.
  static void init() {
    instance._contactsBox = Hive.box<Contact>(BoxNames.contacts);
    instance._ivsBox = Hive.box<Iv>(BoxNames.ivs);
    instance._projetsBox = Hive.box<Projet>(WuectBoxNames.projets);
    instance._systemesBox = Hive.box<Systeme>(WuectBoxNames.systemes);
    instance._pompesBox = Hive.box<Pompe>(WuectBoxNames.pompes);
  }

  // Helper method pour générer un nouvel ID auto-incrémenté
  int _generateNewId(Iterable<dynamic> keys) {
    if (keys.isEmpty) return 1;
    int maxId = 0;
    for (final key in keys) {
      if (key is int && key > maxId) {
        maxId = key;
      }
    }
    return maxId + 1;
  }

  // ====================
  // CRUD pour Contact (box partagée shared_contacts)
  // ====================

  Future<String> insertContact(Contact contact) async {
    final String id = contact.id;
    await _contactsBox.put(id, contact);
    return id;
  }

  Future<List<Contact>> getAllContacts() async {
    return _contactsBox.values.where((c) => c.active).toList();
  }

  Future<Contact?> getContactById(String id) async {
    return _contactsBox.get(id);
  }

  Future<int> updateContact(Contact contact) async {
    await _contactsBox.put(contact.id, contact);
    return 1;
  }

  Future<int> deleteContact(String id) async {
    await _contactsBox.delete(id);
    return 1;
  }

  // ====================
  // CRUD pour IV (box partagée shared_ivs)
  // ====================

  Future<List<Iv>> getAllIVs() async {
    return _ivsBox.values.where((iv) => iv.active).toList();
  }

  Future<Iv?> getIVById(String id) async {
    return _ivsBox.get(id);
  }

  // ====================
  // CRUD pour Projet
  // ====================

  Future<int> insertProjet(Projet projet) async {
    final int id = _generateNewId(_projetsBox.keys);
    final projetToInsert = projet.copyWith(id: id);
    await _projetsBox.put(id, projetToInsert);
    return id;
  }

  Future<List<Projet>> getAllProjets() async {
    return _projetsBox.values.toList();
  }

  Future<Projet?> getProjetById(int id) async {
    return _projetsBox.get(id);
  }

  Future<int> updateProjet(Projet projet) async {
    if (projet.id == null) return 0;
    await _projetsBox.put(projet.id, projet);
    return 1;
  }

  Future<int> deleteProjet(int id) async {
    await _projetsBox.delete(id);
    return 1;
  }

  // ====================
  // CRUD pour Systeme
  // ====================

  Future<int> insertSysteme(Systeme systeme) async {
    final int id = _generateNewId(_systemesBox.keys);
    final systemeToInsert = systeme.copyWith(id: id);
    await _systemesBox.put(id, systemeToInsert);
    return id;
  }

  Future<List<Systeme>> getAllSystemes() async {
    return _systemesBox.values.toList();
  }

  Future<List<Systeme>> getSystemesByProjetId(int projetId) async {
    return _systemesBox.values.where((s) => s.projetId == projetId).toList();
  }

  Future<Systeme?> getSystemeById(int id) async {
    return _systemesBox.get(id);
  }

  Future<int> updateSysteme(Systeme systeme) async {
    if (systeme.id == null) return 0;
    await _systemesBox.put(systeme.id, systeme);
    return 1;
  }

  Future<int> deleteSysteme(int id) async {
    await _systemesBox.delete(id);
    return 1;
  }

  // ====================
  // CRUD pour Pompe
  // ====================

  Future<int> insertPompe(Pompe pompe) async {
    final int id = _generateNewId(_pompesBox.keys);
    final pompeToInsert = pompe.copyWith(id: id);
    await _pompesBox.put(id, pompeToInsert);
    return id;
  }

  Future<List<Pompe>> getAllPompes() async {
    return _pompesBox.values.toList();
  }

  Future<List<Pompe>> getPompesBySystemeId(int systemeId) async {
    return _pompesBox.values.where((p) => p.systemeId == systemeId).toList();
  }

  Future<Pompe?> getPompeById(int id) async {
    return _pompesBox.get(id);
  }

  Future<int> updatePompe(Pompe pompe) async {
    if (pompe.id == null) return 0;
    await _pompesBox.put(pompe.id, pompe);
    return 1;
  }

  Future<int> deletePompe(int id) async {
    await _pompesBox.delete(id);
    return 1;
  }

  // ====================
  // Suppression en cascade
  // ====================

  Future<void> deleteProjetAndRelatedData(int projetId) async {
    final systemes = await getSystemesByProjetId(projetId);
    for (final systeme in systemes) {
      await deletePompeBySystemeId(systeme.id!);
    }

    final systemesToDelete =
        _systemesBox.values.where((s) => s.projetId == projetId).toList();
    for (final systeme in systemesToDelete) {
      await _systemesBox.delete(systeme.id);
    }

    await deleteProjet(projetId);
  }

  Future<int> deletePompeBySystemeId(int systemeId) async {
    final pompesToDelete =
        _pompesBox.values.where((p) => p.systemeId == systemeId).toList();
    for (final pompe in pompesToDelete) {
      await _pompesBox.delete(pompe.id);
    }
    return pompesToDelete.length;
  }

  // Fermeture : les boxes sont gérées par HiveService (Sebae).
  Future<void> close() async {}

  // Pour la compatibilité avec l'ancien code
  Future<void> get database async {}

  void debugPrintBoxes() {
    debugPrint('WUECT boxes: projets=${_projetsBox.length}, '
        'systemes=${_systemesBox.length}, pompes=${_pompesBox.length}');
  }
}
