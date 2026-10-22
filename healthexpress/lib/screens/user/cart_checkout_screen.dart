import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../common/address_selection_modal.dart';
import '../common/patient_detail_collection_dialog.dart';
import 'order_tracking_screen.dart';

class CartCheckoutScreen extends StatelessWidget {
  const CartCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pharmacyProv = context.watch<PharmacyProvider>();
    final fulfillingStore = pharmacyProv.cartStore ?? pharmacyProv.selectedStore ?? pharmacyProv.medicalStores[0];
    final deliveryAddress = pharmacyProv.selectedAddress.isNotEmpty
        ? pharmacyProv.selectedAddress
        : (auth.currentUser.address.isNotEmpty
            ? auth.currentUser.address
            : 'Live GPS Current Location');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Cart & Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
      ),
      body: pharmacyProv.cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 70, color: AppColors.textMuted),
                  const SizedBox(height: 14),
                  const Text('Your cart is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Browse Medicines', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fulfilling Pharmacy Store Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                          child: const Icon(Icons.store_mall_directory_rounded, color: AppColors.success, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    fulfillingStore.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                fulfillingStore.address,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '⚡ 15-Minute Doorstep Fulfillment',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivery Address Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivering to Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(deliveryAddress, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              Text(
                                'Recipient: ${auth.currentUser.name} (${auth.currentUser.phone})',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => AddressSelectionModal.show(context),
                          child: const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Cart Items
                  const Text('Order Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: pharmacyProv.cart.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.medicine.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    Text('₹${item.medicine.price.toInt()} x ${item.quantity}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 14, color: AppColors.primary),
                                      onPressed: () => pharmacyProv.removeFromCart(item.medicine.id),
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      padding: EdgeInsets.zero,
                                    ),
                                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                                      onPressed: () => pharmacyProv.addToCart(item.medicine, fulfillingStore),
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('₹${item.totalPrice.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Bill Details
                  const Text('Bill Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Items Total', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            Text('₹${pharmacyProv.cartSubtotal.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('15-Min Quick Delivery', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            Text(pharmacyProv.deliveryFee == 0 ? 'FREE' : '₹${pharmacyProv.deliveryFee.toInt()}',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: pharmacyProv.deliveryFee == 0 ? AppColors.success : AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('To Pay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('₹${pharmacyProv.cartTotal.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: pharmacyProv.cart.isNotEmpty
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
                    onPressed: () async {
                      if (!auth.isProfileComplete) {
                        final ok = await PatientDetailCollectionDialog.ensureDetails(
                          context,
                          title: 'Confirm Contact Details',
                          description: 'Please verify your phone number and delivery name for rider coordination.',
                        );
                        if (!ok) return;
                      }

                      pharmacyProv.placeOrderForUser(
                        userId: auth.currentUser.id,
                        patientName: auth.currentUser.name,
                        patientPhone: auth.currentUser.phone,
                      );

                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Place Order • ₹${pharmacyProv.cartTotal.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
