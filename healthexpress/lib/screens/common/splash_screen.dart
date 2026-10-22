import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../user/user_main_nav.dart';
import '../doctor/doctor_main_nav.dart';
import '../store/store_main_nav.dart';
import '../store/store_onboarding_screen.dart';
import 'welcome_screen.dart';

class _SplashItem {
  final String image;
  final String title;
  final String description;

  const _SplashItem({
    required this.image,
    required this.title,
    required this.description,
  });
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  bool _hasStartedPrecache = false;
  bool _hasNavigated = false;

  static const List<_SplashItem> _items = [
    _SplashItem(
      image: 'assets/images/splash/01_Offline_Emergency_First_Aid.png',
      title: 'Offline Emergency & First Aid',
      description:
          'Access life-saving first-aid protocols and instant offline ambulance alerts.\nImmediate clinical guidance anytime, anywhere without internet.',
    ),
    _SplashItem(
      image: 'assets/images/splash/02_Medicine_Search_Pharmacy_Delivery.png',
      title: 'Medicine Search & Express Delivery',
      description:
          'Compare genuine medicine prices and find affordable generic alternatives.\nEnjoy express doorstep delivery from verified neighborhood pharmacies.',
    ),
    _SplashItem(
      image: 'assets/images/splash/03_Multilingual_AI_Consultation.png',
      title: 'Multilingual AI Doctor Consultation',
      description:
          'Consult Dr. Shanni in your mother tongue with hands-free voice and video.\nGet instant, clinically verified symptom assessments and triage 24/7.',
    ),
    _SplashItem(
      image: 'assets/images/splash/04_Health_Scheme_Cashless_Hospitals.png',
      title: 'Cashless Hospitals & Scheme Coverage',
      description:
          'Locate Aarogyasri and PM-JAY empanelled hospitals with live bed counts.\nMaximize zero-cost healthcare treatments with verified scheme assistance.',
    ),
    _SplashItem(
      image: 'assets/images/splash/05_AI_Lab_Report_Analysis.png',
      title: 'Instant AI Lab Report Diagnostics',
      description:
          'Scan blood tests, ECGs, and prescriptions for smart clinical interpretation.\nGet simple, plain-language insights with zero medical jargon or confusion.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      if (_currentPage < _items.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _autoPlayTimer?.cancel();
      }
    });
  }

  void _pauseAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStartedPrecache) {
      _hasStartedPrecache = true;
      _precacheAllAssets();
    }
  }

  Future<void> _precacheAllAssets() async {
    for (final item in _items) {
      try {
        await precacheImage(AssetImage(item.image), context).catchError((_) {});
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goToPreviousPage() {
    _pauseAutoPlay();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToNextPage() {
    _pauseAutoPlay();
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _checkAuthAndNavigate();
    }
  }

  void _checkAuthAndNavigate() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _autoPlayTimer?.cancel();

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
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 1. PAGE CONTENT (Title + Subtitle + Contained Image utilizing maximum vertical height)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Column(
                        children: [
                          const SizedBox(height: 12),

                          // Centered Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                                height: 1.25,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Centered Subtitle (2-line description)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              item.description,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary.withValues(alpha: 0.95),
                                height: 1.35,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Image: Reduced size and centered with generous padding to prevent any cropping
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                                child: Image.asset(
                                  item.image,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.local_hospital_rounded,
                                      color: AppColors.primary,
                                      size: 64,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),
                        ],
                      );
                    },
                  ),
                ),

                // 2. BOTTOM BAR (Back button, Dots in middle, Next button)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.borderLight, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bottom Left: Back button (hidden on first page)
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: _currentPage > 0
                            ? IconButton(
                                onPressed: _goToPreviousPage,
                                icon: const Icon(Icons.arrow_back_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.borderLight,
                                  foregroundColor: AppColors.textPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Bottom Middle: Dots
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _items.length,
                          (dotIndex) {
                            final bool isActive = _currentPage == dotIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 3.5),
                              width: isActive ? 24 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          },
                        ),
                      ),

                      // Bottom Right: Next or Get Started Button
                      SizedBox(
                        height: 44,
                        child: _currentPage == _items.length - 1
                            ? ElevatedButton.icon(
                                onPressed: _checkAuthAndNavigate,
                                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                                label: const Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 1,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: _goToNextPage,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 1,
                                  fixedSize: const Size(44, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Top Right: Floating Skip button
            Positioned(
              top: 8,
              right: 16,
              child: TextButton(
                onPressed: _checkAuthAndNavigate,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
