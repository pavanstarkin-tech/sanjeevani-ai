import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../common/welcome_screen.dart';
import '../doctor/doctor_main_nav.dart';
import '../user/user_main_nav.dart';

class StoreProfileScreen extends StatelessWidget {
  const StoreProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final store = auth.currentStore;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Store Partner Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      store.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xFF0D9488),
                        child: Icon(Icons.store_rounded, size: 40, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    store.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          'DL: ${store.licenseNumber}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${store.address}, ${store.area}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Role Switcher
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Switch Application Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    tileColor: const Color(0xFFF1F5F9),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 18,
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 18),
                    ),
                    title: const Text('Switch to Patient Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Access doctor consults & emergency triage', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      auth.setRole(UserRole.user);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const UserMainNav()),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    tileColor: const Color(0xFFF1F5F9),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF16A34A),
                      radius: 18,
                      child: Icon(Icons.medical_services_rounded, color: Colors.white, size: 18),
                    ),
                    title: const Text('Switch to Doctor Portal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Manage consultation queues & patient charts', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      auth.setRole(UserRole.doctor);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const DoctorMainNav()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  auth.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
