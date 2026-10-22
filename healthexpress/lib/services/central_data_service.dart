import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/appointment_model.dart';
import '../models/medicine_model.dart';

class CentralOrderModel {
  final String orderId;
  final String userId;
  final String patientName;
  final String patientPhone;
  final String address;
  final List<String> itemNames;
  final List<CartItemModel> rawItems;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final DateTime orderTime;
  DeliveryStatus deliveryStatus;
  
  // Fulfilling Medical Store Details
  final String storeId;
  final String storeName;
  final String storePhone;
  final String storeAddress;
  final String storeImageUrl;
  final String storeLicense;

  // Delivery Partner Details
  String driverName;
  String driverPhone;
  String etaMinutes;

  CentralOrderModel({
    required this.orderId,
    required this.userId,
    required this.patientName,
    required this.patientPhone,
    required this.address,
    required this.itemNames,
    required this.rawItems,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.orderTime,
    this.deliveryStatus = DeliveryStatus.orderConfirmed,
    this.storeId = 'STORE-01',
    this.storeName = 'Apollo Pharmacy 24x7',
    this.storePhone = '+91 40 2360 8888',
    this.storeAddress = 'Plot 12, Phase 2, Hitech City Main Rd, Hyderabad',
    this.storeImageUrl = 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400',
    this.storeLicense = 'TS-HYD-PHARM-2024-8801',
    this.driverName = 'Ravi Kumar',
    this.driverPhone = '+91 9848123456',
    this.etaMinutes = '15 mins',
  });

  String get storeStatusString {
    switch (deliveryStatus) {
      case DeliveryStatus.orderConfirmed:
        return 'incoming';
      case DeliveryStatus.packed:
        return 'packing';
      case DeliveryStatus.outForDelivery:
        return 'dispatched';
      case DeliveryStatus.delivered:
        return 'delivered';
    }
  }

  void updateFromStoreStatus(String storeStatus) {
    switch (storeStatus.toLowerCase()) {
      case 'incoming':
        deliveryStatus = DeliveryStatus.orderConfirmed;
        break;
      case 'packing':
        deliveryStatus = DeliveryStatus.packed;
        break;
      case 'dispatched':
        deliveryStatus = DeliveryStatus.outForDelivery;
        break;
      case 'delivered':
        deliveryStatus = DeliveryStatus.delivered;
        break;
    }
  }
}

class EmergencyDispatchModel {
  final String id;
  final String userId;
  final String patientName;
  final String patientPhone;
  final String emergencyType;
  final String ambulanceProvider;
  final String location;
  final double latitude;
  final double longitude;
  final String etaMinutes;
  final String status; // 'dispatched' | 'en_route' | 'arrived' | 'completed'
  final DateTime dispatchedAt;
  final String hospitalName;
  final String notes;

  EmergencyDispatchModel({
    required this.id,
    required this.userId,
    required this.patientName,
    required this.patientPhone,
    required this.emergencyType,
    required this.ambulanceProvider,
    required this.location,
    this.latitude = 17.4400,
    this.longitude = 78.3489,
    required this.etaMinutes,
    this.status = 'dispatched',
    required this.dispatchedAt,
    this.hospitalName = 'KIMS Hospitals Emergency & Trauma',
    this.notes = 'Priority Emergency SOS',
  });
}

class CentralDataService extends ChangeNotifier {
  static final CentralDataService instance = CentralDataService._internal();

  CentralDataService._internal() {
    _initializeData();
  }

  final List<AppointmentModel> _appointments = [];
  final List<CentralOrderModel> _orders = [];
  final List<EmergencyDispatchModel> _emergencyDispatches = [];

  List<AppointmentModel> get appointments => List.unmodifiable(_appointments);
  List<CentralOrderModel> get orders => List.unmodifiable(_orders);
  List<EmergencyDispatchModel> get emergencyDispatches => List.unmodifiable(_emergencyDispatches);

  EmergencyDispatchModel? get activeEmergency => _emergencyDispatches.isNotEmpty && _emergencyDispatches.first.status != 'completed'
      ? _emergencyDispatches.first
      : null;

  void _initializeData() {
    // Start with empty real user appointments
    _appointments.clear();
  }

  // ==========================================
  // APPOINTMENT OPERATIONS (Sync Patient & Doctor)
  // ==========================================

  List<AppointmentModel> getUserAppointments(String userId) {
    return _appointments.where((a) => a.userId == userId).toList();
  }

  void addAppointment(AppointmentModel appt) {
    _appointments.insert(0, appt);
    notifyListeners();
  }

  void updateAppointmentStatus(String id, AppointmentStatus status) {
    final index = _appointments.indexWhere((a) => a.id == id);
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void recordDoctorPrescription({
    required String appointmentId,
    required String doctorNotes,
    required List<PrescriptionItem> prescription,
    required List<String> recommendedTests,
  }) {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(
        status: AppointmentStatus.completed,
        doctorNotes: doctorNotes,
        prescription: prescription,
        recommendedTests: recommendedTests,
      );
      notifyListeners();
    }
  }

  List<AppointmentModel> getDoctorAppointments(String doctorId) {
    return _appointments.where((a) => a.doctorId == doctorId || doctorId == 'DOC-01').toList();
  }

  // ==========================================
  // PHARMACY & STORE ORDERS (Sync Patient & Store)
  // ==========================================

  List<CentralOrderModel> getUserOrders(String userId) {
    return _orders.where((o) => o.userId == userId).toList();
  }

  CentralOrderModel? getUserActiveOrder(String userId) {
    final userOrders = getUserOrders(userId);
    if (userOrders.isEmpty) return null;
    return userOrders.first;
  }

  CentralOrderModel placeNewOrder({
    required String userId,
    required String patientName,
    required String patientPhone,
    required String deliveryAddress,
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    required String storeId,
    required String storeName,
    required String storePhone,
    required String storeAddress,
    required String storeImageUrl,
    required String storeLicense,
  }) {
    final orderId = '#HE${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final newOrder = CentralOrderModel(
      orderId: orderId,
      userId: userId,
      patientName: patientName,
      patientPhone: patientPhone,
      address: deliveryAddress,
      itemNames: items.map((i) => '${i.medicine.name} (x${i.quantity})').toList(),
      rawItems: List.from(items),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      totalAmount: total,
      orderTime: DateTime.now(),
      deliveryStatus: DeliveryStatus.orderConfirmed,
      storeId: storeId,
      storeName: storeName,
      storePhone: storePhone,
      storeAddress: storeAddress,
      storeImageUrl: storeImageUrl,
      storeLicense: storeLicense,
      driverName: 'Ravi Kumar',
      driverPhone: '+91 9848123456',
      etaMinutes: '15 mins',
    );

    _orders.insert(0, newOrder);
    notifyListeners();
    return newOrder;
  }

  void updateOrderStatus(String orderId, DeliveryStatus newStatus) {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      _orders[index].deliveryStatus = newStatus;
      notifyListeners();
    }
  }

  void updateStoreOrderStatus(String orderId, String storeStatus) {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      _orders[index].updateFromStoreStatus(storeStatus);
      notifyListeners();
    }
  }

  void advanceActiveOrderStatus(String userId) {
    final active = getUserActiveOrder(userId);
    if (active == null) return;
    final current = active.deliveryStatus;
    if (current == DeliveryStatus.orderConfirmed) {
      updateOrderStatus(active.orderId, DeliveryStatus.packed);
    } else if (current == DeliveryStatus.packed) {
      updateOrderStatus(active.orderId, DeliveryStatus.outForDelivery);
    } else if (current == DeliveryStatus.outForDelivery) {
      updateOrderStatus(active.orderId, DeliveryStatus.delivered);
    }
  }

  // ==========================================
  // EMERGENCY SOS BROADCASTING
  // ==========================================

  EmergencyDispatchModel triggerEmergencySOS({
    required String userId,
    required String patientName,
    required String patientPhone,
    required String location,
    required String ambulanceProvider,
    required String etaMinutes,
    double latitude = 17.4400,
    double longitude = 78.3489,
    String notes = 'Immediate Cardiac / Trauma Emergency',
  }) {
    final dispatchId = 'EMERG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final dispatch = EmergencyDispatchModel(
      id: dispatchId,
      userId: userId,
      patientName: patientName,
      patientPhone: patientPhone,
      emergencyType: 'Emergency SOS Response',
      ambulanceProvider: ambulanceProvider,
      location: location,
      latitude: latitude,
      longitude: longitude,
      etaMinutes: etaMinutes,
      status: 'en_route',
      dispatchedAt: DateTime.now(),
      hospitalName: 'KIMS Hospitals Emergency & Trauma',
      notes: notes,
    );

    _emergencyDispatches.insert(0, dispatch);
    notifyListeners();
    return dispatch;
  }

  void resolveEmergency(String dispatchId) {
    final index = _emergencyDispatches.indexWhere((e) => e.id == dispatchId);
    if (index != -1) {
      _emergencyDispatches.removeAt(index);
      notifyListeners();
    }
  }
}
