import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ticket_model.dart';
import '../../providers/auth_provider.dart';

class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({super.key});

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Booking';
  final TicketPriority _selectedPriority = TicketPriority.medium;
  final List<SupportTicket> _tickets = [];

  final List<String> _categories = ['Booking', 'Payment', 'Doctor Consultation', 'Medicines Delivery', 'Refund', 'Aarogyasri Record Sync'];

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (_subjectController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide subject and description.')));
      return;
    }

    final user = context.read<AuthProvider>().currentUser;

    final newTicket = SupportTicket(
      id: 'TK${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      userId: user.id.isNotEmpty ? user.id : 'USR-GUEST',
      userName: user.name.isNotEmpty ? user.name : 'Patient User',
      userPhone: user.phone.isNotEmpty ? user.phone : 'Not provided',
      category: _selectedCategory,
      subject: _subjectController.text.trim(),
      description: _descController.text.trim(),
      priority: _selectedPriority,
      status: TicketStatus.open,
      createdAt: DateTime.now(),
    );

    setState(() {
      _tickets.insert(0, newTicket);
      _subjectController.clear();
      _descController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.success, content: Text('Ticket #${newTicket.id} created! Our support team will reply shortly.')),
    );
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
        title: const Text('Help & Support Tickets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create New Ticket Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Raise a Support Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Our clinical & billing support team is available 24/7.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),

                  const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
                  ),
                  const SizedBox(height: 14),

                  const Text('Subject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      hintText: 'Brief summary of your query or issue',
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Provide complete details and booking/transaction ID...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Submit Ticket', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Past Tickets List
            const Text('Your Support History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _tickets.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.headset_mic_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text('No support tickets raised yet.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Submit the form above if you need assistance.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : Column(
                    children: _tickets.map((t) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                Text('Ticket #${t.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: t.status == TicketStatus.resolved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    t.status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: t.status == TicketStatus.resolved ? AppColors.success : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(t.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(t.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            Text(
                              'Category: ${t.category} • ${DateFormat('dd MMM, hh:mm a').format(t.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
