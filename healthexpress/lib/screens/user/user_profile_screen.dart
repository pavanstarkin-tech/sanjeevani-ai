import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../../services/device_native_service.dart';
import '../doctor/doctor_main_nav.dart';
import '../doctor/doctor_onboarding_screen.dart';
import '../common/welcome_screen.dart';
import 'health_records_screen.dart';
import 'my_appointments_screen.dart';
import 'medication_reminders_screen.dart';
import 'support_ticket_screen.dart';
import 'emergency_sos_screen.dart';
import 'order_tracking_screen.dart';
import '../admin/admin_reels_management_screen.dart';
import 'doctor_reel_viewer_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  ImageProvider _getUserAvatar(String? photo) {
    if (photo != null && photo.isNotEmpty) {
      if (photo.startsWith('data:image')) {
        try {
          final commaIdx = photo.indexOf(',');
          final b64Str = commaIdx != -1 ? photo.substring(commaIdx + 1) : photo;
          return MemoryImage(base64Decode(b64Str));
        } catch (_) {}
      } else if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return NetworkImage(photo);
      }
    }
    return const NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=300&q=80');
  }

  Future<void> _handleUploadProfilePicture(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final res = await DeviceNativeService.capturePhoto();
    if (res['success'] == true && res['dataUrl'] != null) {
      await auth.updateProfilePhoto(res['dataUrl'] as String);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Profile picture updated successfully!'),
          ),
        );
      }
    }
  }

  void _showEditProfileModal(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final pharmacyProv = context.read<PharmacyProvider>();
    final user = auth.currentUser;

    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final emailCtrl = TextEditingController(text: user.email);
    final addrCtrl = TextEditingController(text: user.address);
    final emNameCtrl = TextEditingController(text: user.emergencyContactName);
    final emPhoneCtrl = TextEditingController(text: user.emergencyContactPhone);
    final emRelCtrl = TextEditingController(text: user.emergencyContactRelation.isNotEmpty ? user.emergencyContactRelation : 'Spouse');
    final bloodCtrl = TextEditingController(text: user.bloodGroup.isNotEmpty ? user.bloodGroup : 'B+ Positive');
    final allergiesCtrl = TextEditingController(text: user.allergies.isNotEmpty ? user.allergies : 'None recorded');

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
                    const Text('Edit Profile & Emergency Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Keep your address and emergency contact updated for ambulance and delivery routing.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),

                // Name & Phone
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Address
                TextField(
                  controller: addrCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Primary Delivery & Home Address',
                    hintText: 'Flat / Door No, Street, Landmark, Area, City, Pincode',
                    prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency Contact Section
                const Text('Emergency Contact (SOS & Hospital)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.emergency)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Contact Name',
                          hintText: 'e.g. Ramesh Kumar',
                          prefixIcon: const Icon(Icons.contact_emergency_rounded, color: AppColors.emergency),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: emPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Emergency Phone',
                          hintText: 'e.g. 9848011223',
                          prefixIcon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.emergency),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emRelCtrl,
                  decoration: InputDecoration(
                    labelText: 'Relationship',
                    hintText: 'e.g. Spouse, Parent, Brother, Friend',
                    prefixIcon: const Icon(Icons.family_restroom_rounded, color: AppColors.emergency),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Medical Basics
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bloodCtrl,
                        decoration: InputDecoration(
                          labelText: 'Blood Group',
                          prefixIcon: const Icon(Icons.bloodtype_rounded, color: Colors.red),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: allergiesCtrl,
                        decoration: InputDecoration(
                          labelText: 'Allergies',
                          prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Save Changes Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final address = addrCtrl.text.trim();
                      final emName = emNameCtrl.text.trim();
                      final emPhone = emPhoneCtrl.text.trim();
                      final emRel = emRelCtrl.text.trim();
                      final blood = bloodCtrl.text.trim();
                      final allergies = allergiesCtrl.text.trim();

                      auth.updatePatientDetails(
                        name: name.isNotEmpty ? name : null,
                        email: email.isNotEmpty ? email : null,
                        phone: phone.isNotEmpty ? phone : null,
                        address: address.isNotEmpty ? address : null,
                        emergencyContactName: emName.isNotEmpty ? emName : null,
                        emergencyContactPhone: emPhone.isNotEmpty ? emPhone : null,
                        emergencyContactRelation: emRel.isNotEmpty ? emRel : null,
                        bloodGroup: blood.isNotEmpty ? blood : null,
                        allergies: allergies.isNotEmpty ? allergies : null,
                      );

                      if (address.isNotEmpty) {
                        pharmacyProv.syncUserAddress(address);
                      }

                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor: AppColors.success, content: Text('Profile & Emergency details updated successfully!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
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
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 26),
            tooltip: 'Edit Profile',
            onPressed: () => _showEditProfileModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [
            // User Header Profile Card
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
                  GestureDetector(
                    onTap: () => _handleUploadProfilePicture(context),
                    child: Stack(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2.5),
                            image: DecorationImage(
                              image: _getUserAvatar(user.profilePhoto),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name.isNotEmpty ? user.name : 'Patient User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(user.phone.isNotEmpty ? '+91 ${user.phone}' : (user.email.isNotEmpty ? user.email : 'Phone not verified'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.all(Radius.circular(8))),
                              child: Text(user.aarogyasriId.isNotEmpty ? 'ID: ${user.aarogyasriId}' : 'Aarogyasri Registered', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                            if (user.age > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), borderRadius: BorderRadius.all(Radius.circular(6))),
                                child: Text('${user.age} yrs • ${user.gender}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Onboarded Clinical & Location Details Card
            Container(
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
                      const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text('Verified Patient & Emergency Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      InkWell(
                        onTap: () => _showEditProfileModal(context),
                        child: const Text('Edit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProfileRow(
                    Icons.location_on_rounded,
                    'Delivery & Home Address',
                    user.address.isNotEmpty ? user.address : 'Not configured (Tap edit to set)',
                  ),
                  const Divider(height: 16, color: AppColors.border),
                  _buildProfileRow(
                    Icons.contact_emergency_rounded,
                    'Emergency Contact',
                    user.emergencyContactName.isNotEmpty
                        ? '${user.emergencyContactName} (${user.emergencyContactPhone}) • ${user.emergencyContactRelation}'
                        : 'No emergency contact set (Tap edit to add)',
                  ),
                  const Divider(height: 16, color: AppColors.border),
                  Row(
                    children: [
                      Expanded(
                        child: _buildProfileRow(
                          Icons.bloodtype_rounded,
                          'Blood Group',
                          user.bloodGroup.isNotEmpty ? user.bloodGroup : 'Not set',
                        ),
                      ),
                      Expanded(
                        child: _buildProfileRow(
                          Icons.healing_rounded,
                          'Allergies',
                          user.allergies.isNotEmpty ? user.allergies : 'None recorded',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Role Switch to Doctor Banner
            InkWell(
              onTap: () {
                auth.setRole(UserRole.doctor);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DoctorMainNav()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                          Text('Switch to Doctor Portal', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('Manage hospital slots, QR scan patient records & consultations', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Menu Items List
            _ProfileMenuItem(
              icon: Icons.qr_code_2_rounded,
              iconColor: AppColors.primary,
              title: 'Aarogyasri (RGIS) & Health Records',
              subtitle: 'Digital pass, lab reports, past surgeries',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthRecordsScreen())),
            ),
            _ProfileMenuItem(
              icon: Icons.calendar_month_rounded,
              iconColor: Colors.purple,
              title: 'My Appointments',
              subtitle: 'Upcoming, completed, and rescheduled slots',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
            ),
            _ProfileMenuItem(
              icon: Icons.alarm_on_rounded,
              iconColor: Colors.orange,
              title: 'Medication Progress & Reminders',
              subtitle: 'Daily pill tracker and adherence streak',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedicationRemindersScreen())),
            ),
            _ProfileMenuItem(
              icon: Icons.delivery_dining_rounded,
              iconColor: Colors.teal,
              title: 'Pharmacy Orders & Live Tracking',
              subtitle: 'Track quick medicines delivery status',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderTrackingScreen())),
            ),
            _ProfileMenuItem(
              icon: Icons.emergency_rounded,
              iconColor: AppColors.emergency,
              title: 'Emergency SOS & Hotlines',
              subtitle: 'Ambulance dispatch & 108 speed dial',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencySosScreen())),
            ),
            _ProfileMenuItem(
              icon: Icons.support_agent_rounded,
              iconColor: Colors.indigo,
              title: 'Help & Support Tickets',
              subtitle: 'Raise tickets for bookings, billing, or app issues',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportTicketScreen())),
            ),
            _ProfileMenuItem(
              icon: Icons.video_collection_rounded,
              iconColor: const Color(0xFFEF4444),
              title: 'Doctor Health Reels (Shorts)',
              subtitle: 'Watch short video health tips from top doctors',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorReelViewerScreen(initialIndex: 0))),
            ),
            _ProfileMenuItem(
              icon: Icons.sell_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'Reels Referral Product Tagging (Admin)',
              subtitle: 'Tag or change referral medicines attached to videos',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminReelsManagementScreen())),
            ),
            _ProfileMenuItem(
              icon: Icons.medical_information_rounded,
              iconColor: Colors.blue,
              title: 'Doctor Onboarding Registration',
              subtitle: 'Register as verified hospital or independent doctor',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorOnboardingScreen())),
            ),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                label: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
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

  Widget _buildProfileRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.iconColor,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textMuted),
      ),
    );
  }
}
