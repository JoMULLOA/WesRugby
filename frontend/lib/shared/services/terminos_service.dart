import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wesrugby/core/config/confGlobal.dart';
import 'package:wesrugby/data/services/tokenManager.dart';

class TerminosService {
  static String get _baseUrl => confGlobal.baseUrl;

  /// Obtener términos activos (público)
  static Future<Map<String, dynamic>> obtenerTerminosActivos() async {
    try {
      final url = Uri.parse('$_baseUrl/terminos/activo');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo términos',
        };
      }
    } catch (e) {
      print('❌ Error en obtenerTerminosActivos: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Verificar si el apoderado debe aceptar términos
  static Future<Map<String, dynamic>> verificarAceptacion() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No autenticado',
        };
      }

      final url = Uri.parse('$_baseUrl/terminos/verificar-aceptacion');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'requiereAceptacion': data['data']['requiereAceptacion'] ?? false,
          'terminoActivo': data['data']['terminoActivo'],
          'fechaAceptacion': data['data']['fechaAceptacion'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error verificando aceptación',
        };
      }
    } catch (e) {
      print('❌ Error en verificarAceptacion: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Aceptar términos y condiciones
  static Future<Map<String, dynamic>> aceptarTerminos(int terminoId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No autenticado',
        };
      }

      final url = Uri.parse('$_baseUrl/terminos/aceptar');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'terminoId': terminoId,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'fechaAceptacion': data['data']?['fechaAceptacion'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error aceptando términos',
        };
      }
    } catch (e) {
      print('❌ Error en aceptarTerminos: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Listar todos los términos (Directiva)
  static Future<Map<String, dynamic>> listarTerminos() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No autenticado',
        };
      }

      final url = Uri.parse('$_baseUrl/terminos');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error listando términos',
        };
      }
    } catch (e) {
      print('❌ Error en listarTerminos: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Crear nuevos términos (Directiva)
  static Future<Map<String, dynamic>> crearTerminos({
    required String version,
    required String titulo,
    required String contenido,
    bool activarInmediatamente = true,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No autenticado',
        };
      }

      final url = Uri.parse('$_baseUrl/terminos');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'version': version,
          'titulo': titulo,
          'contenido': contenido,
          'activarInmediatamente': activarInmediatamente,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error creando términos',
        };
      }
    } catch (e) {
      print('❌ Error en crearTerminos: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Actualizar términos existentes (Directiva)
  static Future<Map<String, dynamic>> actualizarTerminos({
    required int id,
    String? version,
    String? titulo,
    String? contenido,
    bool? activo,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No autenticado',
        };
      }

      final url = Uri.parse('$_baseUrl/terminos/$id');
      
      final body = <String, dynamic>{};
      if (version != null) body['version'] = version;
      if (titulo != null) body['titulo'] = titulo;
      if (contenido != null) body['contenido'] = contenido;
      if (activo != null) body['activo'] = activo;
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error actualizando términos',
        };
      }
    } catch (e) {
      print('❌ Error en actualizarTerminos: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Eliminar términos (Directiva)
  static Future<Map<String, dynamic>> eliminarTerminos(int id) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No autenticado',
        };
      }

      final url = Uri.parse('$_baseUrl/terminos/$id');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error eliminando términos',
        };
      }
    } catch (e) {
      print('❌ Error en eliminarTerminos: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener estadísticas de aceptación (Directiva)
  static Future<Map<String, dynamic>> obtenerEstadisticas(int id) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No autenticado',
        };
      }

      final url = Uri.parse('$_baseUrl/terminos/$id/estadisticas');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo estadísticas',
        };
      }
    } catch (e) {
      print('❌ Error en obtenerEstadisticas: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}
