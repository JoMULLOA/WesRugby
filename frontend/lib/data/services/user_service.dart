import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wesrugby/core/config/confGlobal.dart';
import 'package:wesrugby/data/services/tokenManager.dart';

class UserService {
  static String get baseUrl => confGlobal.baseUrl;

  // Obtener token de autenticación
  static Future<String?> _getToken() async {
    return await TokenManager.getToken();
  }

  // Headers por defecto con autenticación
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtener vehículos del usuario autenticado
  static Future<List<Map<String, dynamic>>> obtenerMisVehiculos() async {
    try {
      print('🚗 Solicitando vehículos del usuario...');

      // Verificar que tengamos un token válido antes de hacer la petición
      final token = await _getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación válido');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/mis-vehiculos'),
        headers: await _getHeaders(),
      );

      print('🚗 Response status: ${response.statusCode}');
      print('🚗 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final vehiculos = List<Map<String, dynamic>>.from(data['data']);
        print('✅ Vehículos obtenidos: ${vehiculos.length}');
        return vehiculos;
      } else if (response.statusCode == 401) {
        // Token expirado o inválido, limpiar datos de autenticación
        await TokenManager.clearAuthData();
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Error ${response.statusCode}: ${errorData['message'] ?? 'Error desconocido'}',
        );
      }
    } catch (e) {
      print('❌ Error obteniendo vehículos: $e');

      // Si el error contiene información sobre token expirado, limpiamos los datos
      if (e.toString().contains('expirado') ||
          e.toString().contains('expired') ||
          e.toString().contains('401')) {
        await TokenManager.clearAuthData();
      }

      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener información del usuario actual
  static Future<Map<String, dynamic>?> obtenerPerfilUsuario() async {
    try {
      // Obtener email desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) {
        return null;
      }

      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/user/busqueda?email=$email'),
        headers: {...headers, 'Cache-Control': 'no-cache'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print('Error obteniendo perfil de usuario: $e');
      return null;
    }
  }

  /// Obtener todos los usuarios (función para administradores)
  static Future<List<Usuario>> obtenerTodosLosUsuarios() async {
    try {
      print('👥 Solicitando todos los usuarios...');

      // Verificar que tengamos un token válido antes de hacer la petición
      final token = await _getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación válido');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: await _getHeaders(),
      );

      print('👥 Response status: ${response.statusCode}');
      print('👥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final usuariosList = jsonData['data'] as List<dynamic>;
          return usuariosList
              .map((userJson) => Usuario.fromJson(userJson))
              .toList();
        } else {
          throw Exception(
            'Respuesta de API no válida: ${jsonData['message'] ?? 'Error desconocido'}',
          );
        }
      } else if (response.statusCode == 204) {
        // Sin contenido, retornar lista vacía
        return [];
      } else if (response.statusCode == 401) {
        // Token expirado o inválido, limpiar datos de autenticación
        await TokenManager.clearAuthData();
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente');
      } else if (response.statusCode == 404) {
        throw Exception('No se encontraron usuarios');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Error HTTP ${response.statusCode}: ${errorData['message'] ?? response.body}',
        );
      }
    } catch (e) {
      print('❌ Error obteniendo usuarios: $e');

      // Si el error contiene información sobre token expirado, limpiamos los datos
      if (e.toString().contains('expirado') ||
          e.toString().contains('expired') ||
          e.toString().contains('401')) {
        await TokenManager.clearAuthData();
      }

      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'Tiempo de espera agotado. Verifica tu conexión a internet.',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
          'No se pudo conectar al servidor. Verifica que el backend esté ejecutándose.',
        );
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Error inesperado: $e');
      }
    }
  }

  /// Actualizar token FCM del usuario
  static Future<Map<String, dynamic>> actualizarTokenFCM(String token) async {
    try {
      print('🔔 Actualizando token FCM: $token');

      final response = await http.patch(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: await _getHeaders(),
        body: json.encode({'fcmToken': token}),
      );

      print('🔔 Response status: ${response.statusCode}');
      print('🔔 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Token FCM actualizado exitosamente',
        };
      } else if (response.statusCode == 401) {
        await TokenManager.clearAuthData();
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Error al actualizar token FCM',
        );
      }
    } catch (e) {
      print('❌ Error actualizando token FCM: $e');

      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'Tiempo de espera agotado. Verifica tu conexión a internet.',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
          'No se pudo conectar al servidor. Verifica que el backend esté ejecutándose.',
        );
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Error inesperado: $e');
      }
    }
  }

  /// Eliminar un usuario y todas sus relaciones
  static Future<Map<String, dynamic>> eliminarUsuarioCompleto(
    String rut,
  ) async {
    try {
      print('🗑️ Iniciando eliminación completa del usuario con RUT: $rut');

      // Paso 1: Obtener todas las amistades del usuario
      // Nota: Necesitaríamos un endpoint específico para esto,
      // por ahora intentaremos eliminar directamente

      // Paso 2: Eliminar el usuario del backend
      // El backend debería manejar la eliminación en cascada de relaciones
      final response = await http.delete(
        Uri.parse('$baseUrl/users/detail/?rut=$rut'),
        headers: await _getHeaders(),
      );

      print('🗑️ Response status: ${response.statusCode}');
      print('🗑️ Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message':
              data['message'] ??
              'Usuario y todas sus relaciones eliminadas exitosamente',
        };
      } else if (response.statusCode == 401) {
        await TokenManager.clearAuthData();
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente');
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para eliminar este usuario');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Error al eliminar usuario');
      }
    } catch (e) {
      print('❌ Error eliminando usuario completo: $e');

      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'Tiempo de espera agotado. Verifica tu conexión a internet.',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
          'No se pudo conectar al servidor. Verifica que el backend esté ejecutándose.',
        );
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Error inesperado: $e');
      }
    }
  }

  /// Eliminar un usuario por RUT
  static Future<Map<String, dynamic>> eliminarUsuario(String rut) async {
    try {
      print('🗑️ Eliminando usuario con RUT: $rut');

      final response = await http.delete(
        Uri.parse('$baseUrl/users/detail/?rut=$rut'),
        headers: await _getHeaders(),
      );

      print('🗑️ Response status: ${response.statusCode}');
      print('🗑️ Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Usuario eliminado exitosamente',
        };
      } else if (response.statusCode == 401) {
        await TokenManager.clearAuthData();
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente');
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para eliminar este usuario');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Error al eliminar usuario');
      }
    } catch (e) {
      print('❌ Error eliminando usuario: $e');

      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'Tiempo de espera agotado. Verifica tu conexión a internet.',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
          'No se pudo conectar al servidor. Verifica que el backend esté ejecutándose.',
        );
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Error inesperado: $e');
      }
    }
  }

  /// Obtener estadísticas de usuarios
  static Future<EstadisticasUsuarios> obtenerEstadisticasUsuarios() async {
    try {
      final usuarios = await obtenerTodosLosUsuarios();

      // Calcular estadísticas
      final totalUsuarios = usuarios.length;
      final usuariosActivos =
          usuarios
              .where((u) => DateTime.now().difference(u.updatedAt).inDays <= 30)
              .length;

      final usuariosPorRol = <String, int>{};
      for (final usuario in usuarios) {
        usuariosPorRol[usuario.rol] = (usuariosPorRol[usuario.rol] ?? 0) + 1;
      }

      return EstadisticasUsuarios(
        totalUsuarios: totalUsuarios,
        usuariosActivos: usuariosActivos,
        usuariosPorRol: usuariosPorRol,
      );
    } catch (e) {
      throw Exception('Error obteniendo estadísticas: $e');
    }
  }
}

class Usuario {
  final String rut;
  final String nombreCompleto;
  final DateTime? fechaNacimiento;
  final String? carrera;
  final int? altura;
  final int? peso;
  final String? descripcion;
  final double? clasificacion;
  final int? puntuacion;
  final String email;
  final String rol;
  final DateTime createdAt;
  final DateTime updatedAt;

  Usuario({
    required this.rut,
    required this.nombreCompleto,
    this.fechaNacimiento,
    this.carrera,
    this.altura,
    this.peso,
    this.descripcion,
    this.clasificacion,
    this.puntuacion,
    required this.email,
    required this.rol,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      rut: json['rut'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      fechaNacimiento:
          json['fechaNacimiento'] != null
              ? DateTime.parse(json['fechaNacimiento'])
              : null,
      carrera: json['carrera'],
      altura: json['altura'],
      peso: json['Peso'], // Nota: en el backend está con mayúscula
      descripcion: json['descripcion'],
      clasificacion: json['clasificacion']?.toDouble(),
      puntuacion: json['puntuacion'],
      email: json['email'] ?? '',
      rol: json['rol'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  String get iniciales {
    final nombres = nombreCompleto.split(' ');
    if (nombres.length >= 2) {
      return '${nombres[0][0]}${nombres[1][0]}'.toUpperCase();
    } else if (nombres.isNotEmpty) {
      return nombres[0][0].toUpperCase();
    }
    return 'U';
  }

  String get edadTexto {
    if (fechaNacimiento == null) return 'No especificada';

    final ahora = DateTime.now();
    final edad = ahora.year - fechaNacimiento!.year;

    // Verificar si ya pasó el cumpleaños este año
    if (ahora.month < fechaNacimiento!.month ||
        (ahora.month == fechaNacimiento!.month &&
            ahora.day < fechaNacimiento!.day)) {
      return '${edad - 1} años';
    }
    return '$edad años';
  }

  String get tiempoRegistrado {
    final diferencia = DateTime.now().difference(createdAt);

    if (diferencia.inDays >= 365) {
      final anios = (diferencia.inDays / 365).floor();
      return '${anios} año${anios > 1 ? 's' : ''}';
    } else if (diferencia.inDays >= 30) {
      final meses = (diferencia.inDays / 30).floor();
      return '${meses} mes${meses > 1 ? 'es' : ''}';
    } else if (diferencia.inDays > 0) {
      return '${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''}';
    } else {
      return 'Hoy';
    }
  }

  bool get esActivo {
    return DateTime.now().difference(updatedAt).inDays <= 30;
  }
}

class EstadisticasUsuarios {
  final int totalUsuarios;
  final int usuariosActivos;
  final Map<String, int> usuariosPorRol;

  EstadisticasUsuarios({
    required this.totalUsuarios,
    required this.usuariosActivos,
    required this.usuariosPorRol,
  });
}
