import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/vision_analysis_model.dart';
import '../../services/groq_vision_service.dart';
import '../../services/livekit_token_service.dart';
import '../../services/sarvam_live_stt_service.dart';
import '../../widgets/real_ai_lens_camera_view.dart';

/// Real-Time LiveKit WebRTC Healthcare Assistant & Live Doctor Avatar
/// Supports both:
/// 1. TEST MODE (AI_TEST_MODE=true in .env): Fully simulated UI, zero AI credits, no LiveKit room connections.
/// 2. LIVE MODE (AI_TEST_MODE=false in .env): Real LiveKit Cloud WebRTC streaming with Sarvam AI voice agent.
class LiveHealthcareAssistantScreen extends StatefulWidget {
  final String? livekitUrl;
  final String? roomToken;
  final String? roomName;
  final bool initialAvatarMode; // true = Live Doctor Avatar, false = Audio Call Assistant

  const LiveHealthcareAssistantScreen({
    super.key,
    this.livekitUrl,
    this.roomToken,
    this.roomName,
    this.initialAvatarMode = true,
  });

  @override
  State<LiveHealthcareAssistantScreen> createState() =>
      _LiveHealthcareAssistantScreenState();
}

class _LiveHealthcareAssistantScreenState
    extends State<LiveHealthcareAssistantScreen> with SingleTickerProviderStateMixin {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  late VideoPlayerController _talkingVideoController;
  late VideoPlayerController _processingVideoController;
  bool _isTalkingVideoInitialized = false;
  bool _isProcessingVideoInitialized = false;

  final GlobalKey<RealAiLensCameraViewState> _cameraKey = GlobalKey<RealAiLensCameraViewState>();
  bool _isCameraPermissionGranted = false;
  bool _isAnalyzingVision = false;
  Offset? _cameraPipOffset;

  bool _isTestMode = AppConfig.isAiTestMode;
  bool _isConnected = false;
  bool _isMicMuted = false;
  bool _isSpeakerOn = true;
  bool _isAiSpeaking = false;
  late bool _isDoctorAvatarMode;

  String _agentStatusText = "Initializing...";

  int _callDurationSeconds = 0;
  Timer? _durationTimer;
  Timer? _simulationTimer;
  int _simulationStep = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _isDoctorAvatarMode = widget.initialAvatarMode;
    _isTestMode = AppConfig.isAiTestMode;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isConnected) {
        setState(() => _callDurationSeconds++);
      }
    });

    _initAvatarVideos();

    if (_isDoctorAvatarMode) {
      _requestCameraPermission();
    }

    if (_isTestMode) {
      _initTestSimulationSession();
    } else {
      _connectToLiveKit();
    }
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted && mounted) {
        setState(() {
          _isCameraPermissionGranted = true;
        });
      }
    } catch (e) {
      debugPrint('[LiveHealthcareAssistantScreen] Camera permission error: $e');
    }
  }

  /// 1. Initialize Doctor Avatar talking and rest/thinking processing videos
  Future<void> _initAvatarVideos() async {
    try {
      _talkingVideoController = VideoPlayerController.asset(
        'assets/reels/robot_doctor_talking.mp4',
      );
      _processingVideoController = VideoPlayerController.asset(
        'assets/reels/robot_doctor_processing.mp4',
      );

      await Future.wait([
        _talkingVideoController.initialize(),
        _processingVideoController.initialize(),
      ]);

      await _talkingVideoController.setLooping(true);
      await _talkingVideoController.setVolume(0.0);
      await _talkingVideoController.pause();

      await _processingVideoController.setLooping(true);
      await _processingVideoController.setVolume(0.0);
      await _processingVideoController.play();

      if (mounted) {
        setState(() {
          _isTalkingVideoInitialized = true;
          _isProcessingVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('[LiveHealthcareAssistantScreen] Avatar video init error: $e');
    }
  }

  // ===========================================================================
  // TEST / SIMULATION MODE (AI_TEST_MODE = true in .env)
  // Zero AI credits used. No LiveKit room connections or cloud dispatch.
  // ===========================================================================
  void _initTestSimulationSession() {
    debugPrint('[LiveHealthcareAssistantScreen] >>> TEST MODE ACTIVE: Zero AI credits used. Simulating interactive consultation.');

    setState(() {
      _isConnected = true;
      _agentStatusText = "Dr. Shanni is online";
    });

    // Start with doctor greeting after 600ms
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _isTestMode) {
        _triggerSimulationStep(0);
      }
    });
  }

  void _triggerSimulationStep(int step) {
    if (!mounted || !_isTestMode) return;
    _simulationTimer?.cancel();
    _simulationStep = step % 4;

    switch (_simulationStep) {
      case 0: // Doctor Greeting (Speaking)
        setState(() {
          _isAiSpeaking = true;
          _agentStatusText = "Dr. Shanni is speaking...";
        });
        _syncAvatarPlayback(true);
        _simulationTimer = Timer(const Duration(seconds: 4), () {
          _triggerSimulationStep(1);
        });
        break;

      case 1: // Listening for patient response
        setState(() {
          _isAiSpeaking = false;
          _agentStatusText = "Listening... (Speak or tap mic)";
        });
        _syncAvatarPlayback(false);
        _simulationTimer = Timer(const Duration(seconds: 4), () {
          _triggerSimulationStep(2);
        });
        break;

      case 2: // Doctor Thinking / Clinical Triage
        setState(() {
          _isAiSpeaking = false;
          _agentStatusText = "Dr. Shanni is thinking...";
        });
        _syncAvatarPlayback(false);
        _simulationTimer = Timer(const Duration(milliseconds: 2500), () {
          _triggerSimulationStep(3);
        });
        break;

      case 3: // Doctor Advice (Speaking)
        setState(() {
          _isAiSpeaking = true;
          _agentStatusText = "Dr. Shanni is speaking...";
        });
        _syncAvatarPlayback(true);
        _simulationTimer = Timer(const Duration(seconds: 5), () {
          _triggerSimulationStep(1);
        });
        break;
    }
  }

  // ===========================================================================
  // LIVE MODE (AI_TEST_MODE = false in .env)
  // Connects to LiveKit Cloud with real-time Sarvam STT, LLM, and TTS.
  // ===========================================================================
  Future<void> _connectToLiveKit() async {
    // Determine room name and patient name prior to any async suspension
    final auth = context.read<AuthProvider>();
    final patientName =
        auth.currentUser.name.isNotEmpty ? auth.currentUser.name : 'Patient';

    // Request microphone permission
    final micStatus = await Permission.microphone.request();
    if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _agentStatusText = "Microphone permission required";
        });
      }
      return;
    }

    final roomName = widget.roomName ??
        'room-health-${DateTime.now().millisecondsSinceEpoch}';

    final token = widget.roomToken ??
        LiveKitTokenService.createToken(
          roomName: roomName,
          participantIdentity: 'patient-${DateTime.now().millisecondsSinceEpoch % 10000}',
          participantName: patientName,
        );

    final url = widget.livekitUrl ?? AppConfig.livekitUrl;

    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );

    _listener = room.createListener();

    _listener!
      ..on<ActiveSpeakersChangedEvent>((event) {
        _checkIfAgentIsSpeaking();
      })
      ..on<ParticipantAttributesChanged>((event) {
        _checkIfAgentIsSpeaking();
      })
      ..on<ParticipantConnectedEvent>((event) {
        if (mounted) {
          setState(() {
            _agentStatusText = "Dr. Shanni is online";
          });
        }
      })
      ..on<RoomDisconnectedEvent>((event) {
        if (mounted) {
          setState(() {
            _isConnected = false;
            _agentStatusText = "Call ended";
          });
          _syncAvatarPlayback(false);
        }
      });

    try {
      debugPrint('[LiveHealthcareAssistantScreen] Connecting to $url with room $roomName...');
      await room.connect(url, token);
      await room.localParticipant?.setMicrophoneEnabled(true);

      try {
        await AudioManager.instance.setSpeakerOutputPreferred(true);
      } catch (e) {
        debugPrint('[LiveHealthcareAssistantScreen] Speakerphone notice: $e');
      }

      if (mounted) {
        setState(() {
          _room = room;
          _isConnected = true;
          _agentStatusText = "Listening...";
        });
      }
    } catch (e) {
      debugPrint('[LiveHealthcareAssistantScreen] LiveKit connect error: $e');
      if (mounted) {
        setState(() {
          _agentStatusText = "Connection error: $e";
        });
      }
    }
  }

  /// 3. Detect whether the Sarvam/LiveKit Agent is currently speaking (Live Mode)
  void _checkIfAgentIsSpeaking() {
    if (_room == null || !mounted || _isTestMode) return;

    bool agentSpeaking = false;
    String status = "Listening...";

    for (final participant in _room!.remoteParticipants.values) {
      final agentState = participant.attributes['lk.agent.state'];

      if (participant.isSpeaking || agentState == 'speaking') {
        agentSpeaking = true;
        status = "Dr. Shanni is speaking...";
        break;
      } else if (agentState == 'thinking') {
        status = "Dr. Shanni is thinking...";
      }
    }

    if (agentSpeaking != _isAiSpeaking || status != _agentStatusText) {
      setState(() {
        _isAiSpeaking = agentSpeaking;
        _agentStatusText = status;
      });
      _syncAvatarPlayback(agentSpeaking);
    }
  }

  /// 4. Synchronize Avatar videos:
  /// - Speaking status: robot_doctor_talking.mp4
  /// - Rest / Thinking status: robot_doctor_processing.mp4
  void _syncAvatarPlayback(bool shouldPlay) {
    if (!_isTalkingVideoInitialized || !_isProcessingVideoInitialized) return;

    if (shouldPlay && _isDoctorAvatarMode) {
      if (_processingVideoController.value.isPlaying) {
        _processingVideoController.pause();
      }
      if (!_talkingVideoController.value.isPlaying) {
        _talkingVideoController.seekTo(Duration.zero);
        _talkingVideoController.play();
      }
    } else if (_isDoctorAvatarMode) {
      if (_talkingVideoController.value.isPlaying) {
        _talkingVideoController.pause();
        _talkingVideoController.seekTo(Duration.zero);
      }
      if (!_processingVideoController.value.isPlaying) {
        _processingVideoController.play();
      }
    }
  }

  Future<void> _toggleMic() async {
    final nextState = !_isMicMuted;
    if (mounted) {
      setState(() {
        _isMicMuted = nextState;
      });
    }

    if (!_isTestMode && _room?.localParticipant != null) {
      try {
        await _room!.localParticipant!.setMicrophoneEnabled(!nextState);
      } catch (e) {
        debugPrint('[LiveHealthcareAssistantScreen] Mic toggle error: $e');
      }
    }
  }

  Future<void> _toggleSpeaker() async {
    if (_isTestMode) {
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
      });
      return;
    }

    try {
      final nextSpeaker = !_isSpeakerOn;
      await AudioManager.instance.setSpeakerOutputPreferred(nextSpeaker);
      if (mounted) {
        setState(() {
          _isSpeakerOn = nextSpeaker;
        });
      }
    } catch (e) {
      debugPrint('[LiveHealthcareAssistantScreen] Speaker toggle error: $e');
    }
  }

  /// Captures frame from live camera feed, analyzes via Groq Vision API,
  /// and passes extracted diagnostic data to Dr. Shanni avatar
  Future<void> _analyzeCameraVision() async {
    if (_isAnalyzingVision) return;
    setState(() {
      _isAnalyzingVision = true;
      _agentStatusText = "Scanning camera view with Groq AI...";
    });

    try {
      // 1. Capture snapshot from live camera viewfinder
      final frameBase64 = await _cameraKey.currentState?.captureFrame();
      if (frameBase64 == null || frameBase64.isEmpty) {
        if (mounted) {
          setState(() {
            _isAnalyzingVision = false;
            _agentStatusText = "Could not capture camera frame";
          });
        }
        return;
      }

      // 2. Pass frame to Groq Cloud Vision model
      final result = await GroqVisionService.analyzeImage(
        base64Image: frameBase64,
        preferredLanguage: 'English',
      );

      // 3. Build spoken response for Dr. Shanni
      String doctorDiagnosisSpeech;
      if (result.isFace || result.scope == VisionScope.general) {
        final rec = result.homeCareTips.isNotEmpty
            ? result.homeCareTips.first
            : (result.healthVerdict.isNotEmpty ? result.healthVerdict : 'You appear alert and responsive.');
        doctorDiagnosisSpeech = "Hello! I can clearly see your face in the live camera feed. ${result.description}. $rec";
      } else if (result.isFood) {
        doctorDiagnosisSpeech = "Hello! I can see ${result.name}. It provides approximately ${result.calories} calories with a health score of ${result.healthScore} out of 10. ${result.healthVerdict}";
      } else if (result.isInfection) {
        final causes = result.probableCauses.isNotEmpty ? result.probableCauses.first : 'clinical symptoms';
        final care = result.homeCareTips.isNotEmpty ? result.homeCareTips.first : 'keep the area clean and dry';
        doctorDiagnosisSpeech = "Hello! I observe signs of ${result.name}, with ${result.infectionSeverity} severity caused by $causes. My recommendation is: $care.";
      } else {
        final uses = result.medicalUses.isNotEmpty ? result.medicalUses.first : 'treatment';
        doctorDiagnosisSpeech = "Hello! I see ${result.name}, containing ${result.composition}. It is commonly used for $uses. Suggested dosage: ${result.dosageGuidelines}.";
      }

      // 4. Send to LiveKit Voice Agent (Live Mode)
      if (!_isTestMode && _room != null) {
        try {
          final payload = utf8.encode(jsonEncode({
            'type': 'vision_analysis',
            'text': doctorDiagnosisSpeech,
            'name': result.name,
            'scope': result.scope.name,
          }));
          await _room!.localParticipant?.publishData(payload);
        } catch (e) {
          debugPrint('[LiveHealthcareAssistantScreen] Vision publishData error: $e');
        }
      }

      // 5. Update UI & trigger Dr. Shanni Avatar speaking response
      if (mounted) {
        setState(() {
          _isAnalyzingVision = false;
          _isAiSpeaking = true;
          _agentStatusText = "Dr. Shanni: $doctorDiagnosisSpeech";
        });
        _syncAvatarPlayback(true);
        SarvamLiveSttService.speakText(doctorDiagnosisSpeech, 'en');

        // Display rich Visual Clinical Comparison Sheet
        _showVisualComparisonSheet(context, result, frameBase64);

        // Keep avatar speaking for 7 seconds, then return to listening
        Timer(const Duration(seconds: 7), () {
          if (mounted) {
            setState(() {
              _isAiSpeaking = false;
              _agentStatusText = "Dr. Shanni is listening...";
            });
            _syncAvatarPlayback(false);
          }
        });
      }
    } catch (e) {
      debugPrint('[LiveHealthcareAssistantScreen] Vision analysis error: $e');
      if (mounted) {
        setState(() {
          _isAnalyzingVision = false;
          _agentStatusText = "Vision scan error. Please try again.";
        });
      }
    }
  }

  /// Displays a rich Clinical Visual Comparison Bottom Sheet with Dr. Shanni's analysis
  void _showVisualComparisonSheet(
    BuildContext context,
    VisionAnalysisResult result,
    String? imageBase64,
  ) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF14B8A6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.remove_red_eye_rounded, size: 14, color: Color(0xFF2DD4BF)),
                        SizedBox(width: 5),
                        Text(
                          "Dr. Shanni Visual Comparison",
                          style: TextStyle(
                            color: Color(0xFF2DD4BF),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Side-by-side or Preview Card
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageBase64 != null && imageBase64.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 90,
                        height: 110,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.memory(
                          base64Decode(imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 40, color: Colors.white54),
                        ),
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            result.isFace
                                ? "Clinical Facial Examination"
                                : (result.isFood
                                    ? "Nutrition & Diet"
                                    : (result.isInfection ? "Dermatology & Skin" : "Medicine & Rx")),
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.description,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (result.symptomsObserved.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  "Key Visual Observations:",
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: result.symptomsObserved.take(3).map((sym) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF34D399)),
                          const SizedBox(width: 4),
                          Text(
                            sym,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (result.homeCareTips.isNotEmpty || result.healthVerdict.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.healthVerdict.isNotEmpty
                              ? result.healthVerdict
                              : result.homeCareTips.first,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  label: const Text("Discuss Live with Dr. Shanni", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (_isMicMuted) {
                      _toggleMic();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _simulationTimer?.cancel();
    _pulseController.dispose();
    _listener?.dispose();
    _room?.disconnect();
    _room?.dispose();
    if (_isTalkingVideoInitialized) {
      _talkingVideoController.dispose();
    }
    if (_isProcessingVideoInitialized) {
      _processingVideoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDoctorAvatarMode ? const Color(0xFFEFF4F9) : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            _room?.disconnect();
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isDoctorAvatarMode ? "Dr. Shanni • Sanjeevani.ai" : "AI Call Assistant",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? const Color(0xFF16A34A) : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnected ? _formatDuration(_callDurationSeconds) : 'Connecting...',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),

                // Mode Badge & Live Status Indicator (Clean, no blue fade)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isAiSpeaking
                            ? Icons.volume_up_rounded
                            : (_isConnected ? Icons.hearing_rounded : Icons.sync_rounded),
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _agentStatusText,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Center Display: Doctor Video Avatar OR Clean Pulsing Voice Visualizer
                Expanded(
                  child: Center(
                    child: _isDoctorAvatarMode
                        ? _buildDoctorAvatarView()
                        : _buildAudioAssistantView(),
                  ),
                ),

                // Bottom Call Controls (Equal size: Speaker on Left, Cut in Center, Mute on Right)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0, top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. Speaker Toggle (Left)
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: FloatingActionButton(
                          heroTag: "speaker_btn",
                          elevation: 2,
                          backgroundColor: _isSpeakerOn ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                          onPressed: _isConnected ? _toggleSpeaker : null,
                          shape: const CircleBorder(),
                          child: Icon(
                            _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            color: _isSpeakerOn ? AppColors.primary : AppColors.textMuted,
                            size: 26,
                          ),
                        ),
                      ),

                      // 2. End Call / Cut Option (Center)
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: FloatingActionButton(
                          heroTag: "end_call_btn",
                          elevation: 4,
                          backgroundColor: AppColors.emergency,
                          onPressed: () {
                            _simulationTimer?.cancel();
                            _room?.disconnect();
                            Navigator.of(context).pop();
                          },
                          shape: const CircleBorder(),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),

                      // 3. Mute / Unmute Mic Button (Right)
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: FloatingActionButton(
                          heroTag: "mic_btn",
                          elevation: 2,
                          backgroundColor: _isMicMuted ? const Color(0xFFFEE2E2) : AppColors.surface,
                          onPressed: _isConnected ? _toggleMic : null,
                          tooltip: _isMicMuted ? "Unmute" : "Mute",
                          shape: const CircleBorder(),
                          child: Icon(
                            _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            color: _isMicMuted ? AppColors.error : AppColors.textPrimary,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Draggable Camera Live Feed Window (Doctor Avatar Mode)
            if (_isDoctorAvatarMode && _isCameraPermissionGranted)
              _buildDraggableCameraFeed(context),
          ],
        ),
      ),
    );
  }

  /// Renders Doctor Avatar Video:
  /// - Speaking status: plays talking video
  /// - Rest / Thinking status: plays processing video
  Widget _buildDoctorAvatarView() {
    if (!_isTalkingVideoInitialized && !_isProcessingVideoInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final activeController = (_isAiSpeaking && _isTalkingVideoInitialized)
        ? _talkingVideoController
        : _processingVideoController;

    final aspectRatio = activeController.value.isInitialized && activeController.value.aspectRatio > 0
        ? activeController.value.aspectRatio
        : 9 / 16;

    return Padding(
      padding: const EdgeInsets.only(top: 63.0, bottom: 8.0),
      child: Center(
        child: Transform.scale(
          scale: 1.25,
          child: AspectRatio(
            aspectRatio: aspectRatio,
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.08, 0.72, 0.98],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.06, 0.94, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isProcessingVideoInitialized)
                    Opacity(
                      opacity: _isAiSpeaking ? 0.0 : 1.0,
                      child: VideoPlayer(_processingVideoController),
                    ),
                  if (_isTalkingVideoInitialized)
                    Opacity(
                      opacity: _isAiSpeaking ? 1.0 : 0.0,
                      child: VideoPlayer(_talkingVideoController),
                    ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  /// Renders standard Live Call Assistant view (Clean pulsating orb - No center icon)
  Widget _buildAudioAssistantView() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        final scale = _isAiSpeaking ? (1.0 + pulse * 0.12) : (1.0 + pulse * 0.04);
        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ripple 2 (when AI is speaking)
              if (_isAiSpeaking)
                Container(
                  width: 240 * (1.0 + pulse * 0.15),
                  height: 240 * (1.0 + pulse * 0.15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08 * (1.0 - pulse)),
                  ),
                ),
              // Outer Ripple 1
              Container(
                width: 200 * scale,
                height: 200 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: _isAiSpeaking ? 0.14 : 0.06),
                ),
              ),
              // Main Visualizer Sphere (No center icon - sleek high-tech orb)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: _isAiSpeaking ? 0.40 : 0.22),
                      blurRadius: _isAiSpeaking ? 36 + (pulse * 16) : 22,
                      spreadRadius: _isAiSpeaking ? 4 + (pulse * 4) : 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                        center: const Alignment(-0.3, -0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Draggable Live Camera Feed Window for Dr. Arogya Avatar
  /// Defaults to bottom-right, draggable anywhere across the screen.
  /// Features a top-right corner camera icon button and responds to taps by analyzing
  /// the captured frame through Groq Vision API.
  Widget _buildDraggableCameraFeed(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    const feedWidth = 118.0;
    const feedHeight = 168.0;

    final defaultLeft = screen.width - feedWidth - 16.0;
    final defaultTop = screen.height - feedHeight - 165.0;

    final currentLeft = (_cameraPipOffset?.dx ?? defaultLeft).clamp(10.0, screen.width - feedWidth - 10.0);
    final currentTop = (_cameraPipOffset?.dy ?? defaultTop).clamp(70.0, screen.height - feedHeight - 80.0);

    return Positioned(
      left: currentLeft,
      top: currentTop,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final nextX = (currentLeft + details.delta.dx).clamp(10.0, screen.width - feedWidth - 10.0);
            final nextY = (currentTop + details.delta.dy).clamp(70.0, screen.height - feedHeight - 80.0);
            _cameraPipOffset = Offset(nextX, nextY);
          });
        },
        onTap: _analyzeCameraVision,
        child: Container(
          width: feedWidth,
          height: feedHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isAnalyzingVision ? AppColors.primary : Colors.white,
              width: _isAnalyzingVision ? 3.0 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isAnalyzingVision
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.22),
                blurRadius: _isAnalyzingVision ? 18 : 12,
                spreadRadius: _isAnalyzingVision ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Live camera viewfinder stream (defaults to front/selfie camera facing patient)
              RealAiLensCameraView(key: _cameraKey, preferFrontCamera: true),

              // Scanning indicator overlay during Groq Vision processing
              if (_isAnalyzingVision)
                Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Dr. Shanni Vision",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Top-right corner camera snapshot button
              Positioned(
                top: 8,
                right: 8,
                child: Tooltip(
                  message: "Click to examine your face with Dr. Shanni",
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _analyzeCameraVision,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isAnalyzingVision ? AppColors.primary : Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isAnalyzingVision ? const Color(0xFF2DD4BF) : Colors.white70,
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (!_isAnalyzingVision)
                              BoxShadow(
                                color: const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Top-left camera switcher icon
              Positioned(
                top: 8,
                left: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await _cameraKey.currentState?.switchCamera();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 1),
                      ),
                      child: const Icon(
                        Icons.flip_camera_ios_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom subtle hint badge
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Tap to diagnose",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
