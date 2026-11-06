# Module Produits Techniques - Guide d'utilisation

## Présentation

Ce module permet de centraliser, organiser et exploiter les informations techniques des produits à partir de fichiers PowerPoint importés. Il offre une extraction automatique structurée avec des fonctionnalités avancées de validation et de suivi de la qualité des données.

## Nouveautés de la version 2.0

### 1. Système de Confiance et Validation

#### Niveaux de Confiance
Le module calcule automatiquement un **score d'extraction (0-100)** pour chaque fiche et attribue un niveau de confiance :

- **Très élevée** (90-100) : Extraction complète et fiable
- **Élevée** (70-89) : Bonne extraction avec quelques éléments
- **Moyenne** (50-69) : Extraction partielle
- **Faible** (30-49) : Peu d'informations extraites
- **Très faible** (0-29) : Extraction minimale

Le niveau de confiance est affiché directement sur la carte du produit avec un indicateur coloré.

#### Statuts de Validation
Chaque fiche peut avoir l'un des statuts suivants :

- **Auto-extrait** (bleu) : Fiche importée automatiquement, non validée
- **À revoir** (orange) : Fiche nécessitant une validation manuelle
- **Validé** (vert) : Fiche vérifiée et approuvée manuellement
- **Modifié manuellement** (violet) : Fiche modifiée après extraction

Vous pouvez modifier le statut via le dialogue de validation ou directement dans l'éditeur de fiche.

### 2. Familles de Produits Standardisées

9 familles de produits sont désormais disponibles :

1. **Pompage** : Pompes et systèmes de pompage
2. **Traitement** : Traitement des eaux et fluides
3. **Instrumentation** : Capteurs, mesure et contrôle
4. **Sécurité** : Systèmes de sécurité et protection
5. **Énergie** : Solutions énergétiques et électriques
6. **Mesure** : Appareils de mesure et analyse
7. **Filtration** : Systèmes de filtration
8. **Irrigation** : Systèmes d'irrigation et arrosage
9. **Autre** : Autres produits techniques

La détection est automatique mais peut être corrigée manuellement.

### 3. Extraction Améliorée

Le module détecte maintenant :

- **9 métriques** (contre 4 auparavant) :
  - Débit
  - Pression
  - Puissance
  - Vitesse
  - Tension
  - Courant
  - Température
  - Hauteur manométrique
  - Diamètre

- **Normes étendues** :
  - ISO, EN, DIN, NF, API, CE, UL, AFNOR, ANSI, ASME

- **Applications améliorées** :
  - Irrigation
  - Traitement
  - Pompage
  - Mesure
  - Sécurité
  - Énergie

### 4. Statistiques et Analyse

Accédez aux statistiques via le bouton **"Statistiques"** (icône 📊) :

- Nombre total de fiches
- Répartition par statut
- Répartition par famille
- Répartition par niveau de confiance
- Score d'extraction moyen

## Utilisation

### Import d'un PowerPoint

1. Cliquez sur le bouton **"Importer PowerPoint"** (icône 📄)
2. Sélectionnez un fichier `.ppt` ou `.pptx`
3. Le module extrait automatiquement les informations
4. La fiche est sauvegardée avec un statut **"Auto-extrait"**

### Validation des Fiches

Pour valider une fiche :

1. Cliquez sur l'icône **✓** (Valider) sur la carte du produit
2. Sélectionnez le nouveau statut dans le dialogue
3. Cliquez sur **"Enregistrer"**

Ou via l'éditeur :

1. Cliquez sur l'icône **✏️** (Modifier)
2. Modifiez le **"Statut de validation"** dans la section "Validation et Confiance"
3. Renseignez le **"Validateur"** (votre nom)
4. Enregistrez

### Filtrage Avancé

Utilisez les filtres en haut de l'écran :

- **Famille** : Filtrer par famille de produits
- **Tag** : Filtrer par tag
- **Usage** : Filtrer par application
- **Statut** : Filtrer par statut de validation
- **Confiance** : Filtrer par niveau de confiance

Cliquez sur **"Réinitialiser"** pour effacer tous les filtres.

### Correction Manuelle

Pour corriger une fiche :

1. Cliquez sur l'icône **✏️** (Modifier)
2. Modifiez les champs nécessaires :
   - Nom, famille, résumé
   - Tags, applications, informations clés
   - Caractéristiques, normes, métriques
   - Statut, niveau de confiance, notes
3. Cliquez sur **"Enregistrer"**

### Statistiques

Pour consulter les statistiques :

1. Cliquez sur le bouton **"Statistiques"** (icône 📊)
2. Consultez les différentes sections :
   - Par famille
   - Par statut
   - Par niveau de confiance
   - Score d'extraction moyen

## Migration des Anciennes Données

Si vous avez des données existantes, le module les migrera automatiquement :

- Les anciennes familles (String) seront converties en **ProductFamily** enum
- Les anciens statuts seront convertis en **ValidationStatus** enum
- Les anciens niveaux de confiance seront convertis en **ConfidenceLevel** enum

La migration est automatique et transparente. Aucune action n'est requise de votre part.

## Bonnes Pratiques

### Pour une extraction optimale

1. **Structurez vos PowerPoint** :
   - Utilisez des titres clairs
   - Organisez les informations avec des puces ou des numéros
   - Utilisez des labels explicites (Débit: 10 m3/h, Pression: 5 bar, etc.)

2. **Validez les fiches** :
   - Vérifiez les fiches avec un niveau de confiance **Faible** ou **Très faible**
   - Marquez les fiches comme **"À revoir"** si nécessaire
   - Validez les fiches correctes avec le statut **"Validé"**

3. **Utilisez les familles standard** :
   - Sélectionnez la famille la plus appropriée
   - Évitez d'utiliser **"Autre"** sauf si vraiment nécessaire

### Pour la gestion des données

1. **Corrigez les erreurs** :
   - Utilisez l'éditeur pour corriger les informations incorrectes
   - Ajoutez des notes pour documenter les corrections

2. **Maintenez la cohérence** :
   - Utilisez les mêmes termes pour les applications et tags
   - Standardisez les unités de mesure

3. **Exploitez les filtres** :
   - Utilisez les filtres pour trouver rapidement les fiches
   - Combinez plusieurs filtres pour des recherches avancées

## Dépannage

### Problèmes d'import

- **Le fichier ne s'importe pas** : Vérifiez que le fichier est bien au format `.ppt` ou `.pptx`
- **L'extraction est incomplète** : Le fichier PowerPoint peut avoir une structure complexe. Essayez de simplifier le fichier ou corrigez manuellement la fiche.

### Problèmes de migration

- **Les anciennes données ne s'affichent pas** : Essayez de fermer et rouvrir l'application. La migration devrait se faire automatiquement.
- **Erreurs de type** : Si vous voyez des erreurs liées aux types, exécutez manuellement la migration via le code.

### Problèmes d'affichage

- **Les couleurs ne s'affichent pas** : Vérifiez que votre thème Flutter supporte les couleurs.
- **Les indicateurs sont manquantes** : Assurez-vous que les champs `confidenceLevel` et `validationStatus` sont bien renseignés.

## API du Module

### TechnicalProductService

```dart
// Import
final service = context.read<TechnicalProductService>();

// Import d'un PowerPoint
await service.importFromPowerPoint(
  sourceName: 'mon_produit.pptx',
  bytes: fileBytes,
);

// Recherche
final results = service.searchAdvanced(
  query: 'pompe',
  family: ProductFamily.pompage,
  status: ValidationStatus.validated,
);

// Validation
final product = service.products.first;
await service.validateProduct(product.id, 'Jean Dupont', ValidationStatus.validated);

// Statistiques
final toReview = service.productsToReview;
final validated = service.validatedProducts;
final byFamily = service.getProductsByFamily(ProductFamily.pompage);
```

### TechnicalProduct

```dart
// Accès aux champs
final product = TechnicalProduct(...);
print(product.name);
print(product.productFamily.displayName);
print(product.confidenceLevel.displayName);
print(product.validationStatus.displayName);
print(product.extractionScore); // 0-100
print(product.statusColor); // Color
print(product.confidenceColor); // Color
```

## Structure des Fichiers

```
lib/modules/technical_products/
├── migration.dart              # Utilitaires de migration
├── technical_products_module.dart  # Définition du module
├── models/
│   ├── technical_product.dart  # Modèle principal
│   ├── product_family.dart     # Enum: Familles de produits
│   ├── validation_status.dart  # Enums: Statut et niveau de confiance
│   └── migration_adapter.dart  # Adapter de migration Hive
├── services/
│   └── technical_product_service.dart  # Service principal
└── views/
    └── technical_products_home.dart    # Vue principale
```

## Contribution

Pour contribuer au module :

1. **Améliorer l'extraction** :
   - Ajouter de nouveaux patterns de détection
   - Améliorer les algorithmes de scoring
   - Optimiser le nettoyage des données

2. **Ajouter des fonctionnalités** :
   - Export des données (CSV, PDF, Excel)
   - Comparaison de fiches
   - Historique des modifications
   - Tableau de bord

3. **Améliorer l'UI** :
   - Meilleure visualisation des métriques
   - Graphiques interactifs
   - Mode sombre

## Historique des Versions

### Version 2.0 - Novembre 2026
- ✅ Ajout des statuts de validation
- ✅ Ajout des niveaux de confiance
- ✅ Familles de produits standardisées
- ✅ Extraction améliorée (9 métriques, normes étendues)
- ✅ Statistiques globales
- ✅ Filtres avancés
- ✅ Migration automatique des anciennes données

### Version 1.0 - Version initiale
- Import PowerPoint
- Extraction automatique
- Correction manuelle
- Recherche et filtrage basique
- Persistance Hive

## Licence

Ce module fait partie de l'application Sebae et est distribué sous la même licence que le projet principal.

## Contact

Pour toute question ou suggestion concernant ce module, contactez l'équipe de développement Sebae.
