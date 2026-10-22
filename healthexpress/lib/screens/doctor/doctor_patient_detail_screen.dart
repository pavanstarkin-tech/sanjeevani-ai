import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import 'doctor_consultation_notes_screen.dart';

class DoctorPatientDetailScreen extends StatelessWidget {
  final UserModel patient;
  final AppointmentModel? appointment;
  const DoctorPatientDetailScreen({super.key, required this.patient, this.appointment});

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
        title: const Text('Verified Patient Health File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Verified Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage((patient.profilePhoto != null && patient.profilePhoto!.isNotEmpty)
                            ? patient.profilePhoto!
                            : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400'),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Aarogyasri ID: ${patient.aarogyasriId}', style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${patient.age > 0 ? '${patient.age} yrs' : 'Age Unspecified'} • ${patient.gender.isNotEmpty ? patient.gender : 'Gender N/A'} • +91 ${patient.phone.isNotEmpty ? patient.phone : 'Not provided'}',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (patient.email.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Text(patient.email, style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Patient Address & Location
            const Text('Residential & Delivery Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Registered Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          patient.address.isNotEmpty ? patient.address : 'No address recorded on file.',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Emergency Contact Person Card
            const Text('Emergency Contact & Next of Kin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.contact_phone_rounded, color: Colors.red, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.emergencyContactName.isNotEmpty
                              ? '${patient.emergencyContactName} (${patient.emergencyContactRelation.isNotEmpty ? patient.emergencyContactRelation : 'Kin'})'
                              : 'Emergency Contact Person',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          patient.emergencyContactPhone.isNotEmpty
                              ? '+91 ${patient.emergencyContactPhone}'
                              : '108 Govt Emergency Dispatch Linked',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: patient.emergencyContactPhone.isNotEmpty ? Colors.red.shade700 : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Critical Clinical Profile (Blood Group, Allergies, Surgeries)
            const Text('Clinical Profile & Medical History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Blood Group', value: patient.bloodGroup, isHighlight: true),
                  const Divider(height: 16, color: AppColors.border),
                  _InfoRow(label: 'Known Allergies', value: patient.allergies),
                  const Divider(height: 16, color: AppColors.border),
                  _InfoRow(label: 'Chronic Ailments', value: patient.chronicConditions),
                  const Divider(height: 16, color: AppColors.border),
                  _InfoRow(label: 'Past Surgeries & Procedures', value: patient.pastSurgeries),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Patient Live Vitals
            const Text('Recorded Health Vitals', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniVitalBox(
                    label: 'Temp',
                    value: patient.temperatureF > 0 ? '${patient.temperatureF}°F' : '--',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniVitalBox(
                    label: 'Pulse',
                    value: patient.heartRateBpm > 0 ? '${patient.heartRateBpm} bpm' : '--',
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniVitalBox(
                    label: 'SpO2',
                    value: patient.oxygenSpo2 > 0 ? '${patient.oxygenSpo2}%' : '--',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniVitalBox(
                    label: 'Weight',
                    value: patient.weightKg > 0 ? '${patient.weightKg.toInt()} kg' : '--',
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Previous Lab Reports List
            const Text('Diagnostic Lab Reports', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: const [
                  _DocReportRow(title: 'Complete Blood Count (CBC)', date: '18 May 2024', status: 'Normal Platelets (2.4L)'),
                  Divider(height: 16, color: AppColors.border),
                  _DocReportRow(title: 'Dengue NS1 Antigen Test', date: '18 May 2024', status: 'Negative'),
                  Divider(height: 16, color: AppColors.border),
                  _DocReportRow(title: 'Lipid Profile', date: '12 Jan 2024', status: 'Optimal Cholesterol'),
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
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 20, color: Colors.white),
              label: const Text('Add Clinical Notes & Digital Prescription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final targetAppt = appointment ??
                    AppointmentModel(
                      id: 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      userId: patient.id,
                      userName: patient.name,
                      userPhone: patient.phone,
                      aarogyasriId: patient.aarogyasriId,
                      doctorId: 'DOC-01',
                      doctorName: 'Dr. Sunil Kumar N',
                      doctorPhoto: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=400',
                      doctorSpecialty: 'Neurology',
                      hospitalId: 'HOSP-01',
                      hospitalName: 'KIMS Hospitals',
                      hospitalLocation: 'Secunderabad',
                      dateTime: DateTime.now(),
                      timeSlot: 'Live Consultation',
                      type: ConsultationType.clinicVisit,
                      status: AppointmentStatus.confirmed,
                      paymentStatus: PaymentStatus.paid,
                      consultationFee: 800,
                      platformFee: 49,
                      discountAmount: 0,
                      totalAmount: 849,
                      aarogyasriApplied: false,
                      symptomsSummary: 'Clinical Aarogyasri Evaluation',
                      meetingRoomId: 'ROOM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                      createdAt: DateTime.now(),
                    );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DoctorConsultationNotesScreen(appointment: targetAppt),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _InfoRow({required this.label, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isHighlight ? AppColors.emergency : AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _MiniVitalBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniVitalBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _DocReportRow extends StatelessWidget {
  final String title;
  final String date;
  final String status;

  const _DocReportRow({required this.title, required this.date, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        Text(status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
      ],
    );
  }
}
