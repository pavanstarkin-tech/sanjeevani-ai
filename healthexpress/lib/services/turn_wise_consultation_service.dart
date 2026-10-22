import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Data model representing a single turn in the doctor-patient consultation.
class ConsultationTurn {
  final int turnNumber;
  final String speakerName;
  final String speakerRole; // 'doctor' or 'patient'
  final bool isDoctor;
  final String text;
  final String audioAsset;
  final double durationSeconds;

  const ConsultationTurn({
    required this.turnNumber,
    required this.speakerName,
    required this.speakerRole,
    required this.isDoctor,
    required this.text,
    required this.audioAsset,
    required this.durationSeconds,
  });
}

/// Service managing the 10-turn structured clinical dialogue between AI Doctor (Dr. Shanni)
/// and Patient (Ramesh), allowing synchronized turn-by-turn playback, auto-advancing,
/// and bidirectional communication across AI Voice Call & Digital Avatar screens.
class TurnWiseConsultationService extends ChangeNotifier {
  static final TurnWiseConsultationService _instance = TurnWiseConsultationService._internal();
  factory TurnWiseConsultationService() => _instance;
  TurnWiseConsultationService._internal();

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _playerCompleteSub;
  Timer? _turnGapTimer;

  int _currentTurnIndex = 0;
  bool _isPlaying = false;
  bool _isAutoAdvance = true;
  bool _isTransitioning = false; // Transition gap between turns (thinking state)

  int get currentTurnIndex => _currentTurnIndex;
  bool get isPlaying => _isPlaying;
  bool get isAutoAdvance => _isAutoAdvance;
  bool get isTransitioning => _isTransitioning;

  ConsultationTurn get currentTurn => turns[_currentTurnIndex];

  /// The complete 10-turn clinical consultation between Dr. Shanni & Patient Ramesh
  static const List<ConsultationTurn> turns = [
    ConsultationTurn(
      turnNumber: 1,
      speakerName: 'Dr. Shanni',
      speakerRole: 'doctor',
      isDoctor: true,
      text: 'Hello! I am Dr. Shanni, your AI Clinical Specialist. How can I assist you with your health today?',
      audioAsset: 'audio/turn_01_priya.wav',
      durationSeconds: 6.49,
    ),
    ConsultationTurn(
      turnNumber: 2,
      speakerName: 'Ramesh (Patient)',
      speakerRole: 'patient',
      isDoctor: false,
      text: 'Hello Doctor. Since yesterday, I have a high fever, severe headache, and bad body chills.',
      audioAsset: 'audio/turn_02_amit.wav',
      durationSeconds: 7.02,
    ),
    ConsultationTurn(
      turnNumber: 3,
      speakerName: 'Dr. Shanni',
      speakerRole: 'doctor',
      isDoctor: true,
      text: 'I understand. Have you checked your body temperature, and do you also have a cough, cold, or throat pain?',
      audioAsset: 'audio/turn_03_priya.wav',
      durationSeconds: 7.25,
    ),
    ConsultationTurn(
      turnNumber: 4,
      speakerName: 'Ramesh (Patient)',
      speakerRole: 'patient',
      isDoctor: false,
      text: 'Yes, my temperature was 101.5 degrees Fahrenheit this morning, and I feel very weak and shivering.',
      audioAsset: 'audio/turn_04_amit.wav',
      durationSeconds: 7.60,
    ),
    ConsultationTurn(
      turnNumber: 5,
      speakerName: 'Dr. Shanni',
      speakerRole: 'doctor',
      isDoctor: true,
      text: 'Thank you for sharing that. Have you taken any medications like Paracetamol yet, and do you have any allergies?',
      audioAsset: 'audio/turn_05_priya.wav',
      durationSeconds: 6.66,
    ),
    ConsultationTurn(
      turnNumber: 6,
      speakerName: 'Ramesh (Patient)',
      speakerRole: 'patient',
      isDoctor: false,
      text: 'I took one Dolo 650 last night. It reduced the headache slightly, but the fever came back. I have no known allergies.',
      audioAsset: 'audio/turn_06_amit.wav',
      durationSeconds: 9.24,
    ),
    ConsultationTurn(
      turnNumber: 7,
      speakerName: 'Dr. Shanni',
      speakerRole: 'doctor',
      isDoctor: true,
      text: 'I see. Given acute fever with body ache, it could be a viral fever. Drink plenty of fluids, take oral electrolytes, and get complete bed rest.',
      audioAsset: 'audio/turn_07_priya.wav',
      durationSeconds: 11.52,
    ),
    ConsultationTurn(
      turnNumber: 8,
      speakerName: 'Ramesh (Patient)',
      speakerRole: 'patient',
      isDoctor: false,
      text: 'Doctor, should I get a blood test done, like a CBC or dengue test, or should I see a physician in person?',
      audioAsset: 'audio/turn_08_amit.wav',
      durationSeconds: 7.02,
    ),
    ConsultationTurn(
      turnNumber: 9,
      speakerName: 'Dr. Shanni',
      speakerRole: 'doctor',
      isDoctor: true,
      text: 'If the fever stays above 101 degrees for more than 48 hours, a CBC and Dengue NS1 test is recommended. If you experience severe dizziness or vomiting, visit an emergency clinic immediately.',
      audioAsset: 'audio/turn_09_priya.wav',
      durationSeconds: 15.87,
    ),
    ConsultationTurn(
      turnNumber: 10,
      speakerName: 'Ramesh (Patient)',
      speakerRole: 'patient',
      isDoctor: false,
      text: 'Thank you so much, Dr. Shanni. I will stay hydrated, take rest, and visit the hospital if symptoms persist.',
      audioAsset: 'audio/turn_10_amit.wav',
      durationSeconds: 7.63,
    ),
  ];

  void init() {
    _playerCompleteSub?.cancel();
    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      _onTurnAudioFinished();
    });
  }

  void setAutoAdvance(bool enabled) {
    _isAutoAdvance = enabled;
    notifyListeners();
  }

  /// Play turn at specific index
  Future<void> playTurn(int index) async {
    if (index < 0 || index >= turns.length) return;

    _turnGapTimer?.cancel();
    _currentTurnIndex = index;
    _isTransitioning = false;
    _isPlaying = true;
    notifyListeners();

    try {
      await _player.stop();
      final turn = turns[index];
      final fullPath = 'assets/${turn.audioAsset}';

      try {
        final byteData = await rootBundle.load(fullPath);
        final bytes = byteData.buffer.asUint8List();
        await _player.play(BytesSource(bytes));
      } catch (_) {
        await _player.play(AssetSource(turn.audioAsset));
      }
    } catch (e) {
      debugPrint('[TurnWiseConsultationService] Play error: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Called when audio for the active turn finishes
  void _onTurnAudioFinished() {
    _isPlaying = false;

    if (_isAutoAdvance && _currentTurnIndex < turns.length - 1) {
      // 700ms natural conversational transition gap
      _isTransitioning = true;
      notifyListeners();

      _turnGapTimer?.cancel();
      _turnGapTimer = Timer(const Duration(milliseconds: 700), () {
        _isTransitioning = false;
        playTurn(_currentTurnIndex + 1);
      });
    } else {
      _isTransitioning = false;
      notifyListeners();
    }
  }

  /// Pause current audio
  Future<void> pause() async {
    _turnGapTimer?.cancel();
    _isPlaying = false;
    _isTransitioning = false;
    try {
      await _player.pause();
    } catch (_) {}
    notifyListeners();
  }

  /// Resume or start from current turn
  Future<void> resume() async {
    if (_isPlaying) return;
    await playTurn(_currentTurnIndex);
  }

  /// Toggle play / pause
  Future<void> togglePlay() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Advance to next turn
  Future<void> nextTurn() async {
    if (_currentTurnIndex < turns.length - 1) {
      await playTurn(_currentTurnIndex + 1);
    }
  }

  /// Go back to previous turn
  Future<void> previousTurn() async {
    if (_currentTurnIndex > 0) {
      await playTurn(_currentTurnIndex - 1);
    }
  }

  /// Stop all playback and reset
  Future<void> stop() async {
    _turnGapTimer?.cancel();
    _isPlaying = false;
    _isTransitioning = false;
    try {
      await _player.stop();
    } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    _turnGapTimer?.cancel();
    _playerCompleteSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
