import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../services/agora_rtc_service.dart';
import '../../widgets/real_ai_lens_camera_view.dart';
import 'chat_screen.dart';

class VideoConsultationScreen extends StatefulWidget {
  final AppointmentModel appointment;
  const VideoConsultationScreen({super.key, required this.appointment});

  @override
  State<VideoConsultationScreen> createState() => _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<RealAiLensCameraViewState> _patientCameraKey = GlobalKey<RealAiLensCameraViewState>();
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  bool _showVitalsHud = true;
  final bool _isRemoteVideoOff = false;
  int _callSeconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  bool _isAgoraConnected = false;
  double _micVolume = 0.0;
  Timer? _volumeTimer;


  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _callSeconds++);
      }
    });

    _volumeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && _isAgoraConnected && !_isMuted) {
        final vol = AgoraRtcService.getLiveAudioVolume();
        if ((vol - _micVolume).abs() > 0.05) {
          setState(() => _micVolume = vol);
        }
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initAgora();
  }

  void _initAgora() async {
    final channelName = 'consult_${widget.appointment.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';
    final res = await AgoraRtcService.joinCall(channelName: channelName, isVideo: true);
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
    _pulseController.dispose();
    AgoraRtcService.leaveCall();
    super.dispose();
  }


  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showPrescriptionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Electronic Prescription (Rx)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Issued by ${widget.appointment.doctorName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
                      SizedBox(width: 4),
                      Text('Aarogyasri Valid', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),

            // Diagnosed Condition
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.medical_information_rounded, size: 20, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Clinical Diagnosis', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text('Acute Upper Respiratory Tract Infection (Fever & Pharyngitis)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Prescribed Medications
            const Text('Prescribed Medications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const _MedicationItem(
              name: 'Dolo 650 (Paracetamol 650mg)',
              dosage: '1 tablet after meals (SOS for fever)',
              duration: '3 Days',
            ),
            const _MedicationItem(
              name: 'Azithral 500 (Azithromycin 500mg)',
              dosage: '1 tablet once daily after breakfast',
              duration: '5 Days',
            ),
            const _MedicationItem(
              name: 'Alex Syrup (Dextromethorphan + CPM)',
              dosage: '10ml thrice daily after food',
              duration: '5 Days',
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                label: const Text('Order Medicines via HealthExpress Pharmacy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prescription sent to 24/7 Express Delivery Pharmacy!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showEndCallConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.call_end_rounded, color: AppColors.emergency),
            SizedBox(width: 8),
            Text('End Consultation?'),
          ],
        ),
        content: Text(
          'Are you sure you want to end your consultation with ${widget.appointment.doctorName}? Consultation summary will be saved to your health records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await AgoraRtcService.leaveCall();
              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Pop consultation screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Consultation completed (${_formatDuration(_callSeconds)}). Digital Rx saved.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('End Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // 1. Remote Doctor Video Stream (Full Screen Feed)
          Positioned.fill(
            child: _isRemoteVideoOff
                ? Container(
                    color: const Color(0xFF0B1329),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                padding: EdgeInsets.all(12 + (_pulseController.value * 12)),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.15 * (1 - _pulseController.value)),
                                ),
                                child: child,
                              );
                            },
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage: NetworkImage(widget.appointment.doctorPhoto),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.appointment.doctorName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mic_rounded, color: AppColors.success, size: 14),
                                SizedBox(width: 6),
                                Text('Doctor audio active • Video muted', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.appointment.doctorPhoto,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Icon(Icons.person_rounded, size: 80, color: Colors.white30),
                          ),
                        ),
                      ),
                      // Top & Bottom Vignette Gradients
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.75),
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            stops: const [0.0, 0.25, 0.7, 1.0],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // 2. Top Header Bar (Safe Area)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Back / Minimize Button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Doctor Profile Chip
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(widget.appointment.doctorPhoto),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.appointment.doctorName,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                                    ],
                                  ),
                                  Text(
                                    '${widget.appointment.doctorSpecialty} • ${widget.appointment.hospitalName}',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Call Duration Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(duration: 600.ms),
                          const SizedBox(width: 6),
                          Text(
                            _formatDuration(_callSeconds),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Agora RTC Telemetry Pill (Top Left Sub-header)
          Positioned(
            top: 75,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: _isAgoraConnected ? AppColors.success : Colors.amber,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isAgoraConnected ? 'Agora RTC • 1080p 60fps • 14ms' : 'Connecting Agora RTC...',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // 4. Floating Local Patient Camera PiP (Top Right)
          Positioned(
            top: 75,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _isFrontCamera = !_isFrontCamera);
                await _patientCameraKey.currentState?.switchCamera();
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(_isFrontCamera ? 'Switched to Front Camera' : 'Switched to Rear Camera'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                width: 95,
                height: 135,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _isVideoOff
                          ? Container(
                              color: const Color(0xFF0F172A),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 24),
                                  SizedBox(height: 4),
                                  Text('Camera Off', style: TextStyle(color: Colors.white38, fontSize: 9)),
                                ],
                              ),
                            )
                          : RealAiLensCameraView(
                              key: _patientCameraKey,
                            ),
                      // Patient Label + Flip Hint
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('You (Live)', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              Icon(Icons.flip_camera_ios_rounded, color: Colors.white70, size: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),


          // 5. Live Vitals HUD (Floating Overlay on Left Side)
          if (_showVitalsHud)
            Positioned(
              left: 16,
              bottom: 120,
              child: Container(
                width: 150,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        const Text('Live Vitals Feed', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _VitalHudRow(icon: Icons.favorite_rounded, label: 'Pulse', value: '74 bpm', color: Colors.redAccent),
                    const _VitalHudRow(icon: Icons.water_drop_rounded, label: 'SpO2', value: '99%', color: Colors.cyanAccent),
                    const _VitalHudRow(icon: Icons.speed_rounded, label: 'BP', value: '120/80', color: Colors.orangeAccent),
                    const _VitalHudRow(icon: Icons.thermostat_rounded, label: 'Temp', value: '98.6 °F', color: Colors.greenAccent),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2, end: 0),
            ),

          // 6. In-Call Chat Overlay Button (Right Floating)
          Positioned(
            right: 16,
            bottom: 120,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChatScreen(appointment: widget.appointment)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Chat', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          // 7. Bottom Floating Glassmorphic Control Dock
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1329).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Mic Mute Toggle
                  _ControlCircleButton(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    isActive: _isMuted,
                    activeColor: AppColors.error,
                    tooltip: _isMuted ? 'Unmute' : 'Mute',
                    onTap: () {
                      setState(() => _isMuted = !_isMuted);
                      AgoraRtcService.toggleAudioMute(_isMuted);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_isMuted ? 'Microphone muted' : 'Microphone unmuted'), duration: const Duration(milliseconds: 700)),
                      );
                    },
                  ),

                  // Camera Video Toggle
                  _ControlCircleButton(
                    icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    isActive: _isVideoOff,
                    activeColor: AppColors.error,
                    tooltip: _isVideoOff ? 'Turn Video On' : 'Turn Video Off',
                    onTap: () {
                      setState(() => _isVideoOff = !_isVideoOff);
                      AgoraRtcService.toggleVideoMute(_isVideoOff);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_isVideoOff ? 'Camera turned off' : 'Camera turned on'), duration: const Duration(milliseconds: 700)),
                      );
                    },
                  ),

                  // Flip Camera
                  _ControlCircleButton(
                    icon: Icons.flip_camera_ios_rounded,
                    tooltip: 'Flip Camera',
                    onTap: () async {
                      setState(() => _isFrontCamera = !_isFrontCamera);
                      await _patientCameraKey.currentState?.switchCamera();
                    },
                  ),


                  // Speaker Toggle
                  _ControlCircleButton(
                    icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                    isActive: !_isSpeakerOn,
                    tooltip: _isSpeakerOn ? 'Speaker On' : 'Earpiece Mode',
                    onTap: () {
                      setState(() => _isSpeakerOn = !_isSpeakerOn);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_isSpeakerOn ? 'Speaker mode active' : 'Earpiece mode active'), duration: const Duration(milliseconds: 700)),
                      );
                    },
                  ),

                  // Live Prescription Drawer
                  _ControlCircleButton(
                    icon: Icons.receipt_long_rounded,
                    tooltip: 'Digital Prescription (Rx)',
                    activeColor: AppColors.primary,
                    isActive: true,
                    onTap: _showPrescriptionSheet,
                  ),

                  // Vitals HUD Toggle
                  _ControlCircleButton(
                    icon: Icons.monitor_heart_outlined,
                    isActive: _showVitalsHud,
                    activeColor: const Color(0xFF0F766E),
                    tooltip: 'Vitals HUD',
                    onTap: () => setState(() => _showVitalsHud = !_showVitalsHud),
                  ),

                  // End Call Button
                  GestureDetector(
                    onTap: _showEndCallConfirmation,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.emergency,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.emergency, blurRadius: 10, spreadRadius: 1),
                        ],
                      ),
                      child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCircleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ControlCircleButton({
    required this.icon,
    this.isActive = false,
    this.activeColor = AppColors.primary,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _VitalHudRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _VitalHudRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
          Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MedicationItem extends StatelessWidget {
  final String name;
  final String dosage;
  final String duration;

  const _MedicationItem({
    required this.name,
    required this.dosage,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medication_rounded, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                Text(dosage, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(duration, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
