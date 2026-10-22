import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import 'doctor_search_screen.dart';
import 'nearby_hospitals_map_screen.dart';
import 'pharmacy_screen.dart';
import 'lab_tests_screen.dart';
import 'rmp_doctor_booking_screen.dart';
import 'emergency_sos_screen.dart';
import 'health_records_screen.dart';
import 'health_qr_screen.dart';
import 'health_vitals_dashboard_screen.dart';
import 'my_appointments_screen.dart';
import 'medication_reminders_screen.dart';
import 'user_profile_screen.dart';
import 'notifications_screen.dart';
import '../common/basic_registration_screen.dart';
import '../../services/location_service.dart';
import 'offline_health_grid_screen.dart';
import 'explainable_lab_report_screen.dart';
import 'jan_aushadhi_finder_screen.dart';
import 'government_scheme_explorer_screen.dart';
import 'public_health_outbreak_heatmap_screen.dart';
import '../../widgets/hero_carousel_section.dart';
import '../../widgets/doctor_reels_section.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationService.syncAppLocationWithLiveGps(context);
    });
  }

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
    return const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appointmentProv = context.watch<AppointmentProvider>();
    final nextAppointment = appointmentProv.getNextUpcomingForUser(auth.currentUser.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar (Hello User on left, Notification & Profile on right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hello, ${auth.currentUser.name.split(' ').first} 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.textPrimary),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                            image: DecorationImage(
                              image: _getUserAvatar(auth.currentUser.profilePhoto),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Incomplete Onboarding Warning Banner (if patient profile is missing vital details)
              if (auth.currentUser.address.isEmpty || auth.currentUser.emergencyContactPhone.isEmpty) ...[
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BasicRegistrationScreen(
                          initialName: auth.currentUser.name,
                          initialEmail: auth.currentUser.email,
                          initialPhone: auth.currentUser.phone,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.assignment_late_rounded, color: Color(0xFFD97706), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Incomplete Onboarding Details',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF92400E)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tap here to enter emergency contact, blood group & delivery address.',
                                style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFD97706)),
                      ],
                    ),
                  ),
                ),
              ],

              // Dynamic Scrolling Hero Section
              const HeroCarouselSection(
                folderPath: r'C:\Users\shese\Desktop\healthyxpress_medha\healthexpress\hero',
              ),
              const SizedBox(height: 18),

              // Quick Actions Grid Header
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // 4x2 Grid of Actions with 3D Assets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionFindDoctor,
                    label: 'Find Doctor',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorSearchScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionHospitals,
                    label: 'Hospitals',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyHospitalsMapScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionMedicines,
                    label: 'Medicines',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PharmacyScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionLabTests,
                    label: 'Lab Tests',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabTestsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionRmpDoctor,
                    label: 'RMP Doctor',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RmpDoctorBookingScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionAmbulance,
                    label: 'Ambulance',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencySosScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionHealthRecords,
                    label: 'Health Records',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthRecordsScreen())),
                  ),
                  _QuickActionButton(
                    imagePath: AppIllustrations.quickActionHealthVitals,
                    label: 'Health Vitals',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthVitalsDashboardScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Doctor Influencer Short-Form Health Reels Section (C:\Users\shese\Desktop\healthyxpress_medha\reels)
              const DoctorReelsSection(),
              const SizedBox(height: 22),

              // 15-Min Medicine Delivery Feature Banner (3D Pop-out Effect)
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PharmacyScreen())),
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 125, 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, color: Color(0xFFFDE047), size: 13),
                                SizedBox(width: 2),
                                Text(
                                  '15-MIN EXPRESS',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Doorstep Medicine Delivery',
                            style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold, height: 1.2),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Order from verified dark-store pharmacies nearby.',
                            style: TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                    // 3D Delivery Bike Popping out of the card
                    Positioned(
                      right: -12,
                      top: -22,
                      bottom: -16,
                      child: Image.asset(
                        AppIllustrations.storeDeliveryBike,
                        width: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sanjeevani.AI — Edge-First Emergency Response & Health Grid Suite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sanjeevani.AI Grid & Intelligence',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'EDGE-FIRST',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5 Feature Cards Grid / Horizontal Scroll
              SizedBox(
                height: 128,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    // Card 1: 5km Offline Health Grid
                    _buildSanjeevaniFeatureCard(
                      context,
                      title: '5 km Offline Grid',
                      subtitle: 'Live ICU/O2 beds & highway trauma corridors',
                      badge: 'ZERO NETWORK',
                      badgeColor: const Color(0xFF10B981),
                      icon: Icons.hub_rounded,
                      gradientColors: const [Color(0xFF0F172A), Color(0xFF1E293B)],
                      accentColor: const Color(0xFF38BDF8),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OfflineHealthGridScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Card 2: Explainable Lab AI & DDI Safety
                    _buildSanjeevaniFeatureCard(
                      context,
                      title: 'Explainable Lab AI',
                      subtitle: 'Plain-language labs, ICD-10 & drug conflicts',
                      badge: 'AI REASONING',
                      badgeColor: const Color(0xFF8B5CF6),
                      icon: Icons.psychology_alt_rounded,
                      gradientColors: const [Color(0xFF1E1B4B), Color(0xFF312E81)],
                      accentColor: const Color(0xFFA78BFA),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ExplainableLabReportScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Card 3: Jan Aushadhi & 30-Min Hold
                    _buildSanjeevaniFeatureCard(
                      context,
                      title: 'Jan Aushadhi Grid',
                      subtitle: 'Save up to 75% & 30-min emergency stock lock',
                      badge: '75% CHEAPER',
                      badgeColor: const Color(0xFFF59E0B),
                      icon: Icons.price_check_rounded,
                      gradientColors: const [Color(0xFF064E3B), Color(0xFF065F46)],
                      accentColor: const Color(0xFF34D399),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const JanAushadhiFinderScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Card 4: Govt Schemes (PM-JAY & Aarogyasri)
                    _buildSanjeevaniFeatureCard(
                      context,
                      title: 'Govt Schemes ₹25L',
                      subtitle: 'PM-JAY & Aarogyasri cashless packages',
                      badge: '100% FREE',
                      badgeColor: const Color(0xFF10B981),
                      icon: Icons.shield_rounded,
                      gradientColors: const [Color(0xFF1E293B), Color(0xFF0F172A)],
                      accentColor: const Color(0xFFFBBF24),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GovernmentSchemeExplorerScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Card 5: Public Health Outbreak Surveillance
                    _buildSanjeevaniFeatureCard(
                      context,
                      title: 'Outbreak Surveillance',
                      subtitle: 'Dengue/Malaria clusters & privacy QR pass',
                      badge: 'EARLY WARNING',
                      badgeColor: const Color(0xFFEF4444),
                      icon: Icons.emergency_share_rounded,
                      gradientColors: const [Color(0xFF450A0A), Color(0xFF7F1D1D)],
                      accentColor: const Color(0xFFF87171),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PublicHealthOutbreakHeatmapScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Health Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
                    child: const Text('View all', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Upcoming Appointment Card
              if (nextAppointment != null)
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF7C3AED), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Upcoming Appointment', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${nextAppointment.doctorName} • ${nextAppointment.hospitalName}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('dd MMM yyyy').format(nextAppointment.dateTime)}, ${nextAppointment.timeSlot}',
                                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DoctorSearchScreen())),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add_task_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No Active Appointments', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              SizedBox(height: 2),
                              Text('Consult top specialists or book RMP home visits.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Medicine Reminder Card
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedicationRemindersScreen())),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.alarm_on_rounded, color: Color(0xFF0284C7), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Medicine Reminder & Schedule', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text('Prescription Dose Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            SizedBox(height: 2),
                            Text('Prescriptions from doctor consultations will sync here', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Aarogyasri / ABDM Digital Health Pass Card
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthQrScreen())),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        AppIllustrations.abdmHealthPass,
                        height: 56,
                        width: 56,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Aarogyasri / ABDM Card', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                SizedBox(width: 6),
                                Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 14),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text('View digital health ID & cashless QR', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSanjeevaniFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required List<Color> gradientColors,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(color: badgeColor, fontSize: 8.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


