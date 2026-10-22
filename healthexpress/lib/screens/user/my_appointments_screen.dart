import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import 'appointment_detail_screen.dart';
import 'chat_screen.dart';
import 'video_consultation_screen.dart';
import 'doctor_search_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRescheduleDialog(AppointmentModel appt) {
    DateTime selectedDate = appt.dateTime.add(const Duration(days: 2));
    String selectedSlot = '11:00 AM';
    final hoursDiff = appt.dateTime.difference(DateTime.now()).inHours;
    final isWithin24h = hoursDiff < 24;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reschedule Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Rescheduling for ${appt.doctorName}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),

                  // Policy Alert Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isWithin24h ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isWithin24h ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        Icon(isWithin24h ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: isWithin24h ? AppColors.warning : AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isWithin24h
                                ? 'Rescheduling within 24h: 30% fee adjustment applies per doctor schedule policy.'
                                : 'Free reschedule available (More than 24 hours in advance).',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isWithin24h ? const Color(0xFF92400E) : const Color(0xFF166534)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Select New Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['09:30 AM', '11:00 AM', '02:30 PM', '05:00 PM'].map((s) {
                      final isSelected = selectedSlot == s;
                      return ChoiceChip(
                        label: Text(s),
                        selected: isSelected,
                        onSelected: (val) => setModalState(() => selectedSlot = s),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final prov = context.read<AppointmentProvider>();
                        prov.rescheduleAppointment(appointmentId: appt.id, newDate: selectedDate, newTimeSlot: selectedSlot);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Appointment rescheduled to ${DateFormat('dd MMM').format(selectedDate)} at $selectedSlot')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm Reschedule', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentProv = context.watch<AppointmentProvider>();
    final authProv = context.watch<AuthProvider>();
    final currentUserId = authProv.currentUser.id;

    final upcoming = appointmentProv.getUpcomingForUser(currentUserId);
    final completed = appointmentProv.getCompletedForUser(currentUserId);
    final cancelled = appointmentProv.getCancelledForUser(currentUserId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Appointments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Completed (${completed.length})'),
            Tab(text: 'Cancelled (${cancelled.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AppointmentsList(
            appointments: upcoming,
            onReschedule: _showRescheduleDialog,
          ),
          _AppointmentsList(
            appointments: completed,
            isCompleted: true,
          ),
          _AppointmentsList(
            appointments: cancelled,
            isCancelled: true,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Schedule Recurring Appointment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorSearchScreen()));
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentsList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final Function(AppointmentModel)? onReschedule;
  final bool isCompleted;
  final bool isCancelled;

  const _AppointmentsList({
    required this.appointments,
    this.onReschedule,
    this.isCompleted = false,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No appointments found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        return _AppointmentCard(
          appointment: appt,
          onReschedule: onReschedule != null ? () => onReschedule!(appt) : null,
          isCompleted: isCompleted,
          isCancelled: isCancelled,
        );
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onReschedule;
  final bool isCompleted;
  final bool isCancelled;

  const _AppointmentCard({
    required this.appointment,
    this.onReschedule,
    this.isCompleted = false,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Details & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(appointment.doctorPhoto),
              ),
              const SizedBox(width: 12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFDCFCE7)
                      : isCancelled
                          ? const Color(0xFFFEE2E2)
                          : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appointment.status.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? AppColors.success
                        : isCancelled
                            ? AppColors.error
                            : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date & Time Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('dd MMM yyyy').format(appointment.dateTime)}, ${appointment.timeSlot} • ${appointment.type.shortName}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
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
              if (!isCompleted && !isCancelled) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                    label: const Text('Reschedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onReschedule,
                  ),
                ),
                const SizedBox(width: 8),
                if (appointment.type == ConsultationType.videoConsult)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.videocam_rounded, size: 16, color: Colors.white),
                      label: const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
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
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: appointment)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
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
