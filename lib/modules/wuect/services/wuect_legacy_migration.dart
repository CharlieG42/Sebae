import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'wuect_legacy_models.dart';

/// Migration des données WUECT standalone vers Sebae.
///
/// WUECT autonome stockait ses données dans son propre répertoire Hive
/// (config `config/app_config.json` → OneDrive, ou répertoire local
/// `wu_ect_hive`) avec ses propres boxes (`contacts`, `ivs`, `projets`,
/// `systemes`, `pompes`) et ses anciens typeIds (0-3).
///
/// Cette migration, exécutée une fois au démarrage de Sebae :
/// 1. localise l'ancien répertoire de données WUECT ;
/// 2. relit les anciennes boxes avec les adapters legacy (dans un isolate
///    dédié : les typeIds legacy 0-3 entrent en conflit avec ceux de Sebae) ;
/// 3. convertit les entités vers les entités actuelles via des Maps simples
///    (l'écriture dans les boxes de Sebae est faite par le callback
///    [writeEntities] dans l'isolate principal) ;
/// 4. marque la migration faite (box `shared_migration_flags`) et renomme
///    l'ancien répertoire en `<chemin>_migrated` (aucune suppression).
abstract final class WuectLegacyMigration {
  static const _flagBox = 'shared_migration_flags';
  static const _flagKey = 'wuect_legacy_migrated';

  /// Exécute la migration si nécessaire. Ne fait rien si déjà faite ou si
  /// aucun ancien répertoire de données n'est trouvé. Les erreurs ne sont
  /// jamais bloquantes pour le démarrage.
  static Future<void> runIfNeeded({
    required Future<void> Function(
        Map<String, List<Map<String, dynamic>>> entities) writeEntities,
  }) async {
    try {
      final flags = await Hive.openBox(_flagBox);
      if (flags.get(_flagKey) == true) return;

      final legacyPath = await findLegacyHivePath();
      if (legacyPath == null) {
        await flags.put(_flagKey, true);
        return;
      }

      debugPrint('WUECT migration: lecture de $legacyPath');
      final entities = await compute(readLegacyInIsolate, legacyPath);
      final total = entities.values
          .map((l) => l.length)
          .fold<int>(0, (a, b) => a + b);
      debugPrint('WUECT migration: $total entités lues');
      if (total > 0) {
        await writeEntities(entities);
      }

      await flags.put(_flagKey, true);
      await _renameLegacyDir(legacyPath);
    } catch (e, st) {
      debugPrint('WUECT migration: échec (non bloquant): $e\n$st');
    }
  }

  /// Localise l'ancien répertoire Hive de WUECT standalone.
  static Future<String?> findLegacyHivePath() async {
    final candidates = <String>[];

    final env = Platform.environment['WUECT_HIVE_PATH'];
    if (env != null && env.isNotEmpty) candidates.add(env);

    final configured = await _loadConfiguredPath();
    if (configured != null) candidates.add(configured);

    final oneDrive = Platform.environment['OneDriveCommercial'] ??
        Platform.environment['OneDrive'];
    if (oneDrive != null && oneDrive.isNotEmpty) {
      candidates.add(path.join(oneDrive, '1 - Service', '2 - OPTIMISATIONS',
          '_Template & Tools', 'WUECT', 'assets'));
    }

    try {
      final appDir = await getApplicationSupportDirectory();
      candidates.add(path.join(appDir.path, 'wu_ect_hive'));
      final docDir = await getApplicationDocumentsDirectory();
      candidates.add(path.join(docDir.path, 'wu_ect_hive'));
    } catch (_) {}

    for (final c in candidates) {
      final dir = Directory(c);
      if (await dir.exists()) {
        final hasHiveFiles = await dir
            .list()
            .any((e) => e is File && e.path.endsWith('.hive'));
        if (hasHiveFiles) return c;
      }
    }
    return null;
  }

  static Future<String?> _loadConfiguredPath() async {
    try {
      final candidates = [
        'config/app_config.json',
        path.join(Directory.current.path, 'config', 'app_config.json'),
      ];
      for (final c in candidates) {
        final f = File(c);
        if (await f.exists()) {
          final raw = await f.readAsString();
          final data = jsonDecode(raw);
          final p = data is Map ? data['hivePath'] : null;
          if (p is String && p.isNotEmpty) {
            final oneDrive = Platform.environment['OneDriveCommercial'] ??
                Platform.environment['OneDrive'];
            if (oneDrive != null && oneDrive.isNotEmpty) {
              return p.replaceAll(r'${OneDriveCommercial}', oneDrive);
            }
            return p;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Lecture des anciennes boxes, exécutée dans un isolate : le singleton
  /// Hive y est vierge, on peut donc y enregistrer les adapters legacy
  /// (typeIds 0-3) sans conflit avec ceux de Sebae.
  static Future<Map<String, List<Map<String, dynamic>>>> readLegacyInIsolate(
      String legacyPath) async {
    final hive = Hive;
    hive.init(legacyPath);
    hive.registerAdapter(LegacyContactAdapter());
    hive.registerAdapter(LegacyProjetAdapter());
    hive.registerAdapter(LegacySystemeAdapter());
    hive.registerAdapter(LegacyPompeAdapter());

    final results = <String, List<Map<String, dynamic>>>{};

    results['contacts'] = await _readBox<LegacyContact>(
        'contacts', (c) => {
              'legacyId': c.id,
              'client': c.client,
              'nom': c.nom,
              'email': c.email,
              'mobile': c.mobile,
            });

    results['projets'] = await _readBox<LegacyProjet>(
        'projets', (p) => {
              'legacyId': p.id,
              'nomSite': p.nomSite,
              'contactId': p.contactId,
              'coutEnergie': p.coutEnergie,
              'pourcentageAugmentationEnergie': p.pourcentageAugmentationEnergie,
              'percentagePerteRendement': p.percentagePerteRendement,
              'ivId': p.ivId,
            });

    results['systemes'] = await _readBox<LegacySysteme>(
        'systemes', (s) => {
              'legacyId': s.id,
              'projetId': s.projetId,
              'nom': s.nom,
              'coutInvestissementTotal': s.coutInvestissementTotal,
            });

    results['pompes'] = await _readBox<LegacyPompe>(
        'pompes', (p) => {
              'legacyId': p.id,
              'systemeId': p.systemeId,
              'marque': p.marque,
              'modele': p.modele,
              'puissanceNominale': p.puissanceNominale,
              'debit': p.debit,
              'hmt': p.hmt,
              'rendementInitialPompe': p.rendementInitialPompe,
              'rendementInitialMoteur': p.rendementInitialMoteur,
              'anneeInstallation': p.anneeInstallation,
              'heuresFonctionnement': p.heuresFonctionnement,
              'coutInvestissement': p.coutInvestissement,
              'p1Estimee': p.p1Estimee,
            });

    return results;
  }

  /// Ouvre une box legacy et convertit ses valeurs. Échoue silencieusement
  /// si la box est absente ou illisible (structure inconnue).
  static Future<List<Map<String, dynamic>>> _readBox<T>(
      String name, Map<String, dynamic> Function(T) convert) async {
    try {
      final box = await Hive.openBox<T>(name);
      final out = <Map<String, dynamic>>[];
      for (final v in box.values) {
        try {
          out.add(convert(v));
        } catch (e) {
          debugPrint('WUECT migration: valeur illisible dans $name: $e');
        }
      }
      await box.close();
      return out;
    } catch (e) {
      debugPrint('WUECT migration: box $name ignorée: $e');
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> _renameLegacyDir(String legacyPath) async {
    try {
      final dir = Directory(legacyPath);
      if (await dir.exists()) {
        final renamed = Directory('${legacyPath}_migrated');
        await dir.rename(renamed.path);
        debugPrint('WUECT migration: ancien dossier renommé ${renamed.path}');
      }
    } catch (e) {
      debugPrint('WUECT migration: renommage impossible: $e');
    }
  }
}
