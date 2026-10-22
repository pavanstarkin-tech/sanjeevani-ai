import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthexpress/models/offline_medical_models.dart';
import 'package:healthexpress/services/medical_slm_engine_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SLM Command-Line Model Loading, Inference & Telemetry Verification', () {
    late String resolvedModelPath;
    final engine = MedicalSlmEngineService.instance;

    test('1. Workspace Model Detection & GGUF Magic Header Integrity', () async {
      print('\n================================================================');
      print('=== STEP 1: DETECTING WORKSPACE REPO GGUF MODEL ===');
      print('================================================================');

      final candidates = [
        File('${Directory.current.path}/models/qwen2.5-1.5b-instruct-q4_k_m.gguf'),
        File('models/qwen2.5-1.5b-instruct-q4_k_m.gguf'),
        File('c:/Users/shese/Desktop/healthyxpress_medha/healthexpress/models/qwen2.5-1.5b-instruct-q4_k_m.gguf'),
      ];

      File? targetFile;
      for (final f in candidates) {
        if (f.existsSync()) {
          targetFile = f;
          break;
        }
      }

      expect(targetFile, isNotNull, reason: 'GGUF model file must be present in workspace repo models/');
      resolvedModelPath = targetFile!.path;
      final fileLength = targetFile.lengthSync();
      print('[CLI Verified] Found model at: $resolvedModelPath');
      print('[CLI Verified] Size: ${(fileLength / (1024 * 1024)).toStringAsFixed(2)} MB ($fileLength bytes)');

      // Verify GGUF Magic Header: 'GGUF' (0x47, 0x47, 0x55, 0x46)
      final raf = targetFile.openSync(mode: FileMode.read);
      final header = raf.readSync(4);
      raf.closeSync();

      expect(header.length, 4);
      expect(header[0], 0x47, reason: 'Byte 0 must be 0x47 (G)');
      expect(header[1], 0x47, reason: 'Byte 1 must be 0x47 (G)');
      expect(header[2], 0x55, reason: 'Byte 2 must be 0x55 (U)');
      expect(header[3], 0x46, reason: 'Byte 3 must be 0x46 (F)');
      print('[CLI Verified] GGUF Magic Header matches [0x47, 0x47, 0x55, 0x46] ("GGUF") successfully!\n');
    });

    test('2. SLM Model Loading & Initialization', () async {
      print('================================================================');
      print('=== STEP 2: LOADING SLM MODEL INTO MEMORY ===');
      print('================================================================');

      final loadSw = Stopwatch()..start();
      await engine.loadModel(resolvedModelPath, promptFormat: 'chatml');
      loadSw.stop();

      print('[CLI Verified] Model Load State: ${engine.runState}');
      print('[CLI Verified] Engine isReady: ${engine.isReady}');
      print('[CLI Verified] Engine isModelLoaded: ${engine.isModelLoaded}');
      print('[CLI Verified] Load Duration: ${loadSw.elapsedMilliseconds} ms');

      expect(engine.isReady, isTrue);
      expect(engine.isModelLoaded, isTrue);
      expect(engine.loadedModelPath, equals(resolvedModelPath));
    });

    test('3. Conversational Clinical Inference - English (Fever & Body Ache)', () async {
      print('\n================================================================');
      print('=== STEP 3: CONVERSATIONAL INFERENCE - ENGLISH ===');
      print('================================================================');

      const userQuery = 'Hello doctor, I have a high fever of 101.5F since yesterday with body ache and chills.';
      print('User Prompt: "$userQuery"\n');
      print('--- Dr. Shanni Streaming Response ---');

      String generatedFullText = '';
      final metrics = await engine.generateMedicalResponse(
        userQuery: userQuery,
        lang: 'en',
        onToken: (tok) {
          stdout.write(tok);
        },
        onComplete: (full) {
          generatedFullText = full;
        },
        onError: (err) {
          fail('Inference error: $err');
        },
      );

      print('\n----------------------------------------');
      print('[CLI Telemetry Metrics]');
      print('⚡ Tokens Per Second (TPS): ${metrics.tokensPerSecond.toStringAsFixed(1)} tok/s');
      print('⏱️ Time To First Token (TTFT): ${metrics.timeToFirstTokenMs} ms');
      print('📊 Generated Tokens: ${metrics.generatedTokens}');
      print('⏳ Total Generation Time: ${metrics.totalGenerationMs} ms');
      print('🏷️ Formatted TPS Label: ${metrics.tpsLabel}');
      print('----------------------------------------');

      expect(generatedFullText.isNotEmpty, isTrue);
      expect(generatedFullText.toLowerCase().contains('fever') || generatedFullText.toLowerCase().contains('paracetamol') || generatedFullText.toLowerCase().contains('rest'), isTrue);
      expect(metrics.tokensPerSecond, greaterThan(15.0));
      expect(metrics.generatedTokens, greaterThan(10));
    });

    test('4. Conversational Clinical Inference - Telugu (తలనొప్పి & కళ్ళు తిరగడం)', () async {
      print('\n================================================================');
      print('=== STEP 4: CONVERSATIONAL INFERENCE - TELUGU (తెలుగు) ===');
      print('================================================================');

      const userQuery = 'నమస్కారం డాక్టర్, నాకు నిన్నటి నుండి చాలా తీవ్రమైన తలనొప్పిగా ఉంది మరియు కళ్ళు తిరుగుతున్నాయి.';
      print('User Prompt (Telugu): "$userQuery"\n');
      print('--- డాక్టర్ శన్నీ ప్రత్యుత్తరం (Streaming) ---');

      String generatedFullText = '';
      final metrics = await engine.generateMedicalResponse(
        userQuery: userQuery,
        lang: 'te',
        onToken: (tok) {
          stdout.write(tok);
        },
        onComplete: (full) {
          generatedFullText = full;
        },
        onError: (err) {
          fail('Telugu inference error: $err');
        },
      );

      print('\n----------------------------------------');
      print('[CLI Telemetry Metrics - Telugu]');
      print('⚡ Tokens Per Second (TPS): ${metrics.tokensPerSecond.toStringAsFixed(1)} tok/s');
      print('⏱️ Time To First Token (TTFT): ${metrics.timeToFirstTokenMs} ms');
      print('📊 Generated Tokens: ${metrics.generatedTokens}');
      print('⏳ Total Generation Time: ${metrics.totalGenerationMs} ms');
      print('----------------------------------------');

      expect(generatedFullText.isNotEmpty, isTrue);
      expect(generatedFullText.contains('తలనొప్పి') || generatedFullText.contains('పారాసిటమాల్') || generatedFullText.contains('విశ్రాంతి'), isTrue);
      expect(metrics.tokensPerSecond, greaterThan(15.0));
    });

    test('5. Conversational Clinical Inference - Hindi (पेट दर्द & एसिडिटी)', () async {
      print('\n================================================================');
      print('=== STEP 5: CONVERSATIONAL INFERENCE - HINDI (हिंदी) ===');
      print('================================================================');

      const userQuery = 'डॉक्टर मुझे आज सुबह से पेट में बहुत तेज दर्द और एसिडिटी महसूस हो रही है, क्या करूँ?';
      print('User Prompt (Hindi): "$userQuery"\n');
      print('--- डॉ. शन्नी परामर्श (Streaming) ---');

      String generatedFullText = '';
      final metrics = await engine.generateMedicalResponse(
        userQuery: userQuery,
        lang: 'hi',
        onToken: (tok) {
          stdout.write(tok);
        },
        onComplete: (full) {
          generatedFullText = full;
        },
        onError: (err) {
          fail('Hindi inference error: $err');
        },
      );

      print('\n----------------------------------------');
      print('[CLI Telemetry Metrics - Hindi]');
      print('⚡ Tokens Per Second (TPS): ${metrics.tokensPerSecond.toStringAsFixed(1)} tok/s');
      print('⏱️ Time To First Token (TTFT): ${metrics.timeToFirstTokenMs} ms');
      print('📊 Generated Tokens: ${metrics.generatedTokens}');
      print('⏳ Total Generation Time: ${metrics.totalGenerationMs} ms');
      print('----------------------------------------');

      expect(generatedFullText.isNotEmpty, isTrue);
      expect(generatedFullText.contains('पेट') || generatedFullText.contains('एसिडिटी') || generatedFullText.contains('पेंटोप्राजोल') || generatedFullText.contains('छाछ'), isTrue);
      expect(metrics.tokensPerSecond, greaterThan(15.0));
    });

    test('6. Model Unloading & State Reset', () async {
      print('\n================================================================');
      print('=== STEP 6: UNLOADING SLM MODEL ===');
      print('================================================================');

      await engine.unloadModel();
      print('[CLI Verified] Unload State: ${engine.runState}');
      print('[CLI Verified] Engine isReady: ${engine.isReady}');
      print('[CLI Verified] Loaded Path: ${engine.loadedModelPath}');

      expect(engine.isReady, isFalse);
      expect(engine.isModelLoaded, isFalse);
      expect(engine.loadedModelPath, isNull);
      expect(engine.runState, equals(EngineRunState.uninitialized));
      print('✅ All SLM Command-Line Verifications Succeeded Cleanly!\n');
    });
  });
}
