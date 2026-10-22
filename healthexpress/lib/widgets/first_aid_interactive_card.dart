import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/offline_medical_models.dart';
import '../providers/offline_medical_slm_provider.dart';

/// Interactive First-Aid Guided Step Card with countdown timer,
/// CPR metronome beat synchronizer, audio guidance, and next/prev progression.
class FirstAidInteractiveCard extends StatelessWidget {
  final FirstAidProtocol protocol;
  final int currentStepIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  const FirstAidInteractiveCard({
    super.key,
    required this.protocol,
    required this.currentStepIndex,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final step = protocol.steps[currentStepIndex];
    final totalSteps = protocol.steps.length;
    final isCritical = protocol.emergencyLevel == EmergencyTriageLevel.critical;
    final themeColor = isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

    return Consumer<OfflineMedicalSlmProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E293B),
                const Color(0xFF0F172A),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: themeColor.withValues(alpha: 0.7), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.18),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  border: Border(bottom: BorderSide(color: themeColor.withValues(alpha: 0.3))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCritical ? Icons.emergency_rounded : Icons.healing_rounded,
                        color: themeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            protocol.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Step ${currentStepIndex + 1} of $totalSteps • ${protocol.validatedBy}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: onClose,
                      tooltip: 'Close Protocol',
                    ),
                  ],
                ),
              ),

              // Step Content Area
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'STEP ${step.stepNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Detailed Instruction
                    Text(
                      step.detail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),

                    // Crucial Warning if present
                    if (step.warning != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF451A03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step.warning!,
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Interactive Metronome Section for CPR Steps
                    if (step.hasMetronome) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.7)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: provider.isCprMetronomeActive ? const Color(0xFFEF4444) : Colors.grey,
                                        boxShadow: provider.isCprMetronomeActive
                                            ? [const BoxShadow(color: Color(0xFFEF4444), blurRadius: 10, spreadRadius: 2)]
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'CPR BEAT METRONOME (110 BPM)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: provider.isCprMetronomeActive ? const Color(0xFF991B1B) : const Color(0xFFEF4444),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  icon: Icon(
                                    provider.isCprMetronomeActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    provider.isCprMetronomeActive ? 'STOP BEAT' : 'START 110 BPM',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  onPressed: () {
                                    if (provider.isCprMetronomeActive) {
                                      provider.stopCprMetronome();
                                    } else {
                                      provider.startCprMetronome();
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (provider.isCprMetronomeActive) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '${provider.cprCompressionCount}',
                                        style: const TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Text('Compressions / 30', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                    ],
                                  ),
                                  Container(width: 1, height: 35, color: Colors.white24),
                                  Column(
                                    children: [
                                      Text(
                                        '${provider.cprCycleCount}',
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Text('Cycles Completed', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Navigation Controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: currentStepIndex > 0 ? onPrevious : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Previous'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        disabledForegroundColor: Colors.white24,
                      ),
                    ),
                    // Voice readout button
                    IconButton(
                      icon: Icon(
                        provider.voiceService.isSpeaking ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                        color: themeColor,
                        size: 22,
                      ),
                      onPressed: () {
                        if (step.audioInstruction != null) {
                          provider.voiceService.speak(step.audioInstruction!);
                        }
                      },
                      tooltip: 'Speak Step Instruction',
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: currentStepIndex < totalSteps - 1 ? onNext : onClose,
                      label: Text(
                        currentStepIndex < totalSteps - 1 ? 'Next Step' : 'Finish Guide',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      icon: Icon(
                        currentStepIndex < totalSteps - 1 ? Icons.arrow_forward_rounded : Icons.check_circle_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
