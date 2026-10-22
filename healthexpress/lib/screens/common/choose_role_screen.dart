import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'auth_method_screen.dart';

/// Screen wrapper for ChooseRoleSheet
class ChooseRoleScreen extends StatelessWidget {
  final UserRole? initialRole;
  final ValueChanged<UserRole>? onRoleSelected;
  final String? title;
  final String? subtitle;
  final String? buttonLabel;

  const ChooseRoleScreen({
    super.key,
    this.initialRole,
    this.onRoleSelected,
    this.title,
    this.subtitle,
    this.buttonLabel,
  });

  /// Static helper to open directly as a modal bottom sheet anywhere
  static Future<void> show(
    BuildContext context, {
    UserRole? initialRole,
    ValueChanged<UserRole>? onRoleSelected,
    String? title,
    String? subtitle,
    String? buttonLabel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChooseRoleSheet(
        initialRole: initialRole,
        onRoleSelected: onRoleSelected,
        title: title,
        subtitle: subtitle,
        buttonLabel: buttonLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ChooseRoleSheet(
              initialRole: initialRole,
              onRoleSelected: onRoleSelected,
              title: title,
              subtitle: subtitle,
              buttonLabel: buttonLabel,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet utilizing only the space it needs with alternating 3D pop-out role cards
class ChooseRoleSheet extends StatefulWidget {
  final UserRole? initialRole;
  final ValueChanged<UserRole>? onRoleSelected;
  final String? title;
  final String? subtitle;
  final String? buttonLabel;

  const ChooseRoleSheet({
    super.key,
    this.initialRole,
    this.onRoleSelected,
    this.title,
    this.subtitle,
    this.buttonLabel,
  });

  static Future<void> show(
    BuildContext context, {
    UserRole? initialRole,
    ValueChanged<UserRole>? onRoleSelected,
    String? title,
    String? subtitle,
    String? buttonLabel,
  }) =>
      ChooseRoleScreen.show(
        context,
        initialRole: initialRole,
        onRoleSelected: onRoleSelected,
        title: title,
        subtitle: subtitle,
        buttonLabel: buttonLabel,
      );

  @override
  State<ChooseRoleSheet> createState() => _ChooseRoleSheetState();
}

class _ChooseRoleSheetState extends State<ChooseRoleSheet> {
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.user;
  }

  Color get _activeThemeColor {
    switch (_selectedRole) {
      case UserRole.user:
        return AppColors.primary;
      case UserRole.doctor:
        return AppColors.success;
      case UserRole.store:
        return const Color(0xFF0D9488);
      default:
        return AppColors.primary;
    }
  }

  void _handleContinue() {
    final role = _selectedRole;
    if (widget.onRoleSelected != null) {
      widget.onRoleSelected!(role);
      Navigator.of(context).pop();
    } else {
      context.read<AuthProvider>().setRole(role);
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AuthMethodScreen(role: role),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header Row with Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title ?? 'Select Account Role',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle ?? 'Select your account role to continue with a personalized experience.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. User / Patient Option Card (3D Image on LEFT, Radio on RIGHT)
              _buildRoleCard(
                role: UserRole.user,
                title: "I'm a User / Patient",
                description: 'AI diagnosis, doctor consultations, quick medicine delivery & Aarogyasri ID.',
                illustrationAsset: AppIllustrations.rolePatient,
                icon: Icons.person_rounded,
                activeBgColor: AppColors.primaryLight,
                activeBorderColor: AppColors.primary,
                isImageOnLeft: true,
                imageWidth: 72,
              ),
              const SizedBox(height: 16),

              // 2. Doctor Option Card (3D Image on RIGHT, Radio on LEFT - Alternating!)
              _buildRoleCard(
                role: UserRole.doctor,
                title: "I'm a Doctor",
                description: 'Hospital affiliation, patient consultations, Aarogyasri scan & earnings ledger.',
                illustrationAsset: AppIllustrations.roleDoctor,
                icon: Icons.medical_services_rounded,
                activeBgColor: const Color(0xFFF0FDF4),
                activeBorderColor: AppColors.success,
                isImageOnLeft: false,
                imageWidth: 72,
              ),
              const SizedBox(height: 16),

              // 3. Medical Store Partner Option Card (3D Image on LEFT, Radio on RIGHT)
              _buildRoleCard(
                role: UserRole.store,
                title: "I'm a Medical Store Partner",
                description: 'Manage 15-min medicine delivery, drug inventory, opening hours & store orders.',
                illustrationAsset: AppIllustrations.roleStore,
                icon: Icons.local_pharmacy_rounded,
                activeBgColor: const Color(0xFFF0FDFA),
                activeBorderColor: const Color(0xFF0D9488),
                isImageOnLeft: true,
                imageWidth: 72,
              ),
              const SizedBox(height: 22),

              // Continue / Switch Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeThemeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.buttonLabel ?? 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String description,
    required String illustrationAsset,
    required IconData icon,
    required Color activeBgColor,
    required Color activeBorderColor,
    required bool isImageOnLeft,
    double imageWidth = 72,
  }) {
    final isSelected = _selectedRole == role;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card Container (Tappable)
        InkWell(
          onTap: () => setState(() => _selectedRole = role),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(
              left: isImageOnLeft ? (imageWidth + 14) : 14,
              right: isImageOnLeft ? 14 : (imageWidth + 14),
              top: 14,
              bottom: 14,
            ),
            decoration: BoxDecoration(
              color: isSelected ? activeBgColor : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? activeBorderColor : AppColors.border,
                width: isSelected ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? activeBorderColor.withValues(alpha: 0.16)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: isSelected ? 12 : 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // If image is on right, show Radio Button on left
                if (!isImageOnLeft) ...[
                  Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? activeBorderColor : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                ],

                // Text Information (Title & Description)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),

                // If image is on left, show Radio Button on right
                if (isImageOnLeft) ...[
                  const SizedBox(width: 8),
                  Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? activeBorderColor : AppColors.textMuted,
                    size: 22,
                  ),
                ],
              ],
            ),
          ),
        ),

        // 3D Illustration popping out of the card (no box behind, proportional bounds)
        Positioned(
          left: isImageOnLeft ? 6 : null,
          right: isImageOnLeft ? null : 6,
          top: -14,
          bottom: -8,
          width: imageWidth,
          child: IgnorePointer(
            child: Image.asset(
              illustrationAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                icon,
                size: 32,
                color: activeBorderColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
