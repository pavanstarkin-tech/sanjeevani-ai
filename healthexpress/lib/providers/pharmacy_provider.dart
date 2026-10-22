import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/medicine_model.dart';
import '../models/medical_store_model.dart';
import '../data/production_database.dart';
import '../services/api_service.dart';
import '../services/central_data_service.dart';

class ActiveOrder {
  final String orderId;
  final String userId;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String deliveryAddress;
  DeliveryStatus status;

  // Store Details
  final String storeId;
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String storeImageUrl;
  final String storeLicense;

  // Delivery Partner Details
  final String driverName;
  final String driverPhone;
  final String etaMinutes;
  final DateTime orderTime;

  ActiveOrder({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    this.status = DeliveryStatus.orderConfirmed,
    required this.storeId,
    required this.storeName,
    required this.storePhone,
    required this.storeAddress,
    required this.storeImageUrl,
    required this.storeLicense,
    this.driverName = 'Ravi Kumar',
    this.driverPhone = '+91 9848123456',
    this.etaMinutes = '14 mins',
    required this.orderTime,
  });
}

class PharmacyProvider extends ChangeNotifier {
  final CentralDataService _central = CentralDataService.instance;
  final List<MedicineModel> _medicines = List.from(ProductionDatabase.medicines);
  final List<MedicalStoreModel> _medicalStores = List.from(ProductionDatabase.medicalStores);
  MedicalStoreModel? _selectedStore;
  MedicalStoreModel? _cartStore;
  bool _isLoading = false;

  // Empty cart by default for clean session
  final List<CartItemModel> _cart = [];

  String _selectedAddress = '';
  String? _uploadedPrescriptionPath;

  PharmacyProvider() {
    _central.addListener(_onCentralChanged);
    loadFromLiveBackend();
  }

  void syncUserAddress(String? userAddress) {
    if (userAddress != null && userAddress.trim().isNotEmpty) {
      _selectedAddress = userAddress.trim();
      notifyListeners();
    }
  }

  void _onCentralChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _central.removeListener(_onCentralChanged);
    super.dispose();
  }

  bool get isLoading => _isLoading;

  Future<void> loadFromLiveBackend() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Ensure all 52 curated products across the 4 categories are always retained
      final Map<String, MedicineModel> map = {};
      for (final m in ProductionDatabase.medicines) {
        map[m.id] = m;
      }
      _medicines.clear();
      _medicines.addAll(map.values);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  List<MedicineModel> get medicines => _medicines;
  List<MedicalStoreModel> get medicalStores => _medicalStores;
  MedicalStoreModel? get selectedStore => _selectedStore;
  MedicalStoreModel? get cartStore => _cartStore;
  List<CartItemModel> get cart => _cart;
  String get selectedAddress => _selectedAddress;
  String? get uploadedPrescriptionPath => _uploadedPrescriptionPath;

  ActiveOrder? getActiveOrderForUser(String userId) {
    final centralActive = _central.getUserActiveOrder(userId);
    if (centralActive == null) return null;
    return ActiveOrder(
      orderId: centralActive.orderId,
      userId: centralActive.userId,
      items: centralActive.rawItems,
      subtotal: centralActive.subtotal,
      deliveryFee: centralActive.deliveryFee,
      total: centralActive.totalAmount,
      deliveryAddress: centralActive.address,
      status: centralActive.deliveryStatus,
      storeId: centralActive.storeId,
      storeName: centralActive.storeName,
      storePhone: centralActive.storePhone,
      storeAddress: centralActive.storeAddress,
      storeImageUrl: centralActive.storeImageUrl,
      storeLicense: centralActive.storeLicense,
      driverName: centralActive.driverName,
      driverPhone: centralActive.driverPhone,
      etaMinutes: centralActive.etaMinutes,
      orderTime: centralActive.orderTime,
    );
  }

  ActiveOrder? get activeOrder {
    // Default active order fallback for UI backwards compatibility
    if (_central.orders.isEmpty) return null;
    final centralActive = _central.orders.first;
    return ActiveOrder(
      orderId: centralActive.orderId,
      userId: centralActive.userId,
      items: centralActive.rawItems,
      subtotal: centralActive.subtotal,
      deliveryFee: centralActive.deliveryFee,
      total: centralActive.totalAmount,
      deliveryAddress: centralActive.address,
      status: centralActive.deliveryStatus,
      storeId: centralActive.storeId,
      storeName: centralActive.storeName,
      storePhone: centralActive.storePhone,
      storeAddress: centralActive.storeAddress,
      storeImageUrl: centralActive.storeImageUrl,
      storeLicense: centralActive.storeLicense,
      driverName: centralActive.driverName,
      driverPhone: centralActive.driverPhone,
      etaMinutes: centralActive.etaMinutes,
      orderTime: centralActive.orderTime,
    );
  }

  void selectStore(MedicalStoreModel? store) {
    if (_selectedStore?.id == store?.id) {
      _selectedStore = null;
    } else {
      _selectedStore = store;
    }
    notifyListeners();
  }

  List<MedicineModel> getMedicinesForStore() {
    if (_selectedStore == null) {
      return _medicines;
    }
    return _medicines.where((m) => _selectedStore!.availableMedicineIds.contains(m.id)).toList();
  }

  int get totalCartCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get cartSubtotal => _cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get deliveryFee => (cartSubtotal > 199.0 || cartSubtotal == 0) ? 0.0 : 25.0;
  double get cartTotal => cartSubtotal + deliveryFee;

  /// Check if an item can be added to the cart without store conflict
  bool canAddToCart(MedicalStoreModel store) {
    if (_cart.isEmpty || _cartStore == null) return true;
    return _cartStore!.id == store.id;
  }

  /// Add to Cart with single-store check
  void addToCart(MedicineModel medicine, [MedicalStoreModel? store]) {
    final effectiveStore = store ?? _selectedStore ?? _medicalStores[0];
    if (_cart.isEmpty) {
      _cartStore = effectiveStore;
    } else if (_cartStore != null && _cartStore!.id != effectiveStore.id) {
      // Different store: reset to new store
      _cart.clear();
      _cartStore = effectiveStore;
    }

    final index = _cart.indexWhere((c) => c.medicine.id == medicine.id);
    if (index != -1) {
      _cart[index].quantity++;
    } else {
      _cart.add(CartItemModel(medicine: medicine, quantity: 1));
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _cartStore = null;
    notifyListeners();
  }

  void removeFromCart(String medicineId) {
    final index = _cart.indexWhere((c) => c.medicine.id == medicineId);
    if (index != -1) {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
      if (_cart.isEmpty) {
        _cartStore = null;
      }
      notifyListeners();
    }
  }

  int getItemQuantity(String medicineId) {
    final item = _cart.firstWhere(
      (c) => c.medicine.id == medicineId,
      orElse: () => CartItemModel(medicine: _medicines[0], quantity: 0),
    );
    return item.quantity;
  }

  void uploadPrescription(String path) {
    _uploadedPrescriptionPath = path;
    notifyListeners();
  }

  void setAddress(String address) {
    _selectedAddress = address;
    notifyListeners();
  }

  ActiveOrder placeOrderForUser({
    required String userId,
    required String patientName,
    required String patientPhone,
  }) {
    final store = _cartStore ?? _selectedStore ?? _medicalStores[0];
    final order = _central.placeNewOrder(
      userId: userId,
      patientName: patientName,
      patientPhone: patientPhone,
      deliveryAddress: _selectedAddress,
      items: _cart,
      subtotal: cartSubtotal,
      deliveryFee: deliveryFee,
      total: cartTotal,
      storeId: store.id,
      storeName: store.name,
      storePhone: store.phone,
      storeAddress: store.address,
      storeImageUrl: store.imageUrl,
      storeLicense: store.licenseNumber,
    );

    _cart.clear();
    _cartStore = null;
    _uploadedPrescriptionPath = null;
    notifyListeners();

    // Sync 15-minute quick delivery order to backend
    ApiService.createPharmacyOrder(
      userId: userId,
      items: order.rawItems.map((item) => {
        'medicineId': item.medicine.id,
        'name': item.medicine.name,
        'qty': item.quantity,
        'price': item.medicine.price,
      }).toList(),
      totalAmount: order.totalAmount,
      deliveryAddress: order.address,
    );

    return ActiveOrder(
      orderId: order.orderId,
      userId: order.userId,
      items: order.rawItems,
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      total: order.totalAmount,
      deliveryAddress: order.address,
      status: order.deliveryStatus,
      storeId: order.storeId,
      storeName: order.storeName,
      storePhone: order.storePhone,
      storeAddress: order.storeAddress,
      storeImageUrl: order.storeImageUrl,
      storeLicense: order.storeLicense,
      driverName: order.driverName,
      driverPhone: order.driverPhone,
      etaMinutes: order.etaMinutes,
      orderTime: order.orderTime,
    );
  }

  ActiveOrder placeOrder() {
    return placeOrderForUser(
      userId: 'USR-101',
      patientName: 'Rahul Kumar',
      patientPhone: '+91 98765 43210',
    );
  }

  void advanceOrderStatus([String? userId]) {
    _central.advanceActiveOrderStatus(userId ?? 'USR-101');
  }
}
