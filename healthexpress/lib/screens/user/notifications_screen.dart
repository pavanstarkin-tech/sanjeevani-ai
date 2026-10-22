import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'order_tracking_screen.dart';
import 'my_appointments_screen.dart';
import 'health_vitals_dashboard_screen.dart';
import 'government_scheme_explorer_screen.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final IconData icon;
  final Color iconColor;
  final Color badgeBg;
  final String category;
  bool isRead;
  final VoidCallback? onTapAction;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
    required this.badgeBg,
    required this.category,
    this.isRead = false,
    this.onTapAction,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedCategory = 'All';

  late List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      NotificationItem(
        id: 'n1',
        title: 'Medicine Order Out for Delivery 🛵',
        message: 'Your emergency prescription order #HX-9421 is on the way. Live GPS tracking active within 1.2 km radius.',
        timestamp: '10 mins ago',
        icon: Icons.delivery_dining_rounded,
        iconColor: AppColors.primary,
        badgeBg: AppColors.primaryLight,
        category: 'Delivery',
        isRead: false,
        onTapAction: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderTrackingScreen()));
        },
      ),
      NotificationItem(
        id: 'n2',
        title: 'Doctor Appointment Confirmed 🩺',
        message: 'Your teleconsultation with Dr. M. V. Rao (Cardiology) is confirmed for 4:30 PM today.',
        timestamp: '1 hour ago',
        icon: Icons.video_call_rounded,
        iconColor: const Color(0xFF7C3AED),
        badgeBg: const Color(0xFFF3E8FF),
        category: 'Consultation',
        isRead: false,
        onTapAction: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()));
        },
      ),
      NotificationItem(
        id: 'n3',
        title: 'ABDM Health Vitals Recorded 📊',
        message: 'Blood Pressure (120/80 mmHg) and SpO2 (98%) successfully synchronized to your Ayushman Bharat Health Account (ABHA).',
        timestamp: '3 hours ago',
        icon: Icons.favorite_rounded,
        iconColor: AppColors.emergency,
        badgeBg: const Color(0xFFFFE4E6),
        category: 'Vitals',
        isRead: true,
        onTapAction: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HealthVitalsDashboardScreen()));
        },
      ),
      NotificationItem(
        id: 'n4',
        title: 'Government Health Scheme Alert 🏛️',
        message: 'New cashless treatment quota released under Dr. YSR Aarogyasri & PM-JAY scheme for tertiary care hospitals.',
        timestamp: 'Yesterday',
        icon: Icons.policy_rounded,
        iconColor: const Color(0xFFD97706),
        badgeBg: const Color(0xFFFEF3C7),
        category: 'Schemes',
        isRead: true,
        onTapAction: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GovernmentSchemeExplorerScreen()));
        },
      ),
      NotificationItem(
        id: 'n5',
        title: 'Dr. Shanni AI Health Check-in 🤖',
        message: 'Ready to review your recent lab test report or answer any health query anytime offline & online in Telugu, Hindi, or English.',
        timestamp: '2 days ago',
        icon: Icons.smart_toy_rounded,
        iconColor: AppColors.primary,
        badgeBg: AppColors.primaryLight,
        category: 'AI Doctor',
        isRead: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? _notifications
        : _notifications.where((n) => n.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var item in _notifications) {
                  item.isRead = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['All', 'Delivery', 'Consultation', 'Vitals', 'Schemes', 'AI Doctor'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primaryLight,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Notification List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No notifications in this category', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          setState(() {
                            _notifications.removeWhere((n) => n.id == item.id);
                          });
                        },
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              item.isRead = true;
                            });
                            item.onTapAction?.call();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item.isRead ? Colors.white : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
                                width: item.isRead ? 1 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: item.badgeBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(item.icon, color: item.iconColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (!item.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.message,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.timestamp,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
