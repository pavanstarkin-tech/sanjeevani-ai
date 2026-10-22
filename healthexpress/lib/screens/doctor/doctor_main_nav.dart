import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_schedule_screen.dart';
import 'doctor_patient_qr_scanner_screen.dart';
import 'doctor_analytics_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorMainNav extends StatefulWidget {
  final int initialIndex;
  const DoctorMainNav({super.key, this.initialIndex = 0});

  @override
  State<DoctorMainNav> createState() => _DoctorMainNavState();
}

class _DoctorMainNavState extends State<DoctorMainNav> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    DoctorDashboardScreen(),
    DoctorScheduleScreen(),
    DoctorPatientQrScannerScreen(), // Center Scanner
    DoctorAnalyticsScreen(),
    DoctorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DoctorNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _DoctorNavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),

                // Center QR Scanner Floating Button for Aarogyasri
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                _DoctorNavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _DoctorNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DoctorNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color(0xFF0F766E) : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F766E) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
