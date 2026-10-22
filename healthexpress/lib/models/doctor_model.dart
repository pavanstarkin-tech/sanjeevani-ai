import '../core/constants/app_constants.dart';

enum PracticeType { independent, hospital, multiple }

class DoctorAffiliation {
  final String hospitalId;
  final String hospitalName;
  final String department;
  final String role;
  final bool isPrimary;

  DoctorAffiliation({
    required this.hospitalId,
    required this.hospitalName,
    required this.department,
    this.role = 'Consultant',
    this.isPrimary = true,
  });
}

class DoctorModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String specialty;
  final String subSpecialty;
  final String qualifications; // e.g. MBBS, MD, DM
  final int experienceYears;
  final String registrationNumber; // MCI / State Council
  final PracticeType practiceType;
  final List<DoctorAffiliation> affiliations;
  final double rating;
  final int reviewCount;
  final String hospitalId;
  final String hospitalName;
  final String location;
  final double distanceKm;
  final double clinicFee;
  final double videoFee;
  final double homeVisitFee;
  final double audioFee;
  final double followUpFee;
  final List<ConsultationType> supportedTypes;
  final String bio;
  final bool isVerified;
  final bool isOnline;
  final bool isRmpDoctor;
  final List<String> availableDays;
  final List<String> availableTimeSlots;

  DoctorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.specialty,
    this.subSpecialty = 'Internal Medicine',
    required this.qualifications,
    required this.experienceYears,
    this.registrationNumber = 'MCI-TS-2012-88421',
    this.practiceType = PracticeType.hospital,
    this.affiliations = const [],
    required this.rating,
    required this.reviewCount,
    required this.hospitalId,
    required this.hospitalName,
    required this.location,
    required this.distanceKm,
    required this.clinicFee,
    required this.videoFee,
    required this.homeVisitFee,
    this.audioFee = 600.0,
    this.followUpFee = 400.0,
    required this.supportedTypes,
    required this.bio,
    this.isVerified = true,
    this.isOnline = true,
    this.isRmpDoctor = false,
    this.availableDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    this.availableTimeSlots = const [
      '09:00 AM',
      '10:30 AM',
      '12:00 PM',
      '02:00 PM',
      '04:30 PM',
      '06:00 PM',
      '07:30 PM'
    ],
  });

  DoctorModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? specialty,
    String? subSpecialty,
    String? qualifications,
    int? experienceYears,
    String? registrationNumber,
    PracticeType? practiceType,
    List<DoctorAffiliation>? affiliations,
    double? rating,
    int? reviewCount,
    String? hospitalId,
    String? hospitalName,
    String? location,
    double? distanceKm,
    double? clinicFee,
    double? videoFee,
    double? homeVisitFee,
    double? audioFee,
    double? followUpFee,
    List<ConsultationType>? supportedTypes,
    String? bio,
    bool? isVerified,
    bool? isOnline,
    bool? isRmpDoctor,
    List<String>? availableDays,
    List<String>? availableTimeSlots,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      specialty: specialty ?? this.specialty,
      subSpecialty: subSpecialty ?? this.subSpecialty,
      qualifications: qualifications ?? this.qualifications,
      experienceYears: experienceYears ?? this.experienceYears,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      practiceType: practiceType ?? this.practiceType,
      affiliations: affiliations ?? this.affiliations,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      location: location ?? this.location,
      distanceKm: distanceKm ?? this.distanceKm,
      clinicFee: clinicFee ?? this.clinicFee,
      videoFee: videoFee ?? this.videoFee,
      homeVisitFee: homeVisitFee ?? this.homeVisitFee,
      audioFee: audioFee ?? this.audioFee,
      followUpFee: followUpFee ?? this.followUpFee,
      supportedTypes: supportedTypes ?? this.supportedTypes,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      isRmpDoctor: isRmpDoctor ?? this.isRmpDoctor,
      availableDays: availableDays ?? this.availableDays,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
    );
  }
}
