class MedicalStoreModel {
  final String id;
  final String name;
  final String address;
  final String area;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final int etaMinutes;
  final bool is24x7;
  final bool isOpen;
  final String phone;
  final String? email;
  final String licenseNumber;
  final String imageUrl;
  final String openingTime;
  final String closingTime;
  final String verificationStatus; // 'pending' | 'verified' | 'rejected'
  final String? ownerUserId;
  final String? rejectionReason;
  final List<String> availableMedicineIds;

  const MedicalStoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    this.rating = 4.7,
    this.reviewCount = 320,
    required this.distanceKm,
    required this.etaMinutes,
    this.is24x7 = true,
    this.isOpen = true,
    required this.phone,
    this.email,
    required this.licenseNumber,
    required this.imageUrl,
    this.openingTime = '08:00 AM',
    this.closingTime = '10:00 PM',
    this.verificationStatus = 'verified',
    this.ownerUserId,
    this.rejectionReason,
    this.availableMedicineIds = const [],
  });

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  factory MedicalStoreModel.fromJson(Map<String, dynamic> json) {
    return MedicalStoreModel(
      id: json['id'] as String? ?? 'STORE-01',
      name: json['name'] as String? ?? 'Apollo Pharmacy',
      address: json['address'] as String? ?? '',
      area: json['area'] as String? ?? 'Hitech City',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.7,
      reviewCount: json['review_count'] as int? ?? 120,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 1.2,
      etaMinutes: json['eta_minutes'] as int? ?? 15,
      is24x7: json['is_24x7'] == 1 || json['is_24x7'] == true,
      isOpen: json['is_open'] == 1 || json['is_open'] == true,
      phone: json['phone'] as String? ?? '+91 9848012345',
      email: json['email'] as String?,
      licenseNumber: json['license_number'] as String? ?? json['license'] as String? ?? 'TS/MED/2024/9912',
      imageUrl: json['image_url'] as String? ?? 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400',
      openingTime: json['opening_time'] as String? ?? '08:00 AM',
      closingTime: json['closing_time'] as String? ?? '10:00 PM',
      verificationStatus: (json['verification_status'] as String? ?? 'verified').toLowerCase(),
      ownerUserId: json['user_id'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      availableMedicineIds: (json['available_medicine_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'area': area,
      'rating': rating,
      'review_count': reviewCount,
      'distance_km': distanceKm,
      'eta_minutes': etaMinutes,
      'is_24x7': is24x7,
      'is_open': isOpen,
      'phone': phone,
      'email': email,
      'license_number': licenseNumber,
      'image_url': imageUrl,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'verification_status': verificationStatus,
      'user_id': ownerUserId,
      'rejection_reason': rejectionReason,
      'available_medicine_ids': availableMedicineIds,
    };
  }

  MedicalStoreModel copyWith({
    String? id,
    String? name,
    String? address,
    String? area,
    double? rating,
    int? reviewCount,
    double? distanceKm,
    int? etaMinutes,
    bool? is24x7,
    bool? isOpen,
    String? phone,
    String? email,
    String? licenseNumber,
    String? imageUrl,
    String? openingTime,
    String? closingTime,
    String? verificationStatus,
    String? ownerUserId,
    String? rejectionReason,
    List<String>? availableMedicineIds,
  }) {
    return MedicalStoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      area: area ?? this.area,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      is24x7: is24x7 ?? this.is24x7,
      isOpen: isOpen ?? this.isOpen,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      availableMedicineIds: availableMedicineIds ?? this.availableMedicineIds,
    );
  }
}
