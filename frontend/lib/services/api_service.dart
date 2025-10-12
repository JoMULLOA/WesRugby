import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tokenManager.dart';

class ApiResponse {
  final int statusCode;
  final dynamic data;
  final String? message;

  ApiResponse({required this.statusCode, this.data, this.message});
  
  // Getter para determinar si la respuesta fue exitosa
  bool get success => statusCode >= 200 && statusCode < 300;
}

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  
  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    return headers;
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET request
  static Future<ApiResponse> get(String endpoint) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        message: 'Error de conexión: $e',
      );
    }
  }

  // POST request
  static Future<ApiResponse> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        message: 'Error de conexión: $e',
      );
    }
  }

  // PUT request
  static Future<ApiResponse> put(String endpoint, [Map<String, dynamic>? data]) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        message: 'Error de conexión: $e',
      );
    }
  }

  // DELETE request
  static Future<ApiResponse> delete(String endpoint) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        message: 'Error de conexión: $e',
      );
    }
  }

  // PATCH request
  static Future<ApiResponse> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        message: 'Error de conexión: $e',
      );
    }
  }

  // POST sin autenticación (para login)
  static Future<ApiResponse> postWithoutAuth(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        message: 'Error de conexión: $e',
      );
    }
  }

  static ApiResponse _handleResponse(http.Response response) {
    try {
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      
      return ApiResponse(
        statusCode: response.statusCode,
        data: data,
        message: data is Map<String, dynamic> ? data['message'] : null,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: response.statusCode,
        message: 'Error procesando respuesta: $e',
      );
    }
  }

  // Método para login específico
  static Future<ApiResponse> login(String email, String password) async {
    return postWithoutAuth('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  // Método para obtener perfil del usuario
  static Future<ApiResponse> getProfile() async {
    return get('/auth/profile');
  }

  // Métodos específicos para módulos
  static Future<ApiResponse> getInscripciones() async {
    return get('/inscripciones');
  }

  static Future<ApiResponse> getPlanessPago() async {
    return get('/planes-pago');
  }

  static Future<ApiResponse> getAsistencias() async {
    return get('/asistencias');
  }

  static Future<ApiResponse> getEventos() async {
    return get('/eventos-deportivos');
  }

  static Future<ApiResponse> getProductos() async {
    return get('/productos');
  }

  static Future<ApiResponse> getVentas() async {
    return get('/ventas-producto');
  }

  static Future<ApiResponse> getComprobantes() async {
    return get('/comprobantes-pago');
  }

  static Future<ApiResponse> getDirectiva() async {
    return get('/directiva');
  }

  // Métodos específicos para gestión de usuarios
  static Future<ApiResponse> getAllUsers() async {
    return get('/user/all');
  }

  static Future<ApiResponse> getUserByRut(String rut) async {
    return get('/user/detail?rut=$rut');
  }

  static Future<ApiResponse> searchUserByEmail(String email) async {
    return get('/user/busqueda?email=$email');
  }

  static Future<ApiResponse> createUser(Map<String, dynamic> userData) async {
    return post('/auth/register-apoderado', userData);
  }

  // Nuevo método para crear usuarios desde el dashboard de directiva
  static Future<ApiResponse> createUserByDirectiva(Map<String, dynamic> userData) async {
    return post('/user/create', userData);
  }

  static Future<ApiResponse> updateUser(Map<String, dynamic> userData) async {
    return put('/user/update-by-directiva', userData);
  }

  // Nuevo método para actualizar usuarios desde el dashboard de directiva
  static Future<ApiResponse> updateUserByDirectiva(Map<String, dynamic> userData) async {
    return put('/user/update-by-directiva', userData);
  }

  static Future<ApiResponse> deleteUserByRut(String rut) async {
    return delete('/user/delete-by-directiva/$rut');
  }

  static Future<ApiResponse> deleteUserByDirectiva(String rut) async {
    return delete('/user/delete-by-directiva/$rut');
  }

  static Future<ApiResponse> changeUserRole(String rut, String newRole) async {
    return put('/user/changeRole', {
      'rut': rut,
      'nuevoRol': newRole,
    });
  }

  // Métodos para estudiantes
  static Future<ApiResponse> getAllEstudiantes() async {
    return get('/estudiantes');
  }

  static Future<ApiResponse> getEstudiantesByApoderado(String rutApoderado) async {
    return get('/estudiantes/por-apoderado?rut=$rutApoderado');
  }

  static Future<ApiResponse> getEstudiante(String rut) async {
    return get('/estudiantes/$rut');
  }

  static Future<ApiResponse> updateEstudiante(String rut, Map<String, dynamic> data) async {
    return put('/estudiantes/$rut', data);
  }

  static Future<ApiResponse> updateEstudianteFoto(String rut, String fotoUrl) async {
    return put('/estudiantes/$rut/foto', {'fotoUrl': fotoUrl});
  }

  // Importación masiva de estudiantes desde Excel
  static Future<ApiResponse> importEstudiantesFromExcel(List<Map<String, dynamic>> estudiantes) async {
    return post('/importacion/estudiantes-excel', {'estudiantes': estudiantes});
  }

  // ============================================================================
  // MÉTODOS PARA GESTIÓN DE TORNEOS
  // ============================================================================

  // Crear torneo (solo directiva)
  static Future<ApiResponse> crearTorneo(Map<String, dynamic> torneoData) async {
    return post('/torneos/crear', torneoData);
  }

  // Obtener todos los torneos (directiva)
  static Future<ApiResponse> obtenerTodosLosTorneos({String? estado}) async {
    String endpoint = '/torneos/todos';
    if (estado != null) {
      endpoint += '?estado=$estado';
    }
    return get(endpoint);
  }

  // Obtener torneos disponibles para participar (coordinadores de rama)
  static Future<ApiResponse> obtenerTorneosDisponibles() async {
    return get('/torneos/disponibles');
  }

  // Participar en torneo (coordinadores de rama)
  static Future<ApiResponse> participarEnTorneo(Map<String, dynamic> participacionData) async {
    return post('/torneos/participar', participacionData);
  }

  // Obtener mis participaciones (coordinadores de rama)
  static Future<ApiResponse> obtenerMisParticipaciones() async {
    return get('/torneos/mis-participaciones');
  }

  // Actualizar estado del torneo (directiva)
  static Future<ApiResponse> actualizarEstadoTorneo(int torneoId, String estado) async {
    return put('/torneos/$torneoId/estado', {'estado': estado});
  }

  // Obtener torneos públicos (todos los roles)
  static Future<ApiResponse> obtenerTorneosPublicos() async {
    return get('/torneos/publicos');
  }

  // ============================================================================
  // MÉTODOS PARA GESTIÓN DE EVENTOS
  // ============================================================================

  // Crear evento (solo directiva)
  static Future<Map<String, dynamic>> crearEvento(Map<String, dynamic> eventoData) async {
    final response = await post('/eventos/crear', eventoData);
    if (response.success) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Error al crear evento');
    }
  }

  // Crear evento deportivo (solo directiva/entrenador)
  static Future<Map<String, dynamic>> crearEventoDeportivo(Map<String, dynamic> eventoData) async {
    final response = await post('/eventos-deportivos', eventoData);
    if (response.success) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Error al crear evento deportivo');
    }
  }

  // Obtener eventos deportivos (solo directiva/entrenador)
  static Future<Map<String, dynamic>> obtenerEventosDeportivos() async {
    final response = await get('/eventos-deportivos');
    if (response.success) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Error al obtener eventos deportivos');
    }
  }

  // Obtener todos los eventos (directiva)
  static Future<Map<String, dynamic>> obtenerEventos() async {
    final response = await get('/eventos/todos');
    if (response.success) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Error al obtener eventos');
    }
  }

  // Obtener eventos disponibles (RamaExterna)
  static Future<Map<String, dynamic>> obtenerEventosDisponibles() async {
    final response = await get('/eventos/disponibles');
    if (response.success) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Error al obtener eventos disponibles');
    }
  }

  // Participar en evento (RamaExterna)
  static Future<Map<String, dynamic>> participarEnEvento(Map<String, dynamic> participacionData) async {
    final response = await post('/eventos/participar', participacionData);
    if (response.success) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Error al participar en evento');
    }
  }

  // Editar participación en evento (RamaExterna - solo durante 10 minutos)
  static Future<Map<String, dynamic>> editarParticipacion(int participacionId, int cantidadNinos, String? listaInvitados) async {
    final body = {
      'cantidadNinos': cantidadNinos,
      if (listaInvitados != null) 'listaInvitados': listaInvitados,
    };
    
    final response = await put('/eventos/participacion/$participacionId', body);
    if (response.success) {
      return {'success': true, 'data': response.data, 'message': 'Participación actualizada exitosamente'};
    } else {
      return {'success': false, 'message': response.message ?? 'Error al editar participación'};
    }
  }

  // Obtener mis participaciones en eventos (RamaExterna)
  static Future<Map<String, dynamic>> obtenerMisParticipacionesEvento() async {
    final response = await get('/eventos/mis-participaciones');
    if (response.success) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Error al obtener participaciones');
    }
  }

  // Obtener categorías ya registradas en un evento (RamaExterna)
  static Future<Map<String, dynamic>> obtenerCategoriasRegistradas(int eventoId) async {
    final response = await get('/eventos/$eventoId/categorias-registradas');
    if (response.success) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Error al obtener categorías registradas');
    }
  }

  // Actualizar evento (directiva)
  static Future<Map<String, dynamic>> actualizarEvento(int eventoId, Map<String, dynamic> datos) async {
    final response = await put('/eventos/$eventoId', datos);
    if (response.success) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Error al actualizar evento');
    }
  }

  // Eliminar evento (directiva)
  static Future<Map<String, dynamic>> eliminarEvento(int eventoId) async {
    final response = await delete('/eventos/$eventoId');
    if (response.success) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Error al eliminar evento');
    }
  }

  // Obtener participaciones de un evento (directiva)
  static Future<Map<String, dynamic>> obtenerParticipacionesEvento(dynamic eventoId) async {
    final response = await get('/eventos/$eventoId/participaciones');
    if (response.success) {
      return response.data;
    } else {
      throw Exception(response.message ?? 'Error al obtener participaciones del evento');
    }
  }
}
