import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/public_health_surveillance_service.dart';

/// Screen displaying Public Health Syndromic Outbreak Surveillance,
/// Regional Epidemiological Early-Warning Clusters, and Privacy Consent QR Tokens.
class PublicHealthOutbreakHeatmapScreen extends StatefulWidget {
  const PublicHealthOutbreakHeatmapScreen({super.key});

  @override
  State<PublicHealthOutbreakHeatmapScreen> createState() => _PublicHealthOutbreakHeatmapScreenState();
}

class _PublicHealthOutbreakHeatmapScreenState extends State<PublicHealthOutbreakHeatmapScreen> {
  final PublicHealthSurveillanceService _service = PublicHealthSurveillanceService();

  bool _shareVitals = true;
  bool _shareLabs = true;
  bool _shareMeds = true;
  bool _shareNotes = false;
  int _validityMins = 15;

  @override
  Widget build(BuildContext context) {
    final clusters = PublicHealthSurveillanceService.activeClusters;
    final token = _service.activeConsentToken;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Public Health Outbreak Grid',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Syndromic Early Warning & Privacy Tokens',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outbreak Surveillance Header Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF991B1B), Color(0xFF7F1D1D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Anonymized Syndromic Surveillance Active',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Early cluster identification across rural mandals to preposition medicines before peak outbreak.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active Outbreak Clusters
            const Text(
              'Active Disease Clusters & Alerts',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...clusters.map((c) => _buildClusterCard(c)),

            const SizedBox(height: 18),

            // Time-Bound Dynamic EHR Privacy Consent Generator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131D33),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.vpn_key_rounded, color: Color(0xFF38BDF8), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Time-Bound EHR Privacy Token',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('DATA MINIMIZATION', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate a secure QR pass with auto-expiring doctor access. Select which health records to expose:',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5),
                  ),
                  const SizedBox(height: 10),

                  // Checkboxes
                  Row(
                    children: [
                      Expanded(child: _checkboxItem('Vitals', _shareVitals, (v) => setState(() => _shareVitals = v!))),
                      Expanded(child: _checkboxItem('Lab Reports', _shareLabs, (v) => setState(() => _shareLabs = v!))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _checkboxItem('Prescriptions', _shareMeds, (v) => setState(() => _shareMeds = v!))),
                      Expanded(child: _checkboxItem('Doctor Notes', _shareNotes, (v) => setState(() => _shareNotes = v!))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Generate Button
                  Row(
                    children: [
                      DropdownButton<int>(
                        value: _validityMins,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 Minutes')),
                          DropdownMenuItem(value: 60, child: Text('1 Hour')),
                          DropdownMenuItem(value: 120, child: Text('2 Hours')),
                        ],
                        onChanged: (val) => setState(() => _validityMins = val!),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E60F6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.qr_code_rounded, size: 16, color: Colors.white),
                          label: const Text('Generate Token QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          onPressed: () {
                            _service.generateConsentToken(
                              validityMinutes: _validityMins,
                              allowVitals: _shareVitals,
                              allowLabReports: _shareLabs,
                              allowPrescriptions: _shareMeds,
                              allowDoctorNotes: _shareNotes,
                            );
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),

                  // QR Display
                  if (token != null && !token.isExpired) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: QrImageView(
                              data: 'SANJEEVANI_TOKEN:${token.tokenId}|EXP:${token.expiresAt.toIso8601String()}',
                              size: 140,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Token: ${token.tokenId} • Expires in ${token.remainingMinutes} mins',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                            icon: const Icon(Icons.cancel_rounded, size: 14),
                            label: const Text('Revoke Token Immediately', style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              _service.revokeConsentToken();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterCard(SyndromicOutbreakCluster cluster) {
    Color threatColor;
    if (cluster.threatLevel == 'HIGH_OUTBREAK_ALERT') {
      threatColor = const Color(0xFFEF4444);
    } else {
      threatColor = const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: threatColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  cluster.diseaseName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: threatColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: threatColor),
                ),
                child: Text(
                  cluster.threatLevel == 'HIGH_OUTBREAK_ALERT' ? 'OUTBREAK ALERT' : 'MODERATE RISK',
                  style: TextStyle(color: threatColor, fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Location: ${cluster.districtMandal}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5),
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Text(
                'Active Cases: ${cluster.activeCasesReported}',
                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '(+${cluster.weeklyGrowthPercent.toStringAsFixed(1)}% this week)',
                style: TextStyle(color: threatColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public Health Advisory: ${cluster.publicHealthAdvisory}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pre-position Supplies: ${cluster.preStockSuppliesNeeded}',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkboxItem(String title, bool val, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(
          value: val,
          onChanged: onChanged,
          activeColor: const Color(0xFF1E60F6),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
      ],
    );
  }
}
