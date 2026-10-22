import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../user/user_main_nav.dart';
import '../common/welcome_screen.dart';
import 'doctor_schedule_screen.dart';
import 'doctor_earnings_screen.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final doctor = auth.currentDoctor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Doctor Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [
            // Doctor Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(doctor.photoUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text(doctor.specialty, style: const TextStyle(fontSize: 13, color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
                        Text(doctor.hospitalName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                          child: const Text('MCI & Hospital Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Switch to Patient Portal Banner
            InkWell(
              onTap: () {
                auth.setRole(UserRole.user);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const UserMainNav()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Switch to Patient App', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('Access AI health assistant, medicine orders & personal vitals', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Items
            _DocMenuItem(
              icon: Icons.calendar_month_rounded,
              title: 'Availability & Shift Schedule',
              subtitle: 'Working days, slot duration, buffer times',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorScheduleScreen())),
            ),
            _DocMenuItem(
              icon: Icons.currency_rupee_rounded,
              title: 'Earnings & Bank Settlements',
              subtitle: 'Track payouts and consultation revenue',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorEarningsScreen())),
            ),
            _DocMenuItem(
              icon: Icons.apartment_rounded,
              title: 'Hospital Affiliation',
              subtitle: 'Current: ${doctor.hospitalName}',
              onTap: () {},
            ),
            _DocMenuItem(
              icon: Icons.rate_review_rounded,
              title: 'Patient Reviews & Ratings',
              subtitle: '${doctor.rating} Rating (350+ reviews)',
              onTap: () {},
            ),
            _DocMenuItem(
              icon: Icons.lock_outline_rounded,
              title: 'Security & Two-Factor Authentication',
              subtitle: 'Biometrics and Aarogyasri signature keys',
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                label: const Text('Sign Out of Doctor Portal', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  auth.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DocMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DocMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF0F766E).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF0F766E), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textMuted),
      ),
    );
  }
}
