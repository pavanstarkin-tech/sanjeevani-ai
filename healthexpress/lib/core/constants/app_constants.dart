enum UserRole {
  user,
  doctor,
  admin,
  store,
}

enum ConsultationType {
  clinicVisit,
  videoConsult,
  homeVisitRMP,
}

extension ConsultationTypeExtension on ConsultationType {
  String get displayName {
    switch (this) {
      case ConsultationType.clinicVisit:
        return 'In-Clinic Visit';
      case ConsultationType.videoConsult:
        return 'Video Consult';
      case ConsultationType.homeVisitRMP:
        return 'Home Visit (RMP)';
    }
  }

  String get shortName {
    switch (this) {
      case ConsultationType.clinicVisit:
        return 'In Clinic';
      case ConsultationType.videoConsult:
        return 'Video Call';
      case ConsultationType.homeVisitRMP:
        return 'Home Visit';
    }
  }
}

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
  refunded,
  failed,
}

enum TicketPriority {
  low,
  medium,
  high,
}

enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed,
}

enum DeliveryStatus {
  orderConfirmed,
  packed,
  outForDelivery,
  delivered,
}

class AppConstants {
  static const String appName = 'HealthExpress AI';
  static const String appTagline = 'AI-Powered. Personalized. Always with you.';
  static const double platformFee = 50.0;
  static const String defaultCurrency = '₹';
  static const String emergencyHelpline = '108';
}
