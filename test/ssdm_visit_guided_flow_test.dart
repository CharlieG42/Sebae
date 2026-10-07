import 'package:flutter_test/flutter_test.dart';
import 'package:sebae/modules/ssdm/models/visit.dart';

void main() {
  group('Visites SSDM', () {
    test('gère les tâches de suivi après la visite', () {
      final visit = Visit(
        id: 'visit-1',
        year: 2026,
        clientId: 'client-1',
        title: 'Visite de prospection',
        appointmentDate: DateTime(2026, 10, 8, 9, 30),
        followUpTasks: const ['Envoyer le devis', 'Relancer le client'],
      );

      expect(visit.followUpTasks, const [
        'Envoyer le devis',
        'Relancer le client',
      ]);
      expect(visit.hasFollowUpTasks, isTrue);
      expect(visit.pendingFollowUpTasks, const [
        'Envoyer le devis',
        'Relancer le client',
      ]);
    });
  });
}
