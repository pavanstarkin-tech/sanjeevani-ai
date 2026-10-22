import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/appointment_model.dart';
import '../models/doctor_model.dart';
import '../services/central_data_service.dart';
import '../services/api_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final CentralDataService _central = CentralDataService.instance;

  AppointmentProvider() {
    _central.addListener(_onCentralChanged);
  }

  void _onCentralChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _central.removeListener(_onCentralChanged);
    super.dispose();
  }

  List<AppointmentModel> get appointments => _central.appointments;

  List<AppointmentModel> get upcomingAppointments => _central.appointments
      .where((a) => a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.pending)
      .toList();

  List<AppointmentModel> get completedAppointments => _central.appointments
      .where((a) => a.status == AppointmentStatus.completed)
      .toList();

  List<AppointmentModel> get cancelledAppointments => _central.appointments
      .where((a) => a.status == AppointmentStatus.cancelled)
      .toList();

  // User-Specific Isolated Queries
  List<AppointmentModel> getAppointmentsForUser(String userId) {
    return _central.getUserAppointments(userId);
  }

  List<AppointmentModel> getUpcomingForUser(String userId) {
    return _central.getUserAppointments(userId)
        .where((a) => a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.pending)
        .toList();
  }

  List<AppointmentModel> getCompletedForUser(String userId) {
    return _central.getUserAppointments(userId)
        .where((a) => a.status == AppointmentStatus.completed)
        .toList();
  }

  List<AppointmentModel> getCancelledForUser(String userId) {
    return _central.getUserAppointments(userId)
        .where((a) => a.status == AppointmentStatus.cancelled)
        .toList();
  }

  AppointmentModel? getNextUpcomingForUser(String userId) {
    final list = getUpcomingForUser(userId);
    if (list.isEmpty) return null;
    return list.first;
  }

  AppointmentModel? getNextUpcoming() {
    final upcoming = upcomingAppointments;
    if (upcoming.isEmpty) return null;
    return upcoming.first;
  }

  AppointmentModel createBooking({
    required String userId,
    required DoctorModel doctor,
    required DateTime date,
    required String timeSlot,
    required ConsultationType type,
    required bool applyAarogyasri,
    required String userName,
    required String userPhone,
    required String aarogyasriId,
    bool isRecurring = false,
    String? symptomsSummary,
  }) {
    double fee = doctor.clinicFee;
    if (type == ConsultationType.videoConsult) fee = doctor.videoFee;
    if (type == ConsultationType.homeVisitRMP) fee = doctor.homeVisitFee;

    double discount = applyAarogyasri ? (fee * 0.5) : 0.0;
    double total = (fee - discount) + AppConstants.platformFee;

    final newBooking = AppointmentModel(
      id: 'BK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      aarogyasriId: aarogyasriId,
      doctorId: doctor.id,
      doctorName: doctor.name,
      doctorPhoto: doctor.photoUrl,
      doctorSpecialty: doctor.specialty,
      hospitalId: doctor.hospitalId,
      hospitalName: doctor.hospitalName,
      hospitalLocation: doctor.location,
      dateTime: date,
      timeSlot: timeSlot,
      type: type,
      status: AppointmentStatus.confirmed,
      paymentStatus: PaymentStatus.paid,
      consultationFee: fee,
      platformFee: AppConstants.platformFee,
      discountAmount: discount,
      totalAmount: total,
      aarogyasriApplied: applyAarogyasri,
      symptomsSummary: symptomsSummary ?? 'General Consultation & Health Evaluation',
      meetingRoomId: 'ROOM-HEAL-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      isRecurring: isRecurring,
    );

    _central.addAppointment(newBooking);

    // Sync to remote MySQL backend
    ApiService.bookAppointment(
      userId: userId,
      doctorId: doctor.id,
      hospitalId: doctor.hospitalId,
      appointmentDate: date.toIso8601String().split('T').first,
      timeSlot: timeSlot,
      type: type.name,
      fee: total,
      symptomsSummary: symptomsSummary,
      isAarogyasri: applyAarogyasri,
    );

    return newBooking;
  }

  bool rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTimeSlot,
  }) {
    final index = _central.appointments.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return false;

    _central.updateAppointmentStatus(appointmentId, AppointmentStatus.confirmed);
    return true;
  }

  bool cancelAppointment(String appointmentId) {
    _central.updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
    return true;
  }

  void addDoctorPrescription({
    required String appointmentId,
    required String doctorNotes,
    required List<PrescriptionItem> prescription,
    required List<String> recommendedTests,
  }) {
    _central.recordDoctorPrescription(
      appointmentId: appointmentId,
      doctorNotes: doctorNotes,
      prescription: prescription,
      recommendedTests: recommendedTests,
    );
  }
}
