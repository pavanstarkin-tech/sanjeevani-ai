import 'package:flutter/foundation.dart';

/// Active Emergency Medicine Stock Reservation Token
class EmergencyStockHoldToken {
  final String holdId;
  final String medicineName;
  final String genericComposition;
  final String pharmacyName;
  final String pharmacyPhone;
  final String pharmacyAddress;
  final DateTime reservedAt;
  final DateTime expiresAt;
  final String batchNumber;
  final String expiryDate;
  final bool isColdChainCompliant;
  final double reservedPrice;

  const EmergencyStockHoldToken({
    required this.holdId,
    required this.medicineName,
    required this.genericComposition,
    required this.pharmacyName,
    required this.pharmacyPhone,
    required this.pharmacyAddress,
    required this.reservedAt,
    required this.expiresAt,
    required this.batchNumber,
    required this.expiryDate,
    required this.isColdChainCompliant,
    required this.reservedPrice,
  });

  int get remainingSeconds => expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 1800);
  bool get isExpired => remainingSeconds <= 0;
}

/// Generic Jan Aushadhi Alternative
class JanAushadhiComparison {
  final String brandedName;
  final String janAushadhiName;
  final String moleculeComposition;
  final double brandedPrice;
  final double janAushadhiPrice;
  final double savingsPercent;
  final String manufacturer;
  final bool inStockAtJanAushadhiKendra;
  final String nearbyKendraAddress;

  const JanAushadhiComparison({
    required this.brandedName,
    required this.janAushadhiName,
    required this.moleculeComposition,
    required this.brandedPrice,
    required this.janAushadhiPrice,
    required this.savingsPercent,
    required this.manufacturer,
    required this.inStockAtJanAushadhiKendra,
    required this.nearbyKendraAddress,
  });

  double get savingsRupees => brandedPrice - janAushadhiPrice;
}

/// Service managing 30-minute Emergency Stock Reservation
/// and Jan Aushadhi Generic Cost-Saving Comparisons.
class EmergencyMedicineHoldService extends ChangeNotifier {
  EmergencyStockHoldToken? _activeHold;

  EmergencyStockHoldToken? get activeHold => _activeHold;
  bool get hasActiveHold => _activeHold != null && !_activeHold!.isExpired;

  /// Curated Jan Aushadhi generic equivalence catalog
  static const List<JanAushadhiComparison> catalog = [
    JanAushadhiComparison(
      brandedName: 'Augmentin 625 Duo Tablet',
      janAushadhiName: 'Amoxycillin & Potassium Clavulanate 625mg (PMBJP)',
      moleculeComposition: 'Amoxycillin 500mg + Clavulanic Acid 125mg',
      brandedPrice: 215.0,
      janAushadhiPrice: 58.0,
      savingsPercent: 73.0,
      manufacturer: 'BPPI Jan Aushadhi Certified Lab',
      inStockAtJanAushadhiKendra: true,
      nearbyKendraAddress: 'Shop #4, Opp. Govt Area Hospital, Secunderabad',
    ),
    JanAushadhiComparison(
      brandedName: 'Pantocid 40mg Tablet',
      janAushadhiName: 'Pantoprazole Gastro-Resistant 40mg (PMBJP)',
      moleculeComposition: 'Pantoprazole Sodium IP 40mg',
      brandedPrice: 168.0,
      janAushadhiPrice: 32.0,
      savingsPercent: 80.9,
      manufacturer: 'PMBJP Pharma Quality Assured',
      inStockAtJanAushadhiKendra: true,
      nearbyKendraAddress: 'Kendra Hub 12, RTC Cross Roads, Hyderabad',
    ),
    JanAushadhiComparison(
      brandedName: 'Glycomet-GP 2 Forte Tablet',
      janAushadhiName: 'Metformin 1000mg + Glimepiride 2mg (PMBJP)',
      moleculeComposition: 'Metformin SR 1000mg + Glimepiride 2mg',
      brandedPrice: 195.0,
      janAushadhiPrice: 42.0,
      savingsPercent: 78.4,
      manufacturer: 'Govt. Central Medical Stores',
      inStockAtJanAushadhiKendra: true,
      nearbyKendraAddress: 'Jan Aushadhi Kendra, Near Bus Station, Shamshabad',
    ),
    JanAushadhiComparison(
      brandedName: 'Asthalin Inhaler 100mcg',
      janAushadhiName: 'Salbutamol Inhaler 200 Doses (PMBJP)',
      moleculeComposition: 'Salbutamol Sulphate IP 100mcg/puff',
      brandedPrice: 185.0,
      janAushadhiPrice: 65.0,
      savingsPercent: 64.8,
      manufacturer: 'PMBJP Respiratory Life-Savings',
      inStockAtJanAushadhiKendra: true,
      nearbyKendraAddress: 'Trauma Mile Jan Aushadhi Chemist, NH-44 Corridor',
    ),
    JanAushadhiComparison(
      brandedName: 'Lantus SoloStar Insulin',
      janAushadhiName: 'Insulin Glargine 100 IU/ml (Cold-Chain PMBJP)',
      moleculeComposition: 'Insulin Glargine rDNA Origin',
      brandedPrice: 720.0,
      janAushadhiPrice: 260.0,
      savingsPercent: 63.8,
      manufacturer: 'Cold-Chain Certified Insulin Depot',
      inStockAtJanAushadhiKendra: true,
      nearbyKendraAddress: 'District Area Hospital Chemist Desk, Hyderabad',
    ),
  ];

  /// Reserve emergency medicine for 30 minutes
  EmergencyStockHoldToken createEmergencyHold({
    required String medicineName,
    required String genericComposition,
    required String pharmacyName,
    required String pharmacyPhone,
    required String pharmacyAddress,
    required double price,
    bool isColdChain = false,
  }) {
    final now = DateTime.now();
    final token = EmergencyStockHoldToken(
      holdId: 'HOLD-${now.millisecondsSinceEpoch.toString().substring(7)}',
      medicineName: medicineName,
      genericComposition: genericComposition,
      pharmacyName: pharmacyName,
      pharmacyPhone: pharmacyPhone,
      pharmacyAddress: pharmacyAddress,
      reservedAt: now,
      expiresAt: now.add(const Duration(minutes: 30)),
      batchNumber: 'BT-2026-${(now.millisecond % 900 + 100)}',
      expiryDate: '12/2027',
      isColdChainCompliant: isColdChain,
      reservedPrice: price,
    );

    _activeHold = token;
    notifyListeners();
    return token;
  }

  /// Cancel or release reservation hold
  void cancelHold() {
    _activeHold = null;
    notifyListeners();
  }
}
