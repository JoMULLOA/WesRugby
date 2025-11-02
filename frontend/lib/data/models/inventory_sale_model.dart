class InventorySaleModel {
  InventorySaleModel({
    required this.id,
    required this.productId,
    required this.priceCents,
    required this.quantity,
    required this.deviceId,
    required this.scannedAt,
  });

  final String id;
  final String productId;
  final int priceCents;
  final int quantity;
  final String deviceId;
  final DateTime scannedAt;

  factory InventorySaleModel.fromJson(Map<String, dynamic> json) {
    return InventorySaleModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      priceCents: json['priceCents'] as int,
      quantity: json['quantity'] as int? ?? 1,
      deviceId: json['deviceId'] as String? ?? 'unknown',
      scannedAt: DateTime.parse(json['scannedAt'] as String).toLocal(),
    );
  }

  String get formattedDate => scannedAt.toIso8601String();
}
