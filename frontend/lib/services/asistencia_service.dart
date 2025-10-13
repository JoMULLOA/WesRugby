import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/asistencia_model.dart';
import 'tokenManager.dart';

class AsistenciaService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// Obtiene todos los alumnos activos del sistema
  static Future<List<Alumno>> obtenerAlumnos({String? categoria}) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '$baseUrl/users/alumnos';
      if (categoria != null && categoria.isNotEmpty) {
        url += '?categoria=$categoria';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> alumnosJson = data['alumnos'] ?? [];
        
        return alumnosJson.map((json) => Alumno.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener alumnos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerAlumnos: $e');
      // Datos mock para desarrollo
      return _getAlumnosMock(categoria);
    }
  }

  /// Obtiene las categorías disponibles
  static Future<List<String>> obtenerCategorias() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/categorias'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['categorias'] ?? []);
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerCategorias: $e');
      return ['Sub-18', 'Sub-16', 'Sub-14', 'Senior', 'Veteranos'];
    }
  }

  /// Inicia una nueva sesión de entrenamiento
  static Future<SesionEntrenamiento> iniciarSesion({
    required String nombre,
    required String categoria,
    String? descripcion,
    required String entrenadorRut,
    required String entrenadorNombre,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final sesionData = {
        'nombre': nombre,
        'categoria': categoria,
        'descripcion': descripcion,
        'entrenadorRut': entrenadorRut,
        'entrenadorNombre': entrenadorNombre,
        'fechaInicio': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/asistencia/sesion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(sesionData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SesionEntrenamiento.fromJson(data['sesion']);
      } else {
        throw Exception('Error al crear sesión: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en iniciarSesion: $e');
      // Crear sesión mock para desarrollo
      return _createMockSesion(nombre, categoria, descripcion, entrenadorRut, entrenadorNombre);
    }
  }

  /// Registra la asistencia de un alumno
  static Future<bool> registrarAsistencia({
    required String sesionId,
    required String rutAlumno,
    required String nombreAlumno,
    required EstadoAsistencia estado,
    String? observaciones,
    String? justificacion,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final registroData = {
        'rutAlumno': rutAlumno,
        'nombreAlumno': nombreAlumno,
        'estado': estado.name,
        'observaciones': observaciones,
        'justificacion': justificacion,
        'fechaHora': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/asistencia/sesion/$sesionId/registro'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(registroData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error al registrar asistencia: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en registrarAsistencia: $e');
      return false;
    }
  }

  /// Actualiza el registro de asistencia de un alumno
  static Future<bool> actualizarAsistencia({
    required String sesionId,
    required String rutAlumno,
    required EstadoAsistencia estado,
    String? observaciones,
    String? justificacion,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final updateData = {
        'estado': estado.name,
        'observaciones': observaciones,
        'justificacion': justificacion,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/asistencia/sesion/$sesionId/registro/$rutAlumno'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error al actualizar asistencia: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en actualizarAsistencia: $e');
      return false;
    }
  }

  /// Finaliza una sesión de entrenamiento
  static Future<bool> finalizarSesion(String sesionId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/asistencia/sesion/$sesionId/finalizar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fechaFin': DateTime.now().toIso8601String(),
          'finalizada': true,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error al finalizar sesión: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en finalizarSesion: $e');
      return false;
    }
  }

  /// Obtiene el historial de sesiones
  static Future<List<SesionEntrenamiento>> obtenerHistorialSesiones({
    String? categoria,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String url = '$baseUrl/asistencia/sesiones';
      List<String> params = [];
      
      if (categoria != null && categoria.isNotEmpty) {
        params.add('categoria=$categoria');
      }
      if (fechaInicio != null) {
        params.add('fechaInicio=${fechaInicio.toIso8601String()}');
      }
      if (fechaFin != null) {
        params.add('fechaFin=${fechaFin.toIso8601String()}');
      }
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> sesionesJson = data['sesiones'] ?? [];
        
        return sesionesJson.map((json) => SesionEntrenamiento.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerHistorialSesiones: $e');
      return [];
    }
  }

  // ========== DATOS MOCK PARA DESARROLLO ==========

  static List<Alumno> _getAlumnosMock(String? categoria) {
    final alumnosMock = [
      Alumno(
        rut: '12345678-9',
        nombreCompleto: 'Juan Carlos Pérez',
        email: 'juan.perez@email.com',
        categoria: 'Sub-18',
        telefono: '+56912345678',
        fechaInscripcion: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Alumno(
        rut: '23456789-0',
        nombreCompleto: 'María González',
        email: 'maria.gonzalez@email.com',
        categoria: 'Sub-16',
        telefono: '+56923456789',
        fechaInscripcion: DateTime.now().subtract(const Duration(days: 45)),
      ),
      Alumno(
        rut: '34567890-1',
        nombreCompleto: 'Pedro Rodríguez',
        email: 'pedro.rodriguez@email.com',
        categoria: 'Sub-18',
        telefono: '+56934567890',
        fechaInscripcion: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Alumno(
        rut: '45678901-2',
        nombreCompleto: 'Ana López',
        email: 'ana.lopez@email.com',
        categoria: 'Senior',
        telefono: '+56945678901',
        fechaInscripcion: DateTime.now().subtract(const Duration(days: 60)),
      ),
      Alumno(
        rut: '56789012-3',
        nombreCompleto: 'Carlos Martínez',
        email: 'carlos.martinez@email.com',
        categoria: 'Sub-16',
        telefono: '+56956789012',
        fechaInscripcion: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Alumno(
        rut: '67890123-4',
        nombreCompleto: 'Sofía Ramírez',
        email: 'sofia.ramirez@email.com',
        categoria: 'Sub-18',
        telefono: '+56967890123',
        fechaInscripcion: DateTime.now().subtract(const Duration(days: 35)),
      ),
    ];

    if (categoria != null && categoria.isNotEmpty) {
      return alumnosMock.where((alumno) => alumno.categoria == categoria).toList();
    }
    return alumnosMock;
  }

  static SesionEntrenamiento _createMockSesion(
    String nombre,
    String categoria,
    String? descripcion,
    String entrenadorRut,
    String entrenadorNombre,
  ) {
    return SesionEntrenamiento(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      categoria: categoria,
      descripcion: descripcion,
      entrenadorRut: entrenadorRut,
      entrenadorNombre: entrenadorNombre,
      fechaInicio: DateTime.now(),
    );
  }

  /// Guarda una nueva sesión de asistencia
  Future<Map<String, dynamic>> guardarSesionAsistencia(Map<String, dynamic> sesionData) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/sesiones-asistencia'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(sesionData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Error al guardar sesión: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al guardar sesión de asistencia: $e');
      throw Exception('Error al guardar la sesión de asistencia');
    }
  }

  /// Obtiene las sesiones del entrenador autenticado
  Future<List<Map<String, dynamic>>> getMisSesiones() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sesiones-asistencia/mis-sesiones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        throw Exception('Formato de respuesta inválido');
      } else {
        throw Exception('Error al obtener sesiones: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener mis sesiones: $e');
      throw Exception('Error al obtener las sesiones');
    }
  }

  /// Obtiene los detalles de una sesión específica
  Future<Map<String, dynamic>> getDetalleSesion(int sesionId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sesiones-asistencia/$sesionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Formato de respuesta inválido');
      } else {
        throw Exception('Error al obtener detalles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener detalle de sesión: $e');
      throw Exception('Error al obtener los detalles de la sesión');
    }
  }
}