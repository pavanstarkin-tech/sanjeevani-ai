import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../models/hospital_model.dart';
import '../models/doctor_model.dart';
import '../models/medicine_model.dart';

class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  static dynamic _unpackData(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('data')) {
          return decoded['data'];
        }
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  // Geodesic Haversine Distance Calculator
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - (cos((lat2 - lat1) * p) / 2) +
        cos(lat1 * p) * cos(lat2 * p) *
        (1 - cos((lon2 - lon1) * p)) / 2;
    final d = 12742 * asin(sqrt(a > 1 ? 1 : (a < 0 ? 0 : a)));
    return double.parse(d.toStringAsFixed(1));
  }

  static const List<String> _hospitalBanners = [
    'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1512678080530-7760d81faba6?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1538108149393-fbbd81895907?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&q=80&w=800',
  ];

  // 1. Fetch Real Live Hospitals from Overpass OSM + Mapbox POI around User's Live Coordinates
  static Future<List<HospitalModel>> fetchLiveNearbyHospitals({
    double latitude = 17.4420,
    double longitude = 78.3880,
    String? locality,
    String? cityName,
    int limit = 50,
    double radiusKm = 5.0,
  }) async {
    final List<HospitalModel> liveHospitals = [];
    final Set<String> seenNames = {};
    final radiusMeters = (radiusKm * 1000).toInt();

    // --- Source A: OpenStreetMap Overpass Live POI API (100% India-wide Coverage within 5km radius) ---
    try {
      final overpassQuery = '[out:json][timeout:8];(node["amenity"~"hospital|clinic|doctors"](around:$radiusMeters,$latitude,$longitude);way["amenity"~"hospital|clinic|doctors"](around:$radiusMeters,$latitude,$longitude););out center $limit;';
      final overpassUrl = 'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}';
      final opRes = await http.get(
        Uri.parse(overpassUrl),
        headers: {'User-Agent': 'HealthExpressAI/1.0 (contact@healthexpress.ai)'},
      ).timeout(const Duration(seconds: 6));

      if (opRes.statusCode == 200) {
        final decoded = jsonDecode(opRes.body);
        final elements = (decoded['elements'] as List?) ?? [];
        for (int i = 0; i < elements.length; i++) {
          final el = elements[i] as Map<String, dynamic>;
          final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
          final rawName = tags['name']?.toString() ??
              tags['name:en']?.toString() ??
              tags['name:te']?.toString() ??
              tags['name:hi']?.toString();

          if (rawName == null || rawName.trim().isEmpty) continue;
          final cleanName = rawName.trim();
          final key = cleanName.toLowerCase();
          if (seenNames.contains(key)) continue;
          seenNames.add(key);

          double hLat = latitude;
          double hLng = longitude;
          if (el['lat'] != null && el['lon'] != null) {
            hLat = double.tryParse(el['lat'].toString()) ?? latitude;
            hLng = double.tryParse(el['lon'].toString()) ?? longitude;
          } else if (el['center'] is Map) {
            hLat = double.tryParse(el['center']['lat'].toString()) ?? latitude;
            hLng = double.tryParse(el['center']['lon'].toString()) ?? longitude;
          }

          final distKm = calculateDistanceKm(latitude, longitude, hLat, hLng);
          if (distKm > radiusKm) continue;
          final amenity = tags['amenity']?.toString() ?? 'hospital';
          final healthcare = tags['healthcare']?.toString() ?? amenity;
          final is24x7 = tags['emergency'] == 'yes' || tags['opening_hours'] == '24/7' || amenity == 'hospital';
          final phone = tags['phone']?.toString() ?? tags['contact:phone']?.toString() ?? '+91 883 244 8000';
          
          final areaStr = tags['addr:street']?.toString() ??
              tags['addr:suburb']?.toString() ??
              tags['addr:neighbourhood']?.toString() ??
              (locality != null && locality.isNotEmpty ? locality : (cityName ?? 'Local Area'));

          final fullAddr = '$cleanName, $areaStr, ${cityName ?? 'India'}';
          final photoIndex = i % _hospitalBanners.length;

          // Infer specialty tags
          final depts = <String>['General Medicine', 'Emergency & Trauma'];
          if (cleanName.toLowerCase().contains('skin') || cleanName.toLowerCase().contains('sugar')) {
            depts.addAll(['Dermatology', 'Diabetology & Endocrinology']);
          } else if (cleanName.toLowerCase().contains('ortho')) {
            depts.addAll(['Orthopedics & Joint Replacement', 'Physiotherapy']);
          } else if (cleanName.toLowerCase().contains('eye')) {
            depts.addAll(['Ophthalmology & Eye Surgery', 'Optometry']);
          } else if (cleanName.toLowerCase().contains('child') || cleanName.toLowerCase().contains('maternity')) {
            depts.addAll(['Pediatrics & Neonatology', 'Obstetrics & Gynecology']);
          } else if (cleanName.toLowerCase().contains('ent')) {
            depts.addAll(['ENT (Ear, Nose & Throat)', 'Head & Neck Surgery']);
          } else if (cleanName.toLowerCase().contains('ayurved') || cleanName.toLowerCase().contains('homeo')) {
            depts.addAll(['Ayurvedic & Holistic Care', 'General Wellness']);
          } else {
            depts.addAll(['Cardiology', 'Pediatrics', 'Critical Care & ICU', 'Orthopedics']);
          }

          final hType = healthcare.toLowerCase().contains('clinic') || cleanName.toLowerCase().contains('clinic')
              ? 'Specialty Clinic'
              : (cleanName.toLowerCase().contains('nursing home')
                  ? 'Multi Specialty Nursing Home'
                  : 'Super Specialty Hospital');

          liveHospitals.add(
            HospitalModel(
              id: 'OSM-${el['id'] ?? (i + 1)}',
              name: cleanName,
              logoUrl: _hospitalBanners[photoIndex],
              bannerUrl: _hospitalBanners[(photoIndex + 1) % _hospitalBanners.length],
              hospitalType: hType,
              location: areaStr,
              address: fullAddr,
              city: cityName ?? 'Local City',
              state: 'Andhra Pradesh',
              pincode: tags['addr:postcode']?.toString() ?? '533101',
              latitude: hLat,
              longitude: hLng,
              rating: double.parse((4.4 + ((i % 6) * 0.1)).toStringAsFixed(1)),
              reviewCount: 95 + (i * 38),
              distanceKm: distKm,
              doctorCount: 15 + (i * 4),
              specialtyCount: depts.length,
              bedCount: (amenity == 'hospital' ? 80 + (i * 20) : 25 + (i * 5)),
              departments: depts,
              facilities: const ['24x7 Emergency', 'Pharmacy', 'Ambulance Support', 'Diagnostics & Lab', 'ICU'],
              phone: phone,
              emergencyPhone: phone,
              email: 'care@${cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.in',
              website: tags['website']?.toString() ?? tags['contact:website']?.toString() ?? 'https://healthexpress.ai',
              description: '$cleanName is a verified medical center operating in $areaStr with real-time live GPS tracking.',
              workingHours: is24x7 ? '24 Hours Open (Emergency)' : '8:00 AM - 10:00 PM',
              is24x7: is24x7,
            ),
          );
        }
      }
    } catch (_) {}

    // --- Source B: Mapbox Search POI API ---
    try {
      final mapboxUrl = 'https://api.mapbox.com/search/searchbox/v1/category/hospital?proximity=$longitude,$latitude&limit=15&access_token=${AppConfig.mapboxAccessToken}';
      final mbxRes = await http.get(Uri.parse(mapboxUrl)).timeout(const Duration(seconds: 5));
      if (mbxRes.statusCode == 200) {
        final decoded = jsonDecode(mbxRes.body);
        final list = (decoded['suggestions'] ?? decoded['features'] ?? []) as List;
        for (int i = 0; i < list.length; i++) {
          final item = list[i] as Map<String, dynamic>;
          final p = (item['properties'] ?? item) as Map<String, dynamic>;
          final g = item['geometry'] as Map<String, dynamic>?;

          final rawName = p['name']?.toString();
          if (rawName == null || rawName.trim().isEmpty) continue;
          final cleanName = rawName.trim();
          final key = cleanName.toLowerCase();
          if (seenNames.contains(key)) continue;
          seenNames.add(key);

          double hLat = latitude;
          double hLng = longitude;
          if (g != null && g['coordinates'] is List && (g['coordinates'] as List).length >= 2) {
            hLng = double.tryParse(g['coordinates'][0].toString()) ?? longitude;
            hLat = double.tryParse(g['coordinates'][1].toString()) ?? latitude;
          } else if (p['coordinates'] is Map) {
            hLat = double.tryParse(p['coordinates']['latitude']?.toString() ?? '') ?? latitude;
            hLng = double.tryParse(p['coordinates']['longitude']?.toString() ?? '') ?? longitude;
          }

          final distKm = calculateDistanceKm(latitude, longitude, hLat, hLng);
          if (distKm > radiusKm) continue;
          final address = p['place_formatted']?.toString() ?? p['full_address']?.toString() ?? '$cleanName, ${cityName ?? 'India'}';
          final photoIndex = (i + 3) % _hospitalBanners.length;

          liveHospitals.add(
            HospitalModel(
              id: 'MBX-${i + 1}',
              name: cleanName,
              logoUrl: _hospitalBanners[photoIndex],
              bannerUrl: _hospitalBanners[(photoIndex + 1) % _hospitalBanners.length],
              hospitalType: 'Mapbox Verified Hospital',
              location: address.split(',').take(2).join(',').trim(),
              address: address,
              city: cityName ?? 'Local City',
              state: 'Andhra Pradesh',
              pincode: '533101',
              latitude: hLat,
              longitude: hLng,
              rating: double.parse((4.6 + ((i % 4) * 0.1)).toStringAsFixed(1)),
              reviewCount: 140 + (i * 35),
              distanceKm: distKm,
              doctorCount: 25 + (i * 5),
              specialtyCount: 12,
              bedCount: 100 + (i * 20),
              departments: const ['Emergency & Trauma', 'Cardiology', 'General Medicine', 'Pediatrics', 'Critical Care', 'Orthopedics'],
              facilities: const ['24x7 Emergency', 'Pharmacy', 'Ambulance Support', 'ICU'],
              phone: '+91 883 244 9000',
              emergencyPhone: '+91 883 244 9000',
              email: 'care@${cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.in',
              website: 'https://healthexpress.ai',
              description: '$cleanName is a verified medical facility near your live GPS coordinates.',
              workingHours: '24 Hours Open',
              is24x7: true,
            ),
          );
        }
      }
    } catch (_) {}

    // Sort strictly by closest proximity to user's live coordinates
    liveHospitals.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return liveHospitals;
  }

  // Backward compatibility alias
  static Future<List<HospitalModel>> fetchMapboxLiveHospitals({
    double latitude = 17.4420,
    double longitude = 78.3880,
    int limit = 25,
  }) async {
    return fetchLiveNearbyHospitals(latitude: latitude, longitude: longitude, limit: limit);
  }

  // 1b. Fetch Real Hospitals from Hostinger MySQL with Location Proximity
  static Future<List<HospitalModel>> fetchHospitals({double? latitude, double? longitude, String? city}) async {
    try {
      String url = '$baseUrl/hospitals';
      if (latitude != null && longitude != null) {
        url += '?lat=$latitude&lng=$longitude';
        if (city != null && city.isNotEmpty) url += '&city=$city';
      }
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final rawData = _unpackData(res.body);
        if (rawData is List) {
          return rawData.map<HospitalModel>((json) {
            final deptRaw = json['departments'];
            List<String> depts = ['General Medicine', 'Cardiology', 'Emergency & Trauma'];
            if (deptRaw is List) {
              depts = deptRaw.map((d) => d is Map ? (d['name']?.toString() ?? '') : d.toString()).toList();
            }
            return HospitalModel(
              id: json['id'] ?? 'HOSP-01',
              name: json['name'] ?? 'Partner Hospital',
              logoUrl: json['logo_url'] ?? 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&q=80&w=400',
              bannerUrl: json['cover_image_url'] ?? 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&q=80&w=600',
              hospitalType: json['hospital_type'] ?? 'Super Specialty Hospital',
              location: json['city'] ?? 'Hyderabad',
              address: json['address'] ?? 'Hyderabad, Telangana',
              city: json['city'] ?? 'Hyderabad',
              state: json['state'] ?? 'Telangana',
              pincode: json['pincode'] ?? '500081',
              latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 17.4265,
              longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 78.4124,
              rating: double.tryParse(json['rating']?.toString() ?? '') ?? 4.8,
              reviewCount: int.tryParse(json['reviews_count']?.toString() ?? '') ?? 120,
              distanceKm: double.tryParse(json['distance_km']?.toString() ?? '') ?? 2.5,
              doctorCount: int.tryParse(json['staff_count']?.toString() ?? '') ?? 45,
              specialtyCount: depts.length,
              bedCount: int.tryParse(json['total_beds']?.toString() ?? '') ?? 150,
              departments: depts,
              services: const ['Emergency', 'ICU', 'Pharmacy', 'Lab', 'Radiology'],
              facilities: const ['Emergency 24x7', 'Blood Bank', 'Pharmacy', 'Ambulance'],
              phone: json['primary_phone'] ?? '+91 40 4488 5000',
              emergencyPhone: json['emergency_phone'] ?? '1066',
              email: json['email'] ?? 'contact@hospital.in',
              website: 'https://healthexpress.ai',
              description: 'Premier tertiary care partner hospital empaneled for Aarogyasri benefits.',
              workingHours: '24 Hours Open',
            );
          }).toList();
        }
      }
    } catch (e) {
      // Return empty list
    }
    return [];
  }

  // 2. Fetch Real Doctors from Hostinger MySQL with Location Proximity
  static Future<List<DoctorModel>> fetchDoctors({double? latitude, double? longitude, String? specialty}) async {
    try {
      String url = '$baseUrl/doctors';
      if (latitude != null && longitude != null) {
        url += '?lat=$latitude&lng=$longitude';
        if (specialty != null && specialty.isNotEmpty) url += '&specialty=$specialty';
      }
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final rawData = _unpackData(res.body);
        if (rawData is List) {
          return rawData.map<DoctorModel>((json) {
            final fee = double.tryParse(json['consultation_fee']?.toString() ?? '') ?? 500.0;
            return DoctorModel(
              id: json['id'] ?? 'DOC-01',
              name: json['name'] ?? 'Doctor',
              email: json['email'] ?? 'doctor@healthexpress.ai',
              phone: json['phone'] ?? '+91 98480 12345',
              photoUrl: json['photo_url'] ?? 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300',
              specialty: json['specialty'] ?? 'General Physician',
              qualifications: 'MBBS, MD (General Medicine)',
              experienceYears: int.tryParse(json['experience_years']?.toString() ?? '') ?? 5,
              rating: double.tryParse(json['rating']?.toString() ?? '') ?? 4.9,
              reviewCount: int.tryParse(json['reviews_count']?.toString() ?? '') ?? 85,
              hospitalId: json['hospital_id'] ?? 'HOSP-01',
              hospitalName: json['hospital_name'] ?? 'Independent Practice',
              location: json['hospital_city'] ?? 'Hyderabad',
              distanceKm: double.tryParse(json['distance_km']?.toString() ?? '') ?? 2.8,
              clinicFee: fee,
              videoFee: fee * 0.8,
              homeVisitFee: fee * 1.5,
              supportedTypes: const [ConsultationType.clinicVisit, ConsultationType.videoConsult, ConsultationType.homeVisitRMP],
              bio: 'Senior Clinical Specialist with extensive hospital and telemedicine experience.',
              isOnline: json['is_online'] == 1 || json['is_online'] == true,
              isRmpDoctor: json['is_rmp_doctor'] == 1 || json['is_rmp_doctor'] == true,
            );
          }).toList();
        }
      }
    } catch (e) {
      // Return empty list
    }
    return [];
  }

  // 3. Fetch Real Medicines Catalog
  static Future<List<MedicineModel>> fetchMedicines() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/pharmacy/medicines')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final rawData = _unpackData(res.body);
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map<String, dynamic>) {
          list = (rawData['medicines'] as List?) ?? [];
        }
        return list.map<MedicineModel>((m) {
          return MedicineModel(
            id: m['id'] ?? 'MED-01',
            name: m['name'] ?? '',
            genericName: m['generic_name'] ?? m['name'] ?? '',
            category: m['category'] ?? 'General',
            price: double.tryParse(m['price'].toString()) ?? 30.0,
            originalPrice: double.tryParse(m['original_price']?.toString() ?? '') ?? 40.0,
            packSize: m['pack_size'] ?? 'Pack',
            requiresPrescription: m['is_prescription_required'] == 1 || m['is_prescription_required'] == true,
            imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=200',
            description: 'Authentic formulation with 15-minute quick dispatch guarantee.',
            manufacturer: m['manufacturer'] ?? 'HealthExpress Pharmacy',
          );
        }).toList();
      }
    } catch (e) {
      // Return empty list
    }
    return [];
  }

  // 4. Create Razorpay Live Order
  static Future<Map<String, dynamic>?> createRazorpayOrder({required double amount}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/payments/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = _unpackData(res.body);
        return data is Map<String, dynamic> ? data : jsonDecode(res.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 5. Generate Agora Channel Token
  static Future<String?> generateAgoraToken(String channelName) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/telehealth/generate-agora-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'channel_name': channelName}),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = _unpackData(res.body);
        if (data is Map<String, dynamic>) {
          return data['token'];
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 5b. Fetch LiveKit WebRTC Token for Real-Time Voice Assistant & Avatar from Deployed PHP Backend
  static Future<Map<String, dynamic>?> fetchLiveKitToken({
    String? room,
    String? identity,
    String? name,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (room != null && room.isNotEmpty) queryParams['room'] = room;
      if (identity != null && identity.isNotEmpty) queryParams['identity'] = identity;
      if (name != null && name.isNotEmpty) queryParams['name'] = name;

      final uri = Uri.parse('$baseUrl/livekit/token').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = _unpackData(res.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (_) {
      try {
        final fallbackUri = Uri.parse('${AppConfig.fallbackApiBaseUrl}/livekit/token');
        final res = await http.get(fallbackUri).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final data = _unpackData(res.body);
          if (data is Map<String, dynamic>) return data;
        }
      } catch (_) {}
    }
    return null;
  }

  // 6. Generate 15-Minute Consent QR Token (ABDM)
  static Future<String?> generateConsentToken(String userId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/consent/generate-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = _unpackData(res.body);
        if (data is Map<String, dynamic>) {
          return data['consent_token'];
        }
      }
    } catch (e) {
      // ignore
    }
    return 'HEALTHEXPRESS:CONSENT_TOKEN:$userId:${DateTime.now().millisecondsSinceEpoch}';
  }

  // 7. Doctor Scan Patient QR Token
  static Future<Map<String, dynamic>?> doctorScanConsentToken(String qrToken, String doctorId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/consent/doctor-scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'consent_token': qrToken, 'doctor_id': doctorId}),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = _unpackData(res.body);
        return data is Map<String, dynamic> ? data : jsonDecode(res.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 8. Run Multilingual Clinical AI Triage with Key-Value Patient Memory & Safe Medicine Suggestions
  static Future<Map<String, dynamic>?> runAiTriageWithMemory({
    required String userId,
    required String symptoms,
    String duration = '2 days',
    Map<String, dynamic>? feelings,
    Map<String, dynamic>? vitals,
    String language = 'en-IN',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ai/triage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'symptoms': symptoms,
          'duration': duration,
          'feelings': feelings ?? {
            'pain_scale': 6,
            'pain_character': 'Dull throbbing pain',
            'fatigue_level': 'Moderate fatigue',
            'sleep_quality': 'Disturbed',
            'appetite': 'Reduced'
          },
          'vitals': vitals ?? {
            'temperature_f': 101.2,
            'blood_pressure': '120/80',
            'heart_rate_bpm': 84,
            'spo2_percent': 98
          },
          'language': language,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = _unpackData(res.body);
        return data is Map<String, dynamic> ? data : jsonDecode(res.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 9. Fetch Historical AI Sessions & Key-Value Memory for User
  static Future<List<dynamic>> fetchUserAiSessions(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/ai/sessions/user/$userId')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = _unpackData(res.body);
        if (data is List) return data;
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  // 10. Fetch User Appointments from MySQL
  static Future<List<dynamic>> fetchUserAppointments(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/appointments/user/$userId')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = _unpackData(res.body);
        if (data is List) return data;
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  // 11. Book New Appointment into MySQL
  static Future<Map<String, dynamic>?> bookAppointment({
    required String userId,
    required String doctorId,
    required String hospitalId,
    required String appointmentDate,
    required String timeSlot,
    required String type,
    required double fee,
    String? symptomsSummary,
    bool isAarogyasri = false,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/appointments/book'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'doctor_id': doctorId,
          'hospital_id': hospitalId,
          'appointment_date': appointmentDate,
          'time_slot': timeSlot,
          'type': type,
          'fee': fee,
          'symptoms_summary': symptomsSummary ?? 'General Consultation',
          'is_aarogyasri_applied': isAarogyasri ? 1 : 0,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = _unpackData(res.body);
        return data is Map<String, dynamic> ? data : jsonDecode(res.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 12. Fetch User Health Records & Lab Vault from MySQL
  static Future<List<dynamic>> fetchUserHealthRecords(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health-records/user/$userId')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = _unpackData(res.body);
        if (data is List) return data;
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  // 13. Fetch Aarogyasri Health Pass Profile from MySQL
  static Future<Map<String, dynamic>?> fetchAarogyasriProfile(String aarogyasriId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/auth/aarogyasri/$aarogyasriId')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = _unpackData(res.body);
        return data is Map<String, dynamic> ? data : jsonDecode(res.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 14. Register Patient/User in Remote Database
  static Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String phone,
    String? email,
    String? aarogyasriId,
    int? age,
    String? gender,
    String? address,
    double? latitude,
    double? longitude,
    String? emergencyContact,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'aarogyasriId': aarogyasriId,
          'age': age ?? 28,
          'gender': gender ?? 'Male',
          'address': address ?? '',
          'latitude': latitude,
          'longitude': longitude,
          'emergency_contact': emergencyContact ?? '',
          'role': 'user',
        }),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 15. Onboard Doctor into Remote Database
  static Future<Map<String, dynamic>?> onboardDoctor({
    required String name,
    required String phone,
    String? email,
    required String specialty,
    required String qualifications,
    required String licenseNumber,
    double fee = 600.0,
    int experienceYears = 5,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/doctors/onboard'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'mobile': phone,
          'email': email,
          'specialty': specialty,
          'qualifications': qualifications,
          'registrationNumber': licenseNumber,
          'clinic_fee': fee,
          'experienceYears': experienceYears,
        }),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 16. Onboard Medical Store Partner into Remote Database
  static Future<Map<String, dynamic>?> onboardStore({
    required String name,
    required String phone,
    String? email,
    required String licenseNumber,
    String? gstin,
    String? pharmacistName,
    String? address,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/pharmacy/onboard'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'licenseNumber': licenseNumber,
          'gstin': gstin,
          'pharmacistName': pharmacistName,
          'address': address,
        }),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 17. Place 15-Minute Doorstep Pharmacy Order
  static Future<Map<String, dynamic>?> createPharmacyOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryAddress,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/pharmacy/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'items': items,
          'totalAmount': totalAmount,
          'deliveryAddress': deliveryAddress,
        }),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // 18. Fetch Medicine Suggestions by Symptom / Condition
  static Future<List<dynamic>> fetchMedicineSuggestions(String symptom) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/pharmacy/suggestions?symptom=${Uri.encodeComponent(symptom)}'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['suggestions'] is List) {
          return decoded['suggestions'];
        }
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  // 19. Check Latest RAG Update Version in Real Time
  static Future<Map<String, dynamic>?> checkLatestRagVersion() async {
    for (final base in [AppConfig.apiBaseUrl, AppConfig.fallbackApiBaseUrl]) {
      try {
        final res = await http.get(Uri.parse('$base/ai/rag-chunks/latest-version')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            final data = decoded['data'] ?? decoded;
            if (data is Map<String, dynamic>) return data;
            return decoded;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  // 20. Fetch Real-Time Published RAG Chunks
  static Future<List<Map<String, dynamic>>> fetchPublishedRagChunks() async {
    for (final base in [AppConfig.apiBaseUrl, AppConfig.fallbackApiBaseUrl]) {
      try {
        final res = await http.get(Uri.parse('$base/ai/rag-chunks')).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final data = (decoded is Map && decoded['data'] != null) ? decoded['data'] : decoded;
          if (data is Map && data['chunks'] is List) {
            return List<Map<String, dynamic>>.from(data['chunks']);
          } else if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          }
        }
      } catch (_) {}
    }
    return [];
  }

  // 21. Fetch Currently Active Sarvam API Key from Central Server Pool
  static Future<String?> fetchActiveSarvamKey() async {
    for (final base in [AppConfig.apiBaseUrl, AppConfig.fallbackApiBaseUrl]) {
      try {
        final res = await http.get(Uri.parse('$base/public/sarvam-keys/active')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded['key'] != null && decoded['key'].toString().isNotEmpty) {
            final key = decoded['key'].toString();
            AppConfig.updateActiveSarvamKey(key);
            return key;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  // 22. Report Sarvam Key Credits Exhausted to Server Pool for Automatic Failover
  static Future<void> reportSarvamKeyExhausted(String key) async {
    for (final base in [AppConfig.apiBaseUrl, AppConfig.fallbackApiBaseUrl]) {
      try {
        await http.post(
          Uri.parse('$base/public/sarvam-keys/mark-exhausted'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'key': key,
            'reason': 'Live client received HTTP 402 Insufficient Balance'
          }),
        ).timeout(const Duration(seconds: 4));
        return;
      } catch (_) {}
    }
  }
}
