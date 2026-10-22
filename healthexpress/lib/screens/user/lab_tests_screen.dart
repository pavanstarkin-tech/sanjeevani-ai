import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/production_database.dart';

class LabTestsScreen extends StatefulWidget {
  const LabTestsScreen({super.key});

  @override
  State<LabTestsScreen> createState() => _LabTestsScreenState();
}

class _LabTestsScreenState extends State<LabTestsScreen> {
  final Set<String> _selectedTestIds = {'TEST-01', 'TEST-02', 'TEST-03'};

  double get _totalAmount {
    return ProductionDatabase.labTests
        .where((t) => _selectedTestIds.contains(t.id))
        .fold(0.0, (sum, t) => sum + t.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Diagnostic Lab Tests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinical Guidance Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Recommended Diagnostics', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Free doorstep sample collection by certified phlebotomists.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.biotech_rounded, color: Colors.white, size: 36),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lab Quality Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FeaturePill(icon: Icons.home_rounded, label: 'Home Collection'),
                _FeaturePill(icon: Icons.timer_rounded, label: 'Reports in 6-24h'),
                _FeaturePill(icon: Icons.verified_user_rounded, label: 'NABL Certified'),
              ],
            ),
            const SizedBox(height: 22),

            // Recommended Tests Checkbox List (Matching Reference Image 4)
            const Text('Recommended Tests for Fever / Viral Symptoms', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Column(
              children: ProductionDatabase.labTests.map((test) {
                final isSelected = _selectedTestIds.contains(test.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedTestIds.add(test.id);
                            } else {
                              _selectedTestIds.remove(test.id);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(test.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text(test.whyRelevant, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Report within ${test.reportDeliveryTime} • ${test.sampleType}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${test.price.toInt()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text('₹${test.originalPrice.toInt()}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Nearby Certified Partner Labs
            const Text('Partner Certified Laboratories', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _LabPartnerTile(name: 'Redcliffe Labs', distance: '1.3 km • 30 mins', rating: 4.6),
            _LabPartnerTile(name: 'Thyrocare Technologies', distance: '2.1 km • 35 mins', rating: 4.5),
            _LabPartnerTile(name: 'Metropolis Healthcare', distance: '2.8 km • 40 mins', rating: 4.4),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Booked ${_selectedTestIds.length} diagnostic tests (₹${_totalAmount.toInt()}). Sample collector assigned!')),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Book Selected Tests • ₹${_totalAmount.toInt()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _LabPartnerTile extends StatelessWidget {
  final String name;
  final String distance;
  final double rating;

  const _LabPartnerTile({required this.name, required this.distance, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.biotech_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(distance, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              Text(' $rating', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
