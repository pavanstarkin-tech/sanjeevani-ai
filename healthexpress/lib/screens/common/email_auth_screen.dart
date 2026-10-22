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

class EmailAuthScreen extends StatefulWidget {
  final UserRole role;
  final bool initialSignUp;

  const EmailAuthScreen({
    super.key,
    required this.role,
    this.initialSignUp = false,
  });

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _obscurePassword = true;
  late bool _isSignIn;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isSignIn = !widget.initialSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _roleTitle {
    switch (widget.role) {
      case UserRole.doctor:
        return '🩺 Doctor Portal';
      case UserRole.store:
        return '🏪 Store Partner';
      case UserRole.user:
      default:
        return '👤 Patient Account';
    }
  }

  Color get _themeColor {
    switch (widget.role) {
      case UserRole.doctor:
        return AppColors.success;
      case UserRole.store:
        return const Color(0xFF0D9488);
      case UserRole.user:
      default:
        return AppColors.primary;
    }
  }

  void _routeAfterAuth() {
    if (!mounted) return;
    if (widget.role == UserRole.doctor) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DoctorMainNav()),
        (route) => false,
      );
    } else if (widget.role == UserRole.store) {
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
    if (widget.role == UserRole.doctor) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DoctorOnboardingScreen(
            initialName: name,
            initialEmail: email,
            initialPhone: phone,
          ),
        ),
      );
    } else if (widget.role == UserRole.store) {
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

  Future<void> _submitEmailPassword() async {
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
          role: widget.role,
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
          role: widget.role,
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    try {
      final session = await auth.loginWithGoogle(role: widget.role);
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
        _routeToRoleDetailCollection(
          name: session.displayName,
          email: session.email,
        );
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

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered email address and Firebase will send you a password reset link.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'user@example.com',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final resetEmail = resetEmailController.text.trim();
              if (resetEmail.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await FirebaseAuthService.sendPasswordResetEmail(email: resetEmail);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Password reset email sent to $resetEmail via Firebase!'),
                    ),
                  );
                }
              } catch (err) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(err.toString().replaceAll('Exception: ', '')),
                    ),
                  );
                }
              }
            },
            child: const Text('Send Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Role Badge & 3D Graphic
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _roleTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _themeColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Firebase Auth',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3D Visual Artwork
              Center(
                child: Image.asset(
                  AppIllustrations.otpSecurity,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              Text(
                _isSignIn ? 'Welcome Back 👋' : 'Create Account 🚀',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignIn
                    ? 'Sign in with your verified Firebase credentials'
                    : 'Register your details to create a new live account',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Sign In / Sign Up Segmented Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isSignIn = true;
                          _errorMessage = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSignIn ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isSignIn
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isSignIn ? _themeColor : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isSignIn = false;
                          _errorMessage = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isSignIn ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isSignIn
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isSignIn ? _themeColor : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error Banner (if error occurred)
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sign Up Name Field
                    if (!_isSignIn) ...[
                      const Text(
                        'Full Name',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(
                          hintText: widget.role == UserRole.doctor ? 'Dr. John Doe' : 'John Doe',
                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textSecondary),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: _themeColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mobile Number (Optional)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        decoration: InputDecoration(
                          hintText: '+91 98480 12345',
                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.textSecondary),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: _themeColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email Field
                    const Text(
                      'Email Address',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email, AutofillHints.username],
                      decoration: InputDecoration(
                        hintText: 'name@example.com',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _themeColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Password',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        if (_isSignIn)
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(fontSize: 13, color: _themeColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: _isSignIn ? const [AutofillHints.password] : const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _themeColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitEmailPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _isSignIn ? 'Sign In with Firebase' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // OR Divider
              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                ],
              ),
              const SizedBox(height: 20),

              // Continue with Google Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google_logo.png',
                        height: 22,
                        width: 22,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Toggle Mode Footer
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignIn ? "Don't have an account?" : "Already have an account?",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                          color: _themeColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
