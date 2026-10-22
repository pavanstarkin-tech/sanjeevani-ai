import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../services/agora_rtc_service.dart';
import 'video_consultation_screen.dart';
import 'chat_screen.dart';

class AudioCallScreen extends StatefulWidget {
  final AppointmentModel appointment;
  const AudioCallScreen({super.key, required this.appointment});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _isBluetooth = false;
  int _callSeconds = 0;
  Timer? _timer;
  late AnimationController _waveController;
  bool _isAgoraConnected = false;
  double _micVolume = 0.0;
  Timer? _volumeTimer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });

    _volumeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && _isAgoraConnected && !_isMuted) {
        final vol = AgoraRtcService.getLiveAudioVolume();
        if ((vol - _micVolume).abs() > 0.04) {
          setState(() => _micVolume = vol);
        }
      }
    });

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initAgoraAudio();
  }

  void _initAgoraAudio() async {
    final channelName = 'audio_${widget.appointment.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';
    final res = await AgoraRtcService.joinCall(channelName: channelName, isVideo: false);
    if (mounted) {
      setState(() {
        _isAgoraConnected = res['success'] == true;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _volumeTimer?.cancel();
    _waveController.dispose();
    AgoraRtcService.leaveCall();
    super.dispose();
  }


  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showAudioOutputPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Audio Output', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.volume_up_rounded, color: Colors.white),
              title: const Text('Device Speaker', style: TextStyle(color: Colors.white)),
              trailing: _isSpeaker && !_isBluetooth ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                setState(() {
                  _isSpeaker = true;
                  _isBluetooth = false;
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
              title: const Text('Phone Earpiece', style: TextStyle(color: Colors.white)),
              trailing: !_isSpeaker && !_isBluetooth ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                setState(() {
                  _isSpeaker = false;
                  _isBluetooth = false;
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth_audio_rounded, color: Colors.white),
              title: const Text('Bluetooth Headset', style: TextStyle(color: Colors.white)),
              trailing: _isBluetooth ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                setState(() {
                  _isBluetooth = true;
                  _isSpeaker = false;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 16),

                // Top Header (Room Badge + Encryption Shield)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded, size: 12, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text(
                              'Agora HD Voice • ${_formatDuration(_callSeconds)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ChatScreen(appointment: widget.appointment)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Animated Acoustic Soundwave Rings
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 200 + (_waveController.value * 28),
                          height: 200 + (_waveController.value * 28),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.08 * (1 - _waveController.value)),
                          ),
                        ),
                        Container(
                          width: 170 + (_waveController.value * 18),
                          height: 170 + (_waveController.value * 18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.18 * (1 - _waveController.value)),
                          ),
                        ),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 65,
                            backgroundImage: NetworkImage(widget.appointment.doctorPhoto),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  widget.appointment.doctorName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.appointment.doctorSpecialty} • ${widget.appointment.hospitalName}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
                const SizedBox(height: 12),

                // Aarogyasri Link & Agora Audio Quality
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: AppColors.success, size: 12),
                          SizedBox(width: 4),
                          Text('Aarogyasri Health Pass Linked', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isAgoraConnected ? 'Agora Voice • Opus 48kHz' : 'Connecting Agora...',
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Switch to Video Call Floating Pill
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => VideoConsultationScreen(appointment: widget.appointment)),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Switch to HD Video Consultation', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Audio Controls Bottom Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute
                      _AudioActionBtn(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        isActive: _isMuted,
                        activeColor: AppColors.error,
                        onTap: () {
                          setState(() => _isMuted = !_isMuted);
                          AgoraRtcService.toggleAudioMute(_isMuted);
                        },
                      ),

                      // Speaker / Audio output
                      _AudioActionBtn(
                        icon: _isBluetooth
                            ? Icons.bluetooth_audio_rounded
                            : _isSpeaker
                                ? Icons.volume_up_rounded
                                : Icons.phone_in_talk_rounded,
                        label: _isBluetooth ? 'Bluetooth' : (_isSpeaker ? 'Speaker' : 'Earpiece'),
                        isActive: _isSpeaker || _isBluetooth,
                        onTap: _showAudioOutputPicker,
                      ),

                      // Keypad / Notes
                      _AudioActionBtn(
                        icon: Icons.dialpad_rounded,
                        label: 'Keypad',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keypad opened')));
                        },
                      ),

                      // End Call
                      GestureDetector(
                        onTap: () async {
                          await AgoraRtcService.leaveCall();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Voice consultation ended (${_formatDuration(_callSeconds)}). Summary saved.'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.emergency,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.emergency, blurRadius: 8, spreadRadius: 1),
                            ],
                          ),
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _AudioActionBtn({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
