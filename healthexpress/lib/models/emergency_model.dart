class AmbulanceService {
  final String id;
  final String providerName; // Apollo 24|7, Medicover, GVK EMRI (108)
  final String vehicleType; // Advanced Life Support (ALS), Basic (BLS)
  final String etaMinutes;
  final double rating;
  final String phone;
  final double distanceKm;
  final double estimatedFare;

  AmbulanceService({
    required this.id,
    required this.providerName,
    required this.vehicleType,
    required this.etaMinutes,
    required this.rating,
    required this.phone,
    required this.distanceKm,
    required this.estimatedFare,
  });
}
