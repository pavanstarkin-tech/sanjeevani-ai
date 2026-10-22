import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../screens/user/offline_ai_doctor_screen.dart';
import '../screens/user/pharmacy_screen.dart';
import '../screens/user/ai_assistant_screen.dart';
import '../screens/user/government_scheme_explorer_screen.dart';
import '../screens/user/explainable_lab_report_screen.dart';

class HeroSlideItem {
  final String filename;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext) targetScreen;

  const HeroSlideItem({
    required this.filename,
    required this.title,
    required this.subtitle,
    required this.targetScreen,
  });
}

/// Dynamic Hero Carousel Section that auto-scrolls images from the hero folder.
/// Supports both absolute folder path (on disk) and packaged asset fallback.
class HeroCarouselSection extends StatefulWidget {
  final String folderPath;
  final double aspectRatio;
  final Duration autoScrollDuration;

  const HeroCarouselSection({
    super.key,
    this.folderPath = r'C:\Users\shese\Desktop\healthyxpress_medha\healthexpress\hero',
    this.aspectRatio = 16 / 9,
    this.autoScrollDuration = const Duration(seconds: 4),
  });

  @override
  State<HeroCarouselSection> createState() => _HeroCarouselSectionState();
}

class _HeroCarouselSectionState extends State<HeroCarouselSection> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;

  final List<HeroSlideItem> _slides = [
    HeroSlideItem(
      filename: 'Emergency Care, Even Offline.png',
      title: 'Emergency Care, Even Offline',
      subtitle: 'On-Device AI Doctor with Zero Internet Required',
      targetScreen: (_) => const OfflineAiDoctorScreen(),
    ),
    HeroSlideItem(
      filename: 'Essential Medicines Within Reach.png',
      title: 'Essential Medicines Within Reach',
      subtitle: 'Find & Coordinate Nearby Medicines Fast',
      targetScreen: (_) => const PharmacyScreen(),
    ),
    HeroSlideItem(
      filename: 'Healthcare That Speaks Your Language.png',
      title: 'Healthcare That Speaks Your Language',
      subtitle: 'Multi-Lingual AI Medical Consultation (Telugu/Hindi/EN)',
      targetScreen: (_) => const AiAssistantScreen(),
    ),
    HeroSlideItem(
      filename: 'Simplified Healthcare Benefits Access.png',
      title: 'Simplified Healthcare Benefits',
      subtitle: 'Instant Government Health Schemes & Ayushman Bharat',
      targetScreen: (_) => const GovernmentSchemeExplorerScreen(),
    ),
    HeroSlideItem(
      filename: 'Understand Your Health Reports.png',
      title: 'Understand Your Health Reports',
      subtitle: 'AI-Powered Explainable Lab & Pathology Reports',
      targetScreen: (_) => const ExplainableLabReportScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Start at a large multiple of slides so it can scroll infinitely forward in one direction
    final initialPage = _slides.isNotEmpty ? _slides.length * 1000 : 0;
    _pageController = PageController(viewportFraction: 1.0, initialPage: initialPage);
    _currentPage = 0;
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(widget.autoScrollDuration, (_) {
      if (!_isUserInteracting && _pageController.hasClients && _slides.isNotEmpty) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Widget _buildSlideImage(HeroSlideItem slide) {
    // 1. Check if the specified folder path exists on local disk
    final localFile = File('${widget.folderPath}${Platform.pathSeparator}${slide.filename}');
    final relativeFile = File('hero${Platform.pathSeparator}${slide.filename}');

    if (localFile.existsSync()) {
      return Image.file(
        localFile,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildAssetFallback(slide),
      );
    } else if (relativeFile.existsSync()) {
      return Image.file(
        relativeFile,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildAssetFallback(slide),
      );
    }

    // 2. Otherwise use the bundled assets fallback
    return _buildAssetFallback(slide);
  }

  Widget _buildAssetFallback(HeroSlideItem slide) {
    return Image.asset(
      'assets/hero/${slide.filename}',
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'hero/${slide.filename}',
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) {
            // Elegant gradient placeholder if image missing
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      slide.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Scrolling Hero Viewport
        Listener(
          onPointerDown: (_) => setState(() => _isUserInteracting = true),
          onPointerUp: (_) => setState(() => _isUserInteracting = false),
          onPointerCancel: (_) => setState(() => _isUserInteracting = false),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: 1000000, // Infinite scrolling in a single forward direction
                  onPageChanged: (index) {
                    setState(() => _currentPage = index % _slides.length);
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index % _slides.length];

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: slide.targetScreen),
                        );
                      },
                      child: _buildSlideImage(slide),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Animated Page Indicator Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (index) {
            final isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
