import 'dart:math' as math;

/// Model representing a single authoritative Medical RAG Chunk.
/// Preserves medical context, clinical guidelines, first-aid instructions,
/// contraindications, and complete source metadata.
class MedicalRagChunk {
  final String id;
  final String sourceTitle;
  final String section;
  final String version;
  final String reviewDate;
  final String category;
  final String condition;
  final String severity;
  final List<String> tags;
  final String content;
  final List<String> contraindications;
  final List<String> redFlags;
  final List<double> vector; // Pre-computed dense embedding vector
  double score; // Runtime similarity score

  // Convenience aliases and getters
  String get chunkId => id;
  String get documentVersion => version;
  String get text => content;
  List<double> get embedding => vector;
  Map<String, dynamic> get metadata => {
        'id': id,
        'version': version,
        'review_date': reviewDate,
        'publication_year': reviewDate.split('-').first,
        'category': category,
        'condition': condition,
      };

  MedicalRagChunk({
    String? id,
    String? chunkId,
    required this.sourceTitle,
    required this.section,
    String? version,
    String? documentVersion,
    required this.reviewDate,
    this.category = 'Clinical Guidance',
    this.condition = 'General Health',
    this.severity = 'Standard',
    this.tags = const [],
    String? content,
    String? text,
    this.contraindications = const [],
    this.redFlags = const [],
    List<double>? vector,
    List<double>? embedding,
    this.score = 0.0,
    Map<String, dynamic>? metadata,
  })  : id = id ?? chunkId ?? '',
        version = version ?? documentVersion ?? 'v1.0',
        content = content ?? text ?? '',
        vector = vector ?? embedding ?? const [];

  factory MedicalRagChunk.fromJson(Map<String, dynamic> json) {
    return MedicalRagChunk(
      id: json['id']?.toString() ?? '',
      sourceTitle: json['source_title']?.toString() ?? 'Clinical Guidance',
      section: json['section']?.toString() ?? 'General',
      version: json['version']?.toString() ?? 'v1.0',
      reviewDate: json['review_date']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Clinical Guidelines',
      condition: json['condition']?.toString() ?? 'General Health',
      severity: json['severity']?.toString() ?? 'Standard',
      tags: (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [],
      content: json['content']?.toString() ?? '',
      contraindications: (json['contraindications'] as List<dynamic>?)?.map((c) => c.toString()).toList() ?? [],
      redFlags: (json['red_flags'] as List<dynamic>?)?.map((r) => r.toString()).toList() ?? [],
      vector: (json['vector'] as List<dynamic>?)?.map((v) => (v as num).toDouble()).toList() ?? [],
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'source_title': sourceTitle,
    'section': section,
    'version': version,
    'review_date': reviewDate,
    'category': category,
    'condition': condition,
    'severity': severity,
    'tags': tags,
    'content': content,
    'contraindications': contraindications,
    'red_flags': redFlags,
    'vector': vector,
    'score': score,
  };

  /// Calculates cosine similarity between this chunk's vector and a query vector.
  double cosineSimilarity(List<double> queryVector) {
    if (vector.isEmpty || queryVector.isEmpty || vector.length != queryVector.length) {
      return 0.0;
    }
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < vector.length; i++) {
      dotProduct += vector[i] * queryVector[i];
      normA += vector[i] * vector[i];
      normB += queryVector[i] * queryVector[i];
    }
    if (normA <= 0 || normB <= 0) return 0.0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }
}

/// Result of an offline RAG query retrieval containing normalized query,
/// detected emergency risks, retrieved chunks, and sufficiency flag.
class RagRetrievalResult {
  final String query;
  final String normalizedQuery;
  final List<String> extractedSymptoms;
  final List<MedicalRagChunk> chunks;
  final bool isEmergencySuspected;
  final String? emergencyTrigger;
  final String? immediateEmergencyAction;
  final bool isEvidenceSufficient;
  final int totalCandidateChunks;
  final int latencyMs;

  const RagRetrievalResult({
    required this.query,
    required this.normalizedQuery,
    required this.extractedSymptoms,
    required this.chunks,
    required this.isEmergencySuspected,
    this.emergencyTrigger,
    this.immediateEmergencyAction,
    required this.isEvidenceSufficient,
    required this.totalCandidateChunks,
    required this.latencyMs,
  });

  /// Compatibility getters
  bool get isSufficient => isEvidenceSufficient;
  String get delimitedContext => toDelimitedEvidence();

  /// Delimited context evidence formatted specifically for Llama 3.1 1B Instruct.
  String toDelimitedEvidence() {
    if (chunks.isEmpty) {
      return '<retrieved_medical_context>\n[No directly matching local medical evidence found. State limitation explicitly.]\n</retrieved_medical_context>';
    }

    final buf = StringBuffer();
    buf.writeln('<retrieved_medical_context>');
    for (int i = 0; i < chunks.length; i++) {
      final c = chunks[i];
      buf.writeln('[Source ${i + 1}: ${c.sourceTitle}, Section: ${c.section}, Version: ${c.version}, Review Date: ${c.reviewDate}]');
      buf.writeln('Condition: ${c.condition} | Severity: ${c.severity}');
      buf.writeln(c.content.trim());
      if (c.contraindications.isNotEmpty) {
        buf.writeln('Contraindications: ${c.contraindications.join("; ")}');
      }
      if (c.redFlags.isNotEmpty) {
        buf.writeln('Red Flags: ${c.redFlags.join("; ")}');
      }
      buf.writeln();
    }
    buf.write('</retrieved_medical_context>');
    return buf.toString();
  }
}
