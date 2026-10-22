import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import 'user_main_nav.dart';
import 'appointment_detail_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final AppointmentModel appointment;
  const BookingConfirmationScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // 3D Success Celebration Box
              Container(
                height: 120,
                width: 120,
                margin: const EdgeInsets.only(bottom: 8),
                child: Image.asset(
                  AppIllustrations.orderSuccessBox,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Booking ID: ${appointment.id}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Booking Details Ticket Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Doctor Info Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(appointment.doctorPhoto),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appointment.doctorName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text(appointment.doctorSpecialty, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                              Text(appointment.hospitalName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 16),

                    // Date, Time & Consultation Mode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailItem(label: 'Date', value: DateFormat('dd MMM yyyy').format(appointment.dateTime)),
                        _DetailItem(label: 'Time Slot', value: appointment.timeSlot),
                        _DetailItem(label: 'Type', value: appointment.type.shortName),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailItem(label: 'Patient', value: appointment.userName),
                        _DetailItem(label: 'Aarogyasri ID', value: appointment.aarogyasriId),
                        _DetailItem(label: 'Status', value: 'Paid (₹${appointment.totalAmount.toInt()})'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 16),

                    // QR Code Pass for Hospital Check-in
                    const Text('Digital Check-in / Doctor Scan Pass', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: QrImageView(
                        data: 'HEAL-APPOINTMENT:${appointment.id}:${appointment.aarogyasriId}',
                        version: QrVersions.auto,
                        size: 130,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Scan at hospital desk or with doctor app', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: appointment)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('View Appointment Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const UserMainNav(initialIndex: 1)),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Go to My Appointments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
