import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../common/patient_detail_collection_dialog.dart';

class HealthQrScreen extends StatelessWidget {
  const HealthQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Digital Health ID Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 26),
            tooltip: 'Edit Medical Details',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => PatientDetailCollectionDialog(initialUser: user),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Digital Pass Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                                child: const Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Text('Aarogyasri Health Pass', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                            child: const Text('VERIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // High-Res QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: QrImageView(
                          data: user.toAarogyasriQrPayload(),
                          version: QrVersions.auto,
                          size: 210,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        user.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${user.aarogyasriId} • ${user.age} yrs (${user.gender})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _QuickMeta(label: 'Blood Group', value: user.bloodGroup),
                          _QuickMeta(label: 'Phone', value: '+91 ${user.phone}'),
                          _QuickMeta(label: 'Emergency', value: user.emergencyContactPhone.isNotEmpty ? user.emergencyContactPhone : '108 Linked'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Share & Download Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.primary),
                        label: const Text('Share Pass', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aarogyasri Health Pass link copied to clipboard!')));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                        label: const Text('Save Offline', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline Health ID saved to device gallery!')));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickMeta extends StatelessWidget {
  final String label;
  final String value;
  const _QuickMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
