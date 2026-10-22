import 'package:flutter/material.dart';
import '../../services/government_scheme_service.dart';

/// Screen exploring Government Healthcare Schemes (Ayushman Bharat PM-JAY
/// & Dr. YSR Aarogyasri), package rates, eligibility, and cashless helpdesk.
class GovernmentSchemeExplorerScreen extends StatefulWidget {
  const GovernmentSchemeExplorerScreen({super.key});

  @override
  State<GovernmentSchemeExplorerScreen> createState() => _GovernmentSchemeExplorerScreenState();
}

class _GovernmentSchemeExplorerScreenState extends State<GovernmentSchemeExplorerScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Cardiology',
    'Orthopedics',
    'Nephrology',
    'Oncology',
    'Maternal & Child',
    'Polytrauma',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredPackages = GovernmentSchemeService.packages.where((pkg) {
      final matchesCategory = _selectedCategory == 'All' || pkg.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          pkg.procedureName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pkg.packageCode.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

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
              'Govt Schemes & Packages',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'PM-JAY ₹5L • Aarogyasri ₹25L Cashless',
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
            // Schemes Hero Cards (Aarogyasri + PM-JAY)
            Row(
              children: [
                Expanded(
                  child: _buildSchemeCard(
                    title: 'Dr. YSR Aarogyasri',
                    coverage: '₹25 LAKH',
                    subtext: 'State Scheme • 3,257 Procedures',
                    color: const Color(0xFF10B981),
                    icon: Icons.shield_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSchemeCard(
                    title: 'Ayushman Bharat',
                    coverage: '₹5 LAKH',
                    subtext: 'PM-JAY • Nationwide 27,000+ Hosps',
                    color: const Color(0xFF38BDF8),
                    icon: Icons.account_balance_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Pre-Auth Workflow Tracker Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF131D33),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timeline_rounded, color: Color(0xFFF59E0B), size: 18),
                          SizedBox(width: 6),
                          Text('Cashless Approval Pipeline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ],
                      ),
                      Text('Emergency: Instant', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _pipelineStep('1. E-Card Scan', true),
                      _pipelineDivider(),
                      _pipelineStep('2. Pre-Auth Sent', true),
                      _pipelineDivider(),
                      _pipelineStep('3. Trust Review', true),
                      _pipelineDivider(),
                      _pipelineStep('4. Free Surgery', true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Search Bar
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search surgery or package (e.g. Stent, Knee, Dialysis)...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 18),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 12),

            // Category Pills
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(cat, style: const TextStyle(fontSize: 11.5)),
                      selectedColor: const Color(0xFF1E60F6),
                      backgroundColor: const Color(0xFF1E293B),
                      side: BorderSide(color: isSelected ? const Color(0xFF38BDF8) : Colors.white12),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Packages List
            ...filteredPackages.map((pkg) => _buildPackageCard(pkg)),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeCard({
    required String title,
    required String coverage,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131D33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(coverage, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(subtext, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPackageCard(GovernmentTreatmentPackage pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pkg.procedureName,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Text('100% FREE', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Code: ${pkg.packageCode} • ${pkg.category}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
              const Spacer(),
              Text(
                'Package: ₹${pkg.standardPackageRate.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_rounded, size: 12, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text('Required Documents: ${pkg.requiredDocuments.join(', ')}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_rounded, size: 12, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    Text('Pre-Auth Approval: ${pkg.preAuthApprovalTimeHours}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pipelineStep(String label, bool isDone) {
    return Column(
      children: [
        Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isDone ? const Color(0xFF10B981) : Colors.white30, size: 14),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ],
    );
  }

  Widget _pipelineDivider() {
    return Container(width: 14, height: 1, color: Colors.white24);
  }
}
