import 'dart:typed_data';

import 'package:url_launcher/url_launcher.dart';
import 'package:wesrugby/data/models/inventory_product_model.dart';
import 'package:wesrugby/data/models/inventory_sale_model.dart';
import 'package:wesrugby/data/models/inventory_sales_summary_model.dart';
import 'package:wesrugby/data/models/inventory_scan_payload.dart';
import 'package:wesrugby/data/services/api_service.dart';

class InventoryService {
  const InventoryService._();

  static String get _apiRoot {
    final base = ApiService.baseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  static Future<List<InventoryProductModel>> fetchProducts() async {
    final response = await ApiService.get('/inventario/products');
    if (!response.success) {
      throw Exception(response.message ?? 'Error al obtener productos');
    }
    if (response.data is! List) {
      throw Exception('Respuesta de productos no v�lida');
    }
    return (response.data as List<dynamic>)
        .map((item) => InventoryProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<InventoryProductModel>> fetchManagementProducts({bool includeInactive = true}) async {
    final params = <String, String>{'includeInactive': includeInactive.toString()};
    final query = '?${Uri(queryParameters: params).query}';
    final response = await ApiService.get('/inventario/products/management');
    if (!response.success) {
      throw Exception(response.message ?? 'Error al obtener productos');
    }
    if (response.data is! List) {
      throw Exception('Respuesta de productos no v�lida');
    }
    return (response.data as List<dynamic>)
        .map((item) => InventoryProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<InventoryProductModel> saveProduct(Map<String, dynamic> data) async {
    final response = await ApiService.post('/inventario/products', data);
    if (!response.success) {
      throw Exception(response.message ?? 'Error al guardar producto');
    }
    return InventoryProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<void> deleteProduct(String id) async {
    final response = await ApiService.delete('/inventario/products/$id');
    if (!response.success) {
      throw Exception(response.message ?? 'Error al eliminar producto');
    }
  }

  static Future<void> deleteProductPermanently(String id) async {
    final response = await ApiService.delete('/inventario/products/$id/permanent');
    if (!response.success) {
      throw Exception(response.message ?? 'Error al eliminar producto permanentemente');
    }
  }

  static Future<String> reissueProductBarcode(String productId) async {
    final response = await ApiService.post('/inventario/barcodes/reissue/$productId', {});
    if (!response.success) {
      throw Exception(response.message ?? 'Error al regenerar c�digo');
    }
    final data = response.data as Map<String, dynamic>;
    return data['barcode'] as String;
  }

  static Future<InventoryProductModel> fetchVariosProduct() async {
    final response = await ApiService.get('/inventario/products/varios');
    if (!response.success) {
      throw Exception(response.message ?? 'Error al obtener producto varios');
    }
    return InventoryProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<List<InventorySalesSummaryModel>> fetchSalesSummary({DateTime? from, DateTime? to, String? productId}) async {
    final params = <String, String>{};
    if (from != null) {
      params['from'] = from.toUtc().toIso8601String();
    }
    if (to != null) {
      params['to'] = to.toUtc().toIso8601String();
    }
    if (productId != null && productId.isNotEmpty) {
      params['productId'] = productId;
    }
    final query = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    final endpoint = '/inventario/sales/summary$query';

    final response = await ApiService.get(endpoint);
    if (!response.success) {
      throw Exception(response.message ?? 'Error al obtener el resumen de ventas');
    }
    if (response.data is! List) {
      throw Exception('Respuesta de resumen no v�lida');
    }

    return (response.data as List<dynamic>)
        .map((item) => InventorySalesSummaryModel.fromJson(item as Map<String, dynamic>))
        .toList();
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

    final query = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    final endpoint = '/inventario/barcodes/sheet$query';
    return ApiService.getBinary(endpoint);
  }

  static Future<void> openBarcodeSheetInBrowser({String? category, String? productId}) async {
    final params = <String, String>{};
    if (productId != null) {
      params['ids'] = productId;
      params['includeAll'] = 'false';
    } else {
      params['includeAll'] = 'true';
    }
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    final query = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    final url = '$_apiRoot/api/inventario/barcodes/sheet$query';
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
