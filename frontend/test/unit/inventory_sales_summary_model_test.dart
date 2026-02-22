import 'package:flutter_test/flutter_test.dart';
import 'package:wesrugby/data/models/inventory_sales_summary_model.dart';

void main() {
  group('InventorySalesSummaryModel.fromJson', () {
    final Map<String, dynamic> validJson = {
      'productId': 'uuid-prod-001',
      'productName': 'Coca Cola',
      'category': 'bebida_latas',
      'pricingMode': 'fixed',
      'barcode': '12345678',
      'totalSales': 10,
      'totalQuantity': 25,
      'totalAmountCents': 25000,
      'lastSaleAt': '2026-02-21T10:00:00.000Z',
    };

    test('parsea todos los campos correctamente', () {
      final model = InventorySalesSummaryModel.fromJson(validJson);
      expect(model.productId, 'uuid-prod-001');
      expect(model.productName, 'Coca Cola');
      expect(model.category, 'bebida_latas');
      expect(model.pricingMode, 'fixed');
      expect(model.barcode, '12345678');
      expect(model.totalSales, 10);
      expect(model.totalQuantity, 25);
      expect(model.totalAmountCents, 25000);
      expect(model.lastSaleAt, isNotNull);
    });

    test('lastSaleAt es null cuando viene null del JSON', () {
      final json = Map<String, dynamic>.from(validJson);
      json['lastSaleAt'] = null;
      final model = InventorySalesSummaryModel.fromJson(json);
      expect(model.lastSaleAt, isNull);
    });

    test('parsea totalSales como String (vienen como string desde la BD)', () {
      final json = Map<String, dynamic>.from(validJson);
      json['totalSales'] = '15';
      json['totalQuantity'] = '30';
      json['totalAmountCents'] = '30000';
      final model = InventorySalesSummaryModel.fromJson(json);
      expect(model.totalSales, 15);
      expect(model.totalQuantity, 30);
      expect(model.totalAmountCents, 30000);
    });

    test('totalAmount es 0 si totalAmountCents viene null', () {
      final json = Map<String, dynamic>.from(validJson);
      json['totalAmountCents'] = null;
      final model = InventorySalesSummaryModel.fromJson(json);
      expect(model.totalAmountCents, 0);
    });
  });

  group('InventorySalesSummaryModel.totalAmount', () {
    test('convierte cents a double correctamente', () {
      final model = InventorySalesSummaryModel(
        productId: 'id-1',
        productName: 'Test',
        category: 'varios',
        pricingMode: 'fixed',
        barcode: '00000001',
        totalSales: 5,
        totalQuantity: 5,
        totalAmountCents: 5000,
        lastSaleAt: null,
      );
      expect(model.totalAmount, 5000.0);
    });

    test('totalAmount de 0 es 0.0', () {
      final model = InventorySalesSummaryModel(
        productId: 'id-2',
        productName: 'Vacío',
        category: 'varios',
        pricingMode: 'variable',
        barcode: '00000002',
        totalSales: 0,
        totalQuantity: 0,
        totalAmountCents: 0,
        lastSaleAt: null,
      );
      expect(model.totalAmount, 0.0);
    });
  });
}
