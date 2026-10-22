import 'package:flutter/material.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/vision_analysis_model.dart';
import 'user_home_screen.dart';
import 'my_appointments_screen.dart';
import 'ai_assistant_screen.dart';
import 'ai_lens_scanner_screen.dart';
import 'nearby_hospitals_map_screen.dart';
import 'user_profile_screen.dart';
import 'dr_shanni_avatar_screen.dart';

class UserMainNav extends StatefulWidget {
  final int initialIndex;
  const UserMainNav({super.key, this.initialIndex = 0});

  @override
  State<UserMainNav> createState() => UserMainNavState();
}

class UserMainNavState extends State<UserMainNav> {
  late int _currentIndex;
  bool _isCenterHovered = false;

  void setTab(int index) {
    if (mounted) setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    UserHomeScreen(),
    MyAppointmentsScreen(),
    AiAssistantScreen(), // Center AI Assistant
    NearbyHospitalsMapScreen(),
    UserProfileScreen(),
  ];

  void _showAiCenterMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sanjeevani.AI Suite',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Select AI Chat Assistant or Camera Vision Scanner',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Option 1: AI Chat & Voice Assistant (Chat Mode)
                  _AiSelectionCard(
                    title: 'AI Chat & Voice Assistant',
                    subtitle: 'Multilingual symptom checker, Sarvam live voice, nearby doctor & hospital booking',
                    illustrationAsset: AppIllustrations.aiChat3d,
                    badgeLabel: 'Live AI Call & Triage',
                    badgeColor: const Color(0xFF2563EB),
                    cardBgColor: const Color(0xFFF8FAFC),
                    borderColor: const Color(0xFF3B82F6),
                    isImageOnLeft: true,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() => _currentIndex = 2);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 2: AI Vision & Lens Scanner (Vision Mode)
                  _AiSelectionCard(
                    title: 'AI Vision & Lens Scanner',
                    subtitle: 'Camera detection to analyze medicines, count food calories & skin conditions',
                    illustrationAsset: AppIllustrations.aiVision3d,
                    badgeLabel: 'Groq Vision 360°',
                    badgeColor: const Color(0xFF059669),
                    cardBgColor: const Color(0xFFF8FAFC),
                    borderColor: const Color(0xFF10B981),
                    isImageOnLeft: false,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AiLensScannerScreen(initialScope: VisionScope.food),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 3: Dr. Shanni AI Doctor Avatar (Live Face-to-Face & See Doctor)
                  _AiSelectionCard(
                    title: 'Dr. Shanni AI Doctor Avatar',
                    subtitle: 'Real-time face-to-face AI doctor avatar. Talk in Indian languages, get live visual symptom analysis via "See Doctor"',
                    illustrationAsset: 'assets/images/illustrations/hero_ai_doctor.png',
                    badgeLabel: 'Live Avatar & See Doctor',
                    badgeColor: const Color(0xFF7C3AED),
                    cardBgColor: const Color(0xFFFAF5FF),
                    borderColor: const Color(0xFF8B5CF6),
                    isImageOnLeft: false, // Placeholder on right side, content on left side per user instruction!
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DrShanniAvatarScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      bottomNavigationBar: _currentIndex == 2
          ? null
          : Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Appointments',
                    isSelected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),

                // Center AI Assistant Hero Button with Elevated Glow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isCenterHovered = true),
                    onExit: (_) => setState(() => _isCenterHovered = false),
                    child: GestureDetector(
                      onTap: _showAiCenterMenu,
                      child: Transform.translate(
                        offset: const Offset(0, -10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          transform: Matrix4.diagonal3Values(
                            _isCenterHovered ? 1.08 : 1.0,
                            _isCenterHovered ? 1.08 : 1.0,
                            1.0,
                          ),
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFF06B6D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: _isCenterHovered ? 0.65 : 0.42),
                                blurRadius: _isCenterHovered ? 20 : 14,
                                spreadRadius: _isCenterHovered ? 3 : 1,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1E40AF), Color(0xFF4F46E5)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: _NavItem(
                    icon: Icons.local_hospital_rounded,
                    label: 'Hospitals',
                    isSelected: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: _currentIndex == 4,
                    onTap: () => setState(() => _currentIndex = 4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 12 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              icon,
              size: isSelected ? 23 : 22,
              color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                letterSpacing: isSelected ? 0.1 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiSelectionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String illustrationAsset;
  final String badgeLabel;
  final Color badgeColor;
  final Color cardBgColor;
  final Color borderColor;
  final bool isImageOnLeft;
  final VoidCallback onTap;

  const _AiSelectionCard({
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
    required this.badgeLabel,
    required this.badgeColor,
    required this.cardBgColor,
    required this.borderColor,
    required this.isImageOnLeft,
    required this.onTap,
  });

  @override
  State<_AiSelectionCard> createState() => _AiSelectionCardState();
}

class _AiSelectionCardState extends State<_AiSelectionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const double imageWidth = 84.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Card Container (Tappable)
          InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(
                left: widget.isImageOnLeft ? (imageWidth + 14) : 16,
                right: widget.isImageOnLeft ? 16 : (imageWidth + 14),
                top: 14,
                bottom: 14,
              ),
              decoration: BoxDecoration(
                color: _isHovered ? widget.badgeColor.withValues(alpha: 0.05) : widget.cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isHovered ? widget.borderColor : const Color(0xFFE2E8F0),
                  width: _isHovered ? 2 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? widget.borderColor.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: _isHovered ? 14 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      widget.badgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3D Avatar Illustration
          Positioned(
            left: widget.isImageOnLeft ? 8 : null,
            right: widget.isImageOnLeft ? null : 8,
            top: -12,
            bottom: -12,
            child: IgnorePointer(
              child: Image.asset(
                widget.illustrationAsset,
                width: imageWidth,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: imageWidth,
                  color: Colors.transparent,
                  child: Icon(
                    widget.isImageOnLeft ? Icons.smart_toy_rounded : Icons.document_scanner_rounded,
                    size: 40,
                    color: widget.badgeColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
