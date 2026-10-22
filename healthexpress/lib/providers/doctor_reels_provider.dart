import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/doctor_reel_model.dart';

class DoctorReelsProvider with ChangeNotifier {
  static const String _taggedProductsPrefKey = 'admin_tagged_products_map';
  
  final List<DoctorReelModel> _reels = [];
  final bool _isLoading = false;

  List<DoctorReelModel> get reels => List.unmodifiable(_reels);
  bool get isLoading => _isLoading;

  DoctorReelsProvider() {
    _initReels();
  }

  void _initReels() {
    const basePath = r'C:\Users\shese\Desktop\healthyxpress_medha\reels';
    
    final initialReels = [
      DoctorReelModel(
        id: 'reel_drsucharita',
        filename: 'drsucharitaent_44d2bd54_1.mp4',
        videoAsset: 'assets/reels/drsucharitaent_44d2bd54_1.mp4',
        videoPath: '$basePath\\drsucharitaent_44d2bd54_1.mp4',
        doctorName: 'Dr. Sucharita Rao',
        doctorSpecialty: 'ENT Specialist & Surgeon',
        doctorHandle: '@drsucharitaent',
        doctorAvatar: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300',
        title: 'Instant Cough & Throat Infection Care',
        caption: 'Watch this before taking strong antibiotic pills! Simple home steam and honey gargle tips that heal faster.',
        taggedProductId: 'MED-03', // Cough Relief Syrup
        likesCount: 34200,
        commentsCount: 1240,
        sharesCount: 5600,
        tags: ['#ENTDoctor', '#CoughRelief', '#ThroatCare'],
      ),
      DoctorReelModel(
        id: 'reel_bablutalks',
        filename: 'bablutalksuk2.0_303e64cd_1.mp4',
        videoAsset: 'assets/reels/bablutalksuk2.0_303e64cd_1.mp4',
        videoPath: '$basePath\\bablutalksuk2.0_303e64cd_1.mp4',
        doctorName: 'Dr. Bablu (Health Talks)',
        doctorSpecialty: 'Wellness & Preventive Health',
        doctorHandle: '@bablutalksuk2.0',
        doctorAvatar: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300',
        title: 'Daily Energy & Dehydration Shield',
        caption: 'Why feeling tired at 3 PM is often not lack of sleep, but electrolyte drop. How WHO ORS revives stamina in 15 mins.',
        taggedProductId: 'MED-104', // Electral ORS
        likesCount: 58900,
        commentsCount: 2310,
        sharesCount: 8900,
        tags: ['#EnergyBoost', '#Hydration', '#Electrolytes'],
      ),
      DoctorReelModel(
        id: 'reel_085cef21',
        filename: '_085cef21_1.mp4',
        videoAsset: 'assets/reels/_085cef21_1.mp4',
        videoPath: '$basePath\\_085cef21_1.mp4',
        doctorName: 'Dr. Rahul Sharma',
        doctorSpecialty: 'Internal Medicine MD',
        doctorHandle: '@dr.rahul_med',
        doctorAvatar: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=300',
        title: 'Fever 101: When to Take Paracetamol',
        caption: 'Never take pain relievers on an empty stomach. The clinical safe interval between paracetamol 650 doses explained.',
        taggedProductId: 'MED-101', // Dolo 650
        likesCount: 42100,
        commentsCount: 890,
        sharesCount: 3400,
        tags: ['#FeverTips', '#Paracetamol', '#DoctorAdvice'],
      ),
      DoctorReelModel(
        id: 'reel_14cacc3b',
        filename: '_14cacc3b_1.mp4',
        videoAsset: 'assets/reels/_14cacc3b_1.mp4',
        videoPath: '$basePath\\_14cacc3b_1.mp4',
        doctorName: 'Dr. Priya Rao',
        doctorSpecialty: 'Gastroenterologist',
        doctorHandle: '@drpriyagastro',
        doctorAvatar: 'https://images.unsplash.com/photo-1594824813560-5a3d0f04c622?auto=format&fit=crop&q=80&w=300',
        title: 'Silent Acidity & GERD Heartburn Remedy',
        caption: 'Waking up with sour taste or chest burning? Why taking proton-pump inhibitors 30 mins before breakfast is the only right way.',
        taggedProductId: 'MED-103', // Pan-D Capsule
        likesCount: 27500,
        commentsCount: 654,
        sharesCount: 2190,
        tags: ['#AcidityRelief', '#GutHealth', '#GERD'],
      ),
      DoctorReelModel(
        id: 'reel_22549530',
        filename: '_22549530_1.mp4',
        videoAsset: 'assets/reels/_22549530_1.mp4',
        videoPath: '$basePath\\_22549530_1.mp4',
        doctorName: 'Dr. Ananya Iyer',
        doctorSpecialty: 'Allergist & Pulmonologist',
        doctorHandle: '@dr.ananya_allergy',
        doctorAvatar: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300',
        title: 'Non-Drowsy Dust & Pollen Allergy Relief',
        caption: 'Continuous sneezing in morning? Here is the exact difference between viral cold and histamine allergic response.',
        taggedProductId: 'MED-102', // Cetzine 10mg
        likesCount: 19800,
        commentsCount: 420,
        sharesCount: 1540,
        tags: ['#AllergyRelief', '#ColdAndCough', '#Sinus'],
      ),
      DoctorReelModel(
        id: 'reel_30de7c75',
        filename: '_30de7c75_1.mp4',
        videoAsset: 'assets/reels/_30de7c75_1.mp4',
        videoPath: '$basePath\\_30de7c75_1.mp4',
        doctorName: 'Dr. Medha (Sanjeevani AI)',
        doctorSpecialty: 'Chief Clinical AI Director',
        doctorHandle: '@dr.medha_ai',
        doctorAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=300',
        title: '3 Golden Rules of Household First Aid',
        caption: 'Burns, cuts, or sudden choking in elderly or kids: what you must NEVER put on an open burn wound.',
        taggedProductId: 'MED-101', // Dolo 650 (First Aid Kit Essential)
        likesCount: 64200,
        commentsCount: 3100,
        sharesCount: 14200,
        tags: ['#FirstAid', '#EmergencyProtocol', '#SaveLives'],
      ),
      DoctorReelModel(
        id: 'reel_59d26cf2',
        filename: '_59d26cf2_1.mp4',
        videoAsset: 'assets/reels/_59d26cf2_1.mp4',
        videoPath: '$basePath\\_59d26cf2_1.mp4',
        doctorName: 'Dr. Suresh Varma',
        doctorSpecialty: 'Cardiologist MD',
        doctorHandle: '@dr.sureshcardio',
        doctorAvatar: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300',
        title: 'Hidden Signs Your Blood Pressure is Rising',
        caption: 'High BP is called the silent killer for a reason. 3 subtle morning signs you shouldn\'t brush off.',
        taggedProductId: 'MED-105', // Telma 40 Blood Pressure
        likesCount: 31200,
        commentsCount: 780,
        sharesCount: 4300,
        tags: ['#HeartHealth', '#BloodPressure', '#Cardio'],
      ),
      DoctorReelModel(
        id: 'reel_5c399098',
        filename: '_5c399098_1.mp4',
        videoAsset: 'assets/reels/_5c399098_1.mp4',
        videoPath: '$basePath\\_5c399098_1.mp4',
        doctorName: 'Dr. Shalini K.',
        doctorSpecialty: 'Consultant Dermatologist',
        doctorHandle: '@dr.shaliniderma',
        doctorAvatar: 'https://images.unsplash.com/photo-1594824813560-5a3d0f04c622?auto=format&fit=crop&q=80&w=300',
        title: 'Stop Fungal & Monsoon Itch in 48 Hours',
        caption: 'Why steroid skin creams make fungal rashes worse long term. Safe doctor-approved antifungal hygiene routines.',
        taggedProductId: 'MED-102', // Cetzine 10mg Allergy & Itch Relief
        likesCount: 22400,
        commentsCount: 512,
        sharesCount: 1890,
        tags: ['#Dermatology', '#SkinCare', '#FungalInfection'],
      ),
      DoctorReelModel(
        id: 'reel_5f191de8',
        filename: '_5f191de8_1.mp4',
        videoAsset: 'assets/reels/_5f191de8_1.mp4',
        videoPath: '$basePath\\_5f191de8_1.mp4',
        doctorName: 'Dr. Naveen Reddy',
        doctorSpecialty: 'Orthopedic Surgeon',
        doctorHandle: '@drnaveenortho',
        doctorAvatar: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=300',
        title: '2-Minute Fix for Desk Lower Back Pain',
        caption: 'Sitting for 8 hours damages the lumbar spine discs. Try this seated pelvic tilt stretch right now!',
        taggedProductId: 'MED-101', // Dolo 650 Back & Muscle Relief
        likesCount: 48900,
        commentsCount: 1120,
        sharesCount: 7400,
        tags: ['#BackPain', '#Orthopedics', '#PostureCorrection'],
      ),
      DoctorReelModel(
        id: 'reel_6a817ac0',
        filename: '_6a817ac0_1.mp4',
        videoAsset: 'assets/reels/_6a817ac0_1.mp4',
        videoPath: '$basePath\\_6a817ac0_1.mp4',
        doctorName: 'Dr. Arvind Sen',
        doctorSpecialty: 'Senior Pediatrician',
        doctorHandle: '@dr.arvindpediatrics',
        doctorAvatar: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&q=80&w=300',
        title: 'Vomiting & Loose Stools in Children',
        caption: 'The pinch test to check infant dehydration. Why giving plain water instead of electrolytes is dangerous.',
        taggedProductId: 'MED-104', // Electral ORS
        likesCount: 38200,
        commentsCount: 1450,
        sharesCount: 6100,
        tags: ['#ChildHealth', '#Pediatrician', '#Dehydration'],
      ),
      DoctorReelModel(
        id: 'reel_706a65ba',
        filename: '_706a65ba_1.mp4',
        videoAsset: 'assets/reels/_706a65ba_1.mp4',
        videoPath: '$basePath\\_706a65ba_1.mp4',
        doctorName: 'Dr. Sucharita Rao',
        doctorSpecialty: 'ENT Specialist',
        doctorHandle: '@drsucharitaent',
        doctorAvatar: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300',
        title: 'Blocked Nose & Sinus Pressure Relief',
        caption: 'Natural eucalyptus steam inhalation trick that unblocks nasal passages in minutes without habit-forming drops.',
        taggedProductId: 'MED-03',
        likesCount: 29100,
        commentsCount: 680,
        sharesCount: 3100,
        tags: ['#Sinusitis', '#NasalBlock', '#ENTCare'],
      ),
      DoctorReelModel(
        id: 'reel_8c96a8bd',
        filename: '_8c96a8bd_1.mp4',
        videoAsset: 'assets/reels/_8c96a8bd_1.mp4',
        videoPath: '$basePath\\_8c96a8bd_1.mp4',
        doctorName: 'Dr. Deepa Nair',
        doctorSpecialty: 'Clinical Nutritionist & Diabetologist',
        doctorHandle: '@drdeepanutri',
        doctorAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=300',
        title: '3 Indian Breakfasts That Spike Blood Sugar',
        caption: 'Switch your high glycemic breakfast with protein-rich moong dal chilla to prevent afternoon diabetes crashes.',
        taggedProductId: 'MED-106', // Glycomet-GP 1 Diabetes Management
        likesCount: 36700,
        commentsCount: 940,
        sharesCount: 5200,
        tags: ['#DiabetesCare', '#HealthyBreakfast', '#Nutrition'],
      ),
      DoctorReelModel(
        id: 'reel_a0ad4e56',
        filename: '_a0ad4e56_1.mp4',
        videoAsset: 'assets/reels/_a0ad4e56_1.mp4',
        videoPath: '$basePath\\_a0ad4e56_1.mp4',
        doctorName: 'Dr. Harish Patel',
        doctorSpecialty: 'Emergency Physician',
        doctorHandle: '@dr.harishemergency',
        doctorAvatar: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=300',
        title: 'How to Treat Mild Heat Exhaustion Fast',
        caption: 'Crucial steps when feeling dizzy in hot summer: shade, cool wet cloths on neck, and gradual oral rehydration.',
        taggedProductId: 'MED-104',
        likesCount: 18400,
        commentsCount: 320,
        sharesCount: 1600,
        tags: ['#HeatExhaustion', '#EmergencyCare', '#SummerHealth'],
      ),
      DoctorReelModel(
        id: 'reel_a0ba2fcb',
        filename: '_a0ba2fcb_1.mp4',
        videoAsset: 'assets/reels/_a0ba2fcb_1.mp4',
        videoPath: '$basePath\\_a0ba2fcb_1.mp4',
        doctorName: 'Dr. Meera Joshi',
        doctorSpecialty: 'General Physician',
        doctorHandle: '@drmeera_health',
        doctorAvatar: 'https://images.unsplash.com/photo-1594824813560-5a3d0f04c622?auto=format&fit=crop&q=80&w=300',
        title: 'Is it Tension Headache or True Migraine?',
        caption: 'Throbbing on one side vs band around forehead. Simple trigger tracker to pinpoint the cause.',
        taggedProductId: 'MED-101',
        likesCount: 26300,
        commentsCount: 590,
        sharesCount: 2800,
        tags: ['#MigraineHelp', '#HeadacheRelief', '#DoctorTips'],
      ),
      DoctorReelModel(
        id: 'reel_a6429a88',
        filename: '_a6429a88_1.mp4',
        videoAsset: 'assets/reels/_a6429a88_1.mp4',
        videoPath: '$basePath\\_a6429a88_1.mp4',
        doctorName: 'Dr. Rajesh K. V.',
        doctorSpecialty: 'Infectious Disease MD',
        doctorHandle: '@drrajesh_id',
        doctorAvatar: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&q=80&w=300',
        title: 'Stop Taking Antibiotics for Viral Flu!',
        caption: 'Antibiotics kill bacteria, NOT viruses! Misuse leads to drug resistance. Here is what works for viral fever.',
        taggedProductId: 'MED-06', // Vitamin C 500mg Immunity Boost
        likesCount: 51200,
        commentsCount: 2100,
        sharesCount: 11000,
        tags: ['#AntibioticResistance', '#ViralFlu', '#SafeMedicines'],
      ),
      DoctorReelModel(
        id: 'reel_d1b2d67e',
        filename: '_d1b2d67e_1.mp4',
        videoAsset: 'assets/reels/_d1b2d67e_1.mp4',
        videoPath: '$basePath\\_d1b2d67e_1.mp4',
        doctorName: 'Dr. Kavitha Menon',
        doctorSpecialty: 'Family Medicine & Endocrinology',
        doctorHandle: '@drkavithamenon',
        doctorAvatar: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300',
        title: 'Why Are You Constantly Exhausted?',
        caption: 'Checking thyroid TSH and Vitamin B12 levels before blaming stress. 3 simple lab markers every adult should check yearly.',
        taggedProductId: 'MED-104', // Electral ORS Vital Energy
        likesCount: 39500,
        commentsCount: 1340,
        sharesCount: 6700,
        tags: ['#ThyroidHealth', '#FatigueFix', '#BloodTests'],
      ),
      DoctorReelModel(
        id: 'reel_dc73d15b',
        filename: '_dc73d15b_1.mp4',
        videoAsset: 'assets/reels/_dc73d15b_1.mp4',
        videoPath: '$basePath\\_dc73d15b_1.mp4',
        doctorName: 'Dr. Sai Prasad',
        doctorSpecialty: 'Neurologist & Sleep Specialist',
        doctorHandle: '@drsaisleep',
        doctorAvatar: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300',
        title: 'Fall Asleep in 7 Minutes: Military Method',
        caption: 'Physiological sigh technique that activates parasympathetic nervous system and resets cortisol spikes before bedtime.',
        taggedProductId: 'MED-08', // Pantoprazole 40mg Nighttime Calm
        likesCount: 72100,
        commentsCount: 3800,
        sharesCount: 22400,
        tags: ['#SleepBetter', '#InsomniaRelief', '#MentalCalm'],
      ),
      DoctorReelModel(
        id: 'reel_e9e4e1e8',
        filename: '_e9e4e1e8_1.mp4',
        videoAsset: 'assets/reels/_e9e4e1e8_1.mp4',
        videoPath: '$basePath\\_e9e4e1e8_1.mp4',
        doctorName: 'Dr. Sunita Deshmukh',
        doctorSpecialty: 'Gynecologist & Obstetrician',
        doctorHandle: '@drsunitagynae',
        doctorAvatar: 'https://images.unsplash.com/photo-1594824813560-5a3d0f04c622?auto=format&fit=crop&q=80&w=300',
        title: 'Iron & Hemoglobin Booster Secrets',
        caption: 'Why drinking tea or coffee right after meals blocks 80% of iron absorption. When and how to take iron supplements.',
        taggedProductId: 'MED-06', // Vitamin C (triples Iron Absorption)
        likesCount: 44100,
        commentsCount: 1620,
        sharesCount: 7800,
        tags: ['#WomensHealth', '#AnemiaPrevention', '#Hemoglobin'],
      ),
      DoctorReelModel(
        id: 'reel_ed149c35',
        filename: '_ed149c35_1.mp4',
        videoAsset: 'assets/reels/_ed149c35_1.mp4',
        videoPath: '$basePath\\_ed149c35_1.mp4',
        doctorName: 'Dr. Venkat Rao',
        doctorSpecialty: 'Pulmonologist & Chest Physician',
        doctorHandle: '@drvenkatpulmo',
        doctorAvatar: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=300',
        title: 'Asthma Inhaler Technique Check',
        caption: '9 out of 10 asthma patients inhale too fast and medication stays on tongue. Why a spacer chamber doubles lung delivery.',
        taggedProductId: 'MED-03', // Cough Relief Syrup
        likesCount: 31000,
        commentsCount: 840,
        sharesCount: 4900,
        tags: ['#AsthmaCare', '#LungsHealth', '#InhalerSpacer'],
      ),
    ];

    _reels.addAll(initialReels);
    _loadPersistedAdminTags();
  }

  Future<void> _loadPersistedAdminTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_taggedProductsPrefKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(raw);
        for (var i = 0; i < _reels.length; i++) {
          final reelId = _reels[i].id;
          if (map.containsKey(reelId)) {
            final prodId = map[reelId]?.toString();
            _reels[i].taggedProductId = (prodId == null || prodId.isEmpty) ? null : prodId;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading persisted admin reel tags: $e');
    }
  }

  /// Admin Functionality: Tag or Untag a product on any doctor reel
  Future<void> tagProductToReel(String reelId, String? productId) async {
    final idx = _reels.indexWhere((r) => r.id == reelId);
    if (idx != -1) {
      _reels[idx].taggedProductId = productId;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_taggedProductsPrefKey);
        Map<String, dynamic> map = {};
        if (raw != null && raw.isNotEmpty) {
          map = jsonDecode(raw);
        }
        if (productId != null && productId.isNotEmpty) {
          map[reelId] = productId;
        } else {
          map.remove(reelId);
        }
        await prefs.setString(_taggedProductsPrefKey, jsonEncode(map));
      } catch (e) {
        debugPrint('Error saving admin tagged product: $e');
      }
    }
  }

  void toggleLike(String reelId) {
    final idx = _reels.indexWhere((r) => r.id == reelId);
    if (idx != -1) {
      final reel = _reels[idx];
      if (reel.isLiked) {
        reel.isLiked = false;
        reel.likesCount = (reel.likesCount - 1).clamp(0, 9999999);
      } else {
        reel.isLiked = true;
        reel.likesCount += 1;
      }
      notifyListeners();
    }
  }

  void toggleSave(String reelId) {
    final idx = _reels.indexWhere((r) => r.id == reelId);
    if (idx != -1) {
      _reels[idx].isSaved = !_reels[idx].isSaved;
      notifyListeners();
    }
  }

  void addComment(String reelId, String author, String text) {
    if (text.trim().isEmpty) return;
    final idx = _reels.indexWhere((r) => r.id == reelId);
    if (idx != -1) {
      _reels[idx].comments.insert(
        0,
        ReelComment(
          id: 'c_${DateTime.now().millisecondsSinceEpoch}',
          author: author.isEmpty ? 'Patient' : author,
          text: text.trim(),
          time: DateTime.now(),
        ),
      );
      _reels[idx].commentsCount += 1;
      notifyListeners();
    }
  }

  DoctorReelModel? getReel(String id) {
    try {
      return _reels.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
