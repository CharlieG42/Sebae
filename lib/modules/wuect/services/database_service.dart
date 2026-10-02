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

  // Boxes du module - lazy initialization pour éviter les erreurs de double init
  Box<Projet>? _projetsBox;
  Box<Systeme>? _systemesBox;
  Box<Pompe>? _pompesBox;

  // Boxes partagées Sebae - lazy initialization
  Box<Contact>? _contactsBox;
  Box<Iv>? _ivsBox;

  DatabaseService._init();

  /// Récupère une box avec initialisation lazy
  Box<Projet> _getProjetsBox() => _projetsBox ??= Hive.box<Projet>(WuectBoxNames.projets);
  Box<Systeme> _getSystemesBox() => _systemesBox ??= Hive.box<Systeme>(WuectBoxNames.systemes);
  Box<Pompe> _getPompesBox() => _pompesBox ??= Hive.box<Pompe>(WuectBoxNames.pompes);
  Box<Contact> _getContactsBox() => _contactsBox ??= Hive.box<Contact>(BoxNames.contacts);
  Box<Iv> _getIvsBox() => _ivsBox ??= Hive.box<Iv>(BoxNames.ivs);

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
    await _getContactsBox().put(id, contact);
    return id;
  }

  Future<List<Contact>> getAllContacts() async {
    return _getContactsBox().values.where((c) => c.active).toList();
  }

  Future<Contact?> getContactById(String id) async {
    return _getContactsBox().get(id);
  }

  Future<int> updateContact(Contact contact) async {
    await _getContactsBox().put(contact.id, contact);
    return 1;
  }

  Future<int> deleteContact(String id) async {
    await _getContactsBox().delete(id);
    return 1;
  }

  // ====================
  // CRUD pour IV (box partagée shared_ivs)
  // ====================

  Future<List<Iv>> getAllIVs() async {
    return _getIvsBox().values.where((iv) => iv.active).toList();
  }

  Future<Iv?> getIVById(String id) async {
    return _getIvsBox().get(id);
  }

  // ====================
  // CRUD pour Projet
  // ====================

  Future<int> insertProjet(Projet projet) async {
    final int id = _generateNewId(_getProjetsBox().keys);
    final projetToInsert = projet.copyWith(id: id);
    await _getProjetsBox().put(id, projetToInsert);
    return id;
  }

  Future<List<Projet>> getAllProjets() async {
    return _getProjetsBox().values.toList();
  }

  Future<Projet?> getProjetById(int id) async {
    return _getProjetsBox().get(id);
  }

  Future<int> updateProjet(Projet projet) async {
    if (projet.id == null) return 0;
    await _getProjetsBox().put(projet.id, projet);
    return 1;
  }

  Future<int> deleteProjet(int id) async {
    await _getProjetsBox().delete(id);
    return 1;
  }

  // ====================
  // CRUD pour Systeme
  // ====================

  Future<int> insertSysteme(Systeme systeme) async {
    final int id = _generateNewId(_getSystemesBox().keys);
    final systemeToInsert = systeme.copyWith(id: id);
    await _getSystemesBox().put(id, systemeToInsert);
    return id;
  }

  Future<List<Systeme>> getAllSystemes() async {
    return _getSystemesBox().values.toList();
  }

  Future<List<Systeme>> getSystemesByProjetId(int projetId) async {
    return _getSystemesBox().values.where((s) => s.projetId == projetId).toList();
  }

  Future<Systeme?> getSystemeById(int id) async {
    return _getSystemesBox().get(id);
  }

  Future<int> updateSysteme(Systeme systeme) async {
    if (systeme.id == null) return 0;
    await _getSystemesBox().put(systeme.id, systeme);
    return 1;
  }

  Future<int> deleteSysteme(int id) async {
    await _getSystemesBox().delete(id);
    return 1;
  }

  // ====================
  // CRUD pour Pompe
  // ====================

  Future<int> insertPompe(Pompe pompe) async {
    final int id = _generateNewId(_getPompesBox().keys);
    final pompeToInsert = pompe.copyWith(id: id);
    await _getPompesBox().put(id, pompeToInsert);
    return id;
  }

  Future<List<Pompe>> getAllPompes() async {
    return _getPompesBox().values.toList();
  }

  Future<List<Pompe>> getPompesBySystemeId(int systemeId) async {
    return _getPompesBox().values.where((p) => p.systemeId == systemeId).toList();
  }

  Future<Pompe?> getPompeById(int id) async {
    return _getPompesBox().get(id);
  }

  Future<int> updatePompe(Pompe pompe) async {
    if (pompe.id == null) return 0;
    await _getPompesBox().put(pompe.id, pompe);
    return 1;
  }

  Future<int> deletePompe(int id) async {
    await _getPompesBox().delete(id);
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
        _getSystemesBox().values.where((s) => s.projetId == projetId).toList();
    for (final systeme in systemesToDelete) {
      await _getSystemesBox().delete(systeme.id);
    }

    await deleteProjet(projetId);
  }

  Future<int> deletePompeBySystemeId(int systemeId) async {
    final pompesToDelete =
        _getPompesBox().values.where((p) => p.systemeId == systemeId).toList();
    for (final pompe in pompesToDelete) {
      await _getPompesBox().delete(pompe.id);
    }
    return pompesToDelete.length;
  }

  // Fermeture : les boxes sont gérées par HiveService (Sebae).
  Future<void> close() async {}

  // Pour la compatibilité avec l'ancien code
  Future<void> get database async {}

  void debugPrintBoxes() {
    debugPrint('WUECT boxes: projets=${_getProjetsBox().length}, '
        'systemes=${_getSystemesBox().length}, pompes=${_getPompesBox().length}');
  }
}
