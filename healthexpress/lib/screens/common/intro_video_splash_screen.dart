import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_win/video_player_win.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../user/user_main_nav.dart';
import '../doctor/doctor_main_nav.dart';
import '../store/store_main_nav.dart';
import 'splash_screen.dart';

/// App Launch Intro Video Screen
/// Plays the healthcare technology animation on a crisp white backdrop,
/// rendering the video at its actual aspect ratio with soft, feathered/blurred
/// edge gradients blending smoothly into white instead of harsh black bars.
class IntroVideoSplashScreen extends StatefulWidget {
  const IntroVideoSplashScreen({super.key});

  @override
  State<IntroVideoSplashScreen> createState() => _IntroVideoSplashScreenState();
}

class _IntroVideoSplashScreenState extends State<IntroVideoSplashScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasNavigated = false;
  late AnimationController _fadeAnimController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimController,
      curve: Curves.easeIn,
    );

    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      if (!kIsWeb && Platform.isWindows) {
        WindowsVideoPlayer.registerWith();
      }

      final controller = VideoPlayerController.asset('assets/splash_intro.mp4');
      _controller = controller;

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      _fadeAnimController.forward();
      await controller.setVolume(1.0);
      await controller.play();

      controller.addListener(_videoListener);
    } catch (e) {
      debugPrint('[IntroVideoSplashScreen] Error initializing video: $e');
      _navigateToNext();
    }
  }

  void _videoListener() {
    if (_controller == null || _hasNavigated) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    // Navigate when video finishes or within 250ms of ending
    if (duration > Duration.zero && position >= duration - const Duration(milliseconds: 250)) {
      _navigateToNext();
    }
  }

  void _navigateToNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    _controller?.removeListener(_videoListener);
    _controller?.pause();

    final auth = context.read<AuthProvider>();
    final Widget nextScreen;

    if (auth.isAuthenticated && auth.isOnboarded) {
      if (auth.currentRole == UserRole.doctor) {
        nextScreen = const DoctorMainNav();
      } else if (auth.currentRole == UserRole.store) {
        nextScreen = const StoreMainNav();
      } else {
        nextScreen = const UserMainNav();
      }
    } else {
      nextScreen = const SplashScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, secAnim) => nextScreen,
        transitionsBuilder: (_, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _fadeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Crisp White Background
          const ColoredBox(color: Colors.white),

          // 2. Clean Video Player centered at actual aspect ratio
          if (_isInitialized && _controller != null)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio > 0
                      ? _controller!.value.aspectRatio
                      : (9 / 16),
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),

          // 3. Floating Skip Button in top right
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _navigateToNext,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
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
