import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import 'booking_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final DoctorModel doctor;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final ConsultationType selectedType;
  final bool applyAarogyasri;
  final double totalAmount;
  final bool isRecurring;

  const PaymentScreen({
    super.key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.selectedType,
    required this.applyAarogyasri,
    required this.totalAmount,
    this.isRecurring = false,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'upi_gpay';
  bool _isProcessing = false;

  void _processPayment() {
    setState(() => _isProcessing = true);

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final appointmentProv = context.read<AppointmentProvider>();

      final newBooking = appointmentProv.createBooking(
        userId: auth.currentUser.id,
        doctor: widget.doctor,
        date: widget.selectedDate,
        timeSlot: widget.selectedTimeSlot,
        type: widget.selectedType,
        applyAarogyasri: widget.applyAarogyasri,
        userName: auth.currentUser.name,
        userPhone: auth.currentUser.phone,
        aarogyasriId: auth.currentUser.aarogyasriId,
        isRecurring: widget.isRecurring,
      );

      setState(() => _isProcessing = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(appointment: newBooking),
        ),
      );
    });
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
        title: const Text('Razorpay Secure Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary)),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: const CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text('Securing transaction with Razorpay...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Please do not press back or refresh.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount to Pay Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Payable Amount', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('₹${widget.totalAmount.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('256-Bit SSL', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // UPI Methods
                  const Text('UPI Options (Instant & Zero Fee)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  _PaymentTile(
                    id: 'upi_gpay',
                    title: 'Google Pay',
                    subtitle: 'Fast UPI auto-pay',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: Colors.blue,
                    selectedId: _selectedMethod,
                    onSelect: (id) => setState(() => _selectedMethod = id),
                  ),
                  const SizedBox(height: 10),
                  _PaymentTile(
                    id: 'upi_phonepe',
                    title: 'PhonePe',
                    subtitle: 'Pay via PhonePe UPI',
                    icon: Icons.mobile_friendly_rounded,
                    iconColor: Colors.purple,
                    selectedId: _selectedMethod,
                    onSelect: (id) => setState(() => _selectedMethod = id),
                  ),
                  const SizedBox(height: 10),
                  _PaymentTile(
                    id: 'upi_paytm',
                    title: 'Paytm / Any UPI App',
                    subtitle: 'BHIM, Cred, Amazon Pay',
                    icon: Icons.qr_code_scanner_rounded,
                    iconColor: Colors.teal,
                    selectedId: _selectedMethod,
                    onSelect: (id) => setState(() => _selectedMethod = id),
                  ),
                  const SizedBox(height: 24),

                  // Cards & Net Banking
                  const Text('Cards & Net Banking', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  _PaymentTile(
                    id: 'card',
                    title: 'Credit / Debit Card',
                    subtitle: 'Visa, Mastercard, RuPay',
                    icon: Icons.credit_card_rounded,
                    iconColor: AppColors.primary,
                    selectedId: _selectedMethod,
                    onSelect: (id) => setState(() => _selectedMethod = id),
                  ),
                  const SizedBox(height: 10),
                  _PaymentTile(
                    id: 'netbanking',
                    title: 'Net Banking',
                    subtitle: 'All Indian banks supported',
                    icon: Icons.account_balance_rounded,
                    iconColor: Colors.indigo,
                    selectedId: _selectedMethod,
                    onSelect: (id) => setState(() => _selectedMethod = id),
                  ),
                  const SizedBox(height: 10),
                  _PaymentTile(
                    id: 'aarogyasri_direct',
                    title: 'Aarogyasri Health Direct Pass',
                    subtitle: 'Auto-claim cashless government balance',
                    icon: Icons.health_and_safety_rounded,
                    iconColor: AppColors.success,
                    selectedId: _selectedMethod,
                    onSelect: (id) => setState(() => _selectedMethod = id),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: !_isProcessing
          ? Container(
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
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Pay ₹${widget.totalAmount.toInt()} & Confirm Slot', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String selectedId;
  final Function(String) onSelect;

  const _PaymentTile({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = id == selectedId;
    return InkWell(
      onTap: () => onSelect(id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
