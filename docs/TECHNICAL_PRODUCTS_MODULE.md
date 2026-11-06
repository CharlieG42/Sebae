# Module Produits techniques

## Objectif

Le module Produits techniques a pour but de centraliser, organiser et exploiter les informations techniques d'un produit à partir d'un ou plusieurs fichiers PowerPoint importés.

L'objectif n'est pas de faire un simple visualiseur de présentation, mais bien un outil de gestion structurée des connaissances techniques :

- identifier le produit
- déduire sa famille
- extraire les éléments techniques utiles
- organiser les informations par usage, tag, métrique et norme
- permettre une correction manuelle si l'extraction automatique est imparfaite
- **NOUVEAU** : calculer un niveau de confiance de l'extraction
- **NOUVEAU** : gérer des statuts de validation
- **NOUVEAU** : standardiser les familles de produits

---

## Ce qui a été mis en place

### 1. Module dédié et intégré à l'application

Le module a été ajouté dans l'architecture de Sebae en tant que module fonctionnel, avec :

- une définition de module compatible avec le système de modules
- un service de gestion des fiches
- une vue dédiée pour la consultation et l'import
- **NOUVEAU** : registration automatique des adapters Hive

### 2. Import de fichier PowerPoint

Le module permet d'importer un fichier `.ppt` ou `.pptx` depuis l'interface.

Le flux de traitement repose sur :

- lecture du fichier ZIP du PowerPoint
- extraction des XML des slides
- récupération des textes des objets de présentation
- décodage du contenu XML
- nettoyage des fragments parasites liés au format Office / XML

**Améliorations récentes :**
- Meilleure gestion des encodages spéciaux
- Filtrage amélioré des éléments parasites (namespaces XML, Quick Menu, etc.)

### 3. Extraction automatique structurée

À partir du contenu importé, le module essaie d'extraire :

- le nom du produit
- **NOUVEAU** : la famille du produit (avec énumération standardisée)
- les tags
- les applications / usages
- les informations clés
- les caractéristiques techniques
- les normes
- **AMÉLIORÉ** : les métriques (débit, pression, puissance, vitesse, tension, courant, température, hauteur manométrique, diamètre)
- un résumé technique synthétique

**Nouveautés :**
- **Calcul automatique du niveau de confiance** : Le module calcule un score d'extraction (0-100) basé sur :
  - Présence d'un titre significatif
  - Détection de la famille de produits
  - Nombre d'applications détectées
  - Nombre de normes identifiées
  - Nombre de métriques extraites
  - Nombre d'informations clés
  - Nombre de caractéristiques
  - Nombre de tags
  - Bonus pour la diversité des informations

- **Niveaux de confiance standardisés :**
  - Très élevée (90-100) : Extraction complète et fiable
  - Élevée (70-89) : Bonne extraction avec quelques éléments
  - Moyenne (50-69) : Extraction partielle
  - Faible (30-49) : Peu d'informations extraites
  - Très faible (0-29) : Extraction minimale

- **Familles de produits standardisées :**
  - Pompage
  - Traitement
  - Instrumentation
  - Sécurité
  - Énergie
  - Mesure
  - Filtration
  - Irrigation
  - Autre

- **Amélioration de la détection des métriques :**
  - Support des unités en français et anglais
  - Détection améliorée des valeurs numériques avec unités
  - Support de nouvelles métriques : tension, courant, température, hauteur manométrique, diamètre

### 4. Persistance locale via Hive

Les fiches techniques sont sauvegardées dans Hive pour garder les données persistantes entre les lancements.

Cela permet :

- de conserver les fiches après fermeture de l'application
- de les retrouver facilement dans l'écran du module
- de les modifier ou les supprimer sans perdre les données

**Nouveautés :**
- **Adapters Hive pour les nouvelles énumérations** : ProductFamily, ValidationStatus, ConfidenceLevel
- Migration automatique des anciennes données (family en String vers ProductFamily enum)

### 5. Recherche et filtres

Le module propose :

- recherche libre par mot-clé
- **NOUVEAU** : filtres par famille (avec liste standardisée)
- filtres par tag
- filtres par application
- **NOUVEAU** : filtres par statut de validation
- **NOUVEAU** : filtres par niveau de confiance

Cela permet de retrouver rapidement un produit selon son usage ou sa catégorie technique.

### 6. Correction manuelle

C'est un point important pour la robustesse du module.

L'utilisateur peut désormais corriger directement une fiche importée dans un éditeur dédié, avec des champs séparés pour :

- nom
- famille (avec sélection dans la liste standardisée)
- résumé
- tags
- applications
- informations clés
- caractéristiques
- normes
- métriques
- **NOUVEAU** : notes
- **NOUVEAU** : statut de validation
- **NOUVEAU** : niveau de confiance
- **NOUVEAU** : nom du validateur

**Nouveautés :**
- Sélection de la famille via un dropdown avec les familles standardisées
- Sélection du statut de validation via un dropdown avec indicateurs de couleur
- Sélection du niveau de confiance via un dropdown avec indicateurs de couleur
- Champ dédié pour les notes sur la fiche

### 7. Gestion des statuts de validation

**Nouvelle fonctionnalité :** Gestion complète des statuts de validation pour chaque fiche :

- **Auto-extrait** : Fiche importée automatiquement, non validée (bleu)
- **À revoir** : Fiche nécessitant une validation manuelle (orange)
- **Validé** : Fiche vérifiée et approuvée manuellement (vert)
- **Modifié manuellement** : Fiche modifiée après extraction (violet)

Cette fonctionnalité permet :
- De suivre l'état de chaque fiche
- De prioriser les fiches à valider
- D'identifier les fiches déjà validées
- De distinguer les fiches automatiques des fiches modifiées

### 8. Statistiques et Analyse

**Nouvelle fonctionnalité :** Le module propose maintenant des statistiques détaillées :

- Nombre total de fiches
- Nombre de fiches par statut (validé, à revoir, auto-extrait, modifié)
- Nombre de fiches par famille de produits
- Nombre de fiches par niveau de confiance
- Score d'extraction moyen

Ces statistiques sont accessibles via un bouton dédié dans l'interface.

---

## Ce qui a déjà été corrigé

### Nettoyage des données importées

Une vraie difficulté de ce type de module est la présence de nombreux éléments parasites dans les fichiers PowerPoint, notamment :

- namespaces XML
- "Quick Menu"
- fragments Office / Drawing
- données techniques de présentation sans valeur métier

Le module applique maintenant un filtrage plus strict pour garder les éléments vraiment utiles à l'utilisateur.

**Améliorations récentes :**
- Ajout de motifs supplémentaires de bruit XML
- Meilleure détection des éléments vides ou non pertinents
- Filtrage des textes trop longs (limite à 180 caractères)

### Mise en priorité des éléments utiles

Le système privilégie les informations qui ont le plus de valeur métier, notamment :

- débit
- pression
- puissance
- moteur
- application
- norme
- pompe / traitement / filtration / irrigation

**Améliorations :**
- Meilleure pondération des mots-clés techniques
- Priorité accrue pour les métriques avec valeurs numériques
- Détection améliorée des phrases contenant des informations techniques

### Représentation plus propre dans l'UI

Les fiches affichent désormais des blocs structurés plutôt qu'un unique bloc de texte dense. Cela rend la lecture plus rapide et plus adaptée à un usage "gestion de connaissance technique".

**Nouveautés :**
- Affichage des indicateurs de confiance et de statut directement dans la carte produit
- Affichage du score d'extraction
- Organisation améliorée des informations
- Affichage des notes si présentes
- Statistiques globales accessibles

---

## Nouveautés implémentées

### 1. Système de confiance et validation ✅

- **Niveau de confiance** : Calcul automatique basé sur le score d'extraction
- **Statut de validation** : Auto-extrait, À revoir, Validé, Modifié manuellement
- **Indicateurs visuels** : Couleurs associées à chaque statut et niveau de confiance
- **Gestion via UI** : Possibilité de modifier le statut et le niveau de confiance

### 2. Familles de produits standardisées ✅

- Énumération ProductFamily avec 9 catégories standard
- Détection automatique basée sur les mots-clés
- Sélection manuelle via dropdown
- Meilleure cohérence des données

### 3. Extraction améliorée ✅

- Détection de 9 métriques différentes (contre 4 auparavant)
- Support des unités en français et anglais
- Meilleure détection des normes (ISO, EN, DIN, NF, API, CE, UL, AFNOR, ANSI, ASME)
- Extraction plus robuste des applications
- Score d'extraction calculé automatiquement

### 4. Interface utilisateur enrichie ✅

- Filtres avancés (famille, tag, application, statut, confiance)
- Affichage des indicateurs de statut et confiance sur chaque carte
- Statistiques globales
- Dialogue d'informations sur le module
- Meilleure organisation de l'éditeur de fiche

### 5. Persistance des nouvelles données ✅

- Adapters Hive pour ProductFamily, ValidationStatus, ConfidenceLevel
- Migration automatique des anciennes données
- Sauvegarde de tous les nouveaux champs

---

## Points de vigilance / limites actuelles

### 1. L'extraction n'est pas encore totalement fiable sur tous les fichiers

Les présentations PowerPoint ont souvent des structures très différentes selon :

- le logiciel utilisé pour les générer
- le niveau de structuration du document
- la présence ou non de tableaux, notes, champs visuels, images, etc.

**Atténuation :**
- Le système de confiance permet d'identifier les extractions peu fiables
- La correction manuelle est toujours possible
- Le statut "À revoir" permet de marquer les fiches nécessitant une attention

### 2. Le tri de pertinence reste heuristique

Le classement des informations est basé sur des mots-clés et des règles de priorité. C'est utile, mais pas parfait.

**Atténuation :**
- L'utilisateur peut réorganiser manuellement les informations
- Le score de confiance reflète la qualité de l'extraction

### 3. Le vrai enjeu métier est la qualité des données

Le module est déjà utile tel quel, mais sa valeur réelle dépendra de la qualité des fiches importées et de la capacité à corriger manuellement les éléments mal classés.

**Nouvelle solution :**
- Le système de validation permet de suivre l'état des fiches
- Les statistiques permettent d'identifier les fiches à améliorer
- Les filtres permettent de cibler les fiches selon leur statut

---

## Suggestions pour la suite

### 1. Export des données

Permettre l'export des fiches techniques dans différents formats :

- CSV
- JSON
- PDF (fiche technique formatée)
- Excel

Cela permettrait :
- D'analyser les données dans des outils externes
- De partager les fiches avec d'autres équipes
- De créer des rapports

### 2. Import multiple

Permettre l'import de plusieurs fichiers PowerPoint en une seule fois, avec :

- Sélection multiple de fichiers
- Traitement par lot
- Rapports d'import (succès, échecs, avertissements)

### 3. Intégration avec d'autres modules

Intégrer les produits techniques avec d'autres modules de Sebae :

- Lien avec les gammes de produits (product_ranges)
- Association avec les clients et contacts
- Utilisation dans les visites SSDM
- Intégration avec WUECT

### 4. Historique des modifications

Ajouter un historique des modifications pour chaque fiche :

- Date de modification
- Type de modification (import, correction manuelle, validation)
- Utilisateur ayant effectué la modification
- Commentaire optionnel

### 5. Comparaison de fiches

Permettre de comparer deux fiches techniques côte à côte :

- Comparaison des caractéristiques
- Comparaison des métriques
- Identification des différences
- Export de la comparaison

### 6. Modèles de fiches

Créer des modèles de fiches pré-remplis pour :

- Pompes
- Systèmes de traitement
- Capteurs
- etc.

Cela permettrait d'accélérer la création de nouvelles fiches.

### 7. Recherche avancée

Améliorer la recherche avec :

- Opérateurs booléens (AND, OR, NOT)
- Recherche dans des champs spécifiques
- Plage de valeurs pour les métriques
- Recherche par date de création/modification

### 8. Tableau de bord

Créer un tableau de bord avec :

- Vue d'ensemble des fiches (par statut, famille, confiance)
- Graphiques de répartition
- Indicateurs clés (nombre total, taux de validation, etc.)
- Alertes pour les fiches nécessitant une attention

### 9. Préparer une couche IA plus avancée

À moyen terme, on peut imaginer :

- extraction plus sémantique depuis le PowerPoint (utilisation de LLM)
- classification améliorée par famille
- détection automatique des corrections nécessaires
- suggestion de corrections
- enrichissement automatique des données (normes, applications)

---

## État actuel

Le module est fonctionnel et exploitable en l'état pour :

- ✅ importer des fichiers PowerPoint
- ✅ stocker les fiches localement
- ✅ retrouver rapidement les produits
- ✅ filtrer par famille / application / tag / statut / confiance
- ✅ modifier manuellement la structure si nécessaire
- ✅ **NOUVEAU** : calculer automatiquement le niveau de confiance
- ✅ **NOUVEAU** : gérer les statuts de validation
- ✅ **NOUVEAU** : utiliser des familles de produits standardisées
- ✅ **NOUVEAU** : afficher des statistiques globales
- ✅ **NOUVEAU** : améliorer l'extraction des métriques et normes

C'est une base solide pour une vraie base de connaissance technique métier, avec maintenant des fonctionnalités avancées de validation et de suivi de la qualité des données.

---

## Changements récents

### Version 2.0 - Novembre 2026

**Nouvelles fonctionnalités :**

1. **Système de validation**
   - Statuts de validation (Auto-extrait, À revoir, Validé, Modifié)
   - Indicateurs visuels (couleurs)
   - Gestion via l'interface

2. **Niveaux de confiance**
   - Calcul automatique du score d'extraction (0-100)
   - 5 niveaux de confiance (Très élevée, Élevée, Moyenne, Faible, Très faible)
   - Indicateurs visuels

3. **Familles standardisées**
   - 9 familles de produits prédéfinies
   - Détection automatique
   - Sélection manuelle

4. **Extraction améliorée**
   - 9 métriques détectables (vs 4 auparavant)
   - Détection améliorée des normes
   - Meilleure détection des applications

5. **Interface enrichie**
   - Filtres avancés (statut, confiance)
   - Affichage des indicateurs sur les cartes
   - Statistiques globales
   - Dialogue d'informations

6. **Gestion des données**
   - Adapters Hive pour les nouvelles énumérations
   - Migration automatique des anciennes données
   - Sauvegarde de tous les nouveaux champs

**Améliorations :**

- Meilleure extraction des métriques (débit, pression, puissance, vitesse, tension, courant, température, hauteur, diamètre)
- Détection des normes étendues (ISO, EN, DIN, NF, API, CE, UL, AFNOR, ANSI, ASME)
- Filtrage amélioré des éléments parasites dans les PowerPoint
- Interface plus intuitive avec indicateurs visuels
- Statistiques et analyses détaillées

**Corrections :**

- Gestion des encodages spéciaux dans les PowerPoint
- Migration des anciennes données vers le nouveau format
- Compatibilité ascendante maintenue

---

## Conclusion

Le module a réussi son objectif initial : centraliser et organiser les informations techniques produites à partir de supports PowerPoint, avec une logique qui reste lisible et modifiable par l'utilisateur.

La **version 2.0** ajoute des fonctionnalités avancées de :
- **Validation** : suivi de l'état des fiches
- **Confiance** : évaluation automatique de la qualité de l'extraction
- **Standardisation** : familles de produits normalisées
- **Analyse** : statistiques et indicateurs

La prochaine étape la plus utile est de :

1. **Valider les fiches existantes** : Utiliser le système de validation pour marquer les fiches comme validées ou à revoir
2. **Corriger les extractions de faible confiance** : Identifier les fiches avec un score de confiance faible et les corriger manuellement
3. **Standardiser les familles** : Utiliser les familles standardisées pour une meilleure cohérence
4. **Exploiter les statistiques** : Utiliser les statistiques pour identifier les tendances et les points à améliorer

Le module est maintenant prêt pour une utilisation intensive en production, avec des outils avancés de gouvernance et de qualité des données.
