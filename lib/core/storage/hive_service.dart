import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../shared/models/client.dart';
import '../../shared/models/client_group.dart';
import '../../shared/models/client_type.dart';
import '../../shared/models/contact.dart';
import '../../shared/models/iv.dart';
import '../../shared/models/product_range.dart';
import '../../modules/ssdm/models/action_step.dart';
import '../../modules/ssdm/models/action_update.dart';
import '../../modules/ssdm/models/sales_action.dart';
import '../../modules/ssdm/models/sales_plan_entry.dart';
import '../../modules/ssdm/models/ssdm_year.dart';
import '../../modules/ssdm/models/visit.dart';
import '../../modules/ssdm/models/visit_frame.dart';
import '../../modules/wuect/models/aide.dart';
import '../../modules/wuect/models/pompe.dart';
import '../../modules/wuect/models/projet.dart';
import '../../modules/wuect/models/systeme.dart';
import 'box_names.dart';

/// Initialisation de Hive et ouverture de toutes les boxes.
///
/// Les boxes partagées (`shared_*`) sont ouvertes ici une seule fois :
/// tous les modules y accedent via `Hive.box(...)`.
///
class HiveService {
  static var _initialized = false;

  static void _registerAdapterIfNeeded<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  static Future<void> _closeAllOpenBoxes() async {
    for (final boxName in BoxNames.all) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
    }
  }

  /// Nettoie les fichiers .lock Hive laissés par un arrêt abrupt ou un crash.
  /// Ce n'est pas une suppression des bases, seulement des verrouillages stales.
  static Future<void> clearStaleHiveLocks(String hivePath) async {
    final hiveDir = Directory(hivePath);
    if (!await hiveDir.exists()) {
      return;
    }

    final entries = await hiveDir.list().toList();
    for (final entry in entries) {
      if (entry is! File) continue;

      final extension = path.extension(entry.path).toLowerCase();
      if (extension != '.lock') continue;

      try {
        final stat = await entry.stat();
        final ageMinutes = DateTime.now().difference(stat.modified).inMinutes;

        // On ne supprime que des lock files anciens, ce qui évite de casser
        // une instance active encore en train d'écrire.
        if (ageMinutes >= 5) {
          await entry.delete();
          print('Removed stale Hive lock: ${entry.path}');
        }
      } catch (_) {
        // Ignorer les fichiers encore verrouillés par une instance active.
      }
    }
  }

  static Future<void> init() async {
    if (_initialized) return;

    // Utiliser un répertoire local hors OneDrive pour éviter les problèmes de lock
    final appDir = await getApplicationSupportDirectory();
    final hivePath = path.join(appDir.path, 'hive_data');

    try {
      await Hive.initFlutter(hivePath);
      await clearStaleHiveLocks(hivePath);
    } catch (error) {
      if (error is PathAccessException) {
        await clearStaleHiveLocks(hivePath);
        await Hive.initFlutter(hivePath);
      } else {
        rethrow;
      }
    }

    print('Hive path: ${path.join(appDir.path, "hive_data")}');

    // --- Adapters : entites partagées ---
    _registerAdapterIfNeeded(IvAdapter());
    _registerAdapterIfNeeded(ClientGroupAdapter());
    _registerAdapterIfNeeded(ClientTypeAdapter());
    // Nouveaux modèles partagés
    _registerAdapterIfNeeded(ClientAdapter());
    _registerAdapterIfNeeded(ContactAdapter());
    _registerAdapterIfNeeded(ProductRangeAdapter());

    // --- Adapters : module SSDM ---
    _registerAdapterIfNeeded(SsdmYearAdapter());
    _registerAdapterIfNeeded(SalesPlanEntryAdapter());
    _registerAdapterIfNeeded(SalesActionAdapter());
    _registerAdapterIfNeeded(ActionUpdateAdapter());
    _registerAdapterIfNeeded(ActionStepAdapter());
    // Nouveau modèle SSDM
    _registerAdapterIfNeeded(VisitAdapter());
    // Modèle Trames de Visite
    _registerAdapterIfNeeded(VisitFrameAdapter());
    // --- Adapters : module WUECT ---
    _registerAdapterIfNeeded(AideAdapter());
    _registerAdapterIfNeeded(ProjetAdapter());
    _registerAdapterIfNeeded(SystemeAdapter());
    _registerAdapterIfNeeded(PompeAdapter());

    // --- Ouverture des boxes ---
    await Future.wait([
      Hive.openBox<Iv>(BoxNames.ivs),
      Hive.openBox<ClientGroup>(BoxNames.clientGroups),
      Hive.openBox<ClientType>(BoxNames.clientTypes),
      // Nouvelles boxes partagées
      Hive.openBox<Client>(BoxNames.clients),
      Hive.openBox<Contact>(BoxNames.contacts),
      Hive.openBox<ProductRange>(BoxNames.productRanges),
      // Boxes SSDM existantes
      Hive.openBox<SsdmYear>(BoxNames.ssdmYears),
      Hive.openBox<SalesPlanEntry>(BoxNames.ssdmPlan),
      Hive.openBox<SalesAction>(BoxNames.ssdmActions),
      // Nouvelle box SSDM
      Hive.openBox<Visit>(BoxNames.ssdmVisits),
      // Box Trames de Visite
      Hive.openBox<VisitFrame>(BoxNames.ssdmVisitFrames),
      // Boxes module WUECT
      Hive.openBox<Projet>(BoxNames.wuectProjets),
      Hive.openBox<Systeme>(BoxNames.wuectSystemes),
      Hive.openBox<Pompe>(BoxNames.wuectPompes),
      Hive.openBox(BoxNames.wuectSettings),
    ]);

    _initialized = true;
  }

  /// Chemin du dossier des données Hive
  static Future<String> get hiveDataPath async {
    final appDir = await getApplicationSupportDirectory();
    return path.join(appDir.path, 'hive_data');
  }

  /// Exécute une sauvegarde automatique locale à chaque lancement.
  /// L'échec ne bloque pas le démarrage pour ne pas empêcher l'utilisateur.
  static Future<void> autoBackupOnLaunch() async {
    try {
      final backupRoot = Directory(defaultBackupPath);
      if (!await backupRoot.exists()) {
        await backupRoot.create(recursive: true);
      }

      final backupDir = await backupTo(defaultBackupPath);
      print('Automatic Hive backup created: $backupDir');
    } catch (error) {
      print('Automatic Hive backup failed: $error');
    }
  }

  /// Sauvegarde les bases de données Hive vers un dossier de backup
  /// Format du dossier: AAAA-MM-DD-HH-MM
  static Future<String> backupTo(String backupRootPath) async {
    final sourcePath = await hiveDataPath;
    final sourceDir = Directory(sourcePath);

    if (!await sourceDir.exists()) {
      throw Exception('Dossier source Hive introuvable: ${sourceDir.path}');
    }

    // Créer le nom du dossier avec timestamp
    final now = DateTime.now();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}';

    final backupDir = Directory(path.join(backupRootPath, timestamp));
    await backupDir.create(recursive: true);

    // Copier tous les fichiers .hive et .lock
    final files = await sourceDir.list().toList();

    for (final entity in files) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        // Les .lock ne sont pas copiés pour éviter les conflits de verrouillage sur Windows.
        if (ext == '.hive') {
          final dest = File(
            path.join(backupDir.path, path.basename(entity.path)),
          );
          await entity.copy(dest.path);
        }
      }
    }

    // Nettoyer les anciennes sauvegardes (garder 30 jours)
    final cutoffDate = now.subtract(const Duration(days: 30));
    final backupRoot = Directory(backupRootPath);

    if (await backupRoot.exists()) {
      final backupDirs = await backupRoot
          .list()
          .where((e) => e is Directory)
          .cast<Directory>()
          .toList();

      for (final dir in backupDirs) {
        final dirName = path.basename(dir.path);
        // Vérifier que le nom correspond au format AAAA-MM-DD-HH-MM
        if (dirName.length == 16 && dirName.contains('-')) {
          try {
            final parts = dirName.split('-');
            if (parts.length == 5) {
              final dateTime = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
                int.parse(parts[3]),
                int.parse(parts[4]),
              );
              if (dateTime.isBefore(cutoffDate)) {
                await dir.delete(recursive: true);
              }
            }
          } catch (e) {
            // Ignorer les erreurs de parsing
          }
        }
      }
    }

    return backupDir.path;
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    await destination.create(recursive: true);

    final entities = await source.list().toList();
    for (final entity in entities) {
      final newPath = path.join(destination.path, path.basename(entity.path));
      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      }
    }
  }

  /// Restaure la sauvegarde Hive la plus récente du dossier de backup.
  /// L'opération est explicite et ne détruit les données courantes qu'avec
  /// `overwrite: true`.
  static Future<void> restoreLatestBackup({bool overwrite = false}) async {
    final backupRoot = Directory(defaultBackupPath);
    if (!await backupRoot.exists()) {
      throw Exception('Aucune sauvegarde détectée dans: ${backupRoot.path}');
    }

    final backupDirs = await backupRoot
        .list()
        .where((entity) => entity is Directory)
        .cast<Directory>()
        .toList();

    if (backupDirs.isEmpty) {
      throw Exception('Aucune sauvegarde détectée dans: ${backupRoot.path}');
    }

    backupDirs.sort((a, b) => b.path.compareTo(a.path));
    await restoreFromBackup(backupDirs.first.path, overwrite: overwrite);
  }

  /// Restaure une sauvegarde Hive sans détruire les données actuelles par défaut.
  ///
  /// `overwrite` doit être mis à `true` pour remplacer l'état actuel.
  /// Cette opération est explicite et sûre : elle ne fait rien sans demande
  /// utilisateur / code spécifique.
  static Future<void> restoreFromBackup(
    String backupDirPath, {
    bool overwrite = false,
  }) async {
    final backupDir = Directory(backupDirPath);
    if (!await backupDir.exists()) {
      throw Exception('Sauvegarde Hive introuvable: ${backupDir.path}');
    }

    final targetPath = await hiveDataPath;
    final targetDir = Directory(targetPath);

    if (await targetDir.exists() && !overwrite) {
      throw Exception(
        'Les données de production existent déjà. Réglez overwrite=true pour restaurer une sauvegarde.',
      );
    }

    if (await targetDir.exists() && overwrite) {
      await targetDir.delete(recursive: true);
    }

    await _copyDirectory(backupDir, targetDir);

    // Fermer les boxes ouvertes afin de recharger les données restaurées.
    await _closeAllOpenBoxes();

    // On relance ensuite l'initialisation de Hive au prochain démarrage.
    _initialized = false;
  }

  /// Chemin par défaut pour les sauvegardes
  static String get defaultBackupPath {
    return r'C:\Users\72904\Dev\Backup\Sebae\hive';
  }
}
