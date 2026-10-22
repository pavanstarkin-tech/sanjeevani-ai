import '../core/constants/app_constants.dart';

class PrescriptionItem {
  final String medicineName;
  final String dosage; // e.g. 1 tab after food
  final String duration; // e.g. 5 days
  final String instruction; // e.g. Morning & Night

  PrescriptionItem({
    required this.medicineName,
    required this.dosage,
    required this.duration,
    required this.instruction,
  });
}

class AppointmentModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String aarogyasriId;
  final String doctorId;
  final String doctorName;
  final String doctorPhoto;
  final String doctorSpecialty;
  final String hospitalId;
  final String hospitalName;
  final String hospitalLocation;
  final DateTime dateTime;
  final String timeSlot;
  final ConsultationType type;
  final AppointmentStatus status;
  final PaymentStatus paymentStatus;
  final double consultationFee;
  final double platformFee;
  final double discountAmount;
  final double totalAmount;
  final bool aarogyasriApplied;
  final String symptomsSummary;
  final String? doctorNotes;
  final List<PrescriptionItem> prescription;
  final List<String> recommendedTests;
  final String meetingRoomId;
  final DateTime createdAt;
  final bool isRecurring;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.aarogyasriId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorPhoto,
    required this.doctorSpecialty,
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalLocation,
    required this.dateTime,
    required this.timeSlot,
    required this.type,
    this.status = AppointmentStatus.confirmed,
    this.paymentStatus = PaymentStatus.paid,
    required this.consultationFee,
    this.platformFee = 50.0,
    this.discountAmount = 0.0,
    required this.totalAmount,
    this.aarogyasriApplied = false,
    this.symptomsSummary = 'Fever, sore throat, and mild headache',
    this.doctorNotes,
    this.prescription = const [],
    this.recommendedTests = const [],
    required this.meetingRoomId,
    required this.createdAt,
    this.isRecurring = false,
  });

  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? aarogyasriId,
    String? doctorId,
    String? doctorName,
    String? doctorPhoto,
    String? doctorSpecialty,
    String? hospitalId,
    String? hospitalName,
    String? hospitalLocation,
    DateTime? dateTime,
    String? timeSlot,
    ConsultationType? type,
    AppointmentStatus? status,
    PaymentStatus? paymentStatus,
    double? consultationFee,
    double? platformFee,
    double? discountAmount,
    double? totalAmount,
    bool? aarogyasriApplied,
    String? symptomsSummary,
    String? doctorNotes,
    List<PrescriptionItem>? prescription,
    List<String>? recommendedTests,
    String? meetingRoomId,
    DateTime? createdAt,
    bool? isRecurring,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      aarogyasriId: aarogyasriId ?? this.aarogyasriId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorPhoto: doctorPhoto ?? this.doctorPhoto,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalLocation: hospitalLocation ?? this.hospitalLocation,
      dateTime: dateTime ?? this.dateTime,
      timeSlot: timeSlot ?? this.timeSlot,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      consultationFee: consultationFee ?? this.consultationFee,
      platformFee: platformFee ?? this.platformFee,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      aarogyasriApplied: aarogyasriApplied ?? this.aarogyasriApplied,
      symptomsSummary: symptomsSummary ?? this.symptomsSummary,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      prescription: prescription ?? this.prescription,
      recommendedTests: recommendedTests ?? this.recommendedTests,
      meetingRoomId: meetingRoomId ?? this.meetingRoomId,
      createdAt: createdAt ?? this.createdAt,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }
}
