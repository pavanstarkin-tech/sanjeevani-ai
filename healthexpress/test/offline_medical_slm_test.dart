import 'package:flutter_test/flutter_test.dart';
import 'package:healthexpress/data/validated_first_aid_protocols.dart';
import 'package:healthexpress/models/offline_medical_models.dart';
import 'package:healthexpress/services/medical_slm_engine_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Validated First-Aid Protocols Test Suite', () {
    test('Protocols library contains critical emergency protocols', () {
      expect(ValidatedFirstAidProtocols.protocols.isNotEmpty, true);
      expect(ValidatedFirstAidProtocols.protocols.length, greaterThanOrEqualTo(10));

      final cpr = ValidatedFirstAidProtocols.protocols.firstWhere((p) => p.id == 'cpr_cardiac_arrest');
      expect(cpr.emergencyLevel, EmergencyTriageLevel.critical);
      expect(cpr.steps.any((s) => s.hasMetronome && s.metronomeBpm == 110), true);

      final choking = ValidatedFirstAidProtocols.protocols.firstWhere((p) => p.id == 'choking_heimlich');
      expect(choking.steps.isNotEmpty, true);
    });

    test('Query matching accurately resolves first-aid intents', () {
      final cprMatch = ValidatedFirstAidProtocols.findProtocolForQuery('patient collapsed not breathing need cpr');
      expect(cprMatch, isNotNull);
      expect(cprMatch!.id, 'cpr_cardiac_arrest');

      final chokingMatch = ValidatedFirstAidProtocols.findProtocolForQuery('someone is choking on food at dinner');
      expect(chokingMatch, isNotNull);
      expect(chokingMatch!.id, 'choking_heimlich');

      final snakeMatch = ValidatedFirstAidProtocols.findProtocolForQuery('snake bite on leg with fang puncture');
      expect(snakeMatch, isNotNull);
      expect(snakeMatch!.id, 'snake_bite');

      final burnMatch = ValidatedFirstAidProtocols.findProtocolForQuery('boiling water burn on hand blister');
      expect(burnMatch, isNotNull);
      expect(burnMatch!.id, 'burns_and_scalds');
    });

    test('Medical SLM Engine alerts via onError when no model is loaded into memory', () async {
      final engine = MedicalSlmEngineService();
      String? errorMessage;

      await engine.generateMedicalResponse(
        userQuery: 'How do I perform CPR on an adult?',
        onToken: (_) {},
        onComplete: (_) {},
        onError: (err) => errorMessage = err,
      );

      expect(errorMessage, isNotNull);
      expect(errorMessage!.contains('Local GGUF model is not loaded'), true);
    });

    test('Emergency guidance protocol helper provides validated triage', () {
      final engine = MedicalSlmEngineService();
      final guidance = engine.generateConversationalDoctorGuidance(
        userQuery: 'CPR emergency',
        lang: 'en',
      );
      expect(guidance.contains('Adult CPR'), true);
      expect(guidance.contains('108'), true);
    });
  });
}
