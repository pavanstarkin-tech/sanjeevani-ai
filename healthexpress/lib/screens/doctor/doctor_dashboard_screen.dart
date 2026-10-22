import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_portal_provider.dart';
import '../../services/central_data_service.dart';
import 'doctor_patient_qr_scanner_screen.dart';
import 'doctor_booking_requests_screen.dart';
import 'doctor_earnings_screen.dart';
import 'doctor_consultation_notes_screen.dart';
import '../user/video_consultation_screen.dart';
import '../user/chat_screen.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final doctor = auth.currentDoctor;
    final doctorProv = context.watch<DoctorPortalProvider>();
    final activeEmergency = CentralDataService.instance.activeEmergency;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Header Bar with Online/Offline Toggle (Matching Reference Image 2)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(doctor.photoUrl),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('${doctor.specialty} • ${doctor.hospitalName}', style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: doctor.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: doctor.isOnline ? AppColors.success : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  doctor.isOnline ? 'Active Online' : 'Offline',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: doctor.isOnline ? AppColors.success : Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: doctor.isOnline,
                      activeThumbColor: AppColors.success,
                      onChanged: (_) => auth.toggleDoctorOnlineStatus(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active Emergency SOS Alert Banner for Casualty Doctors
              if (activeEmergency != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.emergency, width: 2),
                    boxShadow: [
                      BoxShadow(color: AppColors.emergency.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppColors.emergency, shape: BoxShape.circle),
                            child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('🚨 INCOMING CASUALTY SOS DISPATCH', style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.w900, fontSize: 13)),
                                Text('Emergency ambulance en-route to KIMS Trauma', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.emergency, borderRadius: BorderRadius.circular(6)),
                            child: Text(activeEmergency.etaMinutes, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Patient: ${activeEmergency.patientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Phone: ${activeEmergency.patientPhone} • Location: ${activeEmergency.location}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.emergency,
                                    content: Text('Calling patient ${activeEmergency.patientName} (${activeEmergency.patientPhone})...'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 16),
                              label: const Text('Call Patient SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emergency,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                CentralDataService.instance.resolveEmergency(activeEmergency.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Emergency marked as Admitted to Trauma Unit')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: const BorderSide(color: AppColors.emergency),
                              ),
                              child: const Text('Mark Admitted', style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Metric Stats Row (Appointments, Completed, Earnings)
              Row(
                children: [
                  Expanded(
                    child: _DoctorStatCard(
                      value: '${doctorProv.todayAppointmentsCount}',
                      label: "Today's Appts",
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DoctorStatCard(
                      value: '${doctorProv.completedAppointmentsCount}',
                      label: 'Completed',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DoctorStatCard(
                      value: '₹${doctorProv.todayEarnings.toInt()}',
                      label: "Today's Earnings",
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Actions Bar (Appointments, Earnings, Scan QR, Reviews)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickToolButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan Patient QR',
                    color: const Color(0xFF0F766E),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorPatientQrScannerScreen())),
                  ),
                  _QuickToolButton(
                    icon: Icons.calendar_today_rounded,
                    label: 'Booking Queue',
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorBookingRequestsScreen())),
                  ),
                  _QuickToolButton(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Earnings Ledger',
                    color: Colors.purple,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorEarningsScreen())),
                  ),
                  _QuickToolButton(
                    icon: Icons.rate_review_rounded,
                    label: '4.8 (350+)',
                    color: Colors.amber,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's Appointments Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's Appointments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorBookingRequestsScreen())),
                    child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dynamic Appointment List Items from Central Shared State
              if (doctorProv.doctorAppointments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('No appointments scheduled for today.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                ...doctorProv.doctorAppointments.take(4).map((appt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DoctorAppointmentTile(
                      time: appt.timeSlot,
                      patientName: appt.userName,
                      aarogyasriId: appt.aarogyasriId.isNotEmpty ? appt.aarogyasriId : 'AROG-VERIFIED',
                      type: appt.type == ConsultationType.videoConsult
                          ? 'Video Consult'
                          : (appt.type == ConsultationType.homeVisitRMP ? 'Home Visit RMP' : 'In Clinic'),
                      symptoms: appt.symptomsSummary.isNotEmpty ? appt.symptomsSummary : 'Routine health review',
                      appointment: appt,
                    ),
                  );
                }),
              const SizedBox(height: 10),
              const SizedBox(height: 20),

              // Bottom View Full Schedule Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorBookingRequestsScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('View All Appointments & Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _DoctorStatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuickToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickToolButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorAppointmentTile extends StatelessWidget {
  final String time;
  final String patientName;
  final String aarogyasriId;
  final String type;
  final String symptoms;
  final AppointmentModel appointment;

  const _DoctorAppointmentTile({
    required this.time,
    required this.patientName,
    required this.aarogyasriId,
    required this.type,
    required this.symptoms,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 8),
                  Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                child: const Text('Confirmed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(patientName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text('Aarogyasri ID: $aarogyasriId', style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
          Text(symptoms, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                  label: const Text('Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(appointment: appointment))),
                ),
              ),
              const SizedBox(width: 8),
              if (type == 'Video Consult') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.videocam_rounded, size: 14, color: Colors.white),
                    label: const Text('Join Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 8)),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoConsultationScreen(appointment: appointment))),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note_rounded, size: 14, color: Colors.white),
                    label: const Text('Prescribe', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), padding: const EdgeInsets.symmetric(vertical: 8)),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DoctorConsultationNotesScreen(appointment: appointment))),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
