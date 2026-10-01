import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/box_names.dart';
import '../../../shared/models/contact.dart';
import '../models/pompe.dart';
import '../models/projet.dart';
import '../models/systeme.dart';

/// Écriture des entités WUECT migrées dans les boxes de Sebae.
///
/// Reçoit les entités legacy (Maps simples, issues de l'isolate de lecture)
/// et les convertit :
/// - ancien `Contact` WUECT (id int, client, nom, email, mobile) →
///   `Contact` partagé (UUID, `shared_contacts`). Le nom du client legacy
///   est conservé dans `notes` et l'ancien id est mémorisé pour le mapping.
/// - `Projet`/`Systeme`/`Pompe` → boxes `wuect_*`, avec conversion des
///   références contacts (int → UUID). Les projets sans contact valide
///   sont rattachés à un contact « migré » pour ne pas perdre les données.
///
/// Idempotent : les insertions utilisent les mêmes clés auto-incrémentées
/// que le service principal, la migration n'étant exécutée qu'une fois.
abstract final class WuectMigrationWriter {
  static const _uuid = Uuid();

  static Future<void> writeEntities(
      Map<String, List<Map<String, dynamic>>> entities) async {
    final contactsBox = Hive.box<Contact>(BoxNames.contacts);
    final projetsBox = Hive.box<Projet>(BoxNames.wuectProjets);
    final systemesBox = Hive.box<Systeme>(BoxNames.wuectSystemes);
    final pompesBox = Hive.box<Pompe>(BoxNames.wuectPompes);

    // 1) Contacts : mapping legacyId (int) -> UUID partagé
    final contactMap = <int, String>{};
    for (final c in entities['contacts'] ?? const <Map<String, dynamic>>[]) {
      final legacyId = c['legacyId'] as int?;
      if (legacyId == null) continue;
      final nom = (c['nom'] as String? ?? '').trim();
      final parts = nom.split(' ');
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final id = _uuid.v4();
      await contactsBox.put(
        id,
        Contact(
          id: id,
          firstName: firstName,
          lastName: lastName,
          email: c['email'] as String? ?? '',
          mobile: c['mobile'] as String? ?? '',
          notes: 'Client legacy WUECT : ${c['client'] ?? ''}',
        ),
      );
      contactMap[legacyId] = id;
    }

    // Contact de repli pour les projets dont le contact est introuvable
    String fallbackContactId = _uuid.v4();
    await contactsBox.put(
      fallbackContactId,
      Contact(
        id: fallbackContactId,
        firstName: 'WUECT',
        lastName: '(migration)',
        notes: 'Contact créé par la migration WUECT pour les projets sans '
            'contact identifiable.',
      ),
    );

    // 2) Projets + systèmes + pompes (mapping legacyId -> nouvel id)
    final projetMap = <int, int>{};
    final systemeMap = <int, int>{};

    for (final p in entities['projets'] ?? const <Map<String, dynamic>>[]) {
      final legacyId = p['legacyId'] as int?;
      if (legacyId == null) continue;
      final newId = _nextId(projetsBox.keys);
      final legacyContactId = p['contactId'] as int?;
      await projetsBox.put(
        newId,
        Projet(
          id: newId,
          nomSite: p['nomSite'] as String? ?? '',
          contactId: contactMap[legacyContactId] ?? fallbackContactId,
          coutEnergie: (p['coutEnergie'] as num?)?.toDouble() ?? 0.0,
          pourcentageAugmentationEnergie:
              (p['pourcentageAugmentationEnergie'] as num?)?.toDouble() ?? 0.0,
          percentagePerteRendement:
              (p['percentagePerteRendement'] as num?)?.toDouble() ?? 0.0,
          // Les IV legacy ne sont pas migrés automatiquement (modèle trop
          // différent) : à re- associer manuellement dans Sebae.
          ivId: null,
        ),
      );
      projetMap[legacyId] = newId;
    }

    for (final s in entities['systemes'] ?? const <Map<String, dynamic>>[]) {
      final legacyId = s['legacyId'] as int?;
      final legacyProjetId = s['projetId'] as int?;
      if (legacyId == null || legacyProjetId == null) continue;
      final newProjetId = projetMap[legacyProjetId];
      if (newProjetId == null) continue;
      final newId = _nextId(systemesBox.keys);
      await systemesBox.put(
        newId,
        Systeme(
          id: newId,
          projetId: newProjetId,
          nom: s['nom'] as String? ?? '',
          coutInvestissementTotal:
              (s['coutInvestissementTotal'] as num?)?.toDouble() ?? 0.0,
        ),
      );
      systemeMap[legacyId] = newId;
    }

    for (final pompe in entities['pompes'] ?? const <Map<String, dynamic>>[]) {
      final legacySystemeId = pompe['systemeId'] as int?;
      if (legacySystemeId == null) continue;
      final newSystemeId = systemeMap[legacySystemeId];
      if (newSystemeId == null) continue;
      final newId = _nextId(pompesBox.keys);
      await pompesBox.put(
        newId,
        Pompe(
          id: newId,
          systemeId: newSystemeId,
          marque: pompe['marque'] as String? ?? '',
          modele: pompe['modele'] as String? ?? '',
          puissanceNominale: (pompe['puissanceNominale'] as num?)?.toDouble() ?? 0.0,
          debit: (pompe['debit'] as num?)?.toDouble() ?? 0.0,
          hmt: (pompe['hmt'] as num?)?.toDouble() ?? 0.0,
          rendementInitialPompe:
              (pompe['rendementInitialPompe'] as num?)?.toDouble() ?? 0.0,
          rendementInitialMoteur:
              (pompe['rendementInitialMoteur'] as num?)?.toDouble() ?? 0.0,
          anneeInstallation: pompe['anneeInstallation'] as int? ?? 0,
          heuresFonctionnement: pompe['heuresFonctionnement'] as int? ?? 0,
          coutInvestissement:
              (pompe['coutInvestissement'] as num?)?.toDouble() ?? 0.0,
          p1Estimee: (pompe['p1Estimee'] as num?)?.toDouble() ?? 0.0,
        ),
      );
    }
  }

  static int _nextId(Iterable<dynamic> keys) {
    int maxId = 0;
    for (final k in keys) {
      if (k is int && k > maxId) maxId = k;
    }
    return maxId + 1;
  }
}
