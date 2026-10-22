import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_auth_service.dart';
import '../user/user_main_nav.dart';
import '../doctor/doctor_main_nav.dart';
import '../doctor/doctor_onboarding_screen.dart';
import '../store/store_main_nav.dart';
import '../store/store_onboarding_screen.dart';
import 'basic_registration_screen.dart';

class AuthMethodScreen extends StatefulWidget {
  final UserRole role;
  final bool initialSignUp;

  const AuthMethodScreen({
    super.key,
    required this.role,
    this.initialSignUp = false,
  });

  @override
  State<AuthMethodScreen> createState() => _AuthMethodScreenState();
}

class RoleThemePalette {
  final Color primary;
  final Color secondary;
  final Color softTint;
  final Color ambientLight;
  final Color ringBorder;
  final Color dotAccent;
  final String sampleName;

  const RoleThemePalette({
    required this.primary,
    required this.secondary,
    required this.softTint,
    required this.ambientLight,
    required this.ringBorder,
    required this.dotAccent,
    required this.sampleName,
  });

  static RoleThemePalette of(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return const RoleThemePalette(
          primary: Color(0xFF059669),
          secondary: Color(0xFF10B981),
          softTint: Color(0xFFECFDF5),
          ambientLight: Color(0xFFD1FAE5),
          ringBorder: Color(0xFF6EE7B7),
          dotAccent: Color(0xFF34D399),
          sampleName: 'Dr. Sandeep Attawar',
        );
      case UserRole.store:
        return const RoleThemePalette(
          primary: Color(0xFF0D9488),
          secondary: Color(0xFF14B8A6),
          softTint: Color(0xFFF0FDFA),
          ambientLight: Color(0xFFCCFBF1),
          ringBorder: Color(0xFF5EEAD4),
          dotAccent: Color(0xFF2DD4BF),
          sampleName: 'Apollo MedPlus Pharmacy',
        );
      case UserRole.user:
      default:
        return const RoleThemePalette(
          primary: Color(0xFF2563EB),
          secondary: Color(0xFF3B82F6),
          softTint: Color(0xFFEFF6FF),
          ambientLight: Color(0xFFDBEAFE),
          ringBorder: Color(0xFF93C5FD),
          dotAccent: Color(0xFF60A5FA),
          sampleName: 'Rahul Kumar',
        );
    }
  }

  static RoleThemePalette lerp(RoleThemePalette a, RoleThemePalette b, double t) {
    return RoleThemePalette(
      primary: Color.lerp(a.primary, b.primary, t) ?? b.primary,
      secondary: Color.lerp(a.secondary, b.secondary, t) ?? b.secondary,
      softTint: Color.lerp(a.softTint, b.softTint, t) ?? b.softTint,
      ambientLight: Color.lerp(a.ambientLight, b.ambientLight, t) ?? b.ambientLight,
      ringBorder: Color.lerp(a.ringBorder, b.ringBorder, t) ?? b.ringBorder,
      dotAccent: Color.lerp(a.dotAccent, b.dotAccent, t) ?? b.dotAccent,
      sampleName: t > 0.5 ? b.sampleName : a.sampleName,
    );
  }
}

class _AuthMethodScreenState extends State<AuthMethodScreen> with TickerProviderStateMixin {
  late UserRole _currentRole;
  late UserRole _previousRole;
  late bool _isSignIn;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  AnimationController? _radialController;
  Animation<double>? _radialAnimation;
  bool _isRoleMenuOpen = false;

  AnimationController? _themeColorController;
  Animation<double>? _themeAnimation;

  void _ensureControllerInitialized() {
    if (_radialController == null) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      _radialController = controller;
      _radialAnimation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      );
    }

    if (_themeColorController == null) {
      final themeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
        value: 1.0,
      );
      _themeColorController = themeCtrl;
      _themeAnimation = CurvedAnimation(
        parent: themeCtrl,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _currentRole = widget.role;
    _previousRole = widget.role;
    _isSignIn = !widget.initialSignUp;
    _ensureControllerInitialized();
  }

  @override
  void dispose() {
    _radialController?.dispose();
    _themeColorController?.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleRoleMenu() {
    _ensureControllerInitialized();
    setState(() {
      _isRoleMenuOpen = !_isRoleMenuOpen;
      if (_isRoleMenuOpen) {
        _radialController?.forward();
      } else {
        _radialController?.reverse();
      }
    });
  }

  void _selectRole(UserRole role) {
    _ensureControllerInitialized();
    if (role == _currentRole) {
      _toggleRoleMenu();
      return;
    }
    setState(() {
      _previousRole = _currentRole;
      _currentRole = role;
      _errorMessage = null;
      _isRoleMenuOpen = false;
    });
    _themeColorController?.forward(from: 0.0);
    _radialController?.reverse();
  }

  Color get _themeColor => RoleThemePalette.of(_currentRole).primary;

  String get _roleIllustration {
    switch (_currentRole) {
      case UserRole.doctor:
        return AppIllustrations.roleDoctor;
      case UserRole.store:
        return AppIllustrations.roleStore;
      case UserRole.user:
      default:
        return AppIllustrations.rolePatient;
    }
  }

  void _fillDemoCredentials() {
    setState(() {
      _isSignIn = true; // Always switch to Sign In mode for demo credentials
      _errorMessage = null;
      if (_currentRole == UserRole.doctor) {
        _nameController.text = 'Dr. Sandeep Attawar';
        _emailController.text = 'dr.sandeep@healthexpress.ai';
        _passwordController.text = 'Doctor@123';
        _phoneController.text = '9848011223';
      } else if (_currentRole == UserRole.store) {
        _nameController.text = 'MedPlus Pharmacy';
        _emailController.text = 'contact@medplusexpress.com';
        _passwordController.text = 'Store@123';
        _phoneController.text = '9848099881';
      } else {
        _nameController.text = 'Rahul Kumar';
        _emailController.text = 'rahul.kumar@gmail.com';
        _passwordController.text = 'Patient@123';
        _phoneController.text = '9876543210';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Filled ${_currentRole.name.toUpperCase()} credentials! Tap Sign In.'),
        backgroundColor: _themeColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  void _routeAfterAuth() {
    if (!mounted) return;
    if (_currentRole == UserRole.doctor) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DoctorMainNav()),
        (route) => false,
      );
    } else if (_currentRole == UserRole.store) {
      final store = context.read<AuthProvider>().currentStore;
      if (store.isVerified) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const StoreMainNav()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const StoreOnboardingScreen()),
          (route) => false,
        );
      }
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UserMainNav()),
        (route) => false,
      );
    }
  }

  void _routeToRoleDetailCollection({
    String? name,
    String? email,
    String? phone,
  }) {
    if (!mounted) return;
    if (_currentRole == UserRole.doctor) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DoctorOnboardingScreen(
            initialName: name,
            initialEmail: email,
            initialPhone: phone,
          ),
        ),
      );
    } else if (_currentRole == UserRole.store) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StoreOnboardingScreen(
            initialName: name,
            initialEmail: email,
            initialPhone: phone,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BasicRegistrationScreen(
            initialName: name,
            initialEmail: email,
            initialPhone: phone,
          ),
        ),
      );
    }
  }

  Future<void> _handleEmailPasswordAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() => _errorMessage = null);

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both Email and Password.');
      return;
    }

    if (!_isSignIn && name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Full Name.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    // Inform browser/system autofill context
    TextInput.finishAutofillContext();

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();

      if (_isSignIn) {
        await auth.loginWithFirebase(
          email: email,
          password: password,
          role: _currentRole,
        );
        if (mounted) {
          _routeAfterAuth();
        }
      } else {
        await auth.signUpWithFirebase(
          name: name,
          email: email,
          password: password,
          phone: phone.isNotEmpty ? phone : null,
          role: _currentRole,
        );
        if (mounted) {
          _routeToRoleDetailCollection(
            name: name,
            email: email,
            phone: phone.isNotEmpty ? phone : null,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    try {
      final session = await auth.loginWithGoogle(role: _currentRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Image.asset('assets/images/google_logo.png', width: 18, height: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Signed in with Google as ${session.displayName} (${session.email})')),
              ],
            ),
          ),
        );
        if (auth.isOnboarded) {
          _routeAfterAuth();
        } else {
          _routeToRoleDetailCollection(
            name: session.displayName,
            email: session.email,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog([Color? themeColor]) {
    final activeColor = themeColor ?? _themeColor;
    final resetController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: activeColor, size: 24),
            const SizedBox(width: 8),
            const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered email address. Firebase will send you a password reset email immediately.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'name@example.com',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = resetController.text.trim();
              if (email.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await FirebaseAuthService.sendPasswordResetEmail(email: email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      content: Text('Password reset link sent to $email via Firebase!'),
                    ),
                  );
                }
              } catch (err) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      content: Text(err.toString().replaceAll('Exception: ', '')),
                    ),
                  );
                }
              }
            },
            child: const Text('Send Reset Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllerInitialized();
    final mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final double screenHeight = mediaQuery.size.height;
    final double topPadding = mediaQuery.padding.top;
    final Offset cornerOrigin = Offset(screenWidth - 68, topPadding + 62);
    final double maxRadius = math.sqrt(screenWidth * screenWidth + screenHeight * screenHeight) + 120;

    return AnimatedBuilder(
      animation: _themeAnimation ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, _) {
        final t = _themeAnimation?.value ?? 1.0;
        final palette = RoleThemePalette.lerp(
          RoleThemePalette.of(_previousRole),
          RoleThemePalette.of(_currentRole),
          t,
        );

        final double waveRadius = maxRadius * Curves.easeInOutCubic.transform(t);
        final double waveRadiusLagged = maxRadius * Curves.easeInOutCubic.transform((t * 0.88).clamp(0.0, 1.0));
        final double waveOpacity = (1.0 - t).clamp(0.0, 1.0);
        final double borderOpacity = (math.sin(t * math.pi) * 0.75).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // ----------------------------------------------------
              // IPHONE-STYLE CIRCULAR WAVE REVEAL FROM TOP-RIGHT CORNER (SMOOTH & SLOWED)
              // ----------------------------------------------------
              if (!_isRoleMenuOpen && t < 1.0) ...[
                // Primary expanding ambient wash
                Positioned(
                  left: cornerOrigin.dx - waveRadius,
                  top: cornerOrigin.dy - waveRadius,
                  child: IgnorePointer(
                    child: Container(
                      width: waveRadius * 2,
                      height: waveRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            palette.ambientLight.withValues(alpha: 0.88 * waveOpacity),
                            palette.softTint.withValues(alpha: 0.65 * waveOpacity),
                            palette.primary.withValues(alpha: 0.18 * waveOpacity),
                            palette.ringBorder.withValues(alpha: 0.32 * waveOpacity),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.40, 0.70, 0.92, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Outer leading wavefront glowing arc
                Positioned(
                  left: cornerOrigin.dx - waveRadius,
                  top: cornerOrigin.dy - waveRadius,
                  child: IgnorePointer(
                    child: Container(
                      width: waveRadius * 2,
                      height: waveRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.primary.withValues(alpha: borderOpacity * 0.7),
                          width: 2.2 * (1.0 - (t * 0.5)),
                        ),
                      ),
                    ),
                  ),
                ),
                // Secondary inner ripple echo for liquid depth
                Positioned(
                  left: cornerOrigin.dx - waveRadiusLagged,
                  top: cornerOrigin.dy - waveRadiusLagged,
                  child: IgnorePointer(
                    child: Container(
                      width: waveRadiusLagged * 2,
                      height: waveRadiusLagged * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.ringBorder.withValues(alpha: borderOpacity * 0.45),
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // ----------------------------------------------------
              // BACKGROUND: Dynamic Color-Morphing Ambient Spheres & Floating Rings
              // ----------------------------------------------------
              if (!_isRoleMenuOpen) ...[
                // 1. Top-Right Ambient Sphere (fading into white)
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          palette.ambientLight,
                          palette.softTint,
                          const Color(0x00FFFFFF),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // 2. Top-Left Floating Ring
                Positioned(
                  top: 90,
                  left: -40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.ringBorder.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // 3. Mid-Right Floating Dot
                Positioned(
                  top: 240,
                  right: 28,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.dotAccent,
                    ),
                  ),
                ),

                // 4. Mid-Right Floating Light Ring
                Positioned(
                  top: 280,
                  right: 48,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.ringBorder,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // 5. Mid-Left Floating Dot
                Positioned(
                  top: 360,
                  left: 28,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.primary,
                    ),
                  ),
                ),

                // 6. Mid-Left Floating Ring
                Positioned(
                  top: 390,
                  left: 18,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.ringBorder,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // 7. Lower-Left Ambient Glow (fading into white)
                Positioned(
                  bottom: 30,
                  left: -60,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          palette.ambientLight,
                          palette.softTint,
                          const Color(0x00FFFFFF),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // 8. Lower-Right Circular Ring
                Positioned(
                  bottom: 110,
                  right: -30,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.ringBorder.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // 9. Lower-Right Floating Accent Dot
                Positioned(
                  bottom: 70,
                  right: 36,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.dotAccent,
                    ),
                  ),
                ),
              ],

              // ----------------------------------------------------
              // FOREGROUND: Responsive CustomScrollView with SliverFillRemaining
              // ----------------------------------------------------
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                // Top-Right Role Avatar Circle (Hidden with Opacity when role menu is open to prevent ghosting)
                                Opacity(
                                  opacity: _isRoleMenuOpen ? 0.0 : 1.0,
                                  child: GestureDetector(
                                    onTap: _toggleRoleMenu,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 750),
                                      curve: Curves.easeInOutCubic,
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(color: palette.primary, width: 3.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: palette.primary.withValues(alpha: 0.32),
                                            blurRadius: 18,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: ClipOval(
                                        child: Image.asset(
                                          _roleIllustration,
                                          key: ValueKey(_currentRole),
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 44, color: AppColors.primary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Form Card
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: AutofillGroup(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _isSignIn ? 'Account Sign In' : 'Create Account',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                          ),
                                          GestureDetector(
                                            onTap: _fillDemoCredentials,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: palette.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: palette.primary.withValues(alpha: 0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.edit_note_rounded, size: 15, color: palette.primary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Auto-Fill',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: palette.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      if (_errorMessage != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF2F2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFFCA5A5)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                      ],

                                      if (!_isSignIn) ...[
                                        const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _nameController,
                                          textCapitalization: TextCapitalization.words,
                                          autofillHints: const [AutofillHints.name],
                                          decoration: InputDecoration(
                                            hintText: palette.sampleName,
                                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: palette.primary),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.primary, width: 2)),
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        const Text('Mobile Number (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          autofillHints: const [AutofillHints.telephoneNumber],
                                          decoration: InputDecoration(
                                            hintText: '+91 98480 12345',
                                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                            prefixIcon: Icon(Icons.phone_outlined, size: 20, color: palette.primary),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.primary, width: 2)),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                      ],

                                      const Text('Email Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        autofillHints: const [AutofillHints.email, AutofillHints.username],
                                        decoration: InputDecoration(
                                          hintText: 'name@example.com',
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                          prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: palette.primary),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.primary, width: 2)),
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                          if (_isSignIn)
                                            GestureDetector(
                                              onTap: () => _showForgotPasswordDialog(palette.primary),
                                              child: Text(
                                                'Forgot Password?',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: palette.primary),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        autofillHints: _isSignIn ? const [AutofillHints.password] : const [AutofillHints.newPassword],
                                        decoration: InputDecoration(
                                          hintText: '••••••••',
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                          prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: palette.primary),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                              size: 20,
                                              color: AppColors.textSecondary,
                                            ),
                                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.primary, width: 2)),
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              activeColor: palette.primary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                              onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Remember this device for 30 days',
                                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _handleEmailPasswordAuth,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: palette.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            elevation: 1.5,
                                            shadowColor: palette.primary.withValues(alpha: 0.35),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _isSignIn ? 'Sign In' : 'Continue to Detail Setup',
                                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Bottom Section
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'OR CONTINUE WITH',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade400,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : _handleGoogleAuth,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/google_logo.png',
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isSignIn ? "Don't have an account?" : "Already have an account?",
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                      TextButton(
                                        onPressed: () => setState(() {
                                          _isSignIn = !_isSignIn;
                                          _errorMessage = null;
                                        }),
                                        child: Text(
                                          _isSignIn ? 'Sign Up' : 'Sign In',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: palette.primary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ----------------------------------------------------
              // OVERLAY: 1/4 Circle Divided into 3 Parts in Top-Right Corner
              // ----------------------------------------------------
              if (_isRoleMenuOpen) ...[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleRoleMenu,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.16),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _radialAnimation ?? const AlwaysStoppedAnimation(1.0),
                    child: ScaleTransition(
                      alignment: Alignment.topRight,
                      scale: _radialAnimation ?? const AlwaysStoppedAnimation(1.0),
                      child: SizedBox(
                        width: screenWidth,
                        height: screenWidth,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Custom Painted 1/4 Circle Sector radiating from top-right corner to top and left edges
                            Positioned.fill(
                              child: CustomPaint(
                                painter: QuarterCircleMenuPainter(
                                  currentRole: _currentRole,
                                  themeColor: palette.primary,
                                ),
                              ),
                            ),

                            // Sector 1: Patient (0° to 30°, center ray at 15°)
                            _buildQuarterSectorItem(
                              role: UserRole.user,
                              label: 'Patient',
                              illustration: AppIllustrations.rolePatient,
                              fallbackIcon: Icons.person_rounded,
                              centerX: screenWidth - (76.0 + (screenWidth - 76.0) * 0.48) * math.cos(15 * math.pi / 180),
                              centerY: (76.0 + (screenWidth - 76.0) * 0.48) * math.sin(15 * math.pi / 180),
                            ),

                            // Sector 2: Doctor (30° to 60°, center ray at 45°)
                            _buildQuarterSectorItem(
                              role: UserRole.doctor,
                              label: 'Doctor',
                              illustration: AppIllustrations.roleDoctor,
                              fallbackIcon: Icons.medical_services_rounded,
                              centerX: screenWidth - (76.0 + (screenWidth - 76.0) * 0.48) * math.cos(45 * math.pi / 180),
                              centerY: (76.0 + (screenWidth - 76.0) * 0.48) * math.sin(45 * math.pi / 180),
                            ),

                            // Sector 3: Store Partner (60° to 90°, center ray at 75°)
                            _buildQuarterSectorItem(
                              role: UserRole.store,
                              label: 'Store',
                              illustration: AppIllustrations.roleStore,
                              fallbackIcon: Icons.local_pharmacy_rounded,
                              centerX: screenWidth - (76.0 + (screenWidth - 76.0) * 0.48) * math.cos(75 * math.pi / 180),
                              centerY: (76.0 + (screenWidth - 76.0) * 0.48) * math.sin(75 * math.pi / 180),
                            ),

                            // Apex / Corner Circle Button (Layered over top-right apex corner)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _toggleRoleMenu,
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: palette.primary, width: 3.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: palette.primary.withValues(alpha: 0.32),
                                        blurRadius: 18,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: ClipOval(
                                    child: Image.asset(
                                      _roleIllustration,
                                      key: ValueKey(_currentRole),
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 44, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuarterSectorItem({
    required UserRole role,
    required String label,
    required String illustration,
    required IconData fallbackIcon,
    required double centerX,
    required double centerY,
  }) {
    final isSelected = _currentRole == role;
    final roleColor = RoleThemePalette.of(role).primary;

    return Positioned(
      left: centerX - 36,
      top: centerY - 36,
      child: GestureDetector(
        onTap: () => _selectRole(role),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? roleColor.withValues(alpha: 0.15) : Colors.white,
                border: Border.all(
                  color: isSelected ? roleColor : const Color(0xFFCBD5E1),
                  width: isSelected ? 2.6 : 1.4,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: roleColor.withValues(alpha: 0.32),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(5),
              child: ClipOval(
                child: Image.asset(
                  illustration,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: 24, color: roleColor),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? roleColor : AppColors.textPrimary,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: roleColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class QuarterCircleMenuPainter extends CustomPainter {
  final UserRole currentRole;
  final Color themeColor;

  QuarterCircleMenuPainter({
    required this.currentRole,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Hub center is the exact top-right corner of the frame (size.width, 0)
    final Offset center = Offset(size.width, 0);
    final double outerRadius = size.width;
    const double innerRadius = 76.0;

    final Rect outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final Rect innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    // 1. Full Annular 1/4 Sector Path (middle circular band)
    final Path fullSectorPath = Path()
      ..arcTo(outerRect, math.pi, -math.pi / 2, false)
      ..lineTo(center.dx, center.dy + innerRadius)
      ..arcTo(innerRect, math.pi / 2, math.pi / 2, false)
      ..close();

    // Soft drop shadow for floating depth
    canvas.drawShadow(fullSectorPath, Colors.black.withValues(alpha: 0.16), 14, true);

    // Background base fill
    final Paint bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(fullSectorPath, bgPaint);

    // 2. Draw the 3 divided sectors in the middle circular band:
    // Sector 1: Patient (0° to 30° from horizontal-left axis -> angles math.pi to 5*math.pi/6)
    // Sector 2: Doctor (30° to 60° -> angles 5*math.pi/6 to 4*math.pi/6)
    // Sector 3: Store Partner (60° to 90° -> angles 4*math.pi/6 to math.pi/2)
    final roles = [UserRole.user, UserRole.doctor, UserRole.store];
    final sectorColors = [
      AppColors.primary,
      AppColors.success,
      const Color(0xFF0D9488),
    ];

    for (int i = 0; i < 3; i++) {
      final double startAngle = math.pi - (i * math.pi / 6);
      const double sweepAngle = -math.pi / 6;
      final bool isSelected = currentRole == roles[i];

      final Path sectorPath = Path()
        ..arcTo(outerRect, startAngle, sweepAngle, false)
        ..lineTo(
          center.dx - innerRadius * math.cos(startAngle + sweepAngle),
          center.dy - innerRadius * math.sin(startAngle + sweepAngle),
        )
        ..arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false)
        ..close();

      if (isSelected) {
        final Paint activeFillPaint = Paint()
          ..color = sectorColors[i].withValues(alpha: 0.14)
          ..style = PaintingStyle.fill;
        canvas.drawPath(sectorPath, activeFillPaint);

        // Outer arc glowing highlight for active sector
        final Paint activeArcPaint = Paint()
          ..color = sectorColors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5;
        final Path arcPath = Path()
          ..arcTo(
            Rect.fromCircle(center: center, radius: outerRadius - 1.5),
            startAngle,
            sweepAngle,
            false,
          );
        canvas.drawPath(arcPath, activeArcPaint);
      }
    }

    // 3. Radial divider lines separating the 3 parts in the middle band
    final Paint dividerPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 1; i <= 2; i++) {
      final double alpha = i * math.pi / 6;
      final double startX = center.dx - innerRadius * math.cos(alpha);
      final double startY = center.dy + innerRadius * math.sin(alpha);
      final double endX = center.dx - outerRadius * math.cos(alpha);
      final double endY = center.dy + outerRadius * math.sin(alpha);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), dividerPaint);
    }

    // 4. Border stroke for the circular band
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(fullSectorPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant QuarterCircleMenuPainter oldDelegate) {
    return oldDelegate.currentRole != currentRole || oldDelegate.themeColor != themeColor;
  }
}
