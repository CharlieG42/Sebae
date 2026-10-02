import 'package:flutter_test/flutter_test.dart';

import 'package:sebae/modules/wuect/models/pompe.dart';
import 'package:sebae/modules/wuect/models/projet.dart';
import 'package:sebae/modules/wuect/models/systeme.dart';
import 'package:sebae/modules/wuect/services/calcul_service.dart';
import 'package:sebae/shared/models/contact.dart';
import 'package:sebae/shared/models/iv.dart';

void main() {
  group('Modèles WUECT', () {
    test('Projet référence contact et IV par UUID (String)', () {
      const contactId = '7f9c9f4a-1111-4222-8333-abcdef000001';
      const ivId = '7f9c9f4a-2222-4333-9444-abcdef000002';
      final projet = Projet(
        id: 1,
        nomSite: 'Station de relevage A',
        contactId: contactId,
        ivId: ivId,
        coutEnergie: 0.18,
        pourcentageAugmentationEnergie: 4.0,
        percentagePerteRendement: 1.0,
      );

      expect(projet.contactId, contactId);
      expect(projet.ivId, ivId);

      final copy = projet.copyWith(ivId: null);
      expect(copy.ivId, isNull);
      expect(copy.nomSite, 'Station de relevage A');
    });

    test('Pompe : P1 calculée et puissance corrigée', () {
      final pompe = Pompe(
        id: 1,
        systemeId: 1,
        marque: 'Grundfos',
        modele: 'NB 40-200',
        puissanceNominale: 7.5,
        debit: 100.0,
        hmt: 47.5,
        rendementInitialPompe: 80.0,
        rendementInitialMoteur: 90.0,
        anneeInstallation: 2015,
        heuresFonctionnement: 6000,
        coutInvestissement: 4200.0,
      );

      // P1 = (Q * HMT) / (367 * muPompe * muMoteur)
      final expected = (100.0 * 47.5) / (367 * 0.80 * 0.90);
      expect(pompe.p1Calculee, closeTo(expected, 0.0001));
      expect(pompe.puissanceUtilisee, pompe.p1Calculee);

      final corrigee = pompe.copyWith(p1Estimee: 20.0);
      expect(corrigee.puissanceUtilisee, 20.0);
      expect(corrigee.energieSpecifique, closeTo(20.0 / 100.0, 0.0001));
    });

    test('Systeme copyWith', () {
      final s = Systeme(
        id: 1,
        projetId: 5,
        nom: 'Ancien Système',
        coutInvestissementTotal: 12000.0,
      );
      final copy = s.copyWith(nom: 'Nouveau Système');
      expect(copy.nom, 'Nouveau Système');
      expect(copy.projetId, 5);
    });
  });

  group('Calculs comparatifs', () {
    test('calculerMuPerte : pas de perte la première année', () {
      final now = DateTime.now().year;
      expect(CalculService.calculerMuPerte(1.0, now, now), 1.0);
    });

    test('calculerMuPerte : dégradation exponentielle', () {
      final now = DateTime.now().year;
      // 2 ans écoulés, 1% de perte/an : mu = 0.99^2
      expect(
        CalculService.calculerMuPerte(1.0, now - 2, now),
        closeTo(0.99 * 0.99, 0.000001),
      );
    });

    test('calculerDonnees10AnsAvecPompes : 10 années positives', () {
      final projet = Projet(
        id: 1,
        nomSite: 'Test',
        contactId: 'c-uuid',
        coutEnergie: 0.2,
        pourcentageAugmentationEnergie: 2.0,
        percentagePerteRendement: 1.0,
      );
      final pompe = Pompe(
        id: 1,
        systemeId: 1,
        marque: 'Test',
        modele: 'T1',
        puissanceNominale: 10.0,
        debit: 100.0,
        hmt: 20.0,
        rendementInitialPompe: 80.0,
        rendementInitialMoteur: 90.0,
        anneeInstallation: DateTime.now().year - 1,
        heuresFonctionnement: 2000,
        coutInvestissement: 1000.0,
      );

      final result = CalculService.calculerDonnees10AnsAvecPompes(
        [pompe],
        projet,
      );

      expect(result['consommations']!.length, 10);
      expect(result['coutsEnergetiques']!.length, 10);
      for (final c in result['consommations']!) {
        expect(c, greaterThan(0.0));
      }
      // Le coût énergétique augmente chaque année (hausse annuelle 2%)
      final couts = result['coutsEnergetiques']!;
      for (int i = 1; i < couts.length; i++) {
        expect(couts[i], greaterThan(couts[i - 1]));
      }
    });
  });

  group('Entités partagées', () {
    test('IV partagé : trigramme et libellé court', () {
      final iv = Iv(id: 'iv1', name: 'Charles-Elie GENTIL', trigram: 'CEG');
      expect(iv.shortLabel, 'CEG');

      final sansTrigram = Iv(id: 'iv2', name: 'Alice');
      expect(sansTrigram.shortLabel, 'A');
      expect(sansTrigram.trigramOrEmpty, '');
    });

    test('Contact partagé : nom complet et affichage', () {
      final contact = Contact(
        id: 'c1',
        firstName: 'Jean',
        lastName: 'Dupont',
        position: 'Resp. technique',
      );
      expect(contact.fullName, 'Jean Dupont');
      expect(contact.displayName, 'Jean Dupont - Resp. technique');
    });
  });
}
