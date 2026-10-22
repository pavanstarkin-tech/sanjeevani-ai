import 'package:flutter/foundation.dart';

/// Government Healthcare Benefit Package (PM-JAY / Aarogyasri)
class GovernmentTreatmentPackage {
  final String packageCode;
  final String procedureName;
  final String category; // 'Cardiology', 'Orthopedics', 'Oncology', 'Nephrology', 'Maternal & Child', 'Polytrauma'
  final double standardPackageRate;
  final bool coveredUnderPmjay;
  final bool coveredUnderAarogyasri;
  final int averageHospitalStayDays;
  final List<String> requiredDocuments;
  final String preAuthApprovalTimeHours;

  const GovernmentTreatmentPackage({
    required this.packageCode,
    required this.procedureName,
    required this.category,
    required this.standardPackageRate,
    required this.coveredUnderPmjay,
    required this.coveredUnderAarogyasri,
    required this.averageHospitalStayDays,
    required this.requiredDocuments,
    this.preAuthApprovalTimeHours = '2 to 4 Hours (Emergency: Instant)',
  });
}

/// Service managing Government Healthcare Schemes (PM-JAY & Aarogyasri)
class GovernmentSchemeService extends ChangeNotifier {
  static const List<GovernmentTreatmentPackage> packages = [
    GovernmentTreatmentPackage(
      packageCode: 'CARD-STENT-01',
      procedureName: 'Coronary Angioplasty with Drug-Eluting Stent (DES)',
      category: 'Cardiology',
      standardPackageRate: 65000.0,
      coveredUnderPmjay: true,
      coveredUnderAarogyasri: true,
      averageHospitalStayDays: 3,
      requiredDocuments: ['Aadhaar Card', 'Ration Card / PM-JAY e-Card', 'Coronary Angiogram CD & Report'],
    ),
    GovernmentTreatmentPackage(
      packageCode: 'ORTHO-KNEE-02',
      procedureName: 'Total Knee Replacement (Unilateral TKR with Implant)',
      category: 'Orthopedics',
      standardPackageRate: 110000.0,
      coveredUnderPmjay: true,
      coveredUnderAarogyasri: true,
      averageHospitalStayDays: 5,
      requiredDocuments: ['Aadhaar Card', 'White Ration Card', 'Bilateral Knee Weight-bearing X-Rays'],
    ),
    GovernmentTreatmentPackage(
      packageCode: 'NEPHRO-DIAL-03',
      procedureName: 'Maintenance Hemodialysis (Per Session + Erythropoietin)',
      category: 'Nephrology',
      standardPackageRate: 2500.0,
      coveredUnderPmjay: true,
      coveredUnderAarogyasri: true,
      averageHospitalStayDays: 1,
      requiredDocuments: ['Aadhaar Card', 'Aarogyasri Passbook', 'Nephrology Chronic Kidney Disease (CKD) Summary'],
    ),
    GovernmentTreatmentPackage(
      packageCode: 'ONCO-CHEMO-04',
      procedureName: 'Targeted Chemotherapy & Immunotherapy Cycle',
      category: 'Oncology',
      standardPackageRate: 48000.0,
      coveredUnderPmjay: true,
      coveredUnderAarogyasri: true,
      averageHospitalStayDays: 2,
      requiredDocuments: ['Biopsy / Histopathology Report', 'Aadhaar Card', 'Oncology Tumor Board Prescription'],
    ),
    GovernmentTreatmentPackage(
      packageCode: 'MAT-DELIV-05',
      procedureName: 'High-Risk Cesarean Delivery (LSCS) & Neonatal Care',
      category: 'Maternal & Child',
      standardPackageRate: 18500.0,
      coveredUnderPmjay: true,
      coveredUnderAarogyasri: true,
      averageHospitalStayDays: 4,
      requiredDocuments: ['Mother Aadhaar Card', 'MCH / Thayi Card', 'Ultrasound Growth Scan'],
    ),
    GovernmentTreatmentPackage(
      packageCode: 'TRAUMA-SURG-06',
      procedureName: 'Highway Polytrauma & Compound Fracture Internal Fixation',
      category: 'Polytrauma',
      standardPackageRate: 95000.0,
      coveredUnderPmjay: true,
      coveredUnderAarogyasri: true,
      averageHospitalStayDays: 7,
      requiredDocuments: ['Emergency Casualty MLC Copy', 'Aadhaar / Any Govt ID', 'Radiology CT/X-Ray'],
    ),
  ];

  /// Check scheme eligibility based on user socioeconomic indicators
  Map<String, dynamic> checkEligibility({
    required bool hasWhiteRationCard,
    required bool hasPmjayCard,
    required double annualHouseholdIncomeLakhs,
  }) {
    final eligibleAarogyasri = hasWhiteRationCard || annualHouseholdIncomeLakhs <= 5.0;
    final eligiblePmjay = hasPmjayCard || hasWhiteRationCard || annualHouseholdIncomeLakhs <= 2.5;

    return {
      'eligibleAarogyasri': eligibleAarogyasri,
      'aarogyasriMaxCoverage': '₹25,00,000 (State Health Scheme)',
      'eligiblePmjay': eligiblePmjay,
      'pmjayMaxCoverage': '₹5,00,000 (Ayushman Bharat National Scheme)',
      'verdict': (eligibleAarogyasri || eligiblePmjay)
          ? 'Eligible for 100% Cashless Treatment in Empanelled Hospitals'
          : 'Consult Aarogya Mitra Helpdesk for Special Chief Minister Relief Fund (CMRF) waiver.',
    };
  }
}
