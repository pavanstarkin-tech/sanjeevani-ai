class BusinessProductModel {
  final String id;
  final String title;
  final String category;
  final List<String> targetSegments;
  final List<String> targetConditions;
  final double price;
  final double originalPrice;
  final int discountPercent;
  final String badge;
  final String imageUrl;
  final String ctaLabel;
  final List<String> features;
  final double rating;
  final int reviewCount;

  const BusinessProductModel({
    required this.id,
    required this.title,
    required this.category,
    required this.targetSegments,
    required this.targetConditions,
    required this.price,
    required this.originalPrice,
    required this.discountPercent,
    required this.badge,
    required this.imageUrl,
    required this.ctaLabel,
    required this.features,
    this.rating = 4.8,
    this.reviewCount = 240,
  });

  factory BusinessProductModel.fromJson(Map<String, dynamic> json) {
    return BusinessProductModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'Health Care',
      targetSegments: List<String>.from(json['targetSegments'] ?? []),
      targetConditions: List<String>.from(json['targetConditions'] ?? []),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercent: json['discountPercent'] ?? 0,
      badge: json['badge'] ?? 'Featured',
      imageUrl: json['imageUrl'] ?? 'https://images.unsplash.com/photo-1631556097152-c39479cbfeab?auto=format&fit=crop&q=80&w=400',
      ctaLabel: json['ctaLabel'] ?? 'Order Now',
      features: List<String>.from(json['features'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: json['reviewCount'] ?? 240,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'targetSegments': targetSegments,
      'targetConditions': targetConditions,
      'price': price,
      'originalPrice': originalPrice,
      'discountPercent': discountPercent,
      'badge': badge,
      'imageUrl': imageUrl,
      'ctaLabel': ctaLabel,
      'features': features,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}
