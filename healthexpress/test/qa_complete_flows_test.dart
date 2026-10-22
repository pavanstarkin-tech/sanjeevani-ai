import 'package:flutter_test/flutter_test.dart';
import 'package:healthexpress/core/constants/app_constants.dart';
import 'package:healthexpress/models/user_model.dart';
import 'package:healthexpress/models/doctor_model.dart';
import 'package:healthexpress/models/medicine_model.dart';
import 'package:healthexpress/models/appointment_model.dart';
import 'package:healthexpress/services/central_data_service.dart';
import 'package:healthexpress/services/dynamic_issue_suggestion_service.dart';
import 'package:healthexpress/providers/auth_provider.dart';
import 'package:healthexpress/providers/appointment_provider.dart';
import 'package:healthexpress/providers/pharmacy_provider.dart';
import 'package:healthexpress/providers/ai_assistant_provider.dart';
import 'package:healthexpress/providers/emergency_sos_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Auth & Real User State QA Tests', () {
    test('Initial user is clean and empty with zero fake vitals', () {
      final auth = AuthProvider();
      final user = auth.currentUser;

      expect(user.id, isEmpty);
      expect(user.name, isEmpty);
      expect(user.phone, isEmpty);
      expect(user.temperatureF, equals(0.0));
      expect(user.heartRateBpm, equals(0));
      expect(user.oxygenSpo2, equals(0));
      expect(user.weightKg, equals(0.0));
      expect(user.heightCm, equals(0.0));
    });

    test('Onboarding updates user profile with real details', () {
      final auth = AuthProvider();
      auth.completeUserOnboarding(
        name: 'Sumanth Rao',
        phone: '9848099112',
        email: 'sumanth.rao@test.com',
        bloodGroup: 'B+ Positive',
        aarogyasriId: 'AROG-TG-99881',
        age: 34,
        gender: 'Male',
        address: 'Banjara Hills Rd 12, Hyderabad',
        allergies: 'None recorded',
        chronicConditions: 'Asthma',
      );

      final updated = auth.currentUser;
      expect(updated.name, equals('Sumanth Rao'));
      expect(updated.phone, equals('9848099112'));
      expect(updated.bloodGroup, equals('B+ Positive'));
      expect(updated.aarogyasriId, equals('AROG-TG-99881'));
      expect(updated.age, equals(34));
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isOnboarded, isTrue);
    });

    test('Recording real vitals updates and calculates correctly', () {
      final auth = AuthProvider();
      auth.completeUserOnboarding(
        name: 'Sumanth Rao',
        phone: '9848099112',
        email: 'sumanth.rao@test.com',
        bloodGroup: 'B+ Positive',
        aarogyasriId: 'AROG-TG-99881',
        age: 34,
        gender: 'Male',
        address: 'Hyderabad',
      );

      auth.updateVitals(
        temperatureF: 98.6,
        heartRateBpm: 72,
        oxygenSpo2: 99,
        weightKg: 70.0,
        heightCm: 175.0,
      );

      final user = auth.currentUser;
      expect(user.temperatureF, equals(98.6));
      expect(user.heartRateBpm, equals(72));
      expect(user.oxygenSpo2, equals(99));
      expect(user.weightKg, equals(70.0));
      expect(user.heightCm, equals(175.0));

      // BMI calculation verification
      final hMeter = user.heightCm / 100;
      final bmi = user.weightKg / (hMeter * hMeter);
      expect(bmi, closeTo(22.85, 0.05)); // Normal weight range
    });
  });

  group('2. AI Symptom Analysis & Dynamic Clinical Engine QA Tests', () {
    test('Dynamic suggestions generate accurate recommendations for respiratory issues', () {
      final suggestions = DynamicIssueSuggestionService.getSuggestionsForIssue(
        'I have severe cough, fever and throat irritation since 2 days',
      );

      expect(suggestions.specialists, isNotEmpty);
      expect(suggestions.medicines, isNotEmpty);
      expect(suggestions.labPackages, isNotEmpty);
      expect(suggestions.actionChips, isNotEmpty);
      expect(suggestions.quickCareTips, isNotEmpty);

      // Verify specialist matches condition
      expect(suggestions.specialists.any((s) => s.toLowerCase().contains('pulmon') || s.toLowerCase().contains('general')), isTrue);
    });

    test('Dynamic suggestions generate accurate recommendations for chest pain & cardiac symptoms', () {
      final suggestions = DynamicIssueSuggestionService.getSuggestionsForIssue(
        'Chest pain and breathlessness while walking',
      );

      expect(suggestions.specialists.any((s) => s.toLowerCase().contains('cardio')), isTrue);
      expect(suggestions.labPackages.any((l) => l.toLowerCase().contains('ecg') || l.toLowerCase().contains('cardiac') || l.toLowerCase().contains('lipid')), isTrue);
    });

    test('Dynamic suggestions handle stomach/digestive issues', () {
      final suggestions = DynamicIssueSuggestionService.getSuggestionsForIssue(
        'Acidity, stomach burning sensation and gastric pain after meal',
      );

      expect(suggestions.specialists.any((s) => s.toLowerCase().contains('gastro')), isTrue);
      expect(suggestions.medicines.any((m) => m.toLowerCase().contains('pantoprazole') || m.toLowerCase().contains('digene') || m.toLowerCase().contains('antacid')), isTrue);
    });
  });

  group('3. Doctor & Hospital Booking Session QA Tests', () {
    test('Creating a booking assigns real user ID and calculates Aarogyasri subsidy', () {
      final appointmentProv = AppointmentProvider();
      final doctor = DoctorModel(
        id: 'DOC-TEST-01',
        name: 'Dr. Ramesh Reddy',
        specialty: 'Cardiologist',
        hospitalId: 'HOSP-01',
        hospitalName: 'KIMS Hospitals',
        location: 'Secunderabad',
        experienceYears: 18,
        rating: 4.9,
        reviewCount: 340,
        clinicFee: 800.0,
        videoFee: 600.0,
        homeVisitFee: 1200.0,
        isOnline: true,
        photoUrl: '',
        availableSlots: ['10:00 AM', '11:30 AM'],
      );

      // Book with Aarogyasri discount applied
      final booking = appointmentProv.createBooking(
        userId: 'USR-SUMANTH-99',
        doctor: doctor,
        date: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '10:00 AM',
        type: ConsultationType.clinicVisit,
        applyAarogyasri: true,
        userName: 'Sumanth Rao',
        userPhone: '9848099112',
        aarogyasriId: 'AROG-TG-99881',
      );

      expect(booking.userId, equals('USR-SUMANTH-99'));
      expect(booking.userName, equals('Sumanth Rao'));
      expect(booking.doctorName, equals('Dr. Ramesh Reddy'));
      expect(booking.status, equals(AppointmentStatus.confirmed));

      // Fee with 50% Aarogyasri discount: 800 * 0.5 + 49 platform fee = 449.0
      expect(booking.totalAmount, equals(449.0));

      // CentralDataService synchronization
      final userAppts = appointmentProv.getAppointmentsForUser('USR-SUMANTH-99');
      expect(userAppts.length, greaterThanOrEqualTo(1));
      expect(userAppts.any((a) => a.id == booking.id), isTrue);
    });
  });

  group('4. 10-Min Pharmacy & Medicine Delivery QA Tests', () {
    test('Cart additions, quantities, Aarogyasri discount and order checkout flow', () {
      final pharmacyProv = PharmacyProvider();
      final medicine = MedicineModel(
        id: 'MED-TEST-01',
        name: 'Dolo 650mg Paracetamol',
        brand: 'Micro Labs',
        category: 'Fever & Pain Relief',
        price: 32.0,
        discountedPrice: 28.0,
        discountPercent: 12,
        requiresPrescription: false,
        deliveryTimeMinutes: 10,
        inStock: true,
        stripSize: '15 Tablets',
        composition: 'Paracetamol 650mg',
        imageUrl: '',
        description: 'For relief of fever and mild pain',
      );

      pharmacyProv.addToCart(medicine);
      expect(pharmacyProv.cartItems.length, equals(1));
      expect(pharmacyProv.cartTotal, equals(28.0));

      // Update quantity
      pharmacyProv.updateQuantity(medicine.id, 3);
      expect(pharmacyProv.cartItems.first.quantity, equals(3));
      expect(pharmacyProv.cartTotal, equals(84.0));

      // Place real order
      final order = pharmacyProv.placeOrder(
        userId: 'USR-SUMANTH-99',
        patientName: 'Sumanth Rao',
        patientPhone: '9848099112',
        address: 'Banjara Hills Rd 12, Hyderabad',
        paymentMethod: 'UPI / GPay',
      );

      expect(order, isNotNull);
      expect(order!.userId, equals('USR-SUMANTH-99'));
      expect(order.patientName, equals('Sumanth Rao'));
      expect(order.status, equals('confirmed'));
      expect(pharmacyProv.cartItems, isEmpty); // Cart cleared after checkout
    });
  });

  group('5. Emergency 108 SOS Dispatch QA Tests', () {
    test('SOS trigger creates active emergency dispatch', () {
      final emergencyProv = EmergencySosProvider();
      final user = UserModel.empty().copyWith(
        id: 'USR-SUMANTH-99',
        name: 'Sumanth Rao',
        phone: '9848099112',
        bloodGroup: 'B+ Positive',
        aarogyasriId: 'AROG-TG-99881',
      );

      emergencyProv.triggerSos(
        user: user,
        emergencyType: 'Chest Pain / Cardiac Arrest',
        latitude: 17.4399,
        longitude: 78.4983,
        address: 'Road No 12, Banjara Hills, Hyderabad',
      );

      expect(emergencyProv.hasActiveEmergency, isTrue);
      expect(emergencyProv.currentEmergency, isNotNull);
      expect(emergencyProv.currentEmergency!.patientName, equals('Sumanth Rao'));
      expect(emergencyProv.currentEmergency!.patientPhone, equals('9848099112'));
      expect(emergencyProv.currentEmergency!.emergencyType, contains('Cardiac'));
      expect(emergencyProv.currentEmergency!.ambulanceNumber, isNotEmpty);
    });
  });
}
