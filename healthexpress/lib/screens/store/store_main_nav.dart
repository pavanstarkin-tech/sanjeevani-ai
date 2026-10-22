import 'package:flutter/material.dart';
import 'store_dashboard_screen.dart';
import 'store_products_screen.dart';
import 'store_timings_screen.dart';
import 'store_profile_screen.dart';

class StoreMainNav extends StatefulWidget {
  final int initialIndex;
  const StoreMainNav({super.key, this.initialIndex = 0});

  @override
  State<StoreMainNav> createState() => _StoreMainNavState();
}

class _StoreMainNavState extends State<StoreMainNav> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      StoreDashboardScreen(
        onNavigateToProducts: () => setState(() => _currentIndex = 1),
        onNavigateToTimings: () => setState(() => _currentIndex = 2),
      ),
      const StoreProductsScreen(),
      const StoreTimingsScreen(),
      const StoreProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Products',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.schedule_rounded,
                  label: 'Timings',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.store_rounded,
                  label: 'Profile',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0D9488);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : Colors.grey.shade400,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
