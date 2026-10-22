import 'package:flutter_test/flutter_test.dart';
import 'package:healthexpress/services/offline_health_grid_service.dart';
import 'package:healthexpress/services/explainable_clinical_ai_service.dart';
import 'package:healthexpress/services/emergency_medicine_hold_service.dart';
import 'package:healthexpress/services/government_scheme_service.dart';
import 'package:healthexpress/services/public_health_surveillance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sanjeevani.AI — Offline Health Grid Tests', () {
    test('Offline health facilities catalog contains rural and highway facilities with live beds', () async {
      final service = OfflineHealthGridService();
      await service.loadCachedGrid();
      final facilities = service.cachedFacilities;
      expect(facilities.isNotEmpty, isTrue);

      final hasHighway = facilities.any((f) => f.corridorTag.contains('Highway') || f.address.contains('NH-'));
      expect(hasHighway, isTrue);

      // Verify resource counters
      for (final f in facilities) {
        expect(f.bedResource.icuBedsAvailable, greaterThanOrEqualTo(0));
        expect(f.bedResource.oxygenBedsAvailable, greaterThanOrEqualTo(0));
        expect(f.bedResource.ventilatorsAvailable, greaterThanOrEqualTo(0));
        expect(f.bedResource.bloodBankUnits.isNotEmpty, isTrue);
      }
    });

    test('Filter facilities by ICU and specific blood group returns valid matches', () async {
      final service = OfflineHealthGridService();
      await service.loadCachedGrid();

      final icuFacilities = service.filterFacilities(requireIcu: true);
      expect(icuFacilities.isNotEmpty, isTrue);
      for (final f in icuFacilities) {
        expect(f.bedResource.icuBedsAvailable, greaterThan(0));
      }

      final oPositiveFacilities = service.filterFacilities(bloodGroup: 'O+');
      expect(oPositiveFacilities.isNotEmpty, isTrue);
      for (final f in oPositiveFacilities) {
        expect(f.bedResource.bloodBankUnits['O+']!, greaterThan(0));
      }
    });
  });

  group('Sanjeevani.AI — Explainable Multimodal Clinical AI Tests', () {
    final clinicalAi = ExplainableClinicalAiService();

    test('Decodes abnormal HbA1c with plain-language explanation and ICD-10/SNOMED CT coding', () {
      final assessment = clinicalAi.generateAssessment(
        condition: 'Type 2 Diabetes',
        labValues: {
          'hba1c': 8.4,
          'creatinine': 1.1,
          'platelets': 200000,
        },
        currentMedications: ['Metformin 500mg'],
        newMedication: 'Glimepiride 1mg',
      );

      expect(assessment.diagnosticConfidencePercent, greaterThan(80.0));
      expect(assessment.standardCode.icd10Code.startsWith('E11'), isTrue);
      expect(assessment.standardCode.snomedCode.isNotEmpty, isTrue);

      final hba1cParam = assessment.labParameters.firstWhere((p) => p.testName.contains('HbA1c'));
      expect(hba1cParam.status, 'HIGH');
      expect(hba1cParam.plainLanguageExplanation, contains('elevated'));
      expect(hba1cParam.regionalTranslation.isNotEmpty, isTrue);
    });

    test('Detects severe Drug-Drug Interaction between Warfarin and Aspirin', () {
      final alerts = clinicalAi.checkDrugInteractions(
        ['Warfarin 5mg', 'Metformin 500mg'],
        'Aspirin 75mg',
      );

      expect(alerts.isNotEmpty, isTrue);
      final warfarinAspirinAlert = alerts.firstWhere((a) => a.drugA == 'Aspirin' && a.drugB == 'Warfarin');
      expect(warfarinAspirinAlert.severity, 'CRITICAL');
      expect(warfarinAspirinAlert.clinicalEffect.toLowerCase(), contains('hemorrhage'));
      expect(warfarinAspirinAlert.actionAdvice.isNotEmpty, isTrue);
    });

    test('Flags critical thrombocytopenia in dengue fever context', () {
      final assessment = clinicalAi.generateAssessment(
        condition: 'Dengue Fever',
        labValues: {
          'platelets': 35000, // < 50k critical threshold
        },
        currentMedications: [],
      );

      final platParam = assessment.labParameters.firstWhere((p) => p.testName.contains('Platelet'));
      expect(platParam.status, 'CRITICAL');
      expect(assessment.standardCode.icd10Code, 'A90');
    });
  });

  group('Sanjeevani.AI — Emergency Medicine & Jan Aushadhi Tests', () {
    test('Jan Aushadhi generic equivalent calculates correct savings up to 75%+', () {
      final catalog = EmergencyMedicineHoldService.catalog;
      expect(catalog.isNotEmpty, isTrue);

      for (final item in catalog) {
        expect(item.savingsPercent, greaterThan(50.0));
        expect(item.savingsRupees, greaterThan(0.0));
        expect(item.janAushadhiPrice, lessThan(item.brandedPrice));
        expect(item.nearbyKendraAddress.isNotEmpty, isTrue);
      }
    });

    test('Hold reservation service generates 30-minute lock with OTP token', () {
      final holdService = EmergencyMedicineHoldService();
      final token = holdService.createEmergencyHold(
        medicineName: 'Augmentin 625 Duo Tablet',
        genericComposition: 'Amoxycillin 500mg + Clavulanic Acid 125mg',
        pharmacyName: 'Apollo 24x7 Emergency Hub',
        pharmacyPhone: '+91 40 2345 6789',
        pharmacyAddress: 'Banjara Hills Rd No 2, Hyderabad',
        price: 215.0,
      );

      expect(token.holdId.startsWith('HOLD-'), isTrue);
      expect(token.isExpired, isFalse);
      expect(token.remainingSeconds, inInclusiveRange(1700, 1800));
      expect(holdService.hasActiveHold, isTrue);
      expect(holdService.activeHold?.holdId, equals(token.holdId));
    });
  });

  group('Sanjeevani.AI — Government Healthcare Schemes Tests', () {
    test('Packages catalog includes PM-JAY and Dr. YSR Aarogyasri procedures with package codes', () {
      final packages = GovernmentSchemeService.packages;
      expect(packages.isNotEmpty, isTrue);

      final hasAarogyasri = packages.any((p) => p.coveredUnderAarogyasri);
      final hasPmjay = packages.any((p) => p.coveredUnderPmjay);
      expect(hasAarogyasri, isTrue);
      expect(hasPmjay, isTrue);

      // Validate cardiology procedures have fixed government tariff
      final cardio = packages.firstWhere((p) => p.category == 'Cardiology');
      expect(cardio.standardPackageRate, greaterThan(50000.0));
      expect(cardio.packageCode.isNotEmpty, isTrue);
      expect(cardio.requiredDocuments.isNotEmpty, isTrue);
    });

    test('Eligibility engine accurately validates white ration card or low income', () {
      final schemeService = GovernmentSchemeService();
      final eligibleResult = schemeService.checkEligibility(
        hasWhiteRationCard: true,
        hasPmjayCard: false,
        annualHouseholdIncomeLakhs: 2.0,
      );
      expect(eligibleResult['eligibleAarogyasri'], isTrue);
      expect(eligibleResult['eligiblePmjay'], isTrue);
      expect(eligibleResult['aarogyasriMaxCoverage'], contains('₹25,00,000'));

      final ineligibleResult = schemeService.checkEligibility(
        hasWhiteRationCard: false,
        hasPmjayCard: false,
        annualHouseholdIncomeLakhs: 8.0,
      );
      expect(ineligibleResult['eligibleAarogyasri'], isFalse);
      expect(ineligibleResult['eligiblePmjay'], isFalse);
    });
  });

  group('Sanjeevani.AI — Syndromic Surveillance & Dynamic EHR Consent Tests', () {
    test('Outbreak clusters identify active syndromic hotspots', () {
      final clusters = PublicHealthSurveillanceService.activeClusters;
      expect(clusters.isNotEmpty, isTrue);

      for (final cluster in clusters) {
        expect(cluster.activeCasesReported, greaterThan(0));
        expect(['LOW', 'MODERATE', 'HIGH_OUTBREAK_ALERT'], contains(cluster.threatLevel));
        expect(cluster.primarySymptoms.isNotEmpty, isTrue);
        expect(cluster.preStockSuppliesNeeded.isNotEmpty, isTrue);
      }
    });

    test('Dynamic EHR consent token creates secure, time-bound access QR payload', () {
      final surveillanceService = PublicHealthSurveillanceService();
      final token = surveillanceService.generateConsentToken(
        validityMinutes: 15,
        allowVitals: true,
        allowLabReports: true,
      );

      expect(token.tokenId.startsWith('CONSENT-'), isTrue);
      expect(token.remainingMinutes, inInclusiveRange(14, 15));
      expect(token.isExpired, isFalse);
      expect(surveillanceService.activeConsentToken, isNotNull);

      // Revocation test
      surveillanceService.revokeConsentToken();
      expect(surveillanceService.activeConsentToken, isNull);
    });
  });
}
