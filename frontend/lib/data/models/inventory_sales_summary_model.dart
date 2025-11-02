int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class InventorySalesSummaryModel {
  const InventorySalesSummaryModel({
    required this.productId,
    required this.productName,
    required this.category,
    required this.pricingMode,
    required this.barcode,
    required this.totalSales,
    required this.totalQuantity,
    required this.totalAmountCents,
    required this.lastSaleAt,
  });

  final String productId;
  final String productName;
  final String category;
  final String pricingMode;
  final String barcode;
  final int totalSales;
  final int totalQuantity;
  final int totalAmountCents;
  final DateTime? lastSaleAt;

  double get totalAmount => totalAmountCents.toDouble();

  factory InventorySalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return InventorySalesSummaryModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      category: json['category'] as String,
      pricingMode: json['pricingMode'] as String,
      barcode: json['barcode'] as String,
      totalSales: _parseInt(json['totalSales']),
      totalQuantity: _parseInt(json['totalQuantity']),
      totalAmountCents: _parseInt(json['totalAmountCents']),
      lastSaleAt: json['lastSaleAt'] == null
          ? null
          : DateTime.tryParse(json['lastSaleAt'] as String),
    );
  }
}
