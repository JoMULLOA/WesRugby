import 'package:wesrugby/data/services/api_service.dart';

class ConfiguracionPrecioService {
  /// Obtener precios configurados para un año específico
  static Future<ApiResponse> obtenerPreciosPorAnio(int anio) async {
    return ApiService.get('/configuracion-precios/anio/$anio');
  }

  /// Guardar o actualizar configuración de precios
  static Future<ApiResponse> guardarPrecios({
    required int anio,
    required double precioMensualidad,
    required double precioMatricula,
    int descuentoMensualidad2 = 0,
    int descuentoMensualidad3Plus = 0,
    int descuentoMatricula2 = 0,
    int descuentoMatricula3Plus = 0,
  }) async {
    return ApiService.post('/configuracion-precios/', {
      'anio': anio,
      'precioMensualidad': precioMensualidad,
      'precioMatricula': precioMatricula,
      'descuentoMensualidad2': descuentoMensualidad2,
      'descuentoMensualidad3Plus': descuentoMensualidad3Plus,
      'descuentoMatricula2': descuentoMatricula2,
      'descuentoMatricula3Plus': descuentoMatricula3Plus,
    });
  }

  /// Obtener todas las configuraciones de precios
  static Future<ApiResponse> obtenerTodasLasConfiguraciones() async {
    return ApiService.get('/configuracion-precios/');
  }
}
