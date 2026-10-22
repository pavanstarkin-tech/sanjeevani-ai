import 'package:flutter/material.dart';
import '../../services/livekit_token_service.dart';
import 'live_healthcare_assistant_screen.dart';

/// Live Call Assistant Screen
/// Connects to LiveKit WebRTC Voice Agent with high-tech audio visualizer
class AiVoiceCallScreen extends StatelessWidget {
  const AiVoiceCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final roomName = 'room_$timestamp';
    final userId = 'user_$timestamp';
    final token = LiveKitTokenService.generateToken(roomName, userId);

    return LiveHealthcareAssistantScreen(
      initialAvatarMode: false,
      roomName: roomName,
      roomToken: token,
    );
  }
}
