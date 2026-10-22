import '../core/constants/app_constants.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String category; // Booking, Payment, Account, Doctor, Refund, App Issue
  final String subject;
  final String description;
  final TicketPriority priority;
  final TicketStatus status;
  final DateTime createdAt;
  final String? resolution;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.category,
    required this.subject,
    required this.description,
    this.priority = TicketPriority.medium,
    this.status = TicketStatus.open,
    required this.createdAt,
    this.resolution,
  });
}
