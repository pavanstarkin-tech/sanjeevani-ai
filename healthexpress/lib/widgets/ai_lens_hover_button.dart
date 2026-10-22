import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/vision_analysis_model.dart';
import '../screens/user/ai_lens_scanner_screen.dart';

class AiLensHoverButton extends StatefulWidget {
  final VoidCallback? onCustomTap;
  const AiLensHoverButton({super.key, this.onCustomTap});

  @override
  State<AiLensHoverButton> createState() => _AiLensHoverButtonState();
}

class _AiLensHoverButtonState extends State<AiLensHoverButton> {
  bool _isHovered = false;

  void _openScanner(BuildContext context, {VisionScope scope = VisionScope.food}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiLensScannerScreen(initialScope: scope),
      ),
    );
  }

  void _showLensMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: AppColors.aiAssistantGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sanjeevani AI Lens',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Instant Vision Analysis with Groq Cloud AI',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Option 1: Food & Calories
                _LensOptionTile(
                  icon: Icons.restaurant_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFEF3C7),
                  title: 'Snap Food / Dish (Calories & Macros)',
                  subtitle: 'Calculates calories, protein, carbs, fats, glycemic index & related dishes',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openScanner(context, scope: VisionScope.food);
                  },
                ),
                const SizedBox(height: 10),

                // Option 2: Medicine / Tablets
                _LensOptionTile(
                  icon: Icons.medication_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBg: const Color(0xFFDBEAFE),
                  title: 'Snap Medicine / Tablets (Medical Scope)',
                  subtitle: 'Extracts chemical molecule, clinical uses, dosage, precautions & side effects',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openScanner(context, scope: VisionScope.medicine);
                  },
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleVal = _isHovered ? 1.08 : 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onCustomTap != null ? widget.onCustomTap!() : _showLensMenu(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.diagonal3Values(scaleVal, scaleVal, 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: _isHovered ? 0.6 : 0.35),
                blurRadius: _isHovered ? 18 : 12,
                spreadRadius: _isHovered ? 2 : 1,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Camera Lens',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _LensOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LensOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
