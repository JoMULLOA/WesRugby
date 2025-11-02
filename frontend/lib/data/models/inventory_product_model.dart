class InventoryProductModel {
  InventoryProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.sourceType,
    required this.pricingMode,
    required this.barcode,
    required this.active,
    this.defaultPriceCents,
  });

  final String id;
  final String name;
  final String category;
  final String sourceType;
  final String pricingMode;
  final String barcode;
  final bool active;
  final int? defaultPriceCents;

  bool get isVariable => pricingMode == 'variable';

  factory InventoryProductModel.fromJson(Map<String, dynamic> json) {
    return InventoryProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      sourceType: json['sourceType'] as String,
      pricingMode: json['pricingMode'] as String,
      barcode: json['barcode'] as String,
      active: json['active'] as bool? ?? true,
      defaultPriceCents: json['defaultPriceCents'] as int?,
    );
  }

  InventoryProductModel copyWith({
    String? id,
    String? name,
    String? category,
    String? sourceType,
    String? pricingMode,
    String? barcode,
    bool? active,
    int? defaultPriceCents,
  }) {
    return InventoryProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sourceType: sourceType ?? this.sourceType,
      pricingMode: pricingMode ?? this.pricingMode,
      barcode: barcode ?? this.barcode,
      active: active ?? this.active,
      defaultPriceCents: defaultPriceCents ?? this.defaultPriceCents,
    );
  }
}
