import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import 'store_main_nav.dart';
import '../common/welcome_screen.dart';

class StorePendingApprovalScreen extends StatelessWidget {
  const StorePendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final store = auth.currentStore;

    // If already verified, automatically route to the store portal
    if (store.isVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StoreMainNav()),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Verification Status',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
            onPressed: () {
              if (store.isVerified) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const StoreMainNav()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status checked: Still Under Review by Super Admin')),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3D Pending Review Illustration
              Container(
                height: 140,
                margin: const EdgeInsets.only(bottom: 16),
                child: Image.asset(
                  AppIllustrations.storePendingReview,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF59E0B), width: 3),
                    ),
                    child: const Icon(Icons.hourglass_top_rounded, size: 44, color: Color(0xFFD97706)),
                  ),
                ),
              ),

              const Text(
                'Application Under Review',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Your pharmacy registration for "${store.name}" has been received and logged in the state compliance queue.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Credential Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Store Name', store.name, Icons.store_rounded),
                    const Divider(height: 20),
                    _buildDetailRow('Drug License', store.licenseNumber, Icons.verified_user_rounded),
                    const Divider(height: 20),
                    _buildDetailRow('Contact Phone', store.phone, Icons.phone_rounded),
                    const Divider(height: 20),
                    _buildDetailRow('Location', '${store.area}, Hyderabad', Icons.location_on_rounded),
                    const Divider(height: 20),
                    _buildDetailRow('Current Status', 'PENDING ADMIN APPROVAL', Icons.pending_actions_rounded, statusColor: const Color(0xFFD97706)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Simulation / Demo Trigger for Instant Testing
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded, color: Color(0xFF16A34A), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Instant Demo Verification',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'For review and pair-programming, simulate immediate Super Admin approval to unlock the Store Dashboard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          auth.verifyStoreLocally(true);
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const StoreMainNav()),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Simulate Admin Approval & Enter Store',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Switch to Patient / Doctor
              TextButton.icon(
                onPressed: () {
                  auth.setRole(UserRole.user);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Switch Role (Patient / Doctor)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? statusColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: statusColor ?? const Color(0xFF0D9488)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: statusColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
