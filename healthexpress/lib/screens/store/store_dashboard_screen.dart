import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../services/central_data_service.dart';

class StoreDashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToProducts;
  final VoidCallback? onNavigateToTimings;

  const StoreDashboardScreen({
    super.key,
    this.onNavigateToProducts,
    this.onNavigateToTimings,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final storeProvider = context.watch<StoreProvider>();
    final store = auth.currentStore;
    final activeEmergency = CentralDataService.instance.activeEmergency;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              store.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: store.isOpen ? const Color(0xFF16A34A) : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  store.isOpen ? 'STORE ACTIVE • 15-MIN DISPATCH' : 'STORE CURRENTLY CLOSED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: store.isOpen ? const Color(0xFF16A34A) : Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          // Open / Closed Quick Switch
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Text(
                  store.isOpen ? 'Open' : 'Closed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: store.isOpen ? const Color(0xFF0D9488) : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: store.isOpen,
                  activeThumbColor: const Color(0xFF0D9488),
                  onChanged: (val) {
                    auth.toggleStoreOpen();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val ? 'Store is now LIVE for 15-min orders!' : 'Store is paused. No new orders will arrive.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Emergency SOS Alert Banner for Pharmacy Supply
            if (activeEmergency != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.emergency, width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.emergency.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.emergency, shape: BoxShape.circle),
                          child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🚨 PRIORITY EMERGENCY SOS IN PROXIMITY', style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.w900, fontSize: 13)),
                              Text('Standby for urgent trauma & emergency medicine kit request', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.emergency, borderRadius: BorderRadius.circular(6)),
                          child: Text(activeEmergency.etaMinutes, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Patient: ${activeEmergency.patientName} (${activeEmergency.patientPhone})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('Location: ${activeEmergency.location}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Store Status & Timings Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Partner Verification:',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'APPROVED',
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'DL: ${store.licenseNumber}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: onNavigateToTimings,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_calendar_rounded, size: 14, color: Color(0xFF0D9488)),
                              SizedBox(width: 4),
                              Text(
                                'Timings',
                                style: TextStyle(color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            store.is24x7 ? '24 Hours Open (Night Service)' : '${store.openingTime} - ${store.closingTime}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        store.area,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4 Key Performance Indicators
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Active Orders',
                    value: '${storeProvider.activeOrdersCount}',
                    subtitle: '15-Min Deliveries',
                    icon: Icons.delivery_dining_rounded,
                    color: const Color(0xFF0D9488),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'In-Stock Drugs',
                    value: '${storeProvider.inStockCount}/${storeProvider.totalProductsCount}',
                    subtitle: 'Active Catalog',
                    icon: Icons.medication_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: "Today's Revenue",
                    value: '₹${storeProvider.todayRevenue.toStringAsFixed(0)}',
                    subtitle: 'Direct Razorpay',
                    icon: Icons.currency_rupee_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Customer Rating',
                    value: '4.8 ★',
                    subtitle: 'From 120+ Patients',
                    icon: Icons.star_rounded,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 15-Min Express Rider Dispatch Banner
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'EXPRESS DISPATCH',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '15-Min Delivery Active',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Riders standby within 1.5 km of your store for instantaneous medicine pickup.',
                          style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset(
                    AppIllustrations.storeDeliveryBike,
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            // Live Order Fulfillment Queue
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live 15-Min Orders Queue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${storeProvider.activeOrdersCount} Pending',
                    style: const TextStyle(color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (storeProvider.orders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDFA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF0D9488)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No 15-Min Delivery Orders Right Now',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'When nearby patients place 15-minute pharmacy orders, they will appear here instantly for rapid packing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: storeProvider.orders.length,
                itemBuilder: (context, index) {
                final order = storeProvider.orders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order.id,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          _buildStatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Patient: ${order.patientName} • ${order.patientPhone}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.address,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.items.join(', '),
                              style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '₹${order.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Order Actions
                      Row(
                        children: [
                          if (order.status == 'incoming')
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    storeProvider.updateOrderStatus(order.id, 'packing');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Order ${order.id} is now PACKING')),
                                    );
                                  },
                                  icon: const Icon(Icons.inventory_2_rounded, size: 14, color: Colors.white),
                                  label: const Text('Accept & Pack Medicines', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D9488),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ),
                          if (order.status == 'packing')
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    storeProvider.updateOrderStatus(order.id, 'dispatched');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Order ${order.id} handed to delivery rider')),
                                    );
                                  },
                                  icon: const Icon(Icons.moped_rounded, size: 14, color: Colors.white),
                                  label: const Text('Handover to 15-Min Rider', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ),
                          if (order.status == 'dispatched')
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    storeProvider.updateOrderStatus(order.id, 'delivered');
                                  },
                                  icon: const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                                  label: const Text('Confirm Doorstep Delivery', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ),
                          if (order.status == 'delivered')
                            const Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.done_all_rounded, color: Color(0xFF16A34A), size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Delivered in 14 mins',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, size: 15, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'incoming':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'NEW ORDER';
        break;
      case 'packing':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0284C7);
        label = 'PACKING';
        break;
      case 'dispatched':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF9333EA);
        label = 'WITH RIDER';
        break;
      case 'delivered':
      default:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        label = 'DELIVERED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
