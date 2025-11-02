class InventoryScanPayload {
  InventoryScanPayload({
    required this.id,
    required this.barcode,
    required this.scannedAt,
    required this.deviceId,
    this.priceCents,
    this.quantity,
  });

  final String id;
  final String barcode;
  final DateTime scannedAt;
  final String deviceId;
  final int? priceCents;
  final int? quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'scannedAt': scannedAt.toUtc().toIso8601String(),
      'deviceId': deviceId,
      if (priceCents != null) 'priceCents': priceCents,
      if (quantity != null) 'quantity': quantity,
    };
  }
}
