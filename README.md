# Sebae

Plateforme modulaire regroupant les outils métier développés par [WildZimut](https://github.com/CharlieG42), en **Flutter / Dart** avec persistance locale **Hive**.

> **Sebae v2** : le dépôt a été entièrement réinitialisé (l'ancienne application Python/QML est archivée — sauvegarde effectuée avant la refonte). Cette version est une refonte complète orientée plateforme d'outils.

## Organisation

```
Sebae
   | Modules
       | WUECT (disponible — https://github.com/CharlieG42/WUECT)
       | Contrat Maintenance (à venir)
       | Gestion de Projets (priorité 2)
       | SSDM (Service Sales Dev Management — disponible)
   | Paramètres
   | Visualisation et Gestion des bases de données partagées
```

Chaque module est une brique autonome déclarée dans le registre (`lib/core/module_registry.dart`). Un module non encore développé apparaît comme « à venir ».

## Module SSDM (Service Sales Dev Management)

Pilotage annuel du business :

- **Objectif de CA** par année, défini au moment de *Créer une nouvelle année* ;
- **Sales Plan** : objectifs de CA par **IV** (Ingénieur des Ventes), par **groupe de clients** et par **type de clients**, avec suivi du CA réalisé ;
- **Actions** : actions spécifiques à un IV **ou communes à l'équipe**, avec statut, échéance, mise à jour d'avancement et historique ;
- **Dashboard** : couverture de l'objectif, plan vs réalisé par IV (graphiques `fl_chart`), avancement des actions.

## Module WUECT (Water Utility Engineering Calculation Tool)

Comparatifs énergétiques entre systèmes de pompage :

- **Projets** : rattachés à un contact et un IV des bases partagées (`shared_contacts`, `shared_ivs`), coût de l'énergie, Hausse annuelle, perte de rendement ;
- **Systèmes** : Ancien / Nouveau système, avec pompes (débit, HMT, rendements, puissance corrigée P1) ;
- **Comparatif** : consommation et coûts sur la durée d'étude (paramétrable), ROI, graphiques, export PDF et rapport Word (`.docx` depuis gabarit) ;
- **Paramètres du module** : durées, coûts et pertes par défaut, dossier d'export PDF (box `wuect_settings`).

Le module WUECT intégré partage intégralement les données avec l'application WUECT autonome : mêmes boxes Hive (`shared_*`, `wuect_*`) dans le même dossier de données (voir ci-dessous). Les données de l'ancien WUECT (dossier OneDrive ou local) sont migrées automatiquement au premier démarrage de Sebae.

## Bases de données partagées

Les entités communes sont stockées dans des boxes Hive préfixées `shared_` :

| Box | Contenu |
|---|---|
| `shared_ivs` | Ingénieurs des Ventes |
| `shared_client_groups` | Groupes de clients |
| `shared_client_types` | Types de clients |
| `shared_clients` | Clients |
| `shared_contacts` | Contacts |
| `shared_product_ranges` | Gammes de produits |
| `wuect_projets` | Projets WUECT (référencent contact/IV par UUID) |
| `wuect_systemes` | Systèmes de pompage WUECT |
| `wuect_pompes` | Pompes WUECT |
| `wuect_settings` | Paramètres du module WUECT |

Les modules (SSDM aujourd'hui, WUECT demain) lisent ces mêmes boxes : c'est le socle du partage de données. À terme, Sebae doit pouvoir **lancer WUECT de façon autonome** (WUECT reste utilisable seul) tout en partageant ces bases.

## Démarrage

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # génération des TypeAdapters Hive
flutter run
```

> Les fichiers `*.g.dart` (adapters Hive) sont générés par `build_runner`. Après un `git pull`, relancez la commande `build_runner` si les fichiers manquent.

## Structure du code

```
lib/
  main.dart                    # initialisation Hive + Provider
  app.dart                     # MaterialApp + thème
  shell/home_shell.dart       # navigation Modules / Bases / Paramètres
  core/
    module.dart                # définition d'un module
    module_registry.dart       # registre des modules
    storage/                   # noms des boxes + ouverture Hive
  shared/
    models/                    # entités partagées (IV, groupes, types)
    widgets/                   # widgets communs
  data/data_home.dart          # gestion des bases partagées (CRUD)
  settings/settings_view.dart  # paramètres
  modules/
    ssdm/                      # module SSDM (modèles, service, vues)
```

## Feuille de route

1. **SSDM** (en cours) — voir `docs/ROADMAP_SSDM.md`
2. **Intégration WUECT** — lancement depuis Sebae sans modifier le code de WUECT, partage des bases `shared_*`
3. **Gestion de Projets**
4. **Contrat Maintenance**
