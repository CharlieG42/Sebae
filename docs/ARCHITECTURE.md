# Architecture Sebae v2

## Principes

1. **Plateforme modulaire** : Sebae est un hôte d'outils. Chaque module vit dans `lib/modules/<id>/` et expose :
   - ses **modèles Hive** (`models/`, boxes préfixées `<id>_`),
   - un **service** (`ChangeNotifier`) qui encapsule la logique et notifie l'UI,
   - ses **vues** (`views/`),
   - une déclaration `SebaeModule` référencée dans `lib/core/module_registry.dart`.

2. **Socle de données partagé** : les entités transversales (IV, groupes et types de clients) vivent dans des boxes `shared_*` gérées par l'écran « Bases de données partagées ». Les modules n'ont **pas** le droit de dupliquer ces entités : ils les référencent par `id`.

3. **Un module ne dépend pas des autres modules.** Les dépendances croisées se font uniquement via les boxes `shared_*`.

## Conventions Hive

- Boxes : `shared_*` pour le socle, `<moduleId>_*` par module.
- TypeIds : 1–9 = entités partagées ; chaque module reçoit une plage de 10 (SSDM : 20–29, WUECT : 30–39, …).
- Adapters générés par `hive_generator` (commande `dart run build_runner build --delete-conflicting-outputs`), enregistrés dans `lib/core/storage/hive_service.dart`.

## Persistance et intégration WUECT

WUECT (dépôt séparé, Flutter + Hive également) devra :
- rester **autonome** : il doit pouvoir tourner seul, sans Sebae ;
- être **lancé depuis Sebae** sans modification de son code ;
- **partager les bases** : les boxes `shared_*` d'un même répertoire de données Hive.

Pistes retenues (à affiner lors de l'intégration) :
- ouverture des boxes via `Hive.openBox` sur un chemin de base commun (`Hive.init(path)` vers le répertoire partagé) ;
- les entités partagées (IV, groupes, types de clients) utilisent les mêmes classes/adapters des deux côtés — la classe `SebaeModule` de Sebae sert de contrat de données.

## État (ChangeNotifier)

Chaque module expose un service `ChangeNotifier` fourni via `provider` dans `main.dart`. L'UI écoute via `context.watch<T>()` et déclenche les mutations via `context.read<T>()`.
