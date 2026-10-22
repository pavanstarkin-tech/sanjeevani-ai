/// Models for Offline Medical Small Language Model (SLM),
/// GGUF inference, validated first-aid protocols, and clinical guidance.
library;

import 'medical_rag_chunk.dart';

enum GgufDownloadState {
  notDownloaded,
  downloading,
  paused,
  failed,
  downloaded,
  loading,
  loaded,
}

/// Catalog entry for an on-device GGUF model.
class GgufModel {
  final String id;
  final String name;
  final String parameters;
  final String quantization;
  final String sizeLabel;
  final int sizeBytes;
  final String type;
  final String promptFormat;
  final String? repositoryUrl;
  final String? downloadUrl;
  final String? filename;
  final bool verified;
  final String? notes;

  GgufDownloadState downloadState;
  int downloadedBytes;
  int? contentLength;
  double? speedBytesPerSec;
  double? etaSeconds;
  String? errorMessage;
  String? localPath;
  int? localFileBytes;

  GgufModel({
    required this.id,
    required this.name,
    required this.parameters,
    required this.quantization,
    required this.sizeLabel,
    required this.sizeBytes,
    required this.type,
    required this.promptFormat,
    this.repositoryUrl,
    this.downloadUrl,
    this.filename,
    this.verified = false,
    this.notes,
    this.downloadState = GgufDownloadState.notDownloaded,
    this.downloadedBytes = 0,
    this.contentLength,
    this.speedBytesPerSec,
    this.etaSeconds,
    this.errorMessage,
    this.localPath,
    this.localFileBytes,
  });

  bool get canDownload => downloadUrl != null && downloadUrl!.isNotEmpty;

  bool get isOnDisk =>
      localPath != null &&
      (localFileBytes ?? 0) > 0 &&
      (downloadState == GgufDownloadState.downloaded ||
          downloadState == GgufDownloadState.loaded ||
          downloadState == GgufDownloadState.loading);

  double? get downloadFraction {
    final total = contentLength ?? sizeBytes;
    if (total <= 0 || downloadedBytes <= 0) return null;
    return (downloadedBytes / total).clamp(0.0, 1.0);
  }

  String get downloadProgressLabel {
    final total = contentLength ?? sizeBytes;
    return '${formatBytes(downloadedBytes)} / ${formatBytes(total)}';
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String? get speedLabel {
    final s = speedBytesPerSec;
    if (s == null || s <= 0) return null;
    if (s < 1024) return '${s.toStringAsFixed(0)} B/s';
    if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(1)} KB/s';
    return '${(s / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String? get etaLabel {
    final eta = etaSeconds;
    if (eta == null || eta < 0) return null;
    if (eta < 60) return '${eta.round()}s';
    if (eta < 3600) return '${(eta / 60).round()}m ${(eta % 60).round()}s';
    return '${(eta / 3600).floor()}h ${((eta % 3600) / 60).round()}m';
  }

  factory GgufModel.fromJson(Map<String, dynamic> json) {
    return GgufModel(
      id: json['id'] as String,
      name: json['name'] as String,
      parameters: json['parameters'] as String,
      quantization: json['quantization'] as String,
      sizeLabel: json['size_label'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
      type: json['type'] as String,
      promptFormat: (json['prompt_format'] as String?) ?? 'chatml',
      repositoryUrl: json['repository_url'] as String?,
      downloadUrl: json['download_url'] as String?,
      filename: json['filename'] as String?,
      verified: (json['verified'] as bool?) ?? false,
      notes: json['notes'] as String?,
    );
  }
}

/// Inference performance telemetry.
class InferenceMetrics {
  final int? timeToFirstTokenMs;
  final int totalGenerationMs;
  final int generatedTokens;
  final double tokensPerSecond;
  final int? modelLoadDurationMs;
  final int nCtx;
  final int maxTokens;
  final String promptPreview;

  const InferenceMetrics({
    this.timeToFirstTokenMs,
    required this.totalGenerationMs,
    required this.generatedTokens,
    required this.tokensPerSecond,
    this.modelLoadDurationMs,
    required this.nCtx,
    required this.maxTokens,
    this.promptPreview = '',
  });

  String get tpsLabel => '${tokensPerSecond.toStringAsFixed(1)} tok/s';
  String get ttftLabel => timeToFirstTokenMs != null ? '${timeToFirstTokenMs}ms' : 'N/A';
  String get totalTimeLabel {
    if (totalGenerationMs < 1000) return '${totalGenerationMs}ms';
    return '${(totalGenerationMs / 1000).toStringAsFixed(1)}s';
  }
}

/// Avatar emotional & communicative state.
enum DoctorAvatarState {
  idle,
  listening,
  thinking,
  speaking,
  emergency,
}

/// Triage severity level for first aid and clinical assessments.
enum EmergencyTriageLevel {
  critical, // Immediate life threat (CPR, severe bleeding, choking, heart attack)
  urgent,   // Requires prompt intervention (burns, fractures, deep cuts, high fever)
  stable,   // Mild to moderate (sprains, minor scratches, dehydration)
}

/// Structured outcome of emergency risk and triage detection
class EmergencyTriageResult {
  final bool isEmergency;
  final String trigger;
  final String severity;
  final String immediateAction;
  final EmergencyTriageLevel level;

  const EmergencyTriageResult({
    required this.isEmergency,
    required this.trigger,
    required this.severity,
    required this.immediateAction,
    this.level = EmergencyTriageLevel.stable,
  });
}

/// Single step inside an interactive first-aid protocol.
class FirstAidStep {
  final int stepNumber;
  final String title;
  final String detail;
  final String? warning;
  final String? audioInstruction;
  final int? timerSeconds;
  final bool hasMetronome;
  final int metronomeBpm;

  const FirstAidStep({
    required this.stepNumber,
    required this.title,
    required this.detail,
    this.warning,
    this.audioInstruction,
    this.timerSeconds,
    this.hasMetronome = false,
    this.metronomeBpm = 110,
  });
}

/// Medically validated first-aid protocol.
class FirstAidProtocol {
  final String id;
  final String title;
  final String subtitle;
  final EmergencyTriageLevel emergencyLevel;
  final String validatedBy;
  final List<String> keywords;
  final String quickSummary;
  final List<FirstAidStep> steps;
  final List<String> dos;
  final List<String> donts;
  final List<String> redFlags;
  final String iconCode;

  const FirstAidProtocol({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emergencyLevel,
    required this.validatedBy,
    required this.keywords,
    required this.quickSummary,
    required this.steps,
    required this.dos,
    required this.donts,
    required this.redFlags,
    this.iconCode = 'healing',
  });
}

/// Single chat entry in the offline SLM doctor conversation.
class OfflineDoctorMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;
  final bool isStreaming;
  final InferenceMetrics? metrics;
  final FirstAidProtocol? associatedProtocol;
  final EmergencyTriageLevel? triageLevel;
  final List<String>? actionPrompts;
  final List<MedicalRagChunk> retrievedChunks;
  final bool isEmergency;
  final String? immediateAction;
  final String? emergencyStatus;
  final String? whenToSeekHelp;
  final String? sourceAttribution;
  final bool isEvidenceSufficient;

  OfflineDoctorMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isStreaming = false,
    this.metrics,
    this.associatedProtocol,
    this.triageLevel,
    this.actionPrompts,
    this.retrievedChunks = const [],
    this.isEmergency = false,
    this.immediateAction,
    this.emergencyStatus,
    this.whenToSeekHelp,
    this.sourceAttribution,
    this.isEvidenceSufficient = true,
  });

  OfflineDoctorMessage copyWith({
    String? text,
    bool? isStreaming,
    InferenceMetrics? metrics,
    FirstAidProtocol? associatedProtocol,
    EmergencyTriageLevel? triageLevel,
    List<String>? actionPrompts,
    List<MedicalRagChunk>? retrievedChunks,
    bool? isEmergency,
    String? immediateAction,
    String? emergencyStatus,
    String? whenToSeekHelp,
    String? sourceAttribution,
    bool? isEvidenceSufficient,
  }) {
    return OfflineDoctorMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      metrics: metrics ?? this.metrics,
      associatedProtocol: associatedProtocol ?? this.associatedProtocol,
      triageLevel: triageLevel ?? this.triageLevel,
      actionPrompts: actionPrompts ?? this.actionPrompts,
      retrievedChunks: retrievedChunks ?? this.retrievedChunks,
      isEmergency: isEmergency ?? this.isEmergency,
      immediateAction: immediateAction ?? this.immediateAction,
      emergencyStatus: emergencyStatus ?? this.emergencyStatus,
      whenToSeekHelp: whenToSeekHelp ?? this.whenToSeekHelp,
      sourceAttribution: sourceAttribution ?? this.sourceAttribution,
      isEvidenceSufficient: isEvidenceSufficient ?? this.isEvidenceSufficient,
    );
  }
}

