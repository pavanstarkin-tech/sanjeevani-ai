import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../data/production_database.dart';
import '../services/central_data_service.dart';

class DoctorPortalProvider extends ChangeNotifier {
  final CentralDataService _central = CentralDataService.instance;

  DoctorPortalProvider() {
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

  // Consultation distribution
  final double inClinicPercent = 60.0;
  final double videoConsultPercent = 25.0;
  final double rmpVisitPercent = 15.0;

  UserModel? _scannedPatient;

  List<AppointmentModel> get doctorAppointments => _central.appointments;

  int get todayAppointmentsCount => _central.appointments
      .where((a) => a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.pending)
      .length;

  int get completedAppointmentsCount => _central.appointments
      .where((a) => a.status == AppointmentStatus.completed)
      .length;

  double get todayEarnings => _central.appointments
      .where((a) => a.status == AppointmentStatus.completed)
      .fold(0.0, (sum, a) => sum + (a.consultationFee > 0 ? a.consultationFee : 800.0));

  double get weeklyEarnings => todayEarnings > 0 ? todayEarnings * 5.0 : 0.0;
  double get monthlyEarnings => todayEarnings > 0 ? todayEarnings * 22.0 : 0.0;
  int get totalPatients => _central.appointments.map((a) => a.userId).toSet().length;
  UserModel? get scannedPatient => _scannedPatient;

  void acceptBooking(String appointmentId) {
    _central.updateAppointmentStatus(appointmentId, AppointmentStatus.confirmed);
  }

  void rejectBooking(String appointmentId) {
    _central.updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
  }

  UserModel lookupPatientByAarogyasriQR(String qrToken) {
    _scannedPatient = ProductionDatabase.findPatientByAarogyasriId(qrToken);
    notifyListeners();
    return _scannedPatient!;
  }

  void recordConsultation({
    required String appointmentId,
    required String clinicalNotes,
    required List<PrescriptionItem> medicines,
    required List<String> labTests,
  }) {
    _central.recordDoctorPrescription(
      appointmentId: appointmentId,
      doctorNotes: clinicalNotes,
      prescription: medicines,
      recommendedTests: labTests,
    );
  }
}
