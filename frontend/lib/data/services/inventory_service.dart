import 'dart:typed_data';

import 'package:wesrugby/data/models/inventory_product_model.dart';
import 'package:wesrugby/data/models/inventory_sale_model.dart';
import 'package:wesrugby/data/models/inventory_scan_payload.dart';
import 'package:wesrugby/data/services/api_service.dart';

class InventoryService {
  const InventoryService._();

  static Future<List<InventoryProductModel>> fetchProducts() async {
    final response = await ApiService.get('/inventario/products');
    if (!response.success) {
      throw Exception(response.message ?? 'Error al obtener productos');
    }
    if (response.data is! List) {
      throw Exception('Respuesta de productos no válida');
    }
    return (response.data as List<dynamic>)
        .map((item) => InventoryProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<InventoryProductModel> fetchVariosProduct() async {
    final response = await ApiService.get('/inventario/products/varios');
    if (!response.success) {
      throw Exception(response.message ?? 'Error al obtener producto varios');
    }
    return InventoryProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<Uint8List> downloadBarcodeSheet({
    String? category,
    List<String>? ids,
    bool includeAll = true,
    int? columns,
    int? rows,
    int? perPage,
  }) async {
    final params = <String, String>{};
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    if (ids != null && ids.isNotEmpty) {
      params['ids'] = ids.join(',');
      includeAll = false;
    }
    params['includeAll'] = includeAll.toString();
    if (columns != null) {
      params['cols'] = columns.toString();
    }
    if (rows != null) {
      params['rows'] = rows.toString();
    }
    if (perPage != null) {
      params['perPage'] = perPage.toString();
    }

    final query = params.entries.map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}').join('&');
    final endpoint = query.isEmpty
        ? '/inventario/barcodes/sheet'
        : '/inventario/barcodes/sheet?$query';
    return ApiService.getBinary(endpoint);
  }

  static Future<Map<String, dynamic>> syncScans(List<InventoryScanPayload> scans) async {
    final response = await ApiService.post('/inventario/scans/bulk', {
      'scans': scans.map((scan) => scan.toJson()).toList(),
    });
    if (!response.success) {
      throw Exception(response.message ?? 'Error sincronizando scans');
    }
    return response.data as Map<String, dynamic>;
  }

  static Future<InventorySaleModel> createVariosSale({
    required int priceCents,
    int quantity = 1,
    String? deviceId,
  }) async {
    final response = await ApiService.post('/inventario/sales/varios', {
      'priceCents': priceCents,
      'quantity': quantity,
      if (deviceId != null) 'deviceId': deviceId,
    });
    if (!response.success) {
      throw Exception(response.message ?? 'Error creando venta varios');
    }
    return InventorySaleModel.fromJson(response.data as Map<String, dynamic>);
  }
}
