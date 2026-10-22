import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'health_qr_screen.dart';

import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/appointment_provider.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final apptProv = context.watch<AppointmentProvider>();
    final userAppointments = apptProv.getAppointmentsForUser(user.id);
    final completedAppointmentsWithRx = userAppointments
        .where((a) => a.status == AppointmentStatus.completed || a.prescription.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text('Health Records & Aarogyasri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthQrScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Digital Aarogyasri / RGIS Card (Matching Reference Image 2 & 3)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF1E60F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Aarogyasri (RGIS) Card',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('HEALTH CARD ID', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.2)),
                        Text(
                          user.aarogyasriId,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Scan at hospital or doctor app to access verified medical history.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthQrScreen()));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('View Full QR Pass', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Scannable Token QR Code Thumbnail
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthQrScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: QrImageView(
                        data: user.toAarogyasriQrPayload(),
                        version: QrVersions.auto,
                        size: 80,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Reports'),
                Tab(text: 'Prescriptions'),
                Tab(text: 'History'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Overview Details Grid (Matching Reference Image 2 & 3)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _MedicalInfoTile(
                        icon: Icons.bloodtype_rounded,
                        iconColor: Colors.red,
                        label: 'Blood Group',
                        value: user.bloodGroup,
                      ),
                      _MedicalInfoTile(
                        icon: Icons.warning_amber_rounded,
                        iconColor: Colors.orange,
                        label: 'Allergies',
                        value: user.allergies,
                      ),
                      _MedicalInfoTile(
                        icon: Icons.healing_rounded,
                        iconColor: Colors.purple,
                        label: 'Chronic Conditions',
                        value: user.chronicConditions,
                      ),
                      _MedicalInfoTile(
                        icon: Icons.medical_services_rounded,
                        iconColor: Colors.teal,
                        label: 'Past Surgeries & Operations',
                        value: user.pastSurgeries,
                      ),
                      _MedicalInfoTile(
                        icon: Icons.height_rounded,
                        iconColor: Colors.blue,
                        label: 'Height',
                        value: user.heightCm > 0 ? '${user.heightCm.toInt()} cm' : 'Not recorded',
                      ),
                      _MedicalInfoTile(
                        icon: Icons.monitor_weight_rounded,
                        iconColor: Colors.indigo,
                        label: 'Weight',
                        value: user.weightKg > 0 ? '${user.weightKg.toInt()} kg' : 'Not recorded',
                      ),
                    ],
                  ),
                ),

                // Tab 2: Lab Reports
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.biotech_rounded, size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text('No Diagnostic Reports Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        const Text(
                          'Verified digital reports from blood tests, scans, and health packages will appear here once ready.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab 3: Dynamic Prescriptions
                completedAppointmentsWithRx.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0FDF4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.medication_liquid_rounded, size: 48, color: AppColors.success),
                              ),
                              const SizedBox(height: 16),
                              const Text('No Digital Prescriptions Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              const Text(
                                'Digital prescriptions signed by doctors during consultations will sync automatically here with verified drug guidelines.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: completedAppointmentsWithRx.length,
                        itemBuilder: (context, index) {
                          final appt = completedAppointmentsWithRx[index];
                          final dateStr = DateFormat('dd MMM yyyy').format(appt.dateTime);
                          final medList = appt.prescription.isNotEmpty
                              ? appt.prescription.map((p) => '${p.medicineName} (${p.dosage}, ${p.duration})').toList()
                              : [(appt.doctorNotes != null && appt.doctorNotes!.isNotEmpty) ? appt.doctorNotes! : 'Consultation verified and advised.'];

                          return _PrescriptionCard(
                            doctorName: '${appt.doctorName} (${appt.doctorSpecialty})',
                            hospital: appt.hospitalName,
                            date: dateStr,
                            medicines: medList,
                          );
                        },
                      ),

                // Tab 4: History Timeline
                userAppointments.isEmpty
                    ? const Center(
                        child: Text('No past medical consultations on record.', style: TextStyle(color: AppColors.textMuted)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: userAppointments.length,
                        itemBuilder: (context, index) {
                          final appt = userAppointments[index];
                          final dateStr = DateFormat('dd MMM yyyy').format(appt.dateTime);
                          return _HistoryItem(
                            title: '${appt.type.shortName} Consultation',
                            doctor: appt.doctorName,
                            hospital: appt.hospitalName,
                            date: dateStr,
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalInfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MedicalInfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final String doctorName;
  final String hospital;
  final String date;
  final List<String> medicines;

  const _PrescriptionCard({required this.doctorName, required this.hospital, required this.date, required this.medicines});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
              Text(doctorName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          Text(hospital, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          ...medicines.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(m, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String title;
  final String doctor;
  final String hospital;
  final String date;

  const _HistoryItem({required this.title, required this.doctor, required this.hospital, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('$doctor • $hospital', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
