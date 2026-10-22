import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/pharmacy_provider.dart';
import 'chat_screen.dart';
import 'video_consultation_screen.dart';
import 'audio_call_screen.dart';
import 'order_tracking_screen.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final AppointmentModel appointment;
  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Appointment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & ID Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking ID: ${appointment.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Booked on ${DateFormat('dd MMM yyyy, hh:mm a').format(appointment.createdAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: appointment.status == AppointmentStatus.completed ? const Color(0xFFDCFCE7) : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: appointment.status == AppointmentStatus.completed ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Doctor Information Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(appointment.doctorPhoto),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appointment.doctorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text(appointment.doctorSpecialty, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(appointment.hospitalName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),

                  // Quick Communication Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(appointment: appointment)));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.phone_rounded, size: 16),
                          label: const Text('Audio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => AudioCallScreen(appointment: appointment)));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.videocam_rounded, size: 16, color: Colors.white),
                          label: const Text('Video', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoConsultationScreen(appointment: appointment)));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Schedule & Consultation Mode
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consultation Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(DateFormat('EEEE, dd MMMM yyyy').format(appointment.dateTime), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('${appointment.timeSlot} • ${appointment.type.displayName}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Shared Patient Health Records Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Patient Medical Record Access', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Aarogyasri ID: ${appointment.aarogyasriId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Reported symptoms: ${appointment.symptomsSummary}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Doctor Prescription (if available)
            if (appointment.prescription.isNotEmpty || appointment.doctorNotes != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text('Doctor Prescription & Clinical Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    if (appointment.doctorNotes != null) ...[
                      const SizedBox(height: 8),
                      Text(appointment.doctorNotes!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                    ],
                    if (appointment.prescription.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Prescribed Medications:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      for (final rx in appointment.prescription)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.medication_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('${rx.medicineName} • ${rx.dosage} (${rx.duration})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 18),
                          label: const Text(
                            'Order Prescribed Medicines (15-Min Delivery)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onPressed: () {
                            context.read<PharmacyProvider>().placeOrder();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Payment Receipt Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Consultation Fee', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('₹${appointment.consultationFee.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Platform Fee', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('₹${appointment.platformFee.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (appointment.aarogyasriApplied) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Aarogyasri Health Subsidy', style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
                        Text('-₹${appointment.discountAmount.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Paid', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('₹${appointment.totalAmount.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cancel Button (if active)
            if (appointment.status == AppointmentStatus.confirmed)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    final prov = context.read<AppointmentProvider>();
                    prov.cancelAppointment(appointment.id);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appointment cancelled. Refund initiated to source.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel Appointment & Refund', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
