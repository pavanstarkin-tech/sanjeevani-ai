import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/emergency_medicine_hold_service.dart';

/// Screen displaying Jan Aushadhi generic price comparisons,
/// 75% cost savings calculator, and 30-Minute Emergency Stock Reservations.
class JanAushadhiFinderScreen extends StatefulWidget {
  const JanAushadhiFinderScreen({super.key});

  @override
  State<JanAushadhiFinderScreen> createState() => _JanAushadhiFinderScreenState();
}

class _JanAushadhiFinderScreenState extends State<JanAushadhiFinderScreen> {
  final EmergencyMedicineHoldService _service = EmergencyMedicineHoldService();
  String _searchQuery = '';
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _service.hasActiveHold) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final comparisons = EmergencyMedicineHoldService.catalog.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.brandedName.toLowerCase().contains(q) ||
          item.janAushadhiName.toLowerCase().contains(q) ||
          item.moleculeComposition.toLowerCase().contains(q);
    }).toList();

    final activeHold = _service.activeHold;

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
              'Jan Aushadhi & Emergency Hold',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Up to 75% Generic Savings • 30-Min Stock Lock',
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
            // Active Emergency Hold Token Banner (if reserved)
            if (activeHold != null && !activeHold.isExpired) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              activeHold.holdId,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'LOCK: ${_formatTimer(activeHold.remainingSeconds)}',
                            style: const TextStyle(color: Color(0xFFFDE68A), fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeHold.medicineName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      activeHold.genericComposition,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                    const SizedBox(height: 10),

                    // Pharmacy address & batch info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(activeHold.pharmacyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(activeHold.pharmacyAddress, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Batch: ${activeHold.batchNumber} • Exp: ${activeHold.expiryDate}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10)),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF991B1B),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.phone_rounded, size: 14),
                          label: const Text('Call Chemist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling Chemist: ${activeHold.pharmacyPhone}')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // PMBJP Jan Aushadhi Savings Promo Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.price_check_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pradhan Mantri Jan Aushadhi Grid',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Same clinical efficacy, WHO-GMP certified, at 50% to 80% lower cost.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Search Bar
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search brand or generic molecule (e.g. Augmentin, Insulin)...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 18),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 16),

            // Comparisons List
            ...comparisons.map((item) => _buildComparisonCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(JanAushadhiComparison item) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.brandedName,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.lineThrough),
                    ),
                    Text(
                      item.janAushadhiName,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Column(
                  children: [
                    Text(
                      'SAVE ${item.savingsPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                    Text(
                      '- ₹${item.savingsRupees.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            'Composition: ${item.moleculeComposition}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.5),
          ),
          const SizedBox(height: 10),

          // Price Comparison Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '₹${item.brandedPrice.toStringAsFixed(0)} ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, decoration: TextDecoration.lineThrough),
                  ),
                  Text(
                    '₹${item.janAushadhiPrice.toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const Text(' (PMBJP Price)', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),

              // Emergency 30-min Lock Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E60F6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.lock_rounded, size: 14, color: Colors.white),
                label: const Text(
                  '30-Min Lock',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () {
                  final token = _service.createEmergencyHold(
                    medicineName: item.janAushadhiName,
                    genericComposition: item.moleculeComposition,
                    pharmacyName: 'Jan Aushadhi Kendra #12',
                    pharmacyPhone: '+91 98480 33445',
                    pharmacyAddress: item.nearbyKendraAddress,
                    price: item.janAushadhiPrice,
                  );
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF10B981),
                      content: Text('🔒 30-Minute Hold Reserved! Token: ${token.holdId}. Chemist notified to hold medicine.'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 12, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.nearbyKendraAddress,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
