import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/doctor_portal_provider.dart';
import 'doctor_patient_detail_screen.dart';
import 'doctor_consultation_notes_screen.dart';

class DoctorBookingRequestsScreen extends StatelessWidget {
  const DoctorBookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorPortalProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Patient Booking Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
      ),
      body: doctorProv.doctorAppointments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event_available_rounded, size: 50, color: Color(0xFF0F766E)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Booking Requests in Queue',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'When patients book in-clinic, video, or RMP consultations, they will appear here instantly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: doctorProv.doctorAppointments.length,
              itemBuilder: (context, index) {
                final appt = doctorProv.doctorAppointments[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Booking ID: ${appt.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                            child: Text('${DateFormat('dd MMM').format(appt.dateTime)}, ${appt.timeSlot}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(appt.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF0F766E)),
                          const SizedBox(width: 4),
                          Text('Aarogyasri ID: ${appt.aarogyasriId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F766E))),
                          const SizedBox(width: 8),
                          Text('• ${appt.type.shortName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'AI Symptom Summary: ${appt.symptomsSummary}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                final patientObj = UserModel(
                                  id: appt.userId,
                                  name: appt.userName,
                                  email: 'patient.${appt.userId.toLowerCase()}@healthyxpress.in',
                                  phone: appt.userPhone,
                                  joinedDate: DateTime(2024, 1, 15),
                                  aarogyasriId: appt.aarogyasriId.isNotEmpty ? appt.aarogyasriId : 'AROG-VERIFIED-99',
                                  bloodGroup: 'B+ Positive',
                                  allergies: 'None recorded',
                                  chronicConditions: 'Seasonal Rhinitis',
                                  pastSurgeries: 'None',
                                  heightCm: 172.0,
                                  weightKg: 68.0,
                                  temperatureF: 98.4,
                                  heartRateBpm: 74,
                                  oxygenSpo2: 99,
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DoctorPatientDetailScreen(
                                      patient: patientObj,
                                      appointment: appt,
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('View Patient Records', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => DoctorConsultationNotesScreen(appointment: appt)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Prescribe & Consult', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
