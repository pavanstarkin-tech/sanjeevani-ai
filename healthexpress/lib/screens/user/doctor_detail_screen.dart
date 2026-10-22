import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/doctor_model.dart';
import 'book_appointment_screen.dart';

class DoctorDetailScreen extends StatelessWidget {
  final DoctorModel doctor;
  const DoctorDetailScreen({super.key, required this.doctor});

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
        title: const Text('Doctor Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(doctor.photoUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doctor.qualifications,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doctor.specialty,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('${doctor.experienceYears} Years Exp.', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            Text(' ${doctor.rating} ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('(${doctor.reviewCount} reviews)', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Hospital Affiliation Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hospital Affiliation', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        Text(
                          doctor.hospitalName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${doctor.location} • ${doctor.distanceKm} km away',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Consultation Modes Offered
            const Text('Consultation Modes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    icon: Icons.videocam_rounded,
                    title: 'Video Consult',
                    fee: '₹${doctor.videoFee.toInt()}',
                    isSupported: doctor.supportedTypes.contains(ConsultationType.videoConsult),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeCard(
                    icon: Icons.home_rounded,
                    title: 'Home Visit',
                    fee: '₹${doctor.homeVisitFee.toInt()}',
                    isSupported: doctor.supportedTypes.contains(ConsultationType.homeVisitRMP),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeCard(
                    icon: Icons.domain_rounded,
                    title: 'In Clinic',
                    fee: '₹${doctor.clinicFee.toInt()}',
                    isSupported: doctor.supportedTypes.contains(ConsultationType.clinicVisit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // About Doctor Bio
            const Text('About Doctor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                doctor.bio,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            // Working Hours & Slots
            const Text('Available Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Working Days', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(doctor.availableDays.join(', '), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Slot Times', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const Text('09:00 AM - 08:00 PM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BookAppointmentScreen(doctor: doctor)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Book Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String fee;
  final bool isSupported;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.fee,
    required this.isSupported,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isSupported ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSupported ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: isSupported ? AppColors.primary : AppColors.textMuted, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSupported ? AppColors.textPrimary : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            isSupported ? fee : 'N/A',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSupported ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
