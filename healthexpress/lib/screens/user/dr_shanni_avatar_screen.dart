import 'package:flutter/material.dart';
import '../../services/livekit_token_service.dart';
import 'live_healthcare_assistant_screen.dart';

/// Dr. Shanni / Dr. Arogya Live Doctor Avatar Screen
/// Connects to LiveKit WebRTC Voice Agent with synchronized Doctor Avatar video playback
class DrShanniAvatarScreen extends StatelessWidget {
  const DrShanniAvatarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final roomName = 'room_$timestamp';
    final userId = 'user_$timestamp';
    final token = LiveKitTokenService.generateToken(roomName, userId);

    return LiveHealthcareAssistantScreen(
      initialAvatarMode: true,
      roomName: roomName,
      roomToken: token,
    );
  }
}
