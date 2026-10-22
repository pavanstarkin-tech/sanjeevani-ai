import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../models/medical_store_model.dart';
import '../data/production_database.dart';
import '../services/firebase_auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserRole _currentRole = UserRole.user;
  bool _isAuthenticated = false;
  bool _isOnboarded = false;
  bool _isInitialized = false;
  FirebaseUserSession? _firebaseSession;
  UserModel _currentUser = ProductionDatabase.defaultUser;
  DoctorModel _currentDoctor = ProductionDatabase.doctors[0];
  MedicalStoreModel _currentStore = ProductionDatabase.defaultStore;

  AuthProvider() {
    initAuth();
  }

  UserRole get currentRole => _currentRole;
  bool get isAuthenticated => _isAuthenticated;
  bool get isOnboarded => _isOnboarded;
  bool get isInitialized => _isInitialized;
  FirebaseUserSession? get firebaseSession => _firebaseSession;
  UserModel get currentUser => _currentUser;
  DoctorModel get currentDoctor => _currentDoctor;
  MedicalStoreModel get currentStore => _currentStore;

  bool get isDoctorMode => _currentRole == UserRole.doctor;
  bool get isUserMode => _currentRole == UserRole.user;
  bool get isStoreMode => _currentRole == UserRole.store;

  Future<void> initAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSavedUserId = prefs.getString('auth_user_id') != null && prefs.getString('auth_user_id')!.isNotEmpty;
      final isAuthFlag = prefs.getBool('auth_is_authenticated') ?? false;
      
      _isAuthenticated = hasSavedUserId && isAuthFlag;
      _isOnboarded = prefs.getBool('auth_is_onboarded') ?? false;
      
      final roleStr = prefs.getString('auth_current_role');
      if (roleStr == 'doctor') {
        _currentRole = UserRole.doctor;
      } else if (roleStr == 'store') {
        _currentRole = UserRole.store;
      } else {
        _currentRole = UserRole.user;
      }

      final uid = prefs.getString('auth_user_id');
      final name = prefs.getString('auth_user_name');
      final email = prefs.getString('auth_user_email');
      final phone = prefs.getString('auth_user_phone');
      final bloodGroup = prefs.getString('auth_user_blood_group');
      final aarogyasriId = prefs.getString('auth_user_aarogyasri_id');
      final age = prefs.getInt('auth_user_age');
      final gender = prefs.getString('auth_user_gender');
      final address = prefs.getString('auth_user_address');
      final lat = prefs.getDouble('auth_user_lat');
      final lng = prefs.getDouble('auth_user_lng');
      final emergencyName = prefs.getString('auth_user_emergency_name');
      final emergencyPhone = prefs.getString('auth_user_emergency_phone');
      final emergencyRel = prefs.getString('auth_user_emergency_rel');
      final allergies = prefs.getString('auth_user_allergies');
      final chronic = prefs.getString('auth_user_chronic');
      final heightCm = prefs.getDouble('auth_user_height');
      final weightKg = prefs.getDouble('auth_user_weight');
      final tempF = prefs.getDouble('auth_user_temp');
      final hrBpm = prefs.getInt('auth_user_hr');
      final spo2 = prefs.getInt('auth_user_spo2');

      if (uid != null && uid.isNotEmpty) {
        _currentUser = _currentUser.copyWith(
          id: uid,
          name: name ?? _currentUser.name,
          email: email ?? _currentUser.email,
          phone: phone ?? _currentUser.phone,
          bloodGroup: bloodGroup ?? _currentUser.bloodGroup,
          aarogyasriId: aarogyasriId ?? _currentUser.aarogyasriId,
          age: age ?? _currentUser.age,
          gender: gender ?? _currentUser.gender,
          address: address ?? _currentUser.address,
          latitude: lat ?? _currentUser.latitude,
          longitude: lng ?? _currentUser.longitude,
          emergencyContactName: emergencyName ?? _currentUser.emergencyContactName,
          emergencyContactPhone: emergencyPhone ?? _currentUser.emergencyContactPhone,
          emergencyContactRelation: emergencyRel ?? _currentUser.emergencyContactRelation,
          allergies: allergies ?? _currentUser.allergies,
          chronicConditions: chronic ?? _currentUser.chronicConditions,
          heightCm: heightCm ?? _currentUser.heightCm,
          weightKg: weightKg ?? _currentUser.weightKg,
          temperatureF: tempF ?? _currentUser.temperatureF,
          heartRateBpm: hrBpm ?? _currentUser.heartRateBpm,
          oxygenSpo2: spo2 ?? _currentUser.oxygenSpo2,
          profilePhoto: prefs.getString('auth_user_profile_photo') ?? _currentUser.profilePhoto,
        );
      }

      final docId = prefs.getString('auth_doctor_id');
      final docName = prefs.getString('auth_doctor_name');
      if (docId != null && docId.isNotEmpty) {
        _currentDoctor = _currentDoctor.copyWith(
          id: docId,
          name: docName ?? _currentDoctor.name,
        );
      }

      final storeId = prefs.getString('auth_store_id');
      final storeName = prefs.getString('auth_store_name');
      final storeStatus = prefs.getString('auth_store_status');
      if (storeId != null && storeId.isNotEmpty) {
        _currentStore = _currentStore.copyWith(
          id: storeId,
          name: storeName ?? _currentStore.name,
          verificationStatus: storeStatus ?? _currentStore.verificationStatus,
        );
      }
    } catch (_) {
      // SharedPreferences error fallback
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveSessionToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_authenticated', _isAuthenticated);
      await prefs.setBool('auth_is_onboarded', _isOnboarded);
      await prefs.setString('auth_current_role', _currentRole == UserRole.doctor ? 'doctor' : (_currentRole == UserRole.store ? 'store' : 'user'));
      await prefs.setString('auth_user_id', _currentUser.id);
      await prefs.setString('auth_user_name', _currentUser.name);
      await prefs.setString('auth_user_email', _currentUser.email);
      await prefs.setString('auth_user_phone', _currentUser.phone);
      await prefs.setString('auth_user_blood_group', _currentUser.bloodGroup);
      await prefs.setString('auth_user_aarogyasri_id', _currentUser.aarogyasriId);
      await prefs.setInt('auth_user_age', _currentUser.age);
      await prefs.setString('auth_user_gender', _currentUser.gender);
      await prefs.setString('auth_user_address', _currentUser.address);
      if (_currentUser.latitude != null) await prefs.setDouble('auth_user_lat', _currentUser.latitude!);
      if (_currentUser.longitude != null) await prefs.setDouble('auth_user_lng', _currentUser.longitude!);
      await prefs.setString('auth_user_emergency_name', _currentUser.emergencyContactName);
      await prefs.setString('auth_user_emergency_phone', _currentUser.emergencyContactPhone);
      await prefs.setString('auth_user_emergency_rel', _currentUser.emergencyContactRelation);
      await prefs.setString('auth_user_allergies', _currentUser.allergies);
      await prefs.setString('auth_user_chronic', _currentUser.chronicConditions);
      await prefs.setDouble('auth_user_height', _currentUser.heightCm);
      await prefs.setDouble('auth_user_weight', _currentUser.weightKg);
      await prefs.setDouble('auth_user_temp', _currentUser.temperatureF);
      await prefs.setInt('auth_user_hr', _currentUser.heartRateBpm);
      await prefs.setInt('auth_user_spo2', _currentUser.oxygenSpo2);
      if (_currentUser.profilePhoto != null) {
        await prefs.setString('auth_user_profile_photo', _currentUser.profilePhoto!);
      }

      if (_currentRole == UserRole.doctor) {
        await prefs.setString('auth_doctor_id', _currentDoctor.id);
        await prefs.setString('auth_doctor_name', _currentDoctor.name);
      } else if (_currentRole == UserRole.store) {
        await prefs.setString('auth_store_id', _currentStore.id);
        await prefs.setString('auth_store_name', _currentStore.name);
        await prefs.setString('auth_store_status', _currentStore.verificationStatus);
      }
    } catch (_) {
      // Ignored
    }
  }

  void setRole(UserRole role) {
    _currentRole = role;
    _saveSessionToPrefs();
    notifyListeners();
  }

  void switchRole() {
    if (_currentRole == UserRole.user) {
      _currentRole = UserRole.doctor;
    } else if (_currentRole == UserRole.doctor) {
      _currentRole = UserRole.store;
    } else {
      _currentRole = UserRole.user;
    }
    _saveSessionToPrefs();
    notifyListeners();
  }

  /// Instant 1-Click Demo Login bypass
  Future<void> loginAsDemoRole(UserRole role) async {
    _currentRole = role;
    if (role == UserRole.doctor) {
      _currentDoctor = ProductionDatabase.doctors[0];
      _currentUser = _currentUser.copyWith(
        id: _currentDoctor.id,
        name: _currentDoctor.name,
        email: _currentDoctor.email,
        phone: _currentDoctor.phone,
      );
      _firebaseSession = FirebaseUserSession(
        uid: 'abA57u8rmiM64NjcZWnLxmNvENO2',
        email: 'dr.sandeep@healthexpress.ai',
        displayName: 'Dr. Sandeep Attawar',
        idToken: 'demo_token_doctor',
        refreshToken: 'demo_refresh_doctor',
      );
    } else if (role == UserRole.store) {
      _currentStore = ProductionDatabase.defaultStore;
      _currentUser = _currentUser.copyWith(
        id: _currentStore.id,
        name: _currentStore.name,
        email: _currentStore.email,
        phone: _currentStore.phone,
      );
      _firebaseSession = FirebaseUserSession(
        uid: 'bWtKPWC7FjWWZozM6Bos3sL4YY73',
        email: 'contact@medplusexpress.com',
        displayName: 'MedPlus Pharmacy',
        idToken: 'demo_token_store',
        refreshToken: 'demo_refresh_store',
      );
    } else {
      _currentUser = ProductionDatabase.defaultUser;
      _firebaseSession = FirebaseUserSession(
        uid: 'kfGYTSi5rYSk8qSej5KQbJ859Jt1',
        email: 'rahul.kumar@gmail.com',
        displayName: 'Rahul Kumar',
        idToken: 'demo_token_patient',
        refreshToken: 'demo_refresh_patient',
      );
    }
    _isAuthenticated = true;
    _isOnboarded = true;
    await _saveSessionToPrefs();
    notifyListeners();
  }

  /// Real Firebase Email & Password Sign In with Seamless Demo Fallback
  Future<void> loginWithFirebase({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final isDemoAccount = cleanEmail == 'rahul.kumar@gmail.com' ||
        cleanEmail == 'rahul.kumar@email.com' ||
        cleanEmail == 'dr.sandeep@healthexpress.ai' ||
        cleanEmail == 'contact@medplusexpress.com';

    FirebaseUserSession? session;

    try {
      session = await FirebaseAuthService.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password.trim(),
      );
    } catch (e) {
      if (isDemoAccount) {
        // Fallback to verified demo session so testing is never blocked
        await loginAsDemoRole(role);
        return;
      }
      rethrow;
    }

    _firebaseSession = session;
    _currentRole = role;

    if (role == UserRole.doctor) {
      final matchedDoc = ProductionDatabase.doctors.firstWhere(
        (d) => d.email.toLowerCase() == cleanEmail,
        orElse: () => ProductionDatabase.doctors[0],
      );
      _currentDoctor = matchedDoc.copyWith(
        id: session.uid.isNotEmpty ? 'DOC-${session.uid.substring(0, session.uid.length > 8 ? 8 : session.uid.length)}' : 'DOC-abA57u8r',
        name: session.displayName.isNotEmpty ? session.displayName : matchedDoc.name,
        email: session.email,
      );
      _currentUser = _currentUser.copyWith(
        id: session.uid,
        name: _currentDoctor.name,
        email: session.email,
      );
    } else if (role == UserRole.store) {
      _currentStore = ProductionDatabase.defaultStore.copyWith(
        id: session.uid.isNotEmpty ? 'STORE-${session.uid.substring(0, session.uid.length > 8 ? 8 : session.uid.length)}' : 'STORE-bWtKPWC7',
        ownerUserId: session.uid,
        email: session.email,
      );
      _currentUser = _currentUser.copyWith(
        id: session.uid,
        name: _currentStore.name,
        email: session.email,
      );
    } else {
      _currentUser = _currentUser.copyWith(
        id: session.uid,
        name: session.displayName.isNotEmpty ? session.displayName : (_currentUser.name.isNotEmpty ? _currentUser.name : 'Patient User'),
        email: session.email,
      );
    }

    _isAuthenticated = true;
    _isOnboarded = true; // Email sign in assumes existing onboarded account
    await _saveSessionToPrefs();
    notifyListeners();
  }

  /// Real Firebase Email & Password Registration
  Future<void> signUpWithFirebase({
    required String name,
    required String email,
    required String password,
    String? phone,
    required UserRole role,
  }) async {
    FirebaseUserSession session;
    try {
      session = await FirebaseAuthService.signUpWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('already registered') || msg.contains('EMAIL_EXISTS')) {
        // If account exists, attempt sign in directly
        await loginWithFirebase(email: email, password: password, role: role);
        return;
      }
      rethrow;
    }

    _firebaseSession = session;
    _currentRole = role;
    _currentUser = UserModel(
      id: session.uid,
      name: name.isNotEmpty ? name : session.displayName,
      email: session.email,
      phone: phone ?? '',
      aarogyasriId: 'AROG${session.uid.substring(0, session.uid.length > 8 ? 8 : session.uid.length).toUpperCase()}',
      joinedDate: DateTime.now(),
    );

    if (role == UserRole.doctor) {
      _currentDoctor = _currentDoctor.copyWith(
        id: 'DOC-${session.uid.substring(0, session.uid.length > 8 ? 8 : session.uid.length)}',
        name: name.startsWith('Dr.') ? name : 'Dr. $name',
        email: session.email,
        phone: phone ?? _currentDoctor.phone,
      );
    } else if (role == UserRole.store) {
      _currentStore = _currentStore.copyWith(
        id: 'STORE-${session.uid.substring(0, session.uid.length > 8 ? 8 : session.uid.length)}',
        name: '$name Pharmacy',
        ownerUserId: session.uid,
        email: session.email,
        phone: phone ?? _currentStore.phone,
      );
    }

    _isAuthenticated = true;
    _isOnboarded = false; // Must complete role-specific detail onboarding
    await _saveSessionToPrefs();
    notifyListeners();
  }

  /// Real Google Sign In Flow with Firebase Web Popup
  Future<FirebaseUserSession> loginWithGoogle({required UserRole role}) async {
    final session = await FirebaseAuthService.signInWithGoogle();

    _firebaseSession = session;
    _currentRole = role;
    _currentUser = _currentUser.copyWith(
      id: session.uid,
      name: session.displayName.isNotEmpty ? session.displayName : session.email.split('@')[0],
      email: session.email,
      profilePhoto: session.photoUrl,
    );

    if (role == UserRole.doctor) {
      _currentDoctor = _currentDoctor.copyWith(
        id: 'DOC-${session.uid.substring(0, session.uid.length > 8 ? 8 : session.uid.length)}',
        name: session.displayName.startsWith('Dr.') ? session.displayName : 'Dr. ${session.displayName}',
        email: session.email,
        photoUrl: session.photoUrl ?? _currentDoctor.photoUrl,
      );
    } else if (role == UserRole.store) {
      _currentStore = _currentStore.copyWith(
        id: 'STORE-${session.uid.substring(0, session.uid.length > 8 ? 8 : session.uid.length)}',
        name: '${session.displayName} Pharmacy',
        ownerUserId: session.uid,
        email: session.email,
      );
    }

    _isAuthenticated = true;
    final prefs = await SharedPreferences.getInstance();
    final savedOnboarded = prefs.getBool('auth_is_onboarded') ?? false;
    final savedPhone = prefs.getString('auth_user_phone');
    if (savedOnboarded || (savedPhone != null && savedPhone.isNotEmpty)) {
      _isOnboarded = true;
    } else {
      _isOnboarded = false;
    }
    await _saveSessionToPrefs();
    notifyListeners();
    return session;
  }

  void login({required String identifier, String? password, required UserRole role}) {
    _currentRole = role;
    _isAuthenticated = true;
    _isOnboarded = true;
    _saveSessionToPrefs();
    notifyListeners();
  }

  void registerUser({
    required String name,
    required String phone,
    String? email,
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
  }) {
    _currentUser = _currentUser.copyWith(
      name: name,
      phone: phone,
      email: email ?? _currentUser.email,
      aarogyasriId: (aarogyasriId != null && aarogyasriId.isNotEmpty) ? aarogyasriId : _currentUser.aarogyasriId,
      age: age ?? _currentUser.age,
      gender: gender ?? _currentUser.gender,
      address: address ?? _currentUser.address,
      latitude: latitude ?? _currentUser.latitude,
      longitude: longitude ?? _currentUser.longitude,
      emergencyContactName: emergencyContactName ?? _currentUser.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? _currentUser.emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation ?? _currentUser.emergencyContactRelation,
      bloodGroup: bloodGroup ?? _currentUser.bloodGroup,
      allergies: allergies ?? _currentUser.allergies,
      chronicConditions: chronicConditions ?? _currentUser.chronicConditions,
      pastSurgeries: pastSurgeries ?? _currentUser.pastSurgeries,
      heightCm: heightCm ?? _currentUser.heightCm,
      weightKg: weightKg ?? _currentUser.weightKg,
    );
    _isAuthenticated = true;
    _isOnboarded = true;
    _currentRole = UserRole.user;
    _saveSessionToPrefs();
    notifyListeners();

    // Sync to remote MySQL backend
    ApiService.registerUser(
      name: name,
      phone: phone,
      email: email ?? _currentUser.email,
      aarogyasriId: _currentUser.aarogyasriId,
      age: _currentUser.age,
      gender: _currentUser.gender,
      address: _currentUser.address,
      latitude: _currentUser.latitude,
      longitude: _currentUser.longitude,
      emergencyContact: '${_currentUser.emergencyContactName} (${_currentUser.emergencyContactPhone})',
    );
  }

  void registerDoctor({
    required String name,
    required String phone,
    String? email,
    required String specialty,
    required String qualifications,
    required String hospitalId,
    required String hospitalName,
    required double clinicFee,
    String? regNumber,
    int? experienceYears,
  }) {
    _currentDoctor = DoctorModel(
      id: 'DOC-${DateTime.now().millisecondsSinceEpoch}',
      name: name.startsWith('Dr.') ? name : 'Dr. $name',
      email: email ?? '${name.toLowerCase().replaceAll(' ', '.')}@healthexpress.ai',
      phone: phone,
      photoUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=400',
      specialty: specialty,
      qualifications: qualifications,
      experienceYears: experienceYears ?? 5,
      rating: 5.0,
      reviewCount: 1,
      hospitalId: hospitalId,
      hospitalName: hospitalName,
      location: 'Hyderabad, Telangana',
      distanceKm: 2.0,
      clinicFee: clinicFee,
      videoFee: clinicFee,
      homeVisitFee: clinicFee + 300,
      supportedTypes: [ConsultationType.clinicVisit, ConsultationType.videoConsult],
      bio: 'Dedicated $specialty specialist with $qualifications. Practicing at $hospitalName with license $regNumber.',
      isVerified: true,
      isOnline: true,
    );
    _isAuthenticated = true;
    _isOnboarded = true;
    _currentRole = UserRole.doctor;
    _saveSessionToPrefs();
    notifyListeners();

    // Sync to remote MySQL backend
    ApiService.onboardDoctor(
      name: name,
      phone: phone,
      email: email,
      specialty: specialty,
      qualifications: qualifications,
      licenseNumber: regNumber ?? 'MCI-PENDING',
      fee: clinicFee,
      experienceYears: experienceYears ?? 5,
    );
  }


  void registerStore({
    required String name,
    required String licenseNumber,
    required String phone,
    String? email,
    required String address,
    required String area,
    required String openingTime,
    required String closingTime,
    required bool is24x7,
    String? imageUrl,
  }) {
    final newId = 'STORE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _currentStore = MedicalStoreModel(
      id: newId,
      name: name,
      licenseNumber: licenseNumber,
      phone: phone,
      email: email ?? 'contact@${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.com',
      address: address,
      area: area,
      openingTime: openingTime,
      closingTime: closingTime,
      is24x7: is24x7,
      isOpen: true,
      imageUrl: imageUrl ?? 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400',
      distanceKm: 1.2,
      etaMinutes: 15,
      verificationStatus: 'verified', // Set verified for active role usage
      ownerUserId: _currentUser.id,
    );
    _isAuthenticated = true;
    _currentRole = UserRole.store;
    _saveSessionToPrefs();
    notifyListeners();

    // Sync to remote MySQL backend
    ApiService.onboardStore(
      name: name,
      phone: phone,
      email: email,
      licenseNumber: licenseNumber,
      address: '$address, $area',
    );
  }

  void updateStoreTimings({
    required String openingTime,
    required String closingTime,
    required bool is24x7,
  }) {
    _currentStore = _currentStore.copyWith(
      openingTime: openingTime,
      closingTime: closingTime,
      is24x7: is24x7,
    );
    _saveSessionToPrefs();
    notifyListeners();
  }

  void updateStoreContact({
    required String phone,
    String? email,
    required String address,
    required String area,
  }) {
    _currentStore = _currentStore.copyWith(
      phone: phone,
      email: email,
      address: address,
      area: area,
    );
    _saveSessionToPrefs();
    notifyListeners();
  }

  void toggleStoreOpen() {
    _currentStore = _currentStore.copyWith(isOpen: !_currentStore.isOpen);
    _saveSessionToPrefs();
    notifyListeners();
  }

  void verifyStoreLocally(bool approved, [String? reason]) {
    _currentStore = _currentStore.copyWith(
      verificationStatus: approved ? 'verified' : 'rejected',
      rejectionReason: approved ? null : (reason ?? 'License verification pending'),
    );
    _saveSessionToPrefs();
    notifyListeners();
  }

  void updateUserProfile(UserModel updatedUser) {
    _currentUser = updatedUser;
    _saveSessionToPrefs();
    notifyListeners();
  }

  void updatePatientDetails({
    String? name,
    String? email,
    String? phone,
    String? bloodGroup,
    String? allergies,
    String? chronicConditions,
    double? heightCm,
    double? weightKg,
    String? aarogyasriId,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? profilePhoto,
  }) {
    _currentUser = _currentUser.copyWith(
      name: (name != null && name.trim().isNotEmpty) ? name : _currentUser.name,
      email: (email != null && email.trim().isNotEmpty) ? email : _currentUser.email,
      phone: (phone != null && phone.trim().isNotEmpty) ? phone : _currentUser.phone,
      bloodGroup: (bloodGroup != null && bloodGroup.trim().isNotEmpty) ? bloodGroup : _currentUser.bloodGroup,
      allergies: (allergies != null && allergies.trim().isNotEmpty) ? allergies : _currentUser.allergies,
      chronicConditions: (chronicConditions != null && chronicConditions.trim().isNotEmpty) ? chronicConditions : _currentUser.chronicConditions,
      heightCm: heightCm ?? _currentUser.heightCm,
      weightKg: weightKg ?? _currentUser.weightKg,
      aarogyasriId: (aarogyasriId != null && aarogyasriId.trim().isNotEmpty) ? aarogyasriId : _currentUser.aarogyasriId,
      address: (address != null && address.trim().isNotEmpty) ? address : _currentUser.address,
      emergencyContactName: (emergencyContactName != null && emergencyContactName.trim().isNotEmpty) ? emergencyContactName : _currentUser.emergencyContactName,
      emergencyContactPhone: (emergencyContactPhone != null && emergencyContactPhone.trim().isNotEmpty) ? emergencyContactPhone : _currentUser.emergencyContactPhone,
      emergencyContactRelation: (emergencyContactRelation != null && emergencyContactRelation.trim().isNotEmpty) ? emergencyContactRelation : _currentUser.emergencyContactRelation,
      profilePhoto: (profilePhoto != null && profilePhoto.trim().isNotEmpty) ? profilePhoto : _currentUser.profilePhoto,
    );
    _saveSessionToPrefs();
    notifyListeners();
  }

  Future<void> updateProfilePhoto(String photoPathOrBase64) async {
    _currentUser = _currentUser.copyWith(profilePhoto: photoPathOrBase64);
    await _saveSessionToPrefs();
    notifyListeners();
  }

  void updateAddress(String address, {double? latitude, double? longitude}) {
    _currentUser = _currentUser.copyWith(
      address: address.trim(),
      latitude: latitude ?? _currentUser.latitude,
      longitude: longitude ?? _currentUser.longitude,
    );
    _saveSessionToPrefs();
    notifyListeners();
  }

  void updateEmergencyContact({
    required String name,
    required String phone,
    required String relation,
  }) {
    _currentUser = _currentUser.copyWith(
      emergencyContactName: name.trim(),
      emergencyContactPhone: phone.trim(),
      emergencyContactRelation: relation.trim(),
    );
    _saveSessionToPrefs();
    notifyListeners();
  }

  void updateVitals({
    double? temperatureF,
    int? heartRateBpm,
    int? oxygenSpo2,
    double? weightKg,
    double? heightCm,
  }) {
    _currentUser = _currentUser.copyWith(
      temperatureF: temperatureF ?? _currentUser.temperatureF,
      heartRateBpm: heartRateBpm ?? _currentUser.heartRateBpm,
      oxygenSpo2: oxygenSpo2 ?? _currentUser.oxygenSpo2,
      weightKg: weightKg ?? _currentUser.weightKg,
      heightCm: heightCm ?? _currentUser.heightCm,
    );
    _saveSessionToPrefs();
    notifyListeners();
  }

  bool get isProfileComplete {
    return _currentUser.phone.isNotEmpty &&
        _currentUser.bloodGroup.isNotEmpty &&
        _currentUser.name.isNotEmpty;
  }

  void toggleDoctorOnlineStatus() {
    _currentDoctor = _currentDoctor.copyWith(isOnline: !_currentDoctor.isOnline);
    _saveSessionToPrefs();
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _isOnboarded = false;
    _firebaseSession = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('auth_is_authenticated', false);
      await prefs.setBool('auth_is_onboarded', false);
    } catch (_) {
      // Ignored
    }
    notifyListeners();
  }
}

