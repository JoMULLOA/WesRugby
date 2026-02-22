import 'package:flutter_test/flutter_test.dart';
import 'package:wesrugby/data/models/inventory_scan_payload.dart';

void main() {
  final testDate = DateTime.utc(2026, 2, 21, 10, 0, 0);

  group('InventoryScanPayload.toJson', () {
    test('serializa campos obligatorios correctamente', () {
      final payload = InventoryScanPayload(
        id: 'prod-uuid-001',
        barcode: '12345678',
        scannedAt: testDate,
        deviceId: 'DEVICE-001',
      );

      final json = payload.toJson();

      expect(json['id'], 'prod-uuid-001');
      expect(json['barcode'], '12345678');
      expect(json['deviceId'], 'DEVICE-001');
      expect(json['scannedAt'], testDate.toUtc().toIso8601String());
    });

    test('NO incluye priceCents si es null', () {
      final payload = InventoryScanPayload(
        id: 'id-1',
        barcode: '99999999',
        scannedAt: testDate,
        deviceId: 'DEV-X',
      );
      expect(payload.toJson().containsKey('priceCents'), false);
    });

    test('NO incluye quantity si es null', () {
      final payload = InventoryScanPayload(
        id: 'id-1',
        barcode: '99999999',
        scannedAt: testDate,
        deviceId: 'DEV-X',
      );
      expect(payload.toJson().containsKey('quantity'), false);
    });

    test('SÍ incluye priceCents cuando está definido', () {
      final payload = InventoryScanPayload(
        id: 'id-1',
        barcode: '99999999',
        scannedAt: testDate,
        deviceId: 'DEV-X',
        priceCents: 1500,
      );
      expect(payload.toJson()['priceCents'], 1500);
    });

    test('SÍ incluye quantity cuando está definido', () {
      final payload = InventoryScanPayload(
        id: 'id-1',
        barcode: '99999999',
        scannedAt: testDate,
        deviceId: 'DEV-X',
        quantity: 3,
      );
      expect(payload.toJson()['quantity'], 3);
    });

    test('scannedAt se serializa en formato ISO 8601 UTC', () {
      final payload = InventoryScanPayload(
        id: 'id-1',
        barcode: '99999999',
        scannedAt: testDate,
        deviceId: 'DEV-X',
      );
      final json = payload.toJson();
      expect(json['scannedAt'], contains('T'));
      expect(json['scannedAt'], contains('Z')); // UTC
    });
  });
}
