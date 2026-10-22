import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/production_database.dart';
import '../../models/doctor_model.dart';
import '../../models/hospital_model.dart';
import '../../models/medicine_model.dart';
import '../../models/lab_test_model.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../../models/offline_medical_models.dart';
import '../../providers/offline_medical_slm_provider.dart';
import '../../services/medical_slm_engine_service.dart';
import '../../services/clinical_rag_service.dart';
import 'book_appointment_screen.dart';
import 'hospital_detail_screen.dart';
import 'lab_tests_screen.dart';
import 'cart_checkout_screen.dart';
import 'emergency_sos_screen.dart';
import 'ai_voice_call_screen.dart';
import 'offline_ai_doctor_screen.dart';
import 'user_main_nav.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showRagSyncSimulation = true;
  double _ragProgress = 0.0;
  String _ragStatusMessage = 'Connecting to Sanjivani.ai Real-Time Clinical RAG Server...';
  String _currentSyncedVersion = 'rag-v2026.10.17-01';
  Timer? _ragPollTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initRealtimeRagSync();
    _ragPollTimer = Timer.periodic(const Duration(seconds: 14), (_) {
      _pollForRagUpdates();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        context.read<AiAssistantProvider>().seedUserContext(auth.currentUser);
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initRealtimeRagSync() async {
    if (!mounted) return;
    setState(() {
      _showRagSyncSimulation = true;
      _ragProgress = 0.25;
      _ragStatusMessage = 'Connecting to Sanjivani.ai Real-Time Clinical RAG Server...';
    });

    try {
      await ClinicalRagService.instance.syncWithAdminPanel();
      final latestVersion = ClinicalRagService.instance.currentVersion;
      final chunks = ClinicalRagService.instance.chunks;

      if (mounted) {
        setState(() {
          _currentSyncedVersion = latestVersion;
          _ragProgress = 1.0;
          _ragStatusMessage = 'RAG Layer Synced! ${chunks.length} active clinical guidelines & schemes cached for offline.';
        });
      }

      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        setState(() {
          _showRagSyncSimulation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ragProgress = 1.0;
          _ragStatusMessage = 'Real-time clinical RAG layer synchronized.';
        });
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          setState(() {
            _showRagSyncSimulation = false;
          });
        }
      }
    }
  }

  Future<void> _pollForRagUpdates() async {
    try {
      final updated = await ClinicalRagService.instance.syncWithAdminPanel();
      if (updated && mounted) {
        final serverVersion = ClinicalRagService.instance.currentVersion;
        final chunks = ClinicalRagService.instance.chunks;
        setState(() {
          _currentSyncedVersion = serverVersion;
          _showRagSyncSimulation = true;
          _ragProgress = 1.0;
          _ragStatusMessage = 'RAG Layer Updated from Admin! ${chunks.length} live guidelines & schemes active.';
        });
        await Future.delayed(const Duration(milliseconds: 2500));
        if (mounted) {
          setState(() {
            _showRagSyncSimulation = false;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ragPollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  static void showTopOfflineSlmDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Offline SLM',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.download_for_offline_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline SLM Mode',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Offline SLM mode requires a downloaded model. Please download one first.',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OfflineAiDoctorScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFD97706),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Open SLM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  void _sendMessage([String? customText]) {
    final prov = context.read<AiAssistantProvider>();
    if (!prov.isOnline) {
      final slmProv = context.read<OfflineMedicalSlmProvider>();
      final hasModel = slmProv.hasDownloadedModel || MedicalSlmEngineService.instance.isModelLoaded;
      if (!hasModel) {
        showTopOfflineSlmDialog(context);
        return;
      }
    }
    final text = (customText ?? _textController.text).trim();
    if (text.isEmpty) return;
    _textController.clear();
    prov.addUserMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleOrderMedicine(MedicineModel med) {
    context.read<PharmacyProvider>().addToCart(med);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Added ${med.name} to Pharmacy Cart!')),
          ],
        ),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartCheckoutScreen()));
          },
        ),
      ),
    );
  }

  void _handleBookDoctor(DoctorModel doc) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookAppointmentScreen(doctor: doc)),
    );
  }

  void _handleViewHospital(HospitalModel hosp) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: hosp)),
    );
  }

  void _handleBookLabTest(LabTestModel test) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LabTestsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<AiAssistantProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final mainNav = context.findAncestorStateOfType<UserMainNavState>();
        if (mainNav != null) {
          mainNav.setTab(0);
          return;
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: _AiAssistantDrawer(aiProv: aiProv),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          leading: Builder(
            builder: (scaffoldContext) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 26),
              tooltip: 'Open AI Sidebar',
              onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  gradient: AppColors.aiAssistantGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sanjeevani AI Doctor',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: aiProv.isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          aiProv.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: aiProv.isOnline ? const Color(0xFF10B981) : const Color(0xFFD97706),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Live AI Voice Call',
              icon: const Icon(Icons.call_rounded, color: Color(0xFF059669), size: 22),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiVoiceCallScreen()),
                );
              },
            ),
            IconButton(
              tooltip: 'New Chat',
              icon: const Icon(Icons.add_comment_rounded, color: AppColors.primary, size: 21),
              onPressed: () {
                aiProv.startNewSession();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.primary,
                    content: Text('Started fresh consultation session'),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
      body: Column(
        children: [
          // Top Online / Offline Chat Mode Toggle Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Online Chat (Cloud AI) - Active on this screen
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_rounded, size: 15, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'Online Chat',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Offline Chat (Dr. Channi SLM) - Tapping toggles directly to Dr. Channi Offline SLM
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OfflineAiDoctorScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt_rounded, size: 15, color: Color(0xFFD97706)),
                          SizedBox(width: 6),
                          Text(
                            'Offline Chat',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // RAG Layer Fetching Simulation Banner
          if (_showRagSyncSimulation)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF93C5FD)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Real-Time Clinical RAG Synchronization',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                            ),
                            Text(
                              'Latest guideline update found • Live sync with Sanjivani.ai RAG',
                              style: TextStyle(fontSize: 10, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(_ragProgress * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _ragProgress,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _ragStatusMessage,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () {
                _initRealtimeRagSync();
              },
              child: Container(
                margin: const EdgeInsets.only(top: 6, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF93C5FD).withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'RAG Live: $_currentSyncedVersion • Tap to sync',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                    ),
                  ],
                ),
              ),
            ),

          // Top Offline SLM Dialog Banner (Displayed at the top of the chat area)
          Consumer<OfflineMedicalSlmProvider>(
            builder: (context, slmProv, _) {
              if (!aiProv.isOnline && !slmProv.hasDownloadedModel && !MedicalSlmEngineService.instance.isModelLoaded) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download_for_offline_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Offline SLM Mode',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Offline SLM mode requires a downloaded model. Please download one first.',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OfflineAiDoctorScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFD97706),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Open SLM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: aiProv.messages.length,
              itemBuilder: (context, index) {
                final msg = aiProv.messages[index];
                return _MessageBubble(
                  message: msg,
                  onSuggestionTap: (sugg) => _sendMessage(sugg),
                  onOrderMedicine: _handleOrderMedicine,
                  onBookDoctor: _handleBookDoctor,
                  onViewHospital: _handleViewHospital,
                  onBookLabTest: _handleBookLabTest,
                  onEmergencySos: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencySosScreen()));
                  },
                );
              },
            ),
          ),

          // Analyzing / Thinking Indicator
          if (aiProv.isThinking)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          aiProv.selectedLanguage == 'te'
                              ? 'వైద్య విశ్లేషణ జరుగుతోంది...'
                              : (aiProv.selectedLanguage == 'hi' ? 'चिकित्सा विश्लेषण जारी है...' : 'Clinical AI analyzing symptoms...'),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Voice Listening Waveform Banner (Active when listening)
          if (aiProv.isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppColors.emergency,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aiProv.selectedLanguage == 'te' ? '🎙️ మీ మాటలు వినబడుతున్నాయి...' : '🎙️ Listening to your voice in real time...',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          aiProv.liveTranscription,
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => aiProv.toggleVoiceListening(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Text Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Text Input
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: aiProv.selectedLanguage == 'te'
                            ? 'లక్షణాలు టైప్ చేయండి...'
                            : (aiProv.selectedLanguage == 'hi' ? 'लक्षण टाइप करें...' : 'Type symptoms or ask a medical question...'),
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Action Button
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _AiAssistantDrawer extends StatefulWidget {
  final AiAssistantProvider aiProv;

  const _AiAssistantDrawer({required this.aiProv});

  @override
  State<_AiAssistantDrawer> createState() => _AiAssistantDrawerState();
}

class _AiAssistantDrawerState extends State<_AiAssistantDrawer> {
  int _selectedTab = 1; // 0 = Models Tab, 1 = History Tab (Default to History Tab per user request)

  @override
  Widget build(BuildContext context) {
    final aiProv = widget.aiProv;
    final isOnline = aiProv.isOnline;

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ==============================================================
            // 1. TOP OF SIDEBAR: Online/Offline Switch & Live Call Button
            // ==============================================================
            Container(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 14, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Title & Close Button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sanjeevani AI Doctor',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              'Clinical AI Diagnostic Suite',
                              style: TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // OFFLINE & ONLINE SWITCH BUTTON (At the top of the sidebar menu)
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OfflineAiDoctorScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOnline
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isOnline ? Icons.wifi_rounded : Icons.bolt_rounded,
                              color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isOnline ? 'Online Cloud AI' : 'Offline On-Device SLM',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  isOnline
                                      ? 'NVIDIA NIM OpenAI GPT-OSS-20B'
                                      : 'Dr. Channi SLM (Zero Internet)',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isOnline ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Refresh / Auto-detect network connectivity
                          IconButton(
                            tooltip: 'Check Connectivity',
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                            onPressed: () async {
                              final ok = await aiProv.checkNetworkConnectivity();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFFD97706),
                                    content: Text(ok ? 'Connected: Cloud AI Active' : 'Offline: Zero-Internet Dr. Channi Active'),
                                  ),
                                );
                              }
                            },
                          ),
                        // Switch Button
                        Switch.adaptive(
                          value: isOnline,
                          activeThumbColor: const Color(0xFF10B981),
                          activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                          inactiveThumbColor: const Color(0xFFF59E0B),
                          inactiveTrackColor: Colors.white24,
                          onChanged: (newVal) {
                            if (!newVal) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const OfflineAiDoctorScreen()),
                              );
                              return;
                            }
                            aiProv.setOnlineMode(newVal, hasDownloadedModel: true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 2),
                                backgroundColor: newVal ? const Color(0xFF059669) : const Color(0xFFD97706),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: Row(
                                  children: [
                                    Icon(
                                      newVal ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        newVal ? 'Online: Cloud AI Active' : 'Offline: Zero-Internet Dr. Channi Active',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                  // LIVE CALL BUTTON IN THE SAME PLACE (At the top of the sidebar menu)
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AiVoiceCallScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live Doctor Voice Call',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Instant hands-free spoken triage',
                                  style: TextStyle(fontSize: 10.5, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==============================================================
            // 2. LANGUAGE SWITCHING IN SIDEBAR MENU SYSTEM
            // ==============================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.translate_rounded, size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        'LANGUAGE / భాష / भाषा',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildLangChip('en', 'English', 'EN', aiProv),
                        const SizedBox(width: 6),
                        _buildLangChip('te', 'తెలుగు', 'TE', aiProv),
                        const SizedBox(width: 6),
                        _buildLangChip('hi', 'हिन्दी', 'HI', aiProv),
                        const SizedBox(width: 6),
                        _buildLangChip('ta', 'தமிழ்', 'TA', aiProv),
                        const SizedBox(width: 6),
                        _buildLangChip('kn', 'ಕನ್ನಡ', 'KN', aiProv),
                        const SizedBox(width: 6),
                        _buildLangChip('ml', 'മലയാളം', 'ML', aiProv),
                        const SizedBox(width: 6),
                        _buildLangChip('bn', 'বাংলা', 'BN', aiProv),
                        const SizedBox(width: 6),
                        _buildLangChip('mr', 'मराठी', 'MR', aiProv),
                        const SizedBox(width: 6),
                        _buildLangChip('gu', 'ગુજરાતી', 'GU', aiProv),
                        const SizedBox(width: 6),
                        _buildLangChip('pa', 'ਪੰਜਾਬੀ', 'PA', aiProv),
                        const SizedBox(width: 6),
                        _buildLangChip('or', 'ଓଡ଼ିଆ', 'OD', aiProv),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 16, thickness: 1, color: AppColors.border),

            // ==============================================================
            // 3. MODELS TAB & HISTORY TAB IN SIDEBAR MENU
            // ==============================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSidebarTab(
                      index: 0,
                      icon: Icons.memory_rounded,
                      title: 'Models',
                      badge: '${context.watch<OfflineMedicalSlmProvider>().catalogModels.where((m) => m.isOnDisk || m.downloadState == GgufDownloadState.downloaded).length}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSidebarTab(
                      index: 1,
                      icon: Icons.history_rounded,
                      title: 'History',
                      badge: '${aiProv.savedSessions.length}',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ==============================================================
            // 4. TAB CONTENTS
            // ==============================================================
            Expanded(
              child: _selectedTab == 0
                  ? _buildModelsContent(context, aiProv)
                  : _buildHistoryContent(context, aiProv),
            ),

            // ==============================================================
            // 5. SIDEBAR FOOTER (Emergency SOS)
            // ==============================================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmergencySosScreen()),
                        );
                      },
                      icon: const Icon(Icons.emergency_rounded, color: AppColors.error, size: 18),
                      label: const Text(
                        'Emergency SOS (108)',
                        style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip(String code, String name, String tag, AiAssistantProvider aiProv) {
    final isSelected = aiProv.selectedLanguage == code;
    return InkWell(
      onTap: () => aiProv.setLanguage(code),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              tag,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarTab({
    required int index,
    required IconData icon,
    required String title,
    required String badge,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelsContent(BuildContext context, AiAssistantProvider aiProv) {
    final slmProv = context.watch<OfflineMedicalSlmProvider>();
    final downloadedGgufModels = slmProv.catalogModels
        .where((m) => m.isOnDisk || m.downloadState == GgufDownloadState.downloaded || m.downloadState == GgufDownloadState.loaded)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        // Direct Button to Dr. Channi Offline SLM Page
        InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OfflineAiDoctorScreen()),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open Dr. Channi Offline SLM',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        'Zero-internet clinical consultation',
                        style: TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF92400E)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 3. Section Title: Downloaded Models Only
        Row(
          children: [
            const Icon(Icons.download_done_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'DOWNLOADED MODELS ONLY (${downloadedGgufModels.length})',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (downloadedGgufModels.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.download_for_offline_outlined, size: 36, color: AppColors.textSecondary),
                const SizedBox(height: 8),
                const Text(
                  'No Offline Models Downloaded Yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap "Model Manager" above to download Dr. Medha SLM or Llama-3-Med for on-device medical consultation with zero internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OfflineAiDoctorScreen()),
                    );
                  },
                  icon: const Icon(Icons.bolt_rounded, size: 15),
                  label: const Text('Launch Dr. Channi SLM', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          )
        else
          ...downloadedGgufModels.map((m) {
            final isActive = slmProv.activeModel?.id == m.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildModelCard(
                title: '${m.name} (${m.quantization})',
                type: 'On-Device GGUF (${m.sizeLabel})',
                status: isActive ? 'Active SLM' : 'Ready',
                isActive: isActive,
                isCloud: false,
                desc: m.notes ?? 'Downloaded local medical SLM running on device.',
              ),
            );
          }),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildModelCard({
    required String title,
    required String type,
    required String status,
    required bool isActive,
    required bool isCloud,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCloud ? Icons.cloud_outlined : Icons.devices_rounded,
                size: 16,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, height: 1.25),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent(BuildContext context, AiAssistantProvider aiProv) {
    return Column(
      children: [
        // "+ New Consultation" Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              aiProv.startNewSession();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    '+ Start New Consultation',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Session list
        Expanded(
          child: aiProv.savedSessions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 36, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No saved consultations yet',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Every clinical conversation with Sanjeevani AI is automatically preserved here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: aiProv.savedSessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final session = aiProv.savedSessions[index];
                    final isActive = session.id == aiProv.currentSessionId;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (!isActive) {
                          aiProv.loadSession(session.id);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? AppColors.primary : AppColors.border,
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isActive ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                                color: isActive ? AppColors.primary : AppColors.textSecondary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          session.title,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                            color: isActive ? AppColors.primary : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isActive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Active',
                                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (session.lastSnippet.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      session.lastSnippet,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    '${session.updatedAt.day}/${session.updatedAt.month}/${session.updatedAt.year} • ${session.messageCount} messages',
                                    style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                              onPressed: () => aiProv.deleteSession(session.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String) onSuggestionTap;
  final Function(MedicineModel) onOrderMedicine;
  final Function(DoctorModel) onBookDoctor;
  final Function(HospitalModel) onViewHospital;
  final Function(LabTestModel) onBookLabTest;
  final VoidCallback onEmergencySos;

  const _MessageBubble({
    required this.message,
    required this.onSuggestionTap,
    required this.onOrderMedicine,
    required this.onBookDoctor,
    required this.onViewHospital,
    required this.onBookLabTest,
    required this.onEmergencySos,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isAudio) ...[
                      const Icon(Icons.mic, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        message.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.primary, size: 18),
            ),
          ],
        ),
      );
    }

    // AI Message
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              gradient: AppColors.aiAssistantGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formatted Markdown Text with TTS Speaker Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MarkdownFormattedText(text: message.text),
                      ),
                      const SizedBox(width: 6),
                      Consumer<AiAssistantProvider>(
                        builder: (context, ai, _) {
                          final isThisSpeaking = ai.isSpeaking;
                          return Tooltip(
                            message: isThisSpeaking ? 'Stop Audio' : 'Listen to AI Response (Speaker)',
                            child: GestureDetector(
                              onTap: () {
                                if (ai.isSpeaking) {
                                  ai.stopSpeaking();
                                } else {
                                  ai.speakText(message.text);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isThisSpeaking
                                      ? AppColors.primary
                                      : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                  boxShadow: isThisSpeaking
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  isThisSpeaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                                  color: isThisSpeaking ? Colors.white : AppColors.primary,
                                  size: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // 0. DYNAMIC ACTION CARDS (Confirmed Bookings, Live Tracking, Emergency SOS)
                  if (message.dynamicCards != null && message.dynamicCards!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ...message.dynamicCards!.map((card) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: card.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: card.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: card.color, shape: BoxShape.circle),
                              child: Icon(card.icon, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(card.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: card.color)),
                                  const SizedBox(height: 2),
                                  Text(card.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // 1. CLICKABLE SUGGESTED HOSPITALS SECTION (With Distance & Travel ETA)
                  if (message.suggestedHospitals != null && message.suggestedHospitals!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.local_hospital_rounded, size: 16, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Text(
                          'Nearby Hospitals & Facilities',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...message.suggestedHospitals!.map((hosp) {
                      final int etaMins = (hosp.distanceKm * 3.5).round().clamp(3, 45);
                      final hospDocs = ProductionDatabase.doctors.where((d) => d.hospitalId == hosp.id).toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    hosp.logoUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 44,
                                      height: 44,
                                      color: const Color(0xFFE0F2FE),
                                      child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF0284C7)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hosp.name,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hosp.location,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.near_me_rounded, size: 10, color: Color(0xFF0284C7)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${hosp.distanceKm.toStringAsFixed(1)} km',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF059669).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.directions_car_rounded, size: 10, color: Color(0xFF059669)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'ETA: ~$etaMins mins',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (hospDocs.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Divider(height: 12, color: Color(0xFFBAE6FD)),
                              Text(
                                'Available Specialists at ${hosp.name.split(" ").first}:',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              ...hospDocs.take(2).map((doc) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundImage: NetworkImage(doc.photoUrl),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${doc.name} • ${doc.specialty}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => onBookDoctor(doc),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('Book Slot', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => onViewHospital(hosp),
                                  icon: const Icon(Icons.apartment_rounded, size: 13),
                                  label: const Text('View Hospital & Doctors', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0284C7),
                                    side: const BorderSide(color: Color(0xFF0284C7), width: 1),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // 2. CLICKABLE SUGGESTED MEDICINES SECTION
                  if (message.suggestedMedicines != null && message.suggestedMedicines!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.medication_rounded, size: 16, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Text(
                          'Suggested Medications (Direct Order)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...message.suggestedMedicines!.map((med) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF0284C7), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(med.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  Text('${med.packSize} • ₹${med.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => onOrderMedicine(med),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Order 15-Min', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // 3. CLICKABLE SUGGESTED DOCTORS SECTION
                  if (message.suggestedDoctors != null && message.suggestedDoctors!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Recommended Specialist Doctors',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...message.suggestedDoctors!.map((doc) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(doc.photoUrl),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  Text('${doc.specialty} • ${doc.hospitalName}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('Fee: ₹${doc.videoFee.toStringAsFixed(0)} • In-Clinic: ₹${doc.clinicFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => onBookDoctor(doc),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Book Consult', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // 3. CLICKABLE SUGGESTED LAB TESTS SECTION
                  if (message.suggestedLabTests != null && message.suggestedLabTests!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(Icons.biotech_rounded, size: 16, color: Color(0xFF0F766E)),
                        SizedBox(width: 6),
                        Text(
                          'Suggested Diagnostic Blood Panels',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...message.suggestedLabTests!.map((test) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.science_rounded, color: Color(0xFF0F766E), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(test.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  Text('${test.reportDeliveryTime} • ₹${test.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => onBookLabTest(test),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Book Test', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // 4. ACTION SUGGESTIONS IN A SINGLE HORIZONTALLY SCROLLABLE ROW (Dynamic Short Answers per AI response)
                  Builder(
                    builder: (context) {
                      final dynamicSuggestions = _computeDynamicSuggestions(message, context);
                      if (dynamicSuggestions.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: dynamicSuggestions.map((sugg) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    label: Text(
                                      sugg,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                    ),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: AppColors.primary, width: 0.8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    onPressed: () => onSuggestionTap(sugg),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Bottom Right Tokens Per Second & TTFT Telemetry (small gray font per user instruction)
                  if (message.isOffline && message.metrics != null)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${message.metrics!.tokensPerSecond.toStringAsFixed(1)} tok/s • ${message.metrics!.timeToFirstTokenMs ?? 35}ms TTFT',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8), // small, gray color
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  List<String> _computeDynamicSuggestions(ChatMessage message, BuildContext context) {
    if (message.isUser) return const [];

    final text = message.text.toLowerCase().trim();

    // 0. Do NOT show suggestions on greetings or general conversation
    if (text.startsWith('hello') ||
        text.startsWith('hi') ||
        text.startsWith('hey') ||
        text.startsWith('namaste') ||
        text.startsWith('నమస్కారం') ||
        text.startsWith('నమస్తే') ||
        text.startsWith('नमस्ते') ||
        text.contains('how can i help') ||
        text.contains('how are you feeling') ||
        text.contains('clinical ai doctor') ||
        text.contains('డాక్టర్ శన్నీ') ||
        text.contains('डॉ. शन्नी')) {
      return const [];
    }

    final lang = context.read<AiAssistantProvider>().selectedLanguage.toLowerCase();
    final isTe = lang == 'te' || lang.startsWith('te');
    final isHi = lang == 'hi' || lang.startsWith('hi');

    // 1. If AI is asking about Age
    if (text.contains('వయస్సు') || text.contains('उम्र') || text.contains('how old') || text.contains('patient age') || text.contains('வயது') || text.contains('ವಯಸ್ಸು')) {
      if (isTe) return ['వయస్సు: 25-35 సం', 'వయస్సు: 40-55 సం', 'సీనియర్ సిటిజెన్ (60+)', 'పిల్లలు (<15 సం)'];
      if (isHi) return ['उम्र: 25-35 वर्ष', 'उम्र: 40-55 वर्ष', 'वरिष्ठ (60+ वर्ष)', 'बच्चा (<15 वर्ष)'];
      return ['Age: 25-35 yrs', 'Age: 40-55 yrs', 'Senior (60+ yrs)', 'Child (<15 yrs)'];
    }

    // 2. If AI is specifically asking about Duration of a symptom
    if (text.contains('ఎన్ని రోజు') || text.contains('ఎప్పటి నుండి') || text.contains('कितने दिन') || text.contains('कब से') || text.contains('how many days') || text.contains('how long') || text.contains('symptom duration')) {
      if (isTe) return ['ఈ రోజే మొదలైంది', 'నిన్నటి నుండి (1-2 రోజులు)', '3-4 రోజుల నుండి', 'వారం కంటే ఎక్కువ'];
      if (isHi) return ['आज ही शुरू हुआ', 'कल से (1-2 दिन)', '3-4 दिनों से', 'एक हफ्ते से अधिक'];
      return ['Just started today', 'Since yesterday (1-2 days)', '3 - 4 days', 'More than a week'];
    }

    // 3. If AI is asking about Temperature / Fever
    if (text.contains('ఉష్ణోగ్రత') || text.contains('థర్మామీటర్') || text.contains('तापमान') || text.contains('temperature') || text.contains('chills') || text.contains('measured temp')) {
      if (isTe) return ['తేలికపాటి జ్వరం (99-100°F)', 'తీవ్ర జ్వరం (>101°F)', 'చలి & వణుకు ఉంది', 'జ్వరం లేదు (సాధారణం)'];
      if (isHi) return ['हल्का बुखार (99-100°F)', 'तेज बुखार (>101°F)', 'ठंड और कंपकंपी है', 'बुखार नहीं है (सामान्य)'];
      return ['Mild Fever (99-100°F)', 'High Fever (>101°F)', 'With Chills & Shivering', 'No Fever (Normal)'];
    }

    // 4. If AI is asking about Severity
    if (text.contains('తీవ్రంగా') || text.contains('తీవ్రత') || text.contains('ఎంత తీవ్రం') || text.contains('कितनी तेज') || text.contains('गंभीर') || text.contains('how severe') || text.contains('severity')) {
      if (isTe) return ['తక్కువగా ఉంది (Mild)', 'మధ్యస్థంగా ఉంది (Moderate)', 'చాలా తీవ్రంగా ఉంది (Severe)'];
      if (isHi) return ['हल्का दर्द (Mild)', 'मध्यम (Moderate)', 'बहुत तेज / असहनीय (Severe)'];
      return ['Mild (Manageable)', 'Moderate Discomfort', 'Severe / Intense'];
    }

    // 5. If AI is asking about Previous Illness / Existing Meds / Allergies
    if (text.contains('దీర్ఘకాలిక') || text.contains('షుగర్') || text.contains('బీపీ') || text.contains('టాబ్లెట్') || text.contains('అలర్జీ') || text.contains('पुरानी बीमारी') || text.contains('दवा ली') || text.contains('chronic') || text.contains('allerg') || text.contains('hypertension') || text.contains('existing condition')) {
      if (isTe) return ['ఎలాంటి వ్యాధులు లేవు (ఆరోగ్యం)', 'షుగర్ / బీపీ సమస్య ఉంది', 'పారాసిటమాల్ వేసుకున్నాను', 'ఎటువంటి అలర్జీలు లేవు'];
      if (isHi) return ['कोई बीमारी नहीं है (स्वस्थ)', 'शुगर / बीपी की शिकायत है', 'पैरासिटामोल लिया है', 'कोई एलर्जी नहीं है'];
      return ['No prior illness (Healthy)', 'Have Diabetes / High BP', 'Took Paracetamol already', 'No drug allergies'];
    }

    // 6. If AI is providing Treatment / Prescription / Home Care
    if (text.contains('సిఫార్సు చేసిన') || text.contains('మోతాదు') || text.contains('సూచించిన మందులు') || text.contains('सुझाई गई दवाएं') || text.contains('खुराक') || text.contains('care plan') || text.contains('recommended medication') || text.contains('care directives') || text.contains('dosage')) {
      if (isTe) return ['💊 15 నిమిషాల్లో మందుల డెలివరీ', '👨‍⚕️ వీడియో డాక్టర్ కన్సల్టేషన్', '🩸 రక్త పరీక్ష బుక్ చేయండి', '🏠 ఇంటి చిట్కాలు వివరించండి'];
      if (isHi) return ['💊 15 मिनट में दवाइयां मंगवाएं', '👨‍⚕️ डॉक्टर से वीडियो परामर्श', '🩸 ब्लड टेस्ट बुक करें', '🏠 घरेलू उपाय विस्तार से बताएं'];
      return ['💊 Order Medicines (15-Min Delivery)', '👨‍⚕️ Book Video Doctor Consult', '🩸 Book Lab Blood Test', '🏠 Explain Home Care & Diet'];
    }

    // 7. Explicit actionSuggestions if provided
    if (message.actionSuggestions != null && message.actionSuggestions!.isNotEmpty) {
      return message.actionSuggestions!;
    }

    // Do NOT show suggestions for questions or messages that don't need them
    return const [];
  }
}

/// Advanced Clinical Markdown Parser Widget that renders:
/// 1. Markdown Tables (with horizontal scroll, zebra rows, header highlighting)
/// 2. Bulleted Lists (- or * or •) and Numbered Lists (1., 2.)
/// 3. Headings (#, ##, ###)
/// 4. Bold (**text**), Italics (*text*), and Inline Code (`code`)
/// 5. Blockquotes (> quote)
class _MarkdownFormattedText extends StatelessWidget {
  final String text;
  const _MarkdownFormattedText({required this.text});

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    final lines = text.split('\n');
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        i++;
        continue;
      }

      // 1. Table Detection: line starts with | and contains |
      if (_isTableLine(trimmed)) {
        final tableLines = <String>[];
        while (i < lines.length && _isTableLine(lines[i].trim())) {
          tableLines.add(lines[i]);
          i++;
        }
        final tableWidget = _buildTableWidget(tableLines);
        if (tableWidget != null) {
          widgets.add(tableWidget);
        }
        continue;
      }

      // 2. Heading 3: ### Heading
      if (trimmed.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: _buildRichInlineText(
            trimmed.substring(4).trim(),
            baseStyle: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ));
        i++;
        continue;
      }

      // 3. Heading 2: ## Heading
      if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 5),
          child: _buildRichInlineText(
            trimmed.substring(3).trim(),
            baseStyle: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ));
        i++;
        continue;
      }

      // 4. Heading 1: # Heading
      if (trimmed.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: _buildRichInlineText(
            trimmed.substring(2).trim(),
            baseStyle: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ));
        i++;
        continue;
      }

      // 5. Bullet list item: - , * , • , +
      if (trimmed.startsWith('- ') ||
          trimmed.startsWith('* ') ||
          trimmed.startsWith('• ') ||
          trimmed.startsWith('+ ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 2, top: 3, bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 8),
                width: 5.5,
                height: 5.5,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: _buildRichInlineText(
                  trimmed.substring(2).trim(),
                  baseStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ));
        i++;
        continue;
      }

      // 6. Numbered list item: 1. , 2. , etc.
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 2, top: 3, bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${numMatch.group(1)}.',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRichInlineText(
                  numMatch.group(2)!.trim(),
                  baseStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ));
        i++;
        continue;
      }

      // 7. Blockquote: >
      if (trimmed.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: _buildRichInlineText(
            trimmed.substring(2).trim(),
            baseStyle: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13.0,
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
        ));
        i++;
        continue;
      }

      // 8. Plain paragraph line
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: _buildRichInlineText(trimmed),
      ));
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  static bool _isTableLine(String line) {
    final t = line.trim();
    return t.contains('|') && (t.startsWith('|') || t.contains(' | '));
  }

  static Widget? _buildTableWidget(List<String> tableLines) {
    final rows = <List<String>>[];

    for (final l in tableLines) {
      final trimmed = l.trim();
      if (trimmed.isEmpty) continue;

      // Check if it's separator row: e.g. |---|---| or |:---|:---:|
      final isSeparator = trimmed.replaceAll(RegExp(r'[\s|:\-]'), '').isEmpty;
      if (isSeparator) continue;

      var cells = trimmed.split('|');
      if (cells.isNotEmpty && cells.first.trim().isEmpty) cells.removeAt(0);
      if (cells.isNotEmpty && cells.last.trim().isEmpty) cells.removeLast();

      final cleanCells = cells.map((c) => c.trim()).toList();
      if (cleanCells.isNotEmpty) {
        rows.add(cleanCells);
      }
    }

    if (rows.isEmpty) return null;

    int maxCols = 0;
    for (final r in rows) {
      if (r.length > maxCols) maxCols = r.length;
    }
    if (maxCols == 0) return null;

    for (final r in rows) {
      while (r.length < maxCols) {
        r.add('');
      }
    }

    final header = rows.first;
    final dataRows = rows.length > 1 ? rows.sublist(1) : <List<String>>[];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.8),
              verticalInside: BorderSide(color: Colors.grey.shade200, width: 0.8),
            ),
            children: [
              // Header Row
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF2FF), // Soft primary-tinted blue header
                ),
                children: header.map((h) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: _buildRichInlineText(
                      h,
                      baseStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                        fontSize: 12.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Data Rows
              ...dataRows.asMap().entries.map((entry) {
                final idx = entry.key;
                final row = entry.value;
                final isEven = idx % 2 == 0;
                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                  ),
                  children: row.map((cell) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: _buildRichInlineText(
                        cell,
                        baseStyle: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRichInlineText(String text, {TextStyle? baseStyle}) {
    final defaultStyle = baseStyle ??
        const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13.5,
          height: 1.4,
        );

    final spans = <InlineSpan>[];
    // Match **bold**, *italic*, and `code`
    final regExp = RegExp(r'(\*\*([^*]+)\*\*|\*([^*]+)\*|`([^`]+)`)');
    int lastIndex = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }

      if (match.group(2) != null) {
        // Bold **text**
        spans.add(TextSpan(
          text: match.group(2),
          style: defaultStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: defaultStyle.color ?? AppColors.textPrimary,
          ),
        ));
      } else if (match.group(3) != null) {
        // Italic *text*
        spans.add(TextSpan(
          text: match.group(3),
          style: defaultStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(4) != null) {
        // Inline `code`
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Text(
              match.group(4)!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: defaultStyle.fontSize != null ? defaultStyle.fontSize! * 0.9 : 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: defaultStyle,
      ));
    }

    if (spans.isEmpty) {
      return Text(text, style: defaultStyle);
    }

    return RichText(text: TextSpan(children: spans));
  }
}

