import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthexpress/services/sarvam_live_stt_service_stub.dart';
import 'package:healthexpress/services/nvidia_ai_service.dart';
import 'package:healthexpress/services/turn_wise_consultation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. AI Doctor Language Detection Engine QA Tests', () {
    test('Detects Native Telugu Unicode Script accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('నాకు తీవ్రమైన జ్వరం మరియు తలనొప్పి ఉంది');
      expect(detected, equals('te'));
    });

    test('Detects Romanized Telugu / Tenglish keywords accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('naku rendu rojula nundi jwaram undi mandulu ivvandi');
      expect(detected, equals('te'));
    });

    test('Detects Native Hindi Devanagari Script accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('मुझे बहुत तेज़ बुखार और पेट दर्द है');
      expect(detected, equals('hi'));
    });

    test('Detects Romanized Hindi / Hinglish keywords accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('mujhe kal se pet dard aur bukhar ho raha hai dawa chahiye');
      expect(detected, equals('hi'));
    });

    test('Detects English clinical questions accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('I am experiencing high fever, headache and severe cough since yesterday');
      expect(detected, equals('en'));
    });

    test('Detects Native Tamil Unicode Script accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('எனக்கு கடுமையான காய்ச்சல் உள்ளது');
      expect(detected, equals('ta'));
    });

    test('Detects Native Kannada Unicode Script accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('ನನಗೆ ಜ್ವರ ಮತ್ತು ತಲೆನೋವು ಇದೆ');
      expect(detected, equals('kn'));
    });

    test('Detects Native Malayalam Unicode Script accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('എനിക്ക് പനിയും തലവേദനയും ഉണ്ട്');
      expect(detected, equals('ml'));
    });

    test('Detects Native Bengali Unicode Script accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('আমার খুব জ্বর হয়েছে এবং মাথা ব্যথা করছে');
      expect(detected, equals('bn'));
    });

    test('Detects Native Gujarati Unicode Script accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('મને ખૂબ તાવ આવ્યો છે અને માથું દુખે છે');
      expect(detected, equals('gu'));
    });

    test('Detects Native Punjabi Unicode Script accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('ਮੈਨੂੰ ਬੁਖਾਰ ਹੈ ਅਤੇ ਸਿਰ ਦਰਦ ਹੋ ਰਿਹਾ ਹੈ');
      expect(detected, equals('pa'));
    });

    test('Detects Native Odia Unicode Script accurately', () {
      final detected = SarvamLiveSttService.detectLanguage('ମୋତେ ଜ୍ୱର ହୋଇଛି ଏବଂ ମୁଣ୍ଡ ବିନ୍ଧୁଛି');
      expect(detected, equals('or'));
    });

    test('Preserves current language when input is empty or ambiguous', () {
      final emptyResult = SarvamLiveSttService.detectLanguage('', 'te');
      expect(emptyResult, equals('te'));

      final spaceResult = SarvamLiveSttService.detectLanguage('   ', 'hi');
      expect(spaceResult, equals('hi'));
    });
  });

  group('2. Multilingual Welcome Audio & Greetings QA Tests', () {
    final allLanguages = ['en', 'te', 'hi', 'ta', 'kn', 'ml', 'bn', 'mr', 'gu', 'pa', 'or'];

    test('Every Indic language maps to a valid prebuilt welcome audio asset path', () {
      for (final lang in allLanguages) {
        final path = SarvamLiveSttService.getWelcomeAudioPath(lang);
        expect(path, startsWith('audio/welcome_'));
        expect(path, endsWith('.mp3'));
      }
    });

    test('Welcome audio path specifically matches language code', () {
      expect(SarvamLiveSttService.getWelcomeAudioPath('te'), equals('audio/welcome_te.mp3'));
      expect(SarvamLiveSttService.getWelcomeAudioPath('hi'), equals('audio/welcome_hi.mp3'));
      expect(SarvamLiveSttService.getWelcomeAudioPath('en'), equals('audio/welcome_en.mp3'));
      expect(SarvamLiveSttService.getWelcomeAudioPath('ta'), equals('audio/welcome_ta.mp3'));
    });

    test('Initial clinical greetings are authentic and tailored per language', () {
      final teGreeting = SarvamLiveSttService.getInitialGreeting('te');
      expect(teGreeting, contains('డాక్టర్ షణ్ముఖి'));
      expect(teGreeting, contains('ఆరోగ్య సమస్య'));

      final hiGreeting = SarvamLiveSttService.getInitialGreeting('hi');
      expect(hiGreeting, contains('डॉ. षण्मुखी'));
      expect(hiGreeting, contains('तकलीफ़'));

      final enGreeting = SarvamLiveSttService.getInitialGreeting('en');
      expect(enGreeting, contains('Dr. Shanni'));
      expect(enGreeting, contains('symptoms'));
    });
  });

  group('3. LiveKit Telemetry & Turn-Taking Loop QA Tests', () {
    test('getLiveKitStatus returns all required keys including language', () {
      final status = SarvamLiveSttService.getLiveKitStatus();
      expect(status.containsKey('isConnected'), isTrue);
      expect(status.containsKey('isConnecting'), isTrue);
      expect(status.containsKey('isAgentSpeaking'), isTrue);
      expect(status.containsKey('isUserSpeaking'), isTrue);
      expect(status.containsKey('lastMessage'), isTrue);
      expect(status.containsKey('language'), isTrue);
      expect(status['language'], isNotEmpty);
    });

    test('sendLiveKitData properly parses language_change events and updates session', () {
      SarvamLiveSttService.sendLiveKitData(jsonEncode({
        'type': 'language_change',
        'language': 'te',
      }));

      final status = SarvamLiveSttService.getLiveKitStatus();
      expect(status['language'], equals('te'));
    });

    test('Switching language updates greeting in status telemetry', () {
      SarvamLiveSttService.sendLiveKitData(jsonEncode({
        'type': 'language_change',
        'language': 'hi',
      }));

      final status = SarvamLiveSttService.getLiveKitStatus();
      expect(status['language'], equals('hi'));
      expect(status['lastMessage'], contains('डॉ. षण्मुखी'));
    });
  });

  group('4. Clinical AI Clinical Reasoning Engine QA Tests', () {
    test('NvidiaAiService generates clinical guidance in voice mode for acute symptoms', () async {
      final response = await NvidiaAiService.generateResponse(
        userQuery: 'I have severe migraine headache with sensitivity to light since morning',
        lang: 'en',
        patientName: 'TestPatient',
        isVoiceMode: true,
      );

      expect(response.content, isNotEmpty);
      expect(response.triageCategory, isNotEmpty);
      // Voice mode response is concise (under 1200 characters)
      expect(response.content.length, lessThan(1200));
    });

    test('NvidiaAiService handles Telugu clinical query correctly', () async {
      final response = await NvidiaAiService.generateResponse(
        userQuery: 'నాకు తీవ్రమైన జ్వరం మరియు గొంతు నొప్పి ఉంది',
        lang: 'te',
        patientName: 'రమేష్',
        isVoiceMode: true,
      );

      expect(response.content, isNotEmpty);
      expect(response.triageCategory, isNotEmpty);
    });
  });

  group('5. Turn-Wise Consultation Service & Telemetry QA Tests', () {
    test('Turn-Wise Consultation contains exactly 10 structured turns', () {
      expect(TurnWiseConsultationService.turns.length, equals(10));
    });

    test('Turn-Wise Consultation strictly alternates between Doctor and Patient', () {
      for (int i = 0; i < TurnWiseConsultationService.turns.length; i++) {
        final turn = TurnWiseConsultationService.turns[i];
        expect(turn.turnNumber, equals(i + 1));
        if (i % 2 == 0) {
          expect(turn.isDoctor, isTrue, reason: 'Turn ${i + 1} must be AI Doctor');
          expect(turn.speakerName, equals('Dr. Shanni'));
        } else {
          expect(turn.isDoctor, isFalse, reason: 'Turn ${i + 1} must be Patient');
          expect(turn.speakerName, equals('Ramesh (Patient)'));
        }
        expect(turn.text, isNotEmpty);
        expect(turn.audioAsset, startsWith('audio/turn_'));
        expect(turn.audioAsset, endsWith('.wav'));
        expect(turn.durationSeconds, greaterThan(5.0));
      }
    });

    test('LiveKit Status telemetry reports turn counter accurately', () {
      final status = SarvamLiveSttService.getLiveKitStatus();
      expect(status.containsKey('turn'), isTrue);
      expect(status['turn'], isA<int>());
      expect(status['turn'], greaterThanOrEqualTo(1));
    });
  });
}
