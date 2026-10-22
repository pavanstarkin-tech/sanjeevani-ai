import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/offline_medical_models.dart';

/// Futuristic, animated 3D-styled AI Doctor Avatar widget for Dr. Medha.
/// Reacts dynamically to state: Idle, Listening, Thinking, Speaking, and Emergency.
class OfflineDoctorAvatarWidget extends StatefulWidget {
  final DoctorAvatarState state;
  final double soundLevel;
  final bool isSpeaking;
  final VoidCallback? onMicTap;
  final VoidCallback? onAvatarTap;
  final double size;

  const OfflineDoctorAvatarWidget({
    super.key,
    required this.state,
    this.soundLevel = 0.0,
    this.isSpeaking = false,
    this.onMicTap,
    this.onAvatarTap,
    this.size = 140,
  });

  @override
  State<OfflineDoctorAvatarWidget> createState() => _OfflineDoctorAvatarWidgetState();
}

class _OfflineDoctorAvatarWidgetState extends State<OfflineDoctorAvatarWidget> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Color _getStateColor() {
    switch (widget.state) {
      case DoctorAvatarState.emergency:
        return const Color(0xFFEF4444); // Crimson
      case DoctorAvatarState.listening:
        return const Color(0xFF10B981); // Emerald
      case DoctorAvatarState.thinking:
        return const Color(0xFF8B5CF6); // Purple
      case DoctorAvatarState.speaking:
        return const Color(0xFF06B6D4); // Cyan
      case DoctorAvatarState.idle:
        return const Color(0xFF1E60F6); // Medical Blue
    }
  }

  String _getStateLabel() {
    switch (widget.state) {
      case DoctorAvatarState.emergency:
        return 'EMERGENCY PROTOCOL ACTIVE';
      case DoctorAvatarState.listening:
        return 'LISTENING TO YOUR VOICE...';
      case DoctorAvatarState.thinking:
        return 'CLINICAL INFERENCE RUNNING...';
      case DoctorAvatarState.speaking:
        return 'DR. MEDHA IS SPEAKING...';
      case DoctorAvatarState.idle:
        return 'ONLINE • ZERO-INTERNET MODE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = _getStateColor();
    final effectiveSize = widget.size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onAvatarTap,
          child: SizedBox(
            width: effectiveSize + 60,
            height: effectiveSize + 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulse Ring
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * (widget.state == DoctorAvatarState.emergency ? 0.35 : 0.18)) + (widget.soundLevel * 0.15);
                    return Container(
                      width: effectiveSize * scale,
                      height: effectiveSize * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: stateColor.withValues(alpha: widget.state == DoctorAvatarState.emergency ? 0.45 : 0.25),
                            blurRadius: 36,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Rotating Neural Synapse Halo (When Thinking or Speaking)
                if (widget.state == DoctorAvatarState.thinking || widget.state == DoctorAvatarState.speaking)
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: Container(
                          width: effectiveSize + 30,
                          height: effectiveSize + 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: stateColor.withValues(alpha: 0.4),
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 0,
                                left: (effectiveSize + 30) / 2 - 5,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: stateColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: stateColor, blurRadius: 8, spreadRadius: 2),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // Breathing Core Avatar Container
                AnimatedBuilder(
                  animation: _breathingController,
                  builder: (context, child) {
                    final breathScale = 1.0 + (_breathingController.value * 0.04);
                    return Transform.scale(
                      scale: breathScale,
                      child: Container(
                        width: effectiveSize,
                        height: effectiveSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment.topLeft,
                            radius: 1.1,
                            colors: [
                              stateColor.withValues(alpha: 0.85),
                              const Color(0xFF0D1B2A),
                              const Color(0xFF050B14),
                            ],
                          ),
                          border: Border.all(
                            color: stateColor.withValues(alpha: 0.8),
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: stateColor.withValues(alpha: 0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Doctor Avatar Graphic
                            ClipOval(
                              child: Container(
                                width: effectiveSize - 8,
                                height: effectiveSize - 8,
                                color: const Color(0xFF0F172A),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Doctor Bust / Stethoscope Icon Art
                                    Positioned(
                                      bottom: -10,
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: effectiveSize * 0.95,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                    // Stethoscope overlay badge
                                    Positioned(
                                      bottom: 12,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: stateColor.withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: stateColor, blurRadius: 6),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.medical_services_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Audio wave bars overlay (When Speaking or Listening)
                            if (widget.state == DoctorAvatarState.speaking || widget.state == DoctorAvatarState.listening)
                              Positioned(
                                bottom: 18,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (index) {
                                    final barHeight = 8.0 + (widget.soundLevel * 20.0 * (0.4 + (index % 3) * 0.3));
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      width: 3.5,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Floating Status Pill Badge
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D172A).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: stateColor.withValues(alpha: 0.6), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: stateColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: stateColor,
                            boxShadow: [
                              BoxShadow(color: stateColor, blurRadius: 6, spreadRadius: 1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStateLabel(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
