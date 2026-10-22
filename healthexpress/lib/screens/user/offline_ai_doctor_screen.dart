import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medical_rag_chunk.dart';
import '../../models/offline_medical_models.dart';
import '../../providers/offline_medical_slm_provider.dart';
import '../../widgets/markdown_formatted_text.dart';
import 'ai_assistant_screen.dart';

/// Flagship Screen for Offline Medical Small Language Model (SLM)
/// & Offline-Capable AI Doctor Avatar (Dr. Medha).
/// Operates 100% locally on-device with zero internet connectivity required.
class OfflineAiDoctorScreen extends StatefulWidget {
  final FirstAidProtocol? initialProtocol;

  const OfflineAiDoctorScreen({super.key, this.initialProtocol});

  @override
  State<OfflineAiDoctorScreen> createState() => _OfflineAiDoctorScreenState();
}

class _OfflineAiDoctorScreenState extends State<OfflineAiDoctorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<OfflineMedicalSlmProvider>();
        if (widget.initialProtocol != null) {
          provider.launchFirstAidProtocol(widget.initialProtocol!);
        }
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(OfflineMedicalSlmProvider provider) {
    if (!provider.hasDownloadedModel && !provider.engine.isModelLoaded) {
      provider.loadCatalogModels();
    }
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    provider.sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _makeEmergencyCall() async {
    final uri = Uri.parse('tel:108');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineMedicalSlmProvider>(
      builder: (context, provider, _) {
        final activeModel = provider.activeModel;
        final isModelLoaded = provider.engine.isModelLoaded;
        final isGenerating = provider.engine.isGenerating;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.healing_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dr. Channi • Offline SLM',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isModelLoaded
                                  ? (activeModel?.name ?? 'Local Model Loaded')
                                  : 'On-Device Clinical Protocol Engine',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                              ),
                              overflow: TextOverflow.ellipsis,
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
              // Language Selector
              PopupMenuButton<String>(
                icon: const Icon(Icons.translate_rounded, color: AppColors.textSecondary, size: 20),
                tooltip: 'Select Language',
                color: Colors.white,
                onSelected: (lang) => provider.setLanguage(lang),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'en', child: Text('English')),
                  PopupMenuItem(value: 'te', child: Text('తెలుగు (Telugu)')),
                  PopupMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
                  PopupMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)')),
                  PopupMenuItem(value: 'kn', child: Text('ಕನ್ನಡ (Kannada)')),
                  PopupMenuItem(value: 'ml', child: Text('മലയാളം (Malayalam)')),
                  PopupMenuItem(value: 'bn', child: Text('বাংলা (Bengali)')),
                  PopupMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
                  PopupMenuItem(value: 'gu', child: Text('ગુજરાતી (Gujarati)')),
                  PopupMenuItem(value: 'pa', child: Text('ਪੰਜਾਬੀ (Punjabi)')),
                  PopupMenuItem(value: 'or', child: Text('ଓଡ଼ିଆ (Odia)')),
                ],
              ),
              // Model & Medical RAG Status Indicator Chip
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, color: Color(0xFF0284C7), size: 13),
                    SizedBox(width: 4),
                    Text(
                      'RAG + Llama 1B',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Top Online / Offline Chat Mode Toggle Bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // Online Chat (Cloud AI) - Tapping switches back to Sanjeevani AI Doctor online chat
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                            );
                          }
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
                              Icon(Icons.wifi_rounded, size: 15, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Text(
                                'Online Chat',
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
                    const SizedBox(width: 4),
                    // Offline Chat (Dr. Channi SLM) - Active on this screen
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
                            Icon(Icons.bolt_rounded, size: 15, color: Color(0xFFD97706)),
                            SizedBox(width: 6),
                            Text(
                              'Offline Chat',
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
                  ],
                ),
              ),

              // Conversation Messages Stream
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final msg = provider.messages[index];
                    return _buildMessageBubble(context, provider, msg);
                  },
                ),
              ),

              // Input Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Voice Mic Button
                      GestureDetector(
                        onTap: () => provider.toggleVoiceInput(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: provider.voiceService.isListening
                                ? AppColors.success
                                : AppColors.primaryLight,
                            shape: BoxShape.circle,
                            boxShadow: provider.voiceService.isListening
                                ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)]
                                : null,
                          ),
                          child: Icon(
                            provider.voiceService.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            color: provider.voiceService.isListening ? Colors.white : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Text Field
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: provider.voiceService.isListening
                                ? 'Listening to voice...'
                                : 'Describe symptoms or ask first-aid...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                          onSubmitted: (_) => _handleSend(provider),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Send / Stop Button
                      if (isGenerating)
                        IconButton(
                          icon: const Icon(Icons.stop_circle_rounded, color: AppColors.error, size: 30),
                          onPressed: () => provider.engine.stopGeneration(),
                          tooltip: 'Stop generation',
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 24),
                          onPressed: () => _handleSend(provider),
                          tooltip: 'Send message',
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildMessageBubble(
    BuildContext context,
    OfflineMedicalSlmProvider provider,
    OfflineDoctorMessage msg,
  ) {
    final isUser = msg.role == 'user';
    final isEmergency = msg.isEmergency;
    final chunks = msg.retrievedChunks;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: isEmergency
                        ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)])
                        : AppColors.aiAssistantGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEmergency ? Icons.warning_amber_rounded : Icons.auto_awesome,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : (isEmergency ? const Color(0xFFFEF2F2) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? Colors.transparent
                          : (isEmergency ? const Color(0xFFF87171) : AppColors.border),
                      width: isEmergency ? 1.5 : 1.0,
                    ),
                    boxShadow: isUser
                        ? null
                        : [
                            BoxShadow(
                              color: isEmergency
                                  ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.03),
                              blurRadius: isEmergency ? 10 : 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Label & TTS
                      if (!isUser)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isEmergency ? '🚨 Emergency Clinical Protocol' : 'Dr. Channi',
                                  style: TextStyle(
                                    color: isEmergency ? const Color(0xFFDC2626) : AppColors.primary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (chunks.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'RAG Grounded',
                                      style: TextStyle(
                                        color: Color(0xFF0284C7),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!msg.isStreaming && msg.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  if (provider.voiceService.isSpeaking) {
                                    provider.voiceService.stopSpeaking();
                                  } else {
                                    provider.voiceService.speak(msg.text);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Icon(
                                    provider.voiceService.isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                    color: provider.voiceService.isSpeaking ? AppColors.primary : AppColors.textSecondary,
                                    size: 17,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (!isUser) const SizedBox(height: 6),

                      // Emergency Callout Box
                      if (!isUser && isEmergency) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB91C1C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emergency_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'LIFE-THREATENING EMERGENCY SUSPECTED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFB91C1C),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  elevation: 0,
                                ),
                                onPressed: _makeEmergencyCall,
                                icon: const Icon(Icons.phone_in_talk_rounded, size: 14),
                                label: const Text(
                                  'Call 108',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (msg.immediateAction != null && msg.immediateAction!.isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.flash_on_rounded, color: Color(0xFFB45309), size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'IMMEDIATE ACTION: ${msg.immediateAction}',
                                    style: const TextStyle(
                                      color: Color(0xFF78350F),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      // Text Content (Rich Markdown)
                      if (isUser)
                        Text(
                          msg.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        )
                      else if (msg.text.isEmpty && msg.isStreaming)
                        const Text(
                          'Evaluating symptoms & local medical evidence...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        MarkdownFormattedText(
                          text: msg.text,
                          onItemTap: (tappedItem) {
                            final clean = tappedItem
                                .replaceAll(RegExp(r'^[•\-\*\+\d\.\s👉]+'), '')
                                .trim();
                            if (clean.isNotEmpty) {
                              _inputController.text = clean;
                              _handleSend(provider);
                            }
                          },
                          baseStyle: TextStyle(
                            color: isEmergency ? const Color(0xFF1E293B) : AppColors.textPrimary,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),

                      // Insufficient Evidence Notice (when applicable)
                      if (!isUser && !msg.isEvidenceSufficient && !isEmergency && !msg.isStreaming) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Offline evidence note: Local database lacks complete evidence for this specific query. General safety guidelines applied.',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // RAG Grounding Evidence Chips (Section 3 & 4 Deliverable)
                      if (!isUser && chunks.isNotEmpty && !msg.isStreaming) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Sources (${chunks.length})',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showEvidenceModal(context, chunks),
                              child: const Text(
                                'View Sources',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: chunks.take(3).map((chunk) {
                            return InkWell(
                              onTap: () => _showEvidenceModal(context, chunks),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  '${chunk.sourceTitle} • ${chunk.section}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Streaming indicator
                      if (msg.isStreaming) ...[
                        const SizedBox(height: 6),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Inference & RAG Performance Metrics
          if (!isUser && msg.metrics != null)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 2),
                  Text(
                    '${msg.metrics!.tpsLabel} • TTFT: ${msg.metrics!.ttftLabel} • ${msg.metrics!.totalTimeLabel} • RAG: On-Device',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Displays structured modal with full RAG chunk metadata and evidence text
  void _showEvidenceModal(BuildContext context, List<MedicalRagChunk> chunks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Retrieved Medical Evidence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '100% Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chunks.length,
                  itemBuilder: (_, index) {
                    final c = chunks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.sourceTitle,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.folder_outlined, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Section: ${c.section} • Ver: ${c.documentVersion} • Rev: ${c.reviewDate}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.text,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF334155),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
