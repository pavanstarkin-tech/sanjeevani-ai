import 'package:flutter/foundation.dart';

/// Syndromic Disease Cluster Record
class SyndromicOutbreakCluster {
  final String id;
  final String diseaseName;
  final String districtMandal;
  final int activeCasesReported;
  final double weeklyGrowthPercent;
  final String threatLevel; // 'LOW', 'MODERATE', 'HIGH_OUTBREAK_ALERT'
  final List<String> primarySymptoms;
  final String publicHealthAdvisory;
  final String preStockSuppliesNeeded; // e.g. 'IV Saline, Paracetamol, Mosquito Larvicide'
  final DateTime lastUpdated;

  const SyndromicOutbreakCluster({
    required this.id,
    required this.diseaseName,
    required this.districtMandal,
    required this.activeCasesReported,
    required this.weeklyGrowthPercent,
    required this.threatLevel,
    required this.primarySymptoms,
    required this.publicHealthAdvisory,
    required this.preStockSuppliesNeeded,
    required this.lastUpdated,
  });
}

/// Time-Bound EHR Access Consent Token (Privacy-Preserving)
class DynamicEhrConsentToken {
  final String tokenId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool allowVitals;
  final bool allowLabReports;
  final bool allowPrescriptions;
  final bool allowDoctorNotes;

  const DynamicEhrConsentToken({
    required this.tokenId,
    required this.createdAt,
    required this.expiresAt,
    this.allowVitals = true,
    this.allowLabReports = true,
    this.allowPrescriptions = true,
    this.allowDoctorNotes = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get remainingMinutes => expiresAt.difference(DateTime.now()).inMinutes.clamp(0, 120);
}

/// Service managing Public Health Outbreak Surveillance & Privacy Consent
class PublicHealthSurveillanceService extends ChangeNotifier {
  DynamicEhrConsentToken? _activeConsentToken;

  DynamicEhrConsentToken? get activeConsentToken => _activeConsentToken;

  /// Regional syndromic disease cluster database
  static final List<SyndromicOutbreakCluster> activeClusters = [
    SyndromicOutbreakCluster(
      id: 'cluster_dengue_rangareddy',
      diseaseName: 'Dengue Viral Fever (NS1 Cluster)',
      districtMandal: 'Ranga Reddy / Shamshabad Mandal Grid',
      activeCasesReported: 48,
      weeklyGrowthPercent: 32.5,
      threatLevel: 'HIGH_OUTBREAK_ALERT',
      primarySymptoms: ['High Fever > 102°F', 'Retro-orbital Eye Pain', 'Joint Arthralgia', 'Thrombocytopenia'],
      publicHealthAdvisory: 'Vector fogging deployed. PHCs instructed to stock NS1 rapid antigen kits and platelet monitors.',
      preStockSuppliesNeeded: 'IV Ringer Lactate, Paracetamol 500mg, Papaya Leaf Formulations, ORS',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    SyndromicOutbreakCluster(
      id: 'cluster_malaria_medak',
      diseaseName: 'Plasmodium Falciparum Malaria',
      districtMandal: 'Medak / Narsapur Rural Corridor',
      activeCasesReported: 22,
      weeklyGrowthPercent: 14.0,
      threatLevel: 'MODERATE',
      primarySymptoms: ['Chills with Rigors', 'Intermittent High Temperature', 'Splenomegaly'],
      publicHealthAdvisory: 'Mass blood survey in tribal hamlets; distribute long-lasting insecticidal nets (LLINs).',
      preStockSuppliesNeeded: 'Artesunate Combo Therapy (ACT), Chloroquine, Rapid Diagnostic Tests',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    SyndromicOutbreakCluster(
      id: 'cluster_ge_hyderabad',
      diseaseName: 'Acute Viral Gastroenteritis (Waterborne)',
      districtMandal: 'Old City / Charminar Municipal Zone',
      activeCasesReported: 64,
      weeklyGrowthPercent: 8.5,
      threatLevel: 'MODERATE',
      primarySymptoms: ['Watery Diarrhea', 'Severe Dehydration', 'Vomiting', 'Abdominal Cramping'],
      publicHealthAdvisory: 'Chlorination tests ongoing in municipal water pipelines; distribute free ORS packets at urban clinics.',
      preStockSuppliesNeeded: 'WHO Oral Rehydration Salts (ORS), Zinc Sulfate, Ciprofloxacin, IV Dextrose',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  /// Generate dynamic time-bound QR consent token
  DynamicEhrConsentToken generateConsentToken({
    int validityMinutes = 15,
    bool allowVitals = true,
    bool allowLabReports = true,
    bool allowPrescriptions = true,
    bool allowDoctorNotes = false,
  }) {
    final now = DateTime.now();
    final token = DynamicEhrConsentToken(
      tokenId: 'CONSENT-${now.millisecondsSinceEpoch.toString().substring(6)}',
      createdAt: now,
      expiresAt: now.add(Duration(minutes: validityMinutes)),
      allowVitals: allowVitals,
      allowLabReports: allowLabReports,
      allowPrescriptions: allowPrescriptions,
      allowDoctorNotes: allowDoctorNotes,
    );

    _activeConsentToken = token;
    notifyListeners();
    return token;
  }

  void revokeConsentToken() {
    _activeConsentToken = null;
    notifyListeners();
  }
}
