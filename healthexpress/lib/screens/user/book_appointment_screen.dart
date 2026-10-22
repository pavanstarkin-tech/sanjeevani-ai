import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../common/address_selection_modal.dart';
import '../common/patient_detail_collection_dialog.dart';
import 'payment_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final DoctorModel doctor;
  final ConsultationType? initialType;

  const BookAppointmentScreen({
    super.key,
    required this.doctor,
    this.initialType,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '10:30 AM';
  late ConsultationType _selectedType;
  bool _applyAarogyasri = false;
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    } else if (widget.doctor.isRmpDoctor || widget.doctor.supportedTypes.contains(ConsultationType.homeVisitRMP)) {
      _selectedType = widget.doctor.supportedTypes.contains(ConsultationType.homeVisitRMP)
          ? ConsultationType.homeVisitRMP
          : (widget.doctor.supportedTypes.isNotEmpty ? widget.doctor.supportedTypes.first : ConsultationType.clinicVisit);
    } else if (widget.doctor.supportedTypes.contains(ConsultationType.clinicVisit)) {
      _selectedType = ConsultationType.clinicVisit;
    } else if (widget.doctor.supportedTypes.isNotEmpty) {
      _selectedType = widget.doctor.supportedTypes.first;
    } else {
      _selectedType = ConsultationType.videoConsult;
    }
  }

  final List<String> _slots = [
    '09:00 AM',
    '10:30 AM',
    '12:00 PM',
    '02:00 PM',
    '04:30 PM',
    '06:00 PM',
    '07:30 PM',
  ];

  double get _consultationFee {
    switch (_selectedType) {
      case ConsultationType.clinicVisit:
        return widget.doctor.clinicFee;
      case ConsultationType.videoConsult:
        return widget.doctor.videoFee;
      case ConsultationType.homeVisitRMP:
        return widget.doctor.homeVisitFee > 0 ? widget.doctor.homeVisitFee : 299.0;
    }
  }

  double get _discount => _applyAarogyasri ? (_consultationFee * 0.5) : 0.0;
  double get _total => (_consultationFee - _discount) + AppConstants.platformFee;

  void _onProceedToPayment() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isProfileComplete) {
      final updated = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PatientDetailCollectionDialog(initialUser: auth.currentUser),
      );
      if (updated != true) return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          doctor: widget.doctor,
          selectedDate: _selectedDate,
          selectedTimeSlot: _selectedTimeSlot,
          selectedType: _selectedType,
          applyAarogyasri: _applyAarogyasri,
          totalAmount: _total,
          isRecurring: _isRecurring,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isHomeVisit = _selectedType == ConsultationType.homeVisitRMP;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isHomeVisit ? 'Book Doorstep Home Visit' : 'Book Appointment',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          image: DecorationImage(
                            image: NetworkImage(widget.doctor.photoUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.doctor.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${widget.doctor.rating}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.doctor.specialty,
                          style: TextStyle(
                            fontSize: 12,
                            color: isHomeVisit ? const Color(0xFF0D9488) : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.doctor.hospitalName} • ${widget.doctor.location}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Select Date (Horizontal Picker)
            const Text('Select Date', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  final day = DateTime.now().add(Duration(days: index));
                  final isSelected = day.day == _selectedDate.day && day.month == _selectedDate.month;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => setState(() => _selectedDate = day),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 58,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEE').format(day),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white70 : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM').format(day),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 22),

            // Select Time Slot Chips
            const Text('Select Time Slot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _slots.map((slot) {
                final isSelected = _selectedTimeSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedTimeSlot = slot);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // Appointment Type Selection
            const Text('Appointment Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (widget.doctor.supportedTypes.contains(ConsultationType.clinicVisit))
                  Expanded(
                    child: _TypeSelectCard(
                      title: 'In Clinic',
                      subtitle: 'Visit hospital',
                      fee: '₹${widget.doctor.clinicFee.toInt()}',
                      icon: Icons.domain_rounded,
                      isSelected: _selectedType == ConsultationType.clinicVisit,
                      onTap: () => setState(() => _selectedType = ConsultationType.clinicVisit),
                    ),
                  ),
                if (widget.doctor.supportedTypes.contains(ConsultationType.clinicVisit) &&
                    (widget.doctor.supportedTypes.contains(ConsultationType.videoConsult) ||
                     widget.doctor.supportedTypes.contains(ConsultationType.homeVisitRMP)))
                  const SizedBox(width: 8),
                if (widget.doctor.supportedTypes.contains(ConsultationType.videoConsult))
                  Expanded(
                    child: _TypeSelectCard(
                      title: 'Video Consult',
                      subtitle: 'Online call',
                      fee: '₹${widget.doctor.videoFee.toInt()}',
                      icon: Icons.videocam_rounded,
                      isSelected: _selectedType == ConsultationType.videoConsult,
                      onTap: () => setState(() => _selectedType = ConsultationType.videoConsult),
                    ),
                  ),
                if (widget.doctor.supportedTypes.contains(ConsultationType.videoConsult) &&
                    widget.doctor.supportedTypes.contains(ConsultationType.homeVisitRMP))
                  const SizedBox(width: 8),
                if (widget.doctor.supportedTypes.contains(ConsultationType.homeVisitRMP) || widget.doctor.isRmpDoctor)
                  Expanded(
                    child: _TypeSelectCard(
                      title: 'Home Visit',
                      subtitle: 'Doorstep RMP',
                      fee: '₹${widget.doctor.homeVisitFee > 0 ? widget.doctor.homeVisitFee.toInt() : 299}',
                      icon: Icons.home_repair_service_rounded,
                      isSelected: _selectedType == ConsultationType.homeVisitRMP,
                      onTap: () => setState(() => _selectedType = ConsultationType.homeVisitRMP),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // If Home Visit is Selected: Show Verified Doorstep Delivery Address Card
            if (isHomeVisit) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFCCFBF1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.home_rounded, color: Color(0xFF0F766E), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Doorstep Patient Address',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.currentUser.address.isNotEmpty
                                ? '${auth.currentUser.address} • Live GPS Verified'
                                : 'Live GPS Current Location • Verified',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF115E59)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => AddressSelectionModal.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF5EEAD4)),
                        ),
                        child: const Text('Change', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Aarogyasri Health Benefit Card & Discount Switch
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                    child: const Icon(Icons.qr_code_2_rounded, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Apply Aarogyasri (RGIS) Benefit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('ID: ${user.aarogyasriId} • 50% Subsidy', style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _applyAarogyasri,
                    activeThumbColor: AppColors.success,
                    onChanged: (val) => setState(() => _applyAarogyasri = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Schedule Recurring Appointment Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.update_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Schedule as Recurring', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('Auto-schedule monthly follow-up review', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: _isRecurring,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _isRecurring = val ?? false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Fees Details Breakdown
            const Text('Fees Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
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
                      const Text('Consultation Fee', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('₹${_consultationFee.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Platform Fee', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('₹${AppConstants.platformFee.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                  if (_applyAarogyasri) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Aarogyasri Health Subsidy', style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
                        Text('-₹${_discount.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('₹${_total.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
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
              onPressed: _onProceedToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Confirm Booking • ₹${_total.toInt()}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeSelectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? fee;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeSelectCard({
    required this.title,
    required this.subtitle,
    this.fee,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHome = title.contains('Home');
    final activeColor = isHome ? const Color(0xFF0D9488) : AppColors.primary;
    final activeBg = isHome ? const Color(0xFFE6FFFA) : AppColors.primaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: isSelected ? activeColor : AppColors.textMuted, size: 22),
                if (fee != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fee!,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10.5, color: isSelected ? activeColor.withValues(alpha: 0.8) : AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
