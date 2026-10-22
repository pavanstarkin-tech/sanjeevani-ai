import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ai_assistant_provider.dart';
import 'ai_recommendations_screen.dart';

class HealthVitalsDashboardScreen extends StatefulWidget {
  const HealthVitalsDashboardScreen({super.key});

  @override
  State<HealthVitalsDashboardScreen> createState() => _HealthVitalsDashboardScreenState();
}

class _HealthVitalsDashboardScreenState extends State<HealthVitalsDashboardScreen> {
  final List<Map<String, dynamic>> _carePlanItems = [
    {'title': 'Take Prescribed Medication', 'subtitle': 'As directed by physician', 'done': false},
    {'title': 'Drink 8+ Glasses of Water', 'subtitle': 'Maintain hydration', 'done': false},
    {'title': 'Rest & Avoid Stress', 'subtitle': 'Ensure 7-8 hours sleep', 'done': false},
    {'title': 'Check Vitals Twice Daily', 'subtitle': 'Morning and Evening', 'done': false},
  ];

  void _showRecordVitalsModal(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    final tempController = TextEditingController(text: user.temperatureF > 0 ? user.temperatureF.toString() : '');
    final hrController = TextEditingController(text: user.heartRateBpm > 0 ? user.heartRateBpm.toString() : '');
    final spo2Controller = TextEditingController(text: user.oxygenSpo2 > 0 ? user.oxygenSpo2.toString() : '');
    final weightController = TextEditingController(text: user.weightKg > 0 ? user.weightKg.toString() : '');
    final heightController = TextEditingController(text: user.heightCm > 0 ? user.heightCm.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Record Real Vitals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Enter your latest health measurements or Bluetooth device readings.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),

                // Temperature
                TextField(
                  controller: tempController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Body Temperature (°F)',
                    hintText: 'e.g. 98.6',
                    prefixIcon: const Icon(Icons.thermostat_rounded, color: Colors.orange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Heart Rate
                TextField(
                  controller: hrController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Heart Rate (BPM)',
                    hintText: 'e.g. 74',
                    prefixIcon: const Icon(Icons.favorite_rounded, color: Colors.red),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Oxygen SpO2
                TextField(
                  controller: spo2Controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Oxygen SpO2 (%)',
                    hintText: 'e.g. 99',
                    prefixIcon: const Icon(Icons.air_rounded, color: Colors.blue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Weight & Height
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          hintText: 'e.g. 68',
                          prefixIcon: const Icon(Icons.monitor_weight_rounded, color: Colors.teal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          hintText: 'e.g. 170',
                          prefixIcon: const Icon(Icons.height_rounded, color: Colors.indigo),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final double? temp = double.tryParse(tempController.text.trim());
                      final int? hr = int.tryParse(hrController.text.trim());
                      final int? spo2 = int.tryParse(spo2Controller.text.trim());
                      final double? weight = double.tryParse(weightController.text.trim());
                      final double? height = double.tryParse(heightController.text.trim());

                      auth.updateVitals(
                        temperatureF: temp,
                        heartRateBpm: hr,
                        oxygenSpo2: spo2,
                        weightKg: weight,
                        heightCm: height,
                      );

                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor: AppColors.success, content: Text('Vitals updated successfully!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Measurements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final ai = context.watch<AiAssistantProvider>();

    // Temperature computation
    final hasTemp = user.temperatureF > 0;
    final tempVal = hasTemp ? '${user.temperatureF.toStringAsFixed(1)}°F' : '--';
    final String tempStatus;
    final Color tempColor;
    if (!hasTemp) {
      tempStatus = 'Not Recorded';
      tempColor = AppColors.textMuted;
    } else if (user.temperatureF > 100.4) {
      tempStatus = 'High Fever';
      tempColor = Colors.red;
    } else if (user.temperatureF > 99.0) {
      tempStatus = 'Mild Fever';
      tempColor = Colors.orange;
    } else {
      tempStatus = 'Normal (98.6°F)';
      tempColor = AppColors.success;
    }

    // Heart Rate computation
    final hasHr = user.heartRateBpm > 0;
    final hrVal = hasHr ? '${user.heartRateBpm} bpm' : '--';
    final String hrStatus;
    final Color hrColor;
    if (!hasHr) {
      hrStatus = 'Not Recorded';
      hrColor = AppColors.textMuted;
    } else if (user.heartRateBpm > 100) {
      hrStatus = 'Elevated';
      hrColor = Colors.orange;
    } else if (user.heartRateBpm < 60) {
      hrStatus = 'Low (Bradycardia)';
      hrColor = Colors.blue;
    } else {
      hrStatus = 'Normal (60-100)';
      hrColor = AppColors.success;
    }

    // Oxygen SpO2 computation
    final hasSpo2 = user.oxygenSpo2 > 0;
    final spo2Val = hasSpo2 ? '${user.oxygenSpo2}%' : '--';
    final String spo2Status;
    final Color spo2Color;
    if (!hasSpo2) {
      spo2Status = 'Not Recorded';
      spo2Color = AppColors.textMuted;
    } else if (user.oxygenSpo2 >= 95) {
      spo2Status = 'Optimal (≥95%)';
      spo2Color = AppColors.success;
    } else if (user.oxygenSpo2 >= 90) {
      spo2Status = 'Normal (90-94%)';
      spo2Color = Colors.blue;
    } else {
      spo2Status = 'Low (Seek Care)';
      spo2Color = Colors.red;
    }

    // Weight & BMI computation
    final hasWeight = user.weightKg > 0;
    final weightVal = hasWeight ? '${user.weightKg.toStringAsFixed(1)} kg' : '--';
    final String weightStatus;
    final Color weightColor;
    if (!hasWeight) {
      weightStatus = 'Not Recorded';
      weightColor = AppColors.textMuted;
    } else if (user.heightCm > 0) {
      final hMeter = user.heightCm / 100;
      final bmi = user.weightKg / (hMeter * hMeter);
      final bmiCat = bmi < 18.5 ? 'Underweight' : (bmi < 25 ? 'Normal' : (bmi < 30 ? 'Overweight' : 'Obese'));
      weightStatus = 'BMI ${bmi.toStringAsFixed(1)} ($bmiCat)';
      weightColor = bmi >= 18.5 && bmi < 25 ? AppColors.success : Colors.orange;
    } else {
      weightStatus = 'Recorded';
      weightColor = AppColors.success;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Health Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
            tooltip: 'Record Vitals',
            onPressed: () => _showRecordVitalsModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Health Insight Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text('AI Health Insight', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Text('Live', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ai.currentSymptoms.isNotEmpty
                        ? 'Based on your reported symptoms, here are active suggestions and vital tracking.'
                        : 'No active symptoms reported. Consult with our AI assistant or enter measurements to track your wellness.',
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                  ),
                  if (ai.currentSymptoms.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ai.currentSymptoms.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiRecommendationsScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View Suggestions', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Health Overview Vitals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Health Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                TextButton.icon(
                  onPressed: () => _showRecordVitalsModal(context),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Record Vitals', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _VitalCard(
                    icon: Icons.thermostat_rounded,
                    iconColor: Colors.orange,
                    label: 'Temperature',
                    value: tempVal,
                    status: tempStatus,
                    statusColor: tempColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VitalCard(
                    icon: Icons.favorite_rounded,
                    iconColor: Colors.red,
                    label: 'Heart Rate',
                    value: hrVal,
                    status: hrStatus,
                    statusColor: hrColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _VitalCard(
                    icon: Icons.air_rounded,
                    iconColor: Colors.blue,
                    label: 'Oxygen SpO2',
                    value: spo2Val,
                    status: spo2Status,
                    statusColor: spo2Color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VitalCard(
                    icon: Icons.monitor_weight_rounded,
                    iconColor: Colors.teal,
                    label: 'Weight',
                    value: weightVal,
                    status: weightStatus,
                    statusColor: weightColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Today's Care Plan Checklist
            const Text("Today's Care Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Column(
              children: _carePlanItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isDone = item['done'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDone ? AppColors.success.withValues(alpha: 0.3) : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isDone,
                        activeColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            _carePlanItems[index]['done'] = val ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              item['subtitle'],
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
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

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String status;
  final Color statusColor;

  const _VitalCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
        ],
      ),
    );
  }
}
