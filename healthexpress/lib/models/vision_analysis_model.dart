enum VisionScope { food, medicine, infection, general }

class NutrientBreakdown {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;

  NutrientBreakdown({
    this.proteinG = 0.0,
    this.carbsG = 0.0,
    this.fatG = 0.0,
    this.fiberG = 0.0,
    this.sugarG = 0.0,
    this.sodiumMg = 0.0,
  });

  factory NutrientBreakdown.fromJson(Map<String, dynamic> json) {
    return NutrientBreakdown(
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0.0,
      sugarG: (json['sugar_g'] as num?)?.toDouble() ?? 0.0,
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'fiber_g': fiberG,
        'sugar_g': sugarG,
        'sodium_mg': sodiumMg,
      };
}

class RelatedDish {
  final String name;
  final int calories;
  final String whyRecommended;

  RelatedDish({
    required this.name,
    required this.calories,
    required this.whyRecommended,
  });

  factory RelatedDish.fromJson(Map<String, dynamic> json) {
    return RelatedDish(
      name: json['name']?.toString() ?? 'Healthy Alternative',
      calories: (json['calories'] as num?)?.toInt() ?? 200,
      whyRecommended: json['why']?.toString() ??
          json['whyRecommended']?.toString() ??
          'Healthier substitute',
    );
  }
}

class RecommendedInfectionMedication {
  final String name;
  final String category;
  final String dosage;
  final bool requiresPrescription;

  RecommendedInfectionMedication({
    required this.name,
    required this.category,
    required this.dosage,
    this.requiresPrescription = false,
  });

  factory RecommendedInfectionMedication.fromJson(Map<String, dynamic> json) {
    return RecommendedInfectionMedication(
      name: json['name']?.toString() ?? 'Topical / Oral Medication',
      category: json['category']?.toString() ?? json['type']?.toString() ?? 'Pharmaceutical',
      dosage: json['dosage']?.toString() ?? 'As directed by physician',
      requiresPrescription: json['prescription'] == true || json['requires_prescription'] == true,
    );
  }
}

class VisionAnalysisResult {
  final VisionScope scope;
  final String name;
  final String description;
  final String? imageBase64;

  // 1. Food specific fields
  final int calories;
  final String portionSize;
  final NutrientBreakdown nutrients;
  final String glycemicIndex;
  final int healthScore; // 1-10
  final String healthVerdict;
  final List<String> dietaryTags;
  final List<String> healthBenefits;
  final List<String> foodPrecautions;
  final List<RelatedDish> relatedDishes;

  // 2. Medicine / Tablet specific fields
  final String composition;
  final String drugClass;
  final List<String> medicalUses;
  final String dosageGuidelines;
  final String howToTake;
  final List<String> criticalWarnings;
  final List<String> sideEffects;
  final bool prescriptionRequired;
  final String drugSchedule;
  final double estimatedPrice;

  // 3. Disease & Infection specific fields
  final String infectionSeverity; // Mild / Moderate / Urgent
  final String infectionCategory; // Dermatology, Eye, Throat, Wound, etc.
  final List<String> probableCauses;
  final List<String> symptomsObserved;
  final String recommendedSpecialist; // e.g. Dermatologist, General Physician
  final List<RecommendedInfectionMedication> infectionMedications;
  final List<String> recommendedLabTests;
  final List<String> homeCareTips;
  final List<String> redFlagAlerts;

  VisionAnalysisResult({
    required this.scope,
    required this.name,
    required this.description,
    this.imageBase64,
    // Food defaults
    this.calories = 0,
    this.portionSize = '1 standard serving',
    NutrientBreakdown? nutrients,
    this.glycemicIndex = 'Medium',
    this.healthScore = 7,
    this.healthVerdict = '',
    this.dietaryTags = const [],
    this.healthBenefits = const [],
    this.foodPrecautions = const [],
    this.relatedDishes = const [],
    // Medicine defaults
    this.composition = '',
    this.drugClass = '',
    this.medicalUses = const [],
    this.dosageGuidelines = '',
    this.howToTake = '',
    this.criticalWarnings = const [],
    this.sideEffects = const [],
    this.prescriptionRequired = false,
    this.drugSchedule = 'OTC',
    this.estimatedPrice = 0.0,
    // Infection defaults
    this.infectionSeverity = 'Moderate',
    this.infectionCategory = 'Clinical Infection / Dermatology',
    this.probableCauses = const [],
    this.symptomsObserved = const [],
    this.recommendedSpecialist = 'Dermatologist / General Physician',
    this.infectionMedications = const [],
    this.recommendedLabTests = const [],
    this.homeCareTips = const [],
    this.redFlagAlerts = const [],
  }) : nutrients = nutrients ?? NutrientBreakdown();

  bool get isFood => scope == VisionScope.food;
  bool get isMedicine => scope == VisionScope.medicine;
  bool get isInfection => scope == VisionScope.infection;
  bool get isGeneral => scope == VisionScope.general;
  bool get isFace =>
      scope == VisionScope.general ||
      name.toLowerCase().contains('face') ||
      name.toLowerCase().contains('complexion') ||
      name.toLowerCase().contains('patient') ||
      name.toLowerCase().contains('inspection') ||
      name.toLowerCase().contains('examination');

  factory VisionAnalysisResult.fromJson(Map<String, dynamic> json, {String? imageB64}) {
    final rawScope = json['scope']?.toString().toLowerCase().trim() ?? 'food';
    VisionScope scope = VisionScope.food;
    if (rawScope.contains('face') ||
        rawScope.contains('person') ||
        rawScope.contains('patient') ||
        rawScope.contains('general') ||
        rawScope.contains('exam') ||
        rawScope.contains('inspection') ||
        rawScope.contains('demeanor') ||
        rawScope.contains('complexion')) {
      scope = VisionScope.general;
    } else if (rawScope.contains('infect') ||
        rawScope.contains('disease') ||
        rawScope.contains('rash') ||
        rawScope.contains('skin') ||
        rawScope.contains('wound') ||
        rawScope.contains('symptom')) {
      scope = VisionScope.infection;
    } else if (rawScope.contains('med') ||
        rawScope.contains('tablet') ||
        rawScope.contains('pill') ||
        rawScope.contains('drug') ||
        rawScope.contains('pharma') ||
        rawScope.contains('rx')) {
      scope = VisionScope.medicine;
    } else if (rawScope.contains('food') ||
        rawScope.contains('meal') ||
        rawScope.contains('diet') ||
        rawScope.contains('dish')) {
      scope = VisionScope.food;
    } else {
      // If unrecognized, check title keywords
      final rawName = (json['name'] ?? '').toString().toLowerCase();
      if (rawName.contains('face') || rawName.contains('patient') || rawName.contains('complexion')) {
        scope = VisionScope.general;
      }
    }

    // Parse nutrients
    NutrientBreakdown nut = NutrientBreakdown();
    if (json['nutrients'] is Map<String, dynamic>) {
      nut = NutrientBreakdown.fromJson(json['nutrients']);
    }

    // Parse related dishes
    List<RelatedDish> dishes = [];
    if (json['related_dishes'] is List) {
      for (final d in json['related_dishes']) {
        if (d is Map<String, dynamic>) {
          dishes.add(RelatedDish.fromJson(d));
        }
      }
    }

    // Parse infection medications
    List<RecommendedInfectionMedication> infMeds = [];
    if (json['infection_medications'] is List) {
      for (final m in json['infection_medications']) {
        if (m is Map<String, dynamic>) {
          infMeds.add(RecommendedInfectionMedication.fromJson(m));
        }
      }
    } else if (json['medications'] is List) {
      for (final m in json['medications']) {
        if (m is Map<String, dynamic>) {
          infMeds.add(RecommendedInfectionMedication.fromJson(m));
        }
      }
    }

    List<String> listFrom(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (val is String && val.trim().isNotEmpty) {
        return val.split(',').map((e) => e.trim()).toList();
      }
      return [];
    }

    return VisionAnalysisResult(
      scope: scope,
      name: json['name']?.toString() ??
          (scope == VisionScope.infection
              ? 'Analyzed Infection / Condition'
              : (scope == VisionScope.medicine ? 'Identified Medicine' : 'Identified Dish')),
      description: json['description']?.toString() ?? json['summary']?.toString() ?? '',
      imageBase64: imageB64,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      portionSize: json['portion_size']?.toString() ?? '1 standard serving',
      nutrients: nut,
      glycemicIndex: json['glycemic_index']?.toString() ?? 'Medium',
      healthScore: (json['health_score'] as num?)?.toInt() ?? 8,
      healthVerdict: json['health_verdict']?.toString() ?? json['verdict']?.toString() ?? '',
      dietaryTags: listFrom(json['dietary_tags']),
      healthBenefits: listFrom(json['health_benefits'] ?? json['benefits']),
      foodPrecautions: listFrom(json['food_precautions'] ?? json['precautions']),
      relatedDishes: dishes,
      composition: json['composition']?.toString() ?? json['active_ingredient']?.toString() ?? '',
      drugClass: json['drug_class']?.toString() ?? json['category']?.toString() ?? '',
      medicalUses: listFrom(json['medical_uses'] ?? json['uses'] ?? json['indications']),
      dosageGuidelines: json['dosage_guidelines']?.toString() ?? json['dosage']?.toString() ?? '',
      howToTake: json['how_to_take']?.toString() ?? json['instructions']?.toString() ?? '',
      criticalWarnings: listFrom(json['critical_warnings'] ?? json['warnings']),
      sideEffects: listFrom(json['side_effects']),
      prescriptionRequired: json['prescription_required'] == true || json['is_prescription'] == true,
      drugSchedule: json['drug_schedule']?.toString() ?? 'OTC',
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 35.0,
      // Infection parsing
      infectionSeverity: json['infection_severity']?.toString() ?? json['severity']?.toString() ?? 'Moderate',
      infectionCategory: json['infection_category']?.toString() ?? json['category']?.toString() ?? 'Dermatology / Skin Infection',
      probableCauses: listFrom(json['probable_causes'] ?? json['causes']),
      symptomsObserved: listFrom(json['symptoms_observed'] ?? json['symptoms']),
      recommendedSpecialist: json['recommended_specialist']?.toString() ?? json['doctor_specialist']?.toString() ?? 'Dermatologist',
      infectionMedications: infMeds,
      recommendedLabTests: listFrom(json['recommended_lab_tests'] ?? json['lab_tests']),
      homeCareTips: listFrom(json['home_care_tips'] ?? json['care_tips']),
      redFlagAlerts: listFrom(json['red_flag_alerts'] ?? json['urgent_warnings']),
    );
  }
}
