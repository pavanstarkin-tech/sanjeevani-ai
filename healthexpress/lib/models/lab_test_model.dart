class LabTestModel {
  final String id;
  final String name;
  final String code; // e.g. CBC, NS1, MAL
  final double price;
  final double originalPrice;
  final String sampleType; // Blood, Urine, Swab
  final String reportDeliveryTime; // 24 hrs, 6 hrs
  final String description;
  final String whyRelevant;
  final bool fastingRequired;
  final List<String> certifiedLabs;

  LabTestModel({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.originalPrice,
    required this.sampleType,
    this.reportDeliveryTime = '24 hrs',
    required this.description,
    required this.whyRelevant,
    this.fastingRequired = false,
    this.certifiedLabs = const ['Redcliffe Labs', 'Thyrocare', 'Metropolis', 'Apollo Diagnostics'],
  });
}
