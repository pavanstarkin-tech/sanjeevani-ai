import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine_model.dart';
import '../../models/medical_store_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../common/address_selection_modal.dart';
import 'cart_checkout_screen.dart';
import 'order_tracking_screen.dart';
import 'ai_lens_scanner_screen.dart';
import '../../models/vision_analysis_model.dart';

class _DeliveryCategoryItem {
  final String title;
  final String subtitle;
  final String assetPath;
  final String diskPath;
  final String categoryKey;

  const _DeliveryCategoryItem({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.diskPath,
    required this.categoryKey,
  });
}

class _HeroImageSlide {
  final String assetPath;
  final String diskPath;
  final String tag;
  final String title;

  const _HeroImageSlide({
    required this.assetPath,
    required this.diskPath,
    required this.tag,
    required this.title,
  });
}

const List<_HeroImageSlide> _heroSlides = [
  _HeroImageSlide(
    assetPath: 'assets/images/delivery/hero_1.png',
    diskPath: r'C:\Users\shese\Desktop\healthyxpress_medha\MEDICAL-DELIVARY\HERO (1).png',
    tag: '⚡ 10-15 MINS DELIVERY',
    title: 'Fast Dark-Store Medicine Express',
  ),
  _HeroImageSlide(
    assetPath: 'assets/images/delivery/hero_2.png',
    diskPath: r'C:\Users\shese\Desktop\healthyxpress_medha\MEDICAL-DELIVARY\HERO (2).png',
    tag: '❄️ 2-8°C COLD CHAIN',
    title: 'Temperature-Safe Genuine Medicines',
  ),
  _HeroImageSlide(
    assetPath: 'assets/images/delivery/hero_3.png',
    diskPath: r'C:\Users\shese\Desktop\healthyxpress_medha\MEDICAL-DELIVARY\HERO (3).png',
    tag: '📋 RX VERIFIED',
    title: 'Instant Prescription Review & Dispatch',
  ),
];

class _PharmacyHeroCarousel extends StatefulWidget {
  const _PharmacyHeroCarousel();

  @override
  State<_PharmacyHeroCarousel> createState() => _PharmacyHeroCarouselState();
}

class _PharmacyHeroCarouselState extends State<_PharmacyHeroCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0, initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _heroSlides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSlideWidget(_HeroImageSlide slide) {
    Widget imageWidget;
    final file = File(slide.diskPath);
    if (file.existsSync()) {
      imageWidget = Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildAssetImage(slide),
      );
    } else {
      imageWidget = _buildAssetImage(slide);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: imageWidget,
    );
  }

  Widget _buildAssetImage(_HeroImageSlide slide) {
    return Image.asset(
      slide.assetPath,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Image.asset(
        'hero/Essential Medicines Within Reach.png',
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF0284C7),
          alignment: Alignment.center,
          child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 165,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _heroSlides.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, idx) => _buildSlideWidget(_heroSlides[idx]),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_heroSlides.length, (idx) {
            final isActive = _currentPage == idx;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _categorySectionKey = GlobalKey();

  String _selectedCategory = 'All';
  bool _isSearchVisible = false;

  // The 4 Specific Categories from MEDICAL-DELIVARY
  static const List<_DeliveryCategoryItem> _deliveryCategories = [
    _DeliveryCategoryItem(
      title: 'Tablets',
      subtitle: 'Pain, Fever, Cough',
      assetPath: 'assets/images/delivery/tablets.png',
      diskPath: r'C:\Users\shese\Desktop\healthyxpress_medha\MEDICAL-DELIVARY\TABLETS.png',
      categoryKey: 'Tablets',
    ),
    _DeliveryCategoryItem(
      title: 'Vitamins',
      subtitle: 'Daily Immunity & Vitality',
      assetPath: 'assets/images/delivery/vitamins.png',
      diskPath: r'C:\Users\shese\Desktop\healthyxpress_medha\MEDICAL-DELIVARY\VITAMINS.png',
      categoryKey: 'Vitamins',
    ),
    _DeliveryCategoryItem(
      title: 'First Aid',
      subtitle: 'Bandages & Antiseptics',
      assetPath: 'assets/images/delivery/first_aid.png',
      diskPath: r'C:\Users\shese\Desktop\healthyxpress_medha\MEDICAL-DELIVARY\FIRSTEID.png',
      categoryKey: 'First Aid',
    ),
    _DeliveryCategoryItem(
      title: 'Medical Equipment',
      subtitle: 'Monitors & Vaporizers',
      assetPath: 'assets/images/delivery/medical_equipment.png',
      diskPath: r'C:\Users\shese\Desktop\healthyxpress_medha\MEDICAL-DELIVARY\MEDICAL-EQUIPMENT.png',
      categoryKey: 'Medical Equipment',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategoryProducts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _categorySectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildCategoryThumbnail(_DeliveryCategoryItem item) {
    final file = File(item.diskPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildAssetThumbnail(item),
      );
    }
    return _buildAssetThumbnail(item);
  }

  Widget _buildAssetThumbnail(_DeliveryCategoryItem item) {
    return Image.asset(
      item.assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.medication_rounded,
        size: 36,
        color: AppColors.primary,
      ),
    );
  }

  void _handleAddToCart(BuildContext context, MedicineModel med, MedicalStoreModel store) {
    final prov = context.read<PharmacyProvider>();
    if (!prov.canAddToCart(store)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.store_mall_directory_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Single Store Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Your cart already contains items from "${prov.cartStore?.name ?? "another dark store"}".\n\nAt a time, you can order from ONE dark store to guarantee 15-minute quick delivery.\n\nWould you like to clear the cart and add "${med.name}" from "${store.name}"?',
            style: const TextStyle(fontSize: 13, height: 1.3),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Keep Existing Cart'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.of(ctx).pop();
                prov.addToCart(med, store);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text('Cart switched to ${store.name}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Replace & Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      prov.addToCart(med, store);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Added "${med.name}" to cart'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildBlinkitAddToCartButton({
    required BuildContext context,
    required MedicineModel med,
    required PharmacyProvider pharmacyProv,
    required MedicalStoreModel store,
  }) {
    final qty = pharmacyProv.getItemQuantity(med.id);

    if (qty == 0) {
      return InkWell(
        onTap: () => _handleAddToCart(context, med, store),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ADD',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.add, size: 14, color: Color(0xFF16A34A)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => pharmacyProv.removeFromCart(med.id),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(Icons.remove, size: 14, color: Colors.white),
            ),
          ),
          Text(
            '$qty',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          InkWell(
            onTap: () => _handleAddToCart(context, med, store),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlinkitProductCard({
    required BuildContext context,
    required MedicineModel med,
    required PharmacyProvider pharmacyProv,
    required MedicalStoreModel store,
  }) {
    final discountPercent = med.originalPrice > med.price
        ? (((med.originalPrice - med.price) / med.originalPrice) * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container fitted to edges with Delivery Tag & Rx Badge
          SizedBox(
            height: 120,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    med.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 120,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight,
                      alignment: Alignment.center,
                      child: const Icon(Icons.medication_rounded, size: 36, color: AppColors.primary),
                    ),
                  ),
                // No time badge

                if (med.requiresPrescription)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Rx',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
          // Product Details
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  med.packSize.isNotEmpty ? med.packSize : med.genericName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '₹${med.price.toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (med.originalPrice > med.price) ...[
                              const SizedBox(width: 4),
                              Text(
                                '₹${med.originalPrice.toInt()}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (discountPercent > 0)
                          Text(
                            '$discountPercent% OFF',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                      ],
                    ),
                    _buildBlinkitAddToCartButton(
                      context: context,
                      med: med,
                      pharmacyProv: pharmacyProv,
                      store: store,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyProv = context.watch<PharmacyProvider>();
    final activeOrder = pharmacyProv.activeOrder;
    final allMedicines = pharmacyProv.medicines;
    final defaultStore = pharmacyProv.medicalStores.isNotEmpty
        ? pharmacyProv.medicalStores.first
        : MedicalStoreModel(
            id: 'STORE-COLD-01',
            name: 'Central Cold Store Dark Hub #04',
            address: 'Hitech City Cold Hub, Hyderabad',
            area: 'Hitech City',
            rating: 4.9,
            reviewCount: 520,
            distanceKm: 1.2,
            etaMinutes: 12,
            is24x7: true,
            isOpen: true,
            phone: '+91 40 6789 0011',
            licenseNumber: 'TS-HYD-COLD-2024-9904',
            imageUrl: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&q=80&w=400',
            availableMedicineIds: allMedicines.map((m) => m.id).toList(),
          );

    // Filter products based on selected category and search text
    final filteredMedicines = allMedicines.where((m) {
      final matchesSearch = _searchController.text.isEmpty ||
          m.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          m.genericName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          m.category.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesCat = _selectedCategory == 'All' ||
          m.category.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medicine Delivery',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary),
            ),
            InkWell(
              onTap: () => AddressSelectionModal.show(context),
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      () {
                        final auth = context.read<AuthProvider>();
                        final addr = pharmacyProv.selectedAddress.isNotEmpty
                            ? pharmacyProv.selectedAddress
                            : (auth.currentUser.address.isNotEmpty ? auth.currentUser.address : 'Select Delivery Address');
                        return 'Deliver to: ${addr.split(',').first.trim()} ▼';
                      }(),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Search Medicines',
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                }
              });
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
                tooltip: 'Cart',
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartCheckoutScreen()));
                },
              ),
              if (pharmacyProv.totalCartCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${pharmacyProv.totalCartCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (activeOrder != null)
            IconButton(
              icon: const Icon(Icons.delivery_dining_rounded, color: AppColors.primary),
              tooltip: 'Live Track Order',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderTrackingScreen()));
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            if (_isSearchVisible) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search medicines, salts, vitamins...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ),
            ],

            // 1. HERO CAROUSEL SECTION (Matching Homepage Auto-Scroll Banner)
            const _PharmacyHeroCarousel(),
            const SizedBox(height: 18),

            // Delivery Promise Pill (Blinkit / Swiggy Instamart style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFFFACC15), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Express Medicine Delivery',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        Text(
                          'Dispatched from verified 2-8°C cold dark store hub',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.ac_unit_rounded, color: Color(0xFF38BDF8), size: 18),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. THE FOUR CATEGORIES (Below Hero Section)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shop by Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                if (_selectedCategory != 'All')
                  GestureDetector(
                    onTap: () => setState(() => _selectedCategory = 'All'),
                    child: const Text(
                      'Clear Filter',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 4 Category Cards in the SAME ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _deliveryCategories.map((cat) {
                final isSelected = _selectedCategory.toLowerCase() == cat.categoryKey.toLowerCase();
                final categoryCount = allMedicines.where((m) => m.category.toLowerCase() == cat.categoryKey.toLowerCase()).length;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (_selectedCategory.toLowerCase() == cat.categoryKey.toLowerCase()) {
                          _selectedCategory = 'All';
                        } else {
                          _selectedCategory = cat.categoryKey;
                        }
                      });
                      _scrollToCategoryProducts();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(minHeight: 122),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        // ABSOLUTELY NO OUTLINE / NO BORDER
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Enlarged category image with NO background circular container
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: _buildCategoryThumbnail(cat),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 28,
                            child: Center(
                              child: Text(
                                cat.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                  fontSize: 10.5,
                                  color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$categoryCount items',
                            style: TextStyle(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Order with Prescription Card -> Redirects to AI Vision & Lens Scanner (Medicine / Prescription Scope)
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AiLensScannerScreen(initialScope: VisionScope.medicine),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order with Prescription',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Upload doctor slip for instant cold store dispatch',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AiLensScannerScreen(initialScope: VisionScope.medicine),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Upload', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // 3. PRODUCT CATALOG HEADER & FILTER CHIPS
            Container(
              key: _categorySectionKey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory == 'All'
                        ? 'Products (${filteredMedicines.length})'
                        : '$_selectedCategory (${filteredMedicines.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  if (_selectedCategory != 'All')
                    ActionChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedCategory, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide.none,
                      onPressed: () => setState(() => _selectedCategory = 'All'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Horizontal Filter Pills (Blinkit style)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill(
                    label: 'All (${allMedicines.length})',
                    isSelected: _selectedCategory == 'All',
                    onTap: () => setState(() => _selectedCategory = 'All'),
                  ),
                  ..._deliveryCategories.map((c) {
                    final count = allMedicines.where((m) => m.category.toLowerCase() == c.categoryKey.toLowerCase()).length;
                    return _buildFilterPill(
                      label: '${c.title} ($count)',
                      isSelected: _selectedCategory.toLowerCase() == c.categoryKey.toLowerCase(),
                      onTap: () => setState(() => _selectedCategory = c.categoryKey),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. 2-COLUMN PRODUCT GRID (Blinkit / Swiggy Instamart)
            if (filteredMedicines.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'No medicines found in "$_selectedCategory"',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => setState(() => _selectedCategory = 'All'),
                      child: const Text('Show All Medicines'),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.67,
                ),
                itemCount: filteredMedicines.length,
                itemBuilder: (context, index) {
                  final med = filteredMedicines[index];
                  return _buildBlinkitProductCard(
                    context: context,
                    med: med,
                    pharmacyProv: pharmacyProv,
                    store: defaultStore,
                  );
                },
              ),
            const SizedBox(height: 90),
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
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartCheckoutScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${pharmacyProv.totalCartCount} ${pharmacyProv.totalCartCount == 1 ? "item" : "items"} | ₹${pharmacyProv.cartTotal.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Text(
                              'View Cart',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF16A34A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
