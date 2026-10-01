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

  static Future<void> init() async {
    if (_initialized) return;
    
    // Utiliser un répertoire local hors OneDrive pour éviter les problèmes de lock
    final appDir = await getApplicationSupportDirectory();
    final hivePath = path.join(appDir.path, 'hive_data');
    await Hive.initFlutter(hivePath);

    print('Hive path: ${path.join(appDir.path, "hive_data")}'); 

    // --- Adapters : entites partagées ---
    Hive.registerAdapter(IvAdapter());
    Hive.registerAdapter(ClientGroupAdapter());
    Hive.registerAdapter(ClientTypeAdapter());
    // Nouveaux modèles partagés
    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(ContactAdapter());
    Hive.registerAdapter(ProductRangeAdapter());

    // --- Adapters : module SSDM ---
    Hive.registerAdapter(SsdmYearAdapter());
    Hive.registerAdapter(SalesPlanEntryAdapter());
    Hive.registerAdapter(SalesActionAdapter());
    Hive.registerAdapter(ActionUpdateAdapter());
    Hive.registerAdapter(ActionStepAdapter());
    // Nouveau modèle SSDM
    Hive.registerAdapter(VisitAdapter());
    // Modèle Trames de Visite
    Hive.registerAdapter(VisitFrameAdapter());
    // --- Adapters : module WUECT ---
    Hive.registerAdapter(ProjetAdapter());
    Hive.registerAdapter(SystemeAdapter());
    Hive.registerAdapter(PompeAdapter());

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
    final timestamp = '${now.year.toString().padLeft(4, '0')}-'
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
        if (ext == '.hive' || ext == '.lock') {
          final dest = File(path.join(backupDir.path, path.basename(entity.path)));
          await entity.copy(dest.path);
        }
      }
    }

    // Nettoyer les anciennes sauvegardes (garder 30 jours)
    final cutoffDate = now.subtract(const Duration(days: 30));
    final backupRoot = Directory(backupRootPath);
    
    if (await backupRoot.exists()) {
      final backupDirs = await backupRoot.list()
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

  /// Chemin par défaut pour les sauvegardes
  static String get defaultBackupPath {
    return r'C:\Users\72904\Dev\Backup\Sebae\hive';
  }
}
