import 'package:flutter_test/flutter_test.dart';
import 'package:wesrugby/data/models/inventory_product_model.dart';

void main() {
  group('InventoryProductModel.fromJson', () {
    final Map<String, dynamic> validJson = {
      'id': 'abc-123',
      'name': 'Coca Cola',
      'category': 'bebida_latas',
      'sourceType': 'compra',
      'pricingMode': 'fixed',
      'barcode': '12345678',
      'active': true,
      'defaultPriceCents': 1000,
    };

    test('parsea todos los campos correctamente', () {
      final model = InventoryProductModel.fromJson(validJson);
      expect(model.id, 'abc-123');
      expect(model.name, 'Coca Cola');
      expect(model.category, 'bebida_latas');
      expect(model.sourceType, 'compra');
      expect(model.pricingMode, 'fixed');
      expect(model.barcode, '12345678');
      expect(model.active, true);
      expect(model.defaultPriceCents, 1000);
    });

    test('defaultPriceCents puede ser null', () {
      final json = Map<String, dynamic>.from(validJson);
      json['defaultPriceCents'] = null;
      final model = InventoryProductModel.fromJson(json);
      expect(model.defaultPriceCents, isNull);
    });

    test('active es true por defecto cuando viene null', () {
      final json = Map<String, dynamic>.from(validJson);
      json['active'] = null;
      final model = InventoryProductModel.fromJson(json);
      expect(model.active, true);
    });

    test('active puede ser false', () {
      final json = Map<String, dynamic>.from(validJson);
      json['active'] = false;
      final model = InventoryProductModel.fromJson(json);
      expect(model.active, false);
    });
  });

  group('InventoryProductModel.isVariable', () {
    test('retorna true cuando pricingMode es variable', () {
      final model = InventoryProductModel(
        id: '1',
        name: 'Café',
        category: 'cafeteria',
        sourceType: 'compra',
        pricingMode: 'variable',
        barcode: '99999999',
        active: true,
      );
      expect(model.isVariable, true);
    });

    test('retorna false cuando pricingMode es fixed', () {
      final model = InventoryProductModel(
        id: '1',
        name: 'Pelota',
        category: 'otros_productos',
        sourceType: 'donacion',
        pricingMode: 'fixed',
        barcode: '88888888',
        active: true,
      );
      expect(model.isVariable, false);
    });
  });

  group('InventoryProductModel.copyWith', () {
    final original = InventoryProductModel(
      id: 'orig-id',
      name: 'Original',
      category: 'bebida_latas',
      sourceType: 'compra',
      pricingMode: 'fixed',
      barcode: '12345678',
      active: true,
      defaultPriceCents: 500,
    );

    test('copia con nuevo nombre', () {
      final copy = original.copyWith(name: 'Nuevo Nombre');
      expect(copy.name, 'Nuevo Nombre');
      expect(copy.id, original.id); // el resto no cambia
    });

    test('copia sin argumentos mantiene todos los valores', () {
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.active, original.active);
      expect(copy.defaultPriceCents, original.defaultPriceCents);
    });

    test('puede desactivar un producto', () {
      final copy = original.copyWith(active: false);
      expect(copy.active, false);
    });

    test('puede cambiar el precio', () {
      final copy = original.copyWith(defaultPriceCents: 2000);
      expect(copy.defaultPriceCents, 2000);
    });
  });
}
