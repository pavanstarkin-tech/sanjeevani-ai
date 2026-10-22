import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/doctor_portal_provider.dart';

class DoctorAnalyticsScreen extends StatelessWidget {
  const DoctorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorPortalProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Doctor Practice Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Chart Card (Matching Reference Image 2)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Earnings Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                        child: const Text('This Week ▼', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('₹${doctorProv.todayEarnings.toInt()}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                        child: const Text('+18% vs last week', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Simulated Modern Line Graph
                  Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CustomPaint(
                      painter: _LineChartPainter(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Mon', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      Text('Tue', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      Text('Wed', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      Text('Thu', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      Text('Fri', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      Text('Sat', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      Text('Sun', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Patients Mode Breakdown Donut Chart Card (Matching Reference Image 2)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Patients Consultation Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Donut Circle Center
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2563EB), width: 14),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${doctorProv.totalPatients}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                              const Text('Total', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _DonutLegend(color: Color(0xFF2563EB), label: 'In Clinic', percent: '60%'),
                            SizedBox(height: 8),
                            _DonutLegend(color: Color(0xFF0EA5E9), label: 'Video Consult', percent: '25%'),
                            SizedBox(height: 8),
                            _DonutLegend(color: Color(0xFF10B981), label: 'RMP Home Visit', percent: '15%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Patient Satisfaction Metrics
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Patient Satisfaction & Feedback', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('4.8 / 5.0 Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('Based on 350+ verified patient reviews', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF2563EB).withValues(alpha: 0.3), const Color(0xFF2563EB).withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(size.width * 0.2, size.height * 0.8, size.width * 0.35, size.height * 0.3, size.width * 0.5, size.height * 0.4);
    path.cubicTo(size.width * 0.65, size.height * 0.5, size.width * 0.8, size.height * 0.15, size.width, size.height * 0.25);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String percent;

  const _DonutLegend({required this.color, required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(percent, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
