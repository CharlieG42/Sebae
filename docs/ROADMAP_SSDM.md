# Feuille de route SSDM (Service Sales Dev Management)

## Fait (v1)

- Création d'une année (objectif de CA, reprise optionnelle des actions d'équipe de l'année précédente)
- Objectif CA : consultation / modification, couverture par le plan
- Sales Plan : lignes par IV × groupe × type, cible et réalisé
- Actions : création (IV ou équipe), échéance, statut, avancement avec historique
- Dashboard : cartes de synthèse, graphique plan vs réalisé par IV, avancement des actions
- Entités partagées : IV, groupes et types de clients (CRUD dans « Bases partagées »)

## Fait (v2 - actions liées au plan)

- Actions liées aux lignes du Sales Plan : badge compteur par ligne, création rapide pré-remplie, association/dissociation, navigation croisée Sales Plan ↔ Actions, filtre par ligne
- Étapes pondérées par action : libellé, poids, statut (à faire / en cours / fait / bloquée / annulée), échéance, réordonnancement
- Avancement calculé automatiquement depuis les étapes (sinon manuel), statut de l'action resynchronisé, badges « bloquée » / « en retard » dans la liste et le détail
- Création d'une année : recopie des étapes (statuts remis à zéro, échéances décalées) et du lien au Sales Plan
- Dashboard : radar (toile d'araignée) de l'avancement des actions, par IV ou par ligne du Sales Plan

## Prochaines étapes

- [ ] Répartition automatique de l'objectif CA par IV (prorata)
- [ ] Vue plan par groupe / type de clients (croisement)
- [ ] Filtrage des actions par IV / statut
- [ ] Import / export des données (JSON)
- [ ] Réalisé : saisie du CA par ligne de plan (actuellement en édition directe)
- [ ] Suivi mensuel du réalisé et courbe de tendance (fl_chart LineChart)
- [ ] Notifications d'échéance d'actions
