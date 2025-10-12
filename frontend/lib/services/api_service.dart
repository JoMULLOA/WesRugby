import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tokenManager.dart';

class ApiResponse {
  final int statusCode;
  final dynamic data;
  final String? message;

  ApiResponse({required this.statusCode, this.data, this.message});
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
    return patch('/user/actualizar', userData);
  }

  static Future<ApiResponse> deleteUserByRut(String rut) async {
    return delete('/user/delete/$rut');
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
}
