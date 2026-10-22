import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class MedicationRemindersScreen extends StatefulWidget {
  const MedicationRemindersScreen({super.key});

  @override
  State<MedicationRemindersScreen> createState() => _MedicationRemindersScreenState();
}

class _MedicationRemindersScreenState extends State<MedicationRemindersScreen> {
  final List<Map<String, dynamic>> _reminders = [];

  int get _takenCount => _reminders.where((r) => r['taken'] == true).length;
  int get _adherencePercent => _reminders.isEmpty ? 0 : ((_takenCount / _reminders.length) * 100).round();

  void _showAddReminderDialog() {
    final medController = TextEditingController();
    final timingController = TextEditingController(text: 'Morning • 08:00 AM');
    final instrController = TextEditingController(text: '1 Tablet after meal');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Medication Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: medController,
                decoration: InputDecoration(
                  labelText: 'Medicine Name & Dosage',
                  hintText: 'e.g. Amoxicillin 500mg',
                  prefixIcon: const Icon(Icons.medication_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timingController,
                decoration: InputDecoration(
                  labelText: 'Timing & Schedule',
                  hintText: 'e.g. Night • 09:00 PM',
                  prefixIcon: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instrController,
                decoration: InputDecoration(
                  labelText: 'Special Instruction',
                  hintText: 'e.g. Take with warm milk after meal',
                  prefixIcon: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final medName = medController.text.trim();
                    if (medName.isEmpty) return;
                    setState(() {
                      _reminders.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'medicine': medName,
                        'timing': timingController.text.trim(),
                        'instruction': instrController.text.trim(),
                        'taken': false,
                        'color': Colors.teal,
                      });
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added reminder for $medName'), backgroundColor: AppColors.success),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Medication Reminder', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Medication Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Add Medicine',
            onPressed: _showAddReminderDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(user.name.isNotEmpty ? user.name[0] : 'P', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('Blood: ${user.bloodGroup.isNotEmpty ? user.bloodGroup : "Not Set"} • ID: ${user.id}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                    child: Text('$_takenCount/${_reminders.length} Doses', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Adherence Progress Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Today\'s Adherence Progress 🔥', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'You have taken $_takenCount of ${_reminders.length} prescribed doses today.',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                          child: Text('Score: $_adherencePercent/100', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Center(
                      child: Text('$_adherencePercent%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Today's Dosage Schedule
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Today's Medication Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                InkWell(
                  onTap: _showAddReminderDialog,
                  child: const Text('+ Add Dose', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_reminders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.shade300),
                    const SizedBox(height: 12),
                    const Text('No medicines scheduled today', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextButton(onPressed: _showAddReminderDialog, child: const Text('Add your first reminder')),
                  ],
                ),
              )
            else
              Column(
                children: _reminders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final r = entry.value;
                  final isTaken = r['taken'] as bool;
                  final color = r['color'] as Color;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isTaken ? AppColors.success.withValues(alpha: 0.3) : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.medication_rounded, color: color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['medicine'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isTaken ? AppColors.textMuted : AppColors.textPrimary,
                                  decoration: isTaken ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(r['timing'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                              const SizedBox(height: 2),
                              Text(r['instruction'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isTaken ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isTaken ? AppColors.success : AppColors.textMuted,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _reminders[index]['taken'] = !isTaken;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                          onPressed: () {
                            setState(() {
                              _reminders.removeAt(index);
                            });
                          },
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

