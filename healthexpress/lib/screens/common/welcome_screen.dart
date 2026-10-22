import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../user/user_main_nav.dart';
import '../doctor/doctor_main_nav.dart';
import '../store/store_main_nav.dart';
import '../store/store_onboarding_screen.dart';
import 'choose_role_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRedirect();
    });
  }

  void _checkAuthAndRedirect() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.isOnboarded) {
      if (auth.currentRole == UserRole.doctor) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DoctorMainNav()),
        );
      } else if (auth.currentRole == UserRole.store) {
        final store = auth.currentStore;
        if (store.isVerified) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StoreMainNav()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StoreOnboardingScreen()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserMainNav()),
        );
      }
    }
  }

  void _openRoleSelection(BuildContext context) {
    ChooseRoleScreen.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ----------------------------------------------------
          // BACKGROUND: Pure Crisp Blue Circular Elements (Zero Gray Artifacts)
          // ----------------------------------------------------
          // 1. Top-Right Ambient Pure Blue Sphere (fading into white)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFDBEAFE),
                    Color(0xFFEFF6FF),
                    Color(0x00FFFFFF), // Transparent white (never black/gray!)
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 2. Top-Left Floating Crisp Sky Blue Ring
          Positioned(
            top: 100,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF93C5FD).withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // 3. Mid-Right Crisp Royal Blue Floating Dot
          Positioned(
            top: 240,
            right: 28,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF60A5FA),
              ),
            ),
          ),

          // 4. Mid-Right Floating Light Blue Ring
          Positioned(
            top: 280,
            right: 48,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF93C5FD),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // 5. Mid-Left Floating Crisp Sky Blue Dot
          Positioned(
            top: 360,
            left: 28,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),

          // 6. Mid-Left Floating Blue Ring
          Positioned(
            top: 390,
            left: 18,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF93C5FD),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // 7. Lower-Left Ambient Pure Blue Glow (fading into white)
          Positioned(
            bottom: 30,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFDBEAFE),
                    Color(0xFFEFF6FF),
                    Color(0x00FFFFFF),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 8. Lower-Right Crisp Blue Circular Ring
          Positioned(
            bottom: 110,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFBFDBFE),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // ----------------------------------------------------
          // FOREGROUND: Main Screen Content
          // ----------------------------------------------------
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;
                // Proportional doctor image height that scales smoothly across devices
                final doctorHeight = (screenHeight * 0.42).clamp(260.0, 360.0);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. TOP APP BAR (Left-aligned Logo & Title) - Commented out as requested
                            /*
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'HealthExpress AI',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            */
                            const SizedBox.shrink(),

                            // 2. CENTER HERO SECTION (3D Doctor + Seamless Bottom Fade)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 3D Doctor with layered circular backdrop elements & smooth bottom shade
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer concentric decorative blue ring
                                      Container(
                                        width: doctorHeight * 1.08,
                                        height: doctorHeight * 1.08,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFBFDBFE),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),

                                      // Inner pure radial blue circle (blends to pure white, no gray)
                                      Container(
                                        width: doctorHeight * 0.92,
                                        height: doctorHeight * 0.92,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Color(0xFFDBEAFE),
                                              Color(0xFFEFF6FF),
                                              Color(0x00FFFFFF),
                                            ],
                                            stops: [0.0, 0.7, 1.0],
                                          ),
                                        ),
                                      ),

                                      // Floating decorative small blue accent dot
                                      Positioned(
                                        top: 24,
                                        left: 18,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ),

                                      // Floating decorative small ring
                                      Positioned(
                                        top: 36,
                                        right: 20,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF60A5FA),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // 3D AI Doctor Illustration with Bottom-to-Top Fade Mask
                                      ShaderMask(
                                        shaderCallback: (Rect bounds) {
                                          return const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black,
                                              Colors.black,
                                              Colors.transparent,
                                            ],
                                            stops: [0.0, 0.88, 1.0], // Smoothly fades out the bottom 12%
                                          ).createShader(bounds);
                                        },
                                        blendMode: BlendMode.dstIn,
                                        child: Image.asset(
                                          AppIllustrations.heroAiDoctor,
                                          height: doctorHeight,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 100,
                                                height: 100,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFFEFF6FF),
                                                ),
                                                child: const Icon(
                                                  Icons.medical_services_rounded,
                                                  size: 50,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'HealthExpress AI',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Bottom White Shade Overlay (Bottom to Top fade for seamless blend)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        height: 24,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.white,
                                                Color(0x00FFFFFF), // Pure transparent white (zero gray)
                                              ],
                                              stops: [0.0, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Single Line Title: "Your Health, Our Priority"
                                  const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Your Health, Our Priority',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 3. BOTTOM ACTIONS (Get Started Button + Sign In Link)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Single Primary Action Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: () => _openRoleSelection(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                      shadowColor: AppColors.primary.withValues(alpha: 0.35),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'Get Started',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Already Registered? Sign In Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Already registered? ',
                                      style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                                    ),
                                    GestureDetector(
                                      onTap: () => _openRoleSelection(context),
                                      child: const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
