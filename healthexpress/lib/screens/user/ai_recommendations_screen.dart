import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/pharmacy_provider.dart';
import 'doctor_detail_screen.dart';
import 'pharmacy_screen.dart';
import 'lab_tests_screen.dart';
import 'rmp_doctor_booking_screen.dart';
import 'cart_checkout_screen.dart';

class AiRecommendationsScreen extends StatelessWidget {
  const AiRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<AiAssistantProvider>();
    final pharmacyProv = context.watch<PharmacyProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('AI Recommendations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Symptoms Badges Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Based on your symptoms', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: aiProv.currentSymptoms.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section: Lab Tests Recommended
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recommended Lab Tests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabTestsScreen())),
                  child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...aiProv.suggestedLabTests.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.check_box_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  Text('₹${t.price.toInt()} • Reports in ${t.reportDeliveryTime}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabTestsScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Book Recommended Tests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Medicines Suggested
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Suggested Medicines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PharmacyScreen())),
                  child: const Text('Pharmacy', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              children: aiProv.suggestedMedicines.map((med) {
                final qty = pharmacyProv.getItemQuantity(med.id);
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
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('${med.packSize} • ${med.category}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text('₹${med.price.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                      qty == 0
                          ? ElevatedButton(
                              onPressed: () => pharmacyProv.addToCart(med),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryLight,
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16, color: AppColors.primary),
                                    onPressed: () => pharmacyProv.removeFromCart(med.id),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                                    onPressed: () => pharmacyProv.addToCart(med),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Section: Recommended Doctors
            const Text('Suggested Doctors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Column(
              children: aiProv.suggestedDoctors.map((doc) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(doc.photoUrl),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('${doc.specialty} • ${doc.hospitalName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                Text(' ${doc.rating} (${doc.reviewCount})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Text('₹${doc.clinicFee.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doc)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Doorstep RMP Doctor Card Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Can\'t visit hospital?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Book an RMP doctor for doorstep diagnosis & treatment.', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RmpDoctorBookingScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Book Home Visit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: pharmacyProv.totalCartCount > 0
          ? Container(
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
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartCheckoutScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('View Cart (${pharmacyProv.totalCartCount} items)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          ],
                        ),
                        Text('₹${pharmacyProv.cartTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
