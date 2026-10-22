import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../providers/doctor_portal_provider.dart';
import '../user/video_consultation_screen.dart';
import '../user/chat_screen.dart';
import 'doctor_consultation_notes_screen.dart';
import 'doctor_patient_detail_screen.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final Set<String> _activeDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'};
  String _slotDuration = '30 Mins';
  String _bufferTime = '5 Mins';
  final String _startTime = '09:00 AM';
  final String _endTime = '08:00 PM';
  bool _isSaved = false;
  String _selectedFilter = 'All';

  final ScrollController _scrollController = ScrollController();
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void _saveSchedule() {
    setState(() {
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Doctor availability schedule updated & synced!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );

    // Smoothly scroll down to show the updated bookings list
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          480,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorPortalProvider>();
    final allAppointments = doctorProv.doctorAppointments;

    final filteredAppointments = allAppointments.where((a) {
      if (_selectedFilter == 'Video') return a.type == ConsultationType.videoConsult;
      if (_selectedFilter == 'Clinic') return a.type == ConsultationType.clinicVisit;
      if (_selectedFilter == 'RMP') return a.type == ConsultationType.homeVisitRMP;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Availability & Schedule',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF16A34A), size: 8),
                SizedBox(width: 6),
                Text('Slots Active', style: TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collapsible Availability & Shift Settings (Initially Collapsed)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF0F766E), size: 20),
                  ),
                  title: const Text(
                    'Configure Shift & Availability Settings',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${_activeDays.length} Days Active • $_startTime - $_endTime • $_slotDuration Slots',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  children: [
                    const Divider(height: 20),
                    // Working Days Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Working Days', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text('${_activeDays.length} Days Active', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Select the days you are available for hospital & online consultations.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _days.map((day) {
                              final isSelected = _activeDays.contains(day);
                              return FilterChip(
                                label: Text(day),
                                selected: isSelected,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _activeDays.add(day);
                                    } else {
                                      _activeDays.remove(day);
                                    }
                                  });
                                },
                                selectedColor: const Color(0xFFDCFCE7),
                                labelStyle: TextStyle(
                                  color: isSelected ? const Color(0xFF166534) : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: isSelected ? const Color(0xFF10B981) : AppColors.border),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Daily Timing Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daily Shift Hours', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Start Time', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      const SizedBox(height: 2),
                                      Text(_startTime, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('End Time', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      const SizedBox(height: 2),
                                      Text(_endTime, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Slot Configuration Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Slot Duration & Buffer', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          const Text('Consultation Slot Duration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Row(
                            children: ['15 Mins', '30 Mins', '45 Mins'].map((dur) {
                              final isSelected = _slotDuration == dur;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(dur),
                                  selected: isSelected,
                                  onSelected: (val) => setState(() => _slotDuration = dur),
                                  selectedColor: const Color(0xFF0F766E),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          const Text('Buffer Time Between Patients', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Row(
                            children: ['0 Mins', '5 Mins', '10 Mins'].map((buf) {
                              final isSelected = _bufferTime == buf;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(buf),
                                  selected: isSelected,
                                  onSelected: (val) => setState(() => _bufferTime = buf),
                                  selectedColor: const Color(0xFF0F766E),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save Schedule Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                        label: const Text('Save Availability Schedule', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white)),
                        onPressed: _saveSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------
            // BOOKINGS LIST SECTION (Shown on Schedule Page)
            // ----------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event_note_rounded, color: Color(0xFF0F766E), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scheduled Bookings',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${allAppointments.length} Total Patients in Queue',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isSaved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 14),
                        SizedBox(width: 4),
                        Text('Synced Live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
              ],
            ),
            const SizedBox(height: 12),

            // Booking Type Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab('All', allAppointments.length),
                  _buildFilterTab('Video', allAppointments.where((a) => a.type == ConsultationType.videoConsult).length),
                  _buildFilterTab('Clinic', allAppointments.where((a) => a.type == ConsultationType.clinicVisit).length),
                  _buildFilterTab('RMP', allAppointments.where((a) => a.type == ConsultationType.homeVisitRMP).length),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Bookings List Items
            if (filteredAppointments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded, size: 44, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No Bookings in this Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Patient appointments will reflect here as new slots are booked.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredAppointments.length,
                itemBuilder: (context, index) {
                  final appt = filteredAppointments[index];
                  return _BookingCard(appointment: appt);
                },
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0F766E) : AppColors.border),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _BookingCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData typeIcon;
    switch (appointment.type) {
      case ConsultationType.videoConsult:
        typeColor = AppColors.primary;
        typeIcon = Icons.videocam_rounded;
        break;
      case ConsultationType.clinicVisit:
        typeColor = const Color(0xFF0F766E);
        typeIcon = Icons.local_hospital_rounded;
        break;
      case ConsultationType.homeVisitRMP:
        typeColor = Colors.orange.shade800;
        typeIcon = Icons.health_and_safety_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Patient Name & Type Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    child: Text(
                      appointment.userName.isNotEmpty ? appointment.userName[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.userName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, size: 13, color: Color(0xFF0F766E)),
                          const SizedBox(width: 4),
                          Text(
                            appointment.aarogyasriId.isNotEmpty ? appointment.aarogyasriId : 'AAROGYA-TG-VERIFIED',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, size: 13, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      appointment.type.shortName,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: typeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Slot Time & Token ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('dd MMM').format(appointment.dateTime)} • ${appointment.timeSlot}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Slot ID: ${appointment.id}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // AI Symptom Summary Card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Symptoms: ${appointment.symptomsSummary}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              // Chat Button
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                  label: const Text('Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChatScreen(appointment: appointment)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Join Call / Prescribe Button
              if (appointment.type == ConsultationType.videoConsult) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.videocam_rounded, size: 15, color: Colors.white),
                    label: const Text('Join Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => VideoConsultationScreen(appointment: appointment)),
                      );
                    },
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note_rounded, size: 15, color: Colors.white),
                    label: const Text('Consult & Rx', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DoctorConsultationNotesScreen(appointment: appointment)),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(width: 8),

              // View Patient Records
              IconButton(
                icon: const Icon(Icons.person_search_rounded, color: Color(0xFF0F766E), size: 20),
                tooltip: 'View Patient Records',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final patientObj = UserModel(
                    id: appointment.userId,
                    name: appointment.userName,
                    email: 'patient.${appointment.userId.toLowerCase()}@healthyxpress.in',
                    phone: appointment.userPhone,
                    joinedDate: DateTime(2024, 1, 15),
                    aarogyasriId: appointment.aarogyasriId.isNotEmpty ? appointment.aarogyasriId : 'AROG-VERIFIED-99',
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
                        appointment: appointment,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
