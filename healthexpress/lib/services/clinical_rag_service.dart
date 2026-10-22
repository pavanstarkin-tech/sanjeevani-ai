import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Model representing a single Knowledge Layer / RAG Chunk published by Admin
class RagChunkModel {
  final String id;
  final String title;
  final String category;
  final String condition;
  final String severity;
  final List<String> tags;
  final String schemeRef;
  final String content;
  final String status;

  RagChunkModel({
    required this.id,
    required this.title,
    required this.category,
    this.condition = 'General Health',
    this.severity = 'Standard',
    this.tags = const [],
    this.schemeRef = 'HealthExpress RAG',
    required this.content,
    this.status = 'Published',
  });

  factory RagChunkModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((t) => t.toString()).toList();
    } else if (json['tags'] is String) {
      parsedTags = (json['tags'] as String).split(',').map((t) => t.trim()).toList();
    }

    return RagChunkModel(
      id: json['id']?.toString() ?? 'RAG-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Clinical Knowledge',
      category: json['category']?.toString() ?? 'Clinical Guidelines',
      condition: json['condition']?.toString() ?? 'General Health',
      severity: json['severity']?.toString() ?? 'Standard',
      tags: parsedTags,
      schemeRef: json['scheme_ref']?.toString() ?? 'HealthExpress RAG',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Published',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'condition': condition,
    'severity': severity,
    'tags': tags,
    'scheme_ref': schemeRef,
    'content': content,
    'status': status,
  };
}

/// Clinical RAG Service that keeps the mobile app synchronized with the Admin Panel
/// in real time when online, and caches the knowledge layer offline-first for 100%
/// on-device query retrieval before AI generation.
class ClinicalRagService extends ChangeNotifier {
  static final ClinicalRagService instance = ClinicalRagService._internal();
  factory ClinicalRagService() => instance;
  ClinicalRagService._internal();

  static const String _prefKeyChunks = 'cached_clinical_rag_chunks_v2';
  static const String _prefKeyVersion = 'cached_clinical_rag_version_v2';

  String _currentVersion = 'rag-v2026.10.19-01';
  DateTime? _lastSyncTime;
  List<RagChunkModel> _chunks = [];
  bool _isSyncing = false;
  Timer? _autoSyncTimer;

  String get currentVersion => _currentVersion;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<RagChunkModel> get chunks => List.unmodifiable(_chunks);
  bool get isSyncing => _isSyncing;

  /// Initialize service, load offline cache, and start background sync
  Future<void> init() async {
    await _loadCachedChunks();
    // If cached chunks is empty or does not contain full state schemes, load bundled state schemes
    final hasStateSchemes = _chunks.any((c) => c.id.startsWith('RAG-SCHEME-'));
    if (_chunks.isEmpty || !hasStateSchemes) {
      await _loadStateSchemesFromAsset();
      if (_chunks.isEmpty) {
        _seedDefaultChunks();
      }
    }

    // Attempt immediate sync
    syncWithAdminPanel();

    // Start periodic background sync (every 18 seconds)
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 18), (_) {
      syncWithAdminPanel();
    });
  }

  /// Load cached chunks from SharedPreferences for instant offline availability
  Future<void> _loadCachedChunks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVersion = prefs.getString(_prefKeyVersion);
      if (savedVersion != null && savedVersion.isNotEmpty) {
        _currentVersion = savedVersion;
      }

      final jsonStr = prefs.getString(_prefKeyChunks);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        _chunks = list.map((item) => RagChunkModel.fromJson(item as Map<String, dynamic>)).toList();
        debugPrint('[ClinicalRagService] Loaded ${_chunks.length} RAG chunks from offline cache (v: $_currentVersion)');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ClinicalRagService] Error loading cached RAG chunks: $e');
    }
  }

  /// Persist chunks to SharedPreferences
  Future<void> _persistChunks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyVersion, _currentVersion);
      final jsonList = _chunks.map((c) => c.toJson()).toList();
      await prefs.setString(_prefKeyChunks, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[ClinicalRagService] Error saving RAG chunks to cache: $e');
    }
  }

  /// Polls the admin panel for real-time RAG updates
  Future<bool> syncWithAdminPanel() async {
    if (_isSyncing) return false;
    _isSyncing = true;

    try {
      final versionData = await ApiService.checkLatestRagVersion();
      if (versionData != null && versionData['version'] != null) {
        final serverVersion = versionData['version'] as String;
        if (serverVersion != _currentVersion || _chunks.isEmpty) {
          debugPrint('[ClinicalRagService] Detected new RAG layer update: $serverVersion (Current: $_currentVersion). Synchronizing...');
          final serverChunks = await ApiService.fetchPublishedRagChunks();
          if (serverChunks.isNotEmpty) {
            _currentVersion = serverVersion;
            _chunks = serverChunks.map((c) => RagChunkModel.fromJson(c)).toList();
            _lastSyncTime = DateTime.now();
            await _persistChunks();
            debugPrint('[ClinicalRagService] Successfully synchronized ${_chunks.length} RAG chunks from Admin Panel (Version: $_currentVersion)');
            notifyListeners();
            _isSyncing = false;
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('[ClinicalRagService] Auto-sync check notice: $e');
    }

    _isSyncing = false;
    return false;
  }

  /// Retrieve the most relevant RAG chunks for a query and symptoms.
  /// Works 100% offline using locally stored chunks or online.
  List<RagChunkModel> retrieveRelevantChunks(
    String query, {
    List<String> symptoms = const [],
    int maxResults = 3,
  }) {
    if (_chunks.isEmpty) return [];

    final qLower = query.toLowerCase().trim();
    final qTerms = qLower.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
    final symptomLower = symptoms.map((s) => s.toLowerCase().trim()).toList();

    final scored = <MapEntry<RagChunkModel, int>>[];

    for (final chunk in _chunks) {
      int score = 0;
      final titleLower = chunk.title.toLowerCase();
      final contentLower = chunk.content.toLowerCase();
      final condLower = chunk.condition.toLowerCase();
      final catLower = chunk.category.toLowerCase();
      final schemeLower = chunk.schemeRef.toLowerCase();

      // 1. Direct query terms match in Title (High weight)
      for (final term in qTerms) {
        if (titleLower.contains(term)) score += 8;
        if (condLower.contains(term)) score += 6;
        if (schemeLower.contains(term)) score += 6;
        if (contentLower.contains(term)) score += 3;
        if (catLower.contains(term)) score += 2;
      }

      // 2. Tag matches
      for (final tag in chunk.tags) {
        final tLower = tag.toLowerCase();
        if (qLower.contains(tLower)) score += 7;
        for (final s in symptomLower) {
          if (s.contains(tLower) || tLower.contains(s)) score += 6;
        }
      }

      // 3. Matched symptoms in condition or content
      for (final sym in symptomLower) {
        if (titleLower.contains(sym)) score += 8;
        if (condLower.contains(sym)) score += 6;
        if (contentLower.contains(sym)) score += 3;
      }

      // 4. Special Intent Boosts
      // Schemes intent
      if (qLower.contains('scheme') || qLower.contains('aarogyasri') || qLower.contains('ayushman') ||
          qLower.contains('pmjay') || qLower.contains('jan aushadhi') || qLower.contains('insurance') ||
          qLower.contains('పథకం') || qLower.contains('ఆరోగ్యశ్రీ') || qLower.contains('योजना')) {
        if (chunk.category.toLowerCase().contains('scheme') || chunk.title.toLowerCase().contains('scheme') || chunk.schemeRef.isNotEmpty) {
          score += 15;
        }
      }

      // Fever / Dengue boost
      if (qLower.contains('dengue') || qLower.contains('platelet') || qLower.contains('fever') || qLower.contains('జ్వరం') || qLower.contains('बुखार')) {
        if (chunk.title.toLowerCase().contains('dengue') || chunk.condition.toLowerCase().contains('fever')) {
          score += 12;
        }
      }

      // Emergency / Ambulance / Heart / Stroke boost
      if (qLower.contains('emergency') || qLower.contains('chest pain') || qLower.contains('heart') || qLower.contains('stroke') || qLower.contains('108')) {
        if (chunk.category.toLowerCase().contains('emergency') || chunk.title.toLowerCase().contains('emergency') || chunk.severity.toLowerCase().contains('critical')) {
          score += 15;
        }
      }

      // Medicines / Tablet / Generic boost
      if (qLower.contains('medicine') || qLower.contains('tablet') || qLower.contains('generic') || qLower.contains('jan aushadhi') || qLower.contains('మందులు') || qLower.contains('दवा')) {
        if (chunk.category.toLowerCase().contains('pharmacy') || chunk.title.toLowerCase().contains('generic')) {
          score += 12;
        }
      }

      if (score > 0) {
        scored.add(MapEntry(chunk, score));
      }
    }

    if (scored.isEmpty) return [];

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(maxResults).map((e) => e.key).toList();
  }

  /// Builds an authoritative RAG knowledge context string to inject into AI Prompts
  String buildRagContextPrompt(
    String query, {
    List<String> symptoms = const [],
    int maxResults = 2,
  }) {
    final relevant = retrieveRelevantChunks(query, symptoms: symptoms, maxResults: maxResults);
    if (relevant.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('=== VERIFIED CLINICAL & SCHEME RAG KNOWLEDGE LAYER [Version: $_currentVersion] ===');
    for (final chunk in relevant) {
      buffer.writeln('• SOURCE: ${chunk.title} [Category: ${chunk.category} | Scheme: ${chunk.schemeRef}]');
      buffer.writeln('  GUIDELINES: ${chunk.content}');
    }
    buffer.writeln('=== END RAG KNOWLEDGE LAYER ===');
    return buffer.toString().trim();
  }

  /// Seed initial high-quality clinical protocols if offline storage is empty
  void _seedDefaultChunks() {
    _chunks = [
      RagChunkModel(
        id: 'RAG-01',
        title: 'ICMR Dengue & Viral Fever Clinical Protocol',
        category: 'Clinical Guidelines',
        condition: 'Dengue Fever, Viral Pyrexia, Thrombocytopenia',
        severity: 'High',
        tags: ['dengue', 'fever', 'platelets', 'icmr', 'ns1', 'paracetamol', 'hydration', 'జ్వరం', 'బుఖార్'],
        schemeRef: 'Aarogyasri Acute Inpatient Care',
        content: 'ICMR Guidelines for Dengue: 1. Avoid all NSAIDs, Aspirin, and Ibuprofen due to severe bleeding risks. 2. Prescribe Paracetamol (650mg SOS) for fever. 3. Monitor daily Complete Blood Picture (CBP); platelets below 50,000/mcL requires hospitalization. 4. Maintain oral rehydration (ORS, coconut water). 5. Covered under Aarogyasri for free inpatient care.',
      ),
      RagChunkModel(
        id: 'RAG-02',
        title: 'Dr. YSR Aarogyasri & Telangana Aarogyasri Comprehensive Health Scheme',
        category: 'Government Schemes',
        condition: 'Cardiology, Oncology, Orthopedics, Poly-Trauma, Surgeries',
        severity: 'Emergency / Tertiary',
        tags: ['aarogyasri', 'scheme', 'cashless', 'heart', 'cardiology', 'surgery', 'hospital', 'ఆరోగ్యశ్రీ', 'పథకం'],
        schemeRef: 'State Government Aarogyasri Trust',
        content: 'Aarogyasri Health Scheme provides 100% cashless treatment up to ₹10,00,000 per family per year across 1,672+ empaneled government and private network hospitals. Covers 3,257 surgical and medical procedures including: PTCA Stenting, CABG bypass, valve replacement, knee/hip replacement, and cancer therapy. Beneficiaries must present Digital Aarogyasri Card or Aadhaar.',
      ),
      RagChunkModel(
        id: 'RAG-03',
        title: 'Ayushman Bharat PM-JAY National Health Protection Scheme',
        category: 'Government Schemes',
        condition: 'Chronic Kidney Disease, Hemodialysis, Multi-Organ Care',
        severity: 'High / Chronic',
        tags: ['ayushman', 'pmjay', 'pm-jay', 'dialysis', 'kidney', 'cashless', 'insurance', 'hospital', 'आयुष्मान'],
        schemeRef: 'National Health Authority (NHA)',
        content: 'Ayushman Bharat PM-JAY provides health coverage of ₹5,00,000 per family per year for secondary and tertiary care hospitalization across 27,000+ empaneled hospitals. Key highlights: 1. Free maintenance hemodialysis across all empaneled centers. 2. Pre-hospitalization (3 days) and post-hospitalization (15 days) medications included. 3. Zero deposit required.',
      ),
      RagChunkModel(
        id: 'RAG-04',
        title: 'Pradhan Mantri Bhartiya Janaushadhi Pariyojana (PMBJP)',
        category: 'Pharmacy',
        condition: 'Generic Medicines, Chronic Diabetes, Hypertension, Antibiotics',
        severity: 'Standard',
        tags: ['jan aushadhi', 'generic', 'medicines', 'tablets', 'discount', 'paracetamol', 'pantoprazole', 'dolo', 'दवा'],
        schemeRef: 'Department of Pharmaceuticals, Govt of India',
        content: 'Jan Aushadhi Kendras provide certified WHO-GMP quality generic medicines at 50% to 90% cheaper prices: 1. Paracetamol 650mg: ₹12.50 (vs ₹34 branded). 2. Pantoprazole 40mg: ₹18.00 (vs ₹95 branded). 3. Metformin 500mg: ₹9.00 (vs ₹42 branded). 4. Cetirizine 10mg: ₹7.50 (vs ₹45 branded). All products meet Indian Pharmacopoeia standards.',
      ),
    ];
  }

  /// Returns all available Indian states covered in the RAG knowledge layer
  List<String> getAvailableStates() {
    return [
      'Andhra Pradesh',
      'Telangana',
      'Tamil Nadu',
      'Karnataka',
      'Kerala',
    ];
  }

  /// Returns all schemes for a specific state
  List<RagChunkModel> getSchemesForState(String stateName) {
    final lowerState = stateName.toLowerCase().trim();
    return _chunks.where((c) {
      final title = c.title.toLowerCase();
      final content = c.content.toLowerCase();
      final tags = c.tags.map((t) => t.toLowerCase()).toList();
      return title.contains('[$lowerState]') ||
          content.contains('state / jurisdiction: $lowerState') ||
          content.contains('state: $lowerState') ||
          tags.contains(lowerState);
    }).toList();
  }

  /// Loads 54 validated Indian state health schemes bundled offline in assets
  Future<void> _loadStateSchemesFromAsset() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/state_health_schemes.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final List<RagChunkModel> loaded = [];

      data.forEach((stateName, schemesList) {
        if (schemesList is List) {
          for (final item in schemesList) {
            final map = item as Map<String, dynamic>;
            final rawName = map['name']?.toString() ?? '';
            final purpose = map['purpose']?.toString() ?? '';
            final beneficiaries = map['beneficiaries']?.toString() ?? '';
            final eligibility = map['eligibility']?.toString() ?? '';
            final benefits = map['benefits']?.toString() ?? '';
            final documents = map['documents']?.toString() ?? '';
            final howToApply = map['howToApply']?.toString() ?? '';
            final fees = map['fees']?.toString() ?? '';
            final website = map['website']?.toString() ?? '';
            final helpline = map['helpline']?.toString() ?? '';
            final status = map['status']?.toString() ?? 'Active';
            final id = map['id']?.toString() ?? 'RAG-${DateTime.now().millisecondsSinceEpoch}';

            final words = rawName.toLowerCase().split(RegExp(r'[\s\(\)\-\/]+')).where((w) => w.length > 2).toList();
            final tags = <String>{
              stateName.toLowerCase(),
              'scheme',
              'government scheme',
              'healthcare',
              'health insurance',
              'cashless',
              ...words,
            }.toList();

            final content = '''
[State: $stateName]
Scheme Name: $rawName
Details & Purpose: $purpose
Target Beneficiaries: $beneficiaries
Eligibility Criteria: $eligibility
Benefits & Financial Coverage: $benefits
Required Documents: $documents
Application & Claim Process: $howToApply
Cost to Patient: $fees
Helpline: $helpline | Official Portal: $website | Status: $status
'''.trim();

            loaded.add(RagChunkModel(
              id: id,
              title: '[$stateName] $rawName',
              category: 'Government Schemes',
              condition: '$beneficiaries - $purpose',
              severity: benefits.contains('Lakh') ? 'High / Cashless Tertiary' : 'Universal Healthcare',
              tags: tags,
              schemeRef: '$stateName State Health Agency',
              content: content,
              status: status,
            ));
          }
        }
      });

      if (loaded.isNotEmpty) {
        _seedDefaultChunks();
        final existingIds = _chunks.map((c) => c.id).toSet();
        for (final s in loaded) {
          if (!existingIds.contains(s.id)) {
            _chunks.add(s);
          }
        }
        _currentVersion = 'rag-v2026.10.20-schemes-54';
        await _persistChunks();
        debugPrint('[ClinicalRagService] Loaded ${_chunks.length} RAG chunks (including state health schemes) into memory');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ClinicalRagService] Error loading state schemes from asset: $e');
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
