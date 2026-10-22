import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/doctor_portal_provider.dart';

class DoctorConsultationNotesScreen extends StatefulWidget {
  final AppointmentModel appointment;
  const DoctorConsultationNotesScreen({super.key, required this.appointment});

  @override
  State<DoctorConsultationNotesScreen> createState() => _DoctorConsultationNotesScreenState();
}

class _DoctorConsultationNotesScreenState extends State<DoctorConsultationNotesScreen> {
  final _diagnosisController = TextEditingController(text: 'Acute Viral Pharyngitis with low-grade pyrexia.');
  final _adviceController = TextEditingController(text: 'Adequate hydration, warm saline gargle 3 times a day, avoid cold beverages.');
  
  final List<PrescriptionItem> _prescriptions = [
    PrescriptionItem(medicineName: 'Paracetamol 650mg', dosage: '1 tab after food', duration: '5 days', instruction: 'Morning & Night'),
    PrescriptionItem(medicineName: 'Cetirizine 10mg', dosage: '1 tab at bedtime', duration: '5 days', instruction: 'Night'),
    PrescriptionItem(medicineName: 'Vitamin C 500mg (Chewable)', dosage: '1 tab daily', duration: '15 days', instruction: 'After breakfast'),
  ];

  final _newMedNameController = TextEditingController();
  final _newDosageController = TextEditingController();

  void _addMedicine() {
    if (_newMedNameController.text.trim().isEmpty) return;
    setState(() {
      _prescriptions.add(
        PrescriptionItem(
          medicineName: _newMedNameController.text.trim(),
          dosage: _newDosageController.text.trim().isEmpty ? '1 tab after food' : _newDosageController.text.trim(),
          duration: '5 days',
          instruction: 'Twice daily',
        ),
      );
      _newMedNameController.clear();
      _newDosageController.clear();
    });
  }

  void _saveAndIssue() {
    final apptProv = context.read<AppointmentProvider>();
    final docProv = context.read<DoctorPortalProvider>();

    apptProv.addDoctorPrescription(
      appointmentId: widget.appointment.id,
      doctorNotes: _diagnosisController.text.trim(),
      prescription: _prescriptions,
      recommendedTests: ['Complete Blood Count (CBC)'],
    );

    docProv.recordConsultation(
      appointmentId: widget.appointment.id,
      clinicalNotes: _diagnosisController.text.trim(),
      medicines: _prescriptions,
      labTests: ['Complete Blood Count (CBC)'],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Digital Prescription signed and synced to Patient Health Records & Aarogyasri portal!'),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _adviceController.dispose();
    _newMedNameController.dispose();
    _newDosageController.dispose();
    super.dispose();
  }

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
        title: const Text('Digital Prescription & Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded, color: Color(0xFF0F766E), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Patient: ${widget.appointment.userName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('Aarogyasri ID: ${widget.appointment.aarogyasriId} • Booking: ${widget.appointment.id}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Clinical Diagnosis / Assessment
            const Text('Clinical Diagnosis / Assessment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _diagnosisController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Enter clinical diagnosis...'),
            ),
            const SizedBox(height: 20),

            // Prescribed Medicines Section
            const Text('Prescription (Rx)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                  ..._prescriptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                            child: const Icon(Icons.medication_rounded, size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.medicineName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                Text('${item.dosage} • ${item.duration} (${item.instruction})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            onPressed: () {
                              setState(() => _prescriptions.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 12, color: AppColors.border),
                  const SizedBox(height: 8),

                  // Add New Medicine Fields
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _newMedNameController,
                          decoration: const InputDecoration(
                            hintText: 'Medicine Name',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _newDosageController,
                          decoration: const InputDecoration(
                            hintText: 'Dosage',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addMedicine,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Advice & Dietary Instructions
            const Text('Clinical Advice & Dietary Guidelines', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _adviceController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Enter recovery advice...'),
            ),
            const SizedBox(height: 24),

            // Issue Prescription Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                label: const Text('Sign & Issue Digital Prescription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saveAndIssue,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
