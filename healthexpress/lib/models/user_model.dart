class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profilePhoto;
  final String aarogyasriId; // e.g. AROG12345678 / RGIS ID
  final int age;
  final String gender;
  final String address;
  final double? latitude;
  final double? longitude;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;
  final String bloodGroup;
  final String allergies;
  final String chronicConditions;
  final String pastSurgeries;
  final double heightCm;
  final double weightKg;
  final double temperatureF;
  final int heartRateBpm;
  final int oxygenSpo2;
  final DateTime joinedDate;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePhoto,
    required this.aarogyasriId,
    this.age = 0,
    this.gender = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelation = '',
    this.bloodGroup = 'Not Specified',
    this.allergies = 'None',
    this.chronicConditions = 'None',
    this.pastSurgeries = 'None',
    this.heightCm = 0.0,
    this.weightKg = 0.0,
    this.temperatureF = 98.6,
    this.heartRateBpm = 72,
    this.oxygenSpo2 = 99,
    required this.joinedDate,
  });

  factory UserModel.empty() {
    return UserModel(
      id: '',
      name: '',
      email: '',
      phone: '',
      aarogyasriId: '',
      age: 0,
      gender: '',
      address: '',
      bloodGroup: 'Not Specified',
      allergies: 'None',
      chronicConditions: 'None',
      pastSurgeries: 'None',
      joinedDate: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty && name.isEmpty && phone.isEmpty;
  bool get isNotEmpty => !isEmpty;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profilePhoto,
    String? aarogyasriId,
    int? age,
    String? gender,
    String? address,
    double? latitude,
    double? longitude,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? bloodGroup,
    String? allergies,
    String? chronicConditions,
    String? pastSurgeries,
    double? heightCm,
    double? weightKg,
    double? temperatureF,
    int? heartRateBpm,
    int? oxygenSpo2,
    DateTime? joinedDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      aarogyasriId: aarogyasriId ?? this.aarogyasriId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      pastSurgeries: pastSurgeries ?? this.pastSurgeries,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      temperatureF: temperatureF ?? this.temperatureF,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      oxygenSpo2: oxygenSpo2 ?? this.oxygenSpo2,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  String toAarogyasriQrPayload() {
    return 'HEALTHEXPRESS:AAROGYASRI:$aarogyasriId|$name|$age|$gender|$bloodGroup|$allergies|$emergencyContactPhone|$phone|$address|$emergencyContactName|$emergencyContactRelation|$chronicConditions|$temperatureF|$heartRateBpm|$oxygenSpo2|$weightKg|$heightCm|$email';
  }

  static UserModel fromAarogyasriQrPayload(String payload) {
    if (payload.trim().isEmpty) return UserModel.empty();

    String clean = payload.trim();
    if (clean.startsWith('HEALTHEXPRESS:AAROGYASRI:')) {
      clean = clean.substring('HEALTHEXPRESS:AAROGYASRI:'.length);
    } else if (clean.startsWith('AAROGYASRI:')) {
      clean = clean.substring('AAROGYASRI:'.length);
    }

    // Handle Pipe delimiter
    if (clean.contains('|')) {
      final parts = clean.split('|');
      final aid = parts.isNotEmpty ? parts[0].trim() : '';
      final name = parts.length > 1 ? parts[1].trim() : 'Verified Citizen';
      final age = parts.length > 2 ? (int.tryParse(parts[2].trim()) ?? 0) : 0;
      final gender = parts.length > 3 ? parts[3].trim() : '';
      final blood = parts.length > 4 ? parts[4].trim() : 'Not Specified';
      final allergies = parts.length > 5 ? parts[5].trim() : 'None';
      final emPhone = parts.length > 6 ? parts[6].trim() : '';
      final phone = parts.length > 7 ? parts[7].trim() : '';
      final address = parts.length > 8 ? parts[8].trim() : '';
      final emName = parts.length > 9 ? parts[9].trim() : '';
      final emRel = parts.length > 10 ? parts[10].trim() : '';
      final chronic = parts.length > 11 ? parts[11].trim() : 'None';
      final temp = parts.length > 12 ? (double.tryParse(parts[12].trim()) ?? 98.6) : 98.6;
      final hr = parts.length > 13 ? (int.tryParse(parts[13].trim()) ?? 72) : 72;
      final spo2 = parts.length > 14 ? (int.tryParse(parts[14].trim()) ?? 99) : 99;
      final weight = parts.length > 15 ? (double.tryParse(parts[15].trim()) ?? 0.0) : 0.0;
      final height = parts.length > 16 ? (double.tryParse(parts[16].trim()) ?? 0.0) : 0.0;
      final email = parts.length > 17 ? parts[17].trim() : '';

      return UserModel(
        id: 'USR-${aid.replaceAll('-', '')}',
        name: name,
        email: email,
        phone: phone,
        aarogyasriId: aid,
        age: age,
        gender: gender,
        address: address,
        bloodGroup: blood,
        allergies: allergies,
        chronicConditions: chronic,
        emergencyContactName: emName,
        emergencyContactPhone: emPhone,
        emergencyContactRelation: emRel,
        temperatureF: temp,
        heartRateBpm: hr,
        oxygenSpo2: spo2,
        weightKg: weight,
        heightCm: height,
        joinedDate: DateTime.now(),
      );
    }

    // Handle Colon delimiter
    if (clean.contains(':')) {
      final parts = clean.split(':');
      final aid = parts.isNotEmpty ? parts[0].trim() : '';
      final name = parts.length > 1 ? parts[1].trim() : 'Verified Citizen';
      final age = parts.length > 2 ? (int.tryParse(parts[2].trim()) ?? 0) : 0;
      final gender = parts.length > 3 ? parts[3].trim() : '';
      final blood = parts.length > 4 ? parts[4].trim() : 'Not Specified';
      final allergies = parts.length > 5 ? parts[5].trim() : 'None';
      final emPhone = parts.length > 6 ? parts[6].trim() : '';

      return UserModel(
        id: 'USR-${aid.replaceAll('-', '')}',
        name: name,
        email: '',
        phone: '',
        aarogyasriId: aid,
        age: age,
        gender: gender,
        bloodGroup: blood,
        allergies: allergies,
        emergencyContactPhone: emPhone,
        joinedDate: DateTime.now(),
      );
    }

    // Plain ID fallback
    return UserModel.empty().copyWith(
      id: 'USR-${clean.replaceAll('-', '')}',
      aarogyasriId: clean,
      name: 'Aarogyasri Beneficiary',
    );
  }
}
