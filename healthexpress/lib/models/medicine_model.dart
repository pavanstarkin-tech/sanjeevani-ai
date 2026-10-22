class MedicineModel {
  final String id;
  final String name;
  final String genericName;
  final String category; // e.g. Pain & Fever, Antibiotics, Vitamins, Allergy
  final String packSize; // e.g. 10 Tablets, 100ml Bottle
  final double price;
  final double originalPrice;
  final bool requiresPrescription;
  final String imageUrl;
  final String description;
  final String manufacturer;
  final int inStockCount;

  MedicineModel({
    required this.id,
    required this.name,
    required this.genericName,
    required this.category,
    required this.packSize,
    required this.price,
    required this.originalPrice,
    this.requiresPrescription = false,
    required this.imageUrl,
    required this.description,
    required this.manufacturer,
    this.inStockCount = 50,
  });
}

class CartItemModel {
  final MedicineModel medicine;
  int quantity;

  CartItemModel({
    required this.medicine,
    this.quantity = 1,
  });

  double get totalPrice => medicine.price * quantity;
}
