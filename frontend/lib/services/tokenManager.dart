import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userInfoKey = 'user_info';

  // Guardar token de autenticación
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Obtener token de autenticación
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Guardar información del usuario
  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userInfoKey, json.encode(userInfo));
  }

  // Obtener información del usuario
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString(_userInfoKey);
    if (userInfoString != null) {
      try {
        return json.decode(userInfoString) as Map<String, dynamic>;
      } catch (e) {
        print('Error decodificando información del usuario: $e');
        return null;
      }
    }
    return null;
  }

  // Verificar si hay una sesión activa
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final userInfo = await getUserInfo();
    return token != null && token.isNotEmpty && userInfo != null;
  }

  // Limpiar token y datos del usuario (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userInfoKey);
  }

  // Método para compatibilidad con código existente
  static Future<void> clearAuthData() async {
    await clearToken();
  }

  // Obtener rol del usuario
  static Future<String?> getUserRole() async {
    final userInfo = await getUserInfo();
    return userInfo?['rol'];
  }

  // Obtener ID del usuario
  static Future<String?> getUserId() async {
    final userInfo = await getUserInfo();
    return userInfo?['id']?.toString();
  }

  // Obtener nombre completo del usuario
  static Future<String?> getFullName() async {
    final userInfo = await getUserInfo();
    if (userInfo != null) {
      final nombres = userInfo['nombres'] ?? '';
      final apellidos = userInfo['apellidos'] ?? '';
      return '$nombres $apellidos'.trim();
    }
    return null;
  }

  // Obtener email del usuario
  static Future<String?> getEmail() async {
    final userInfo = await getUserInfo();
    return userInfo?['email'];
  }

  // Verificar si el token ha expirado (básico)
  static Future<bool> isTokenExpired() async {
    // Esta es una implementación básica
    // En un escenario real, deberías decodificar el JWT y verificar la fecha de expiración
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return true;
    }
    
    // TODO: Implementar verificación real de expiración del JWT
    // Por ahora, asumimos que el token es válido
    return false;
  }

  // Refrescar token (placeholder)
  static Future<bool> refreshToken() async {
    // TODO: Implementar lógica de refresh token con el backend
    // Por ahora, retornamos false
    return false;
  }

  // Obtener headers de autorización para requests HTTP
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
    };
  }

  // Validar formato de token JWT (básico)
  static bool isValidJWTFormat(String token) {
    final parts = token.split('.');
    return parts.length == 3;
  }

  // Debug: Imprimir información del usuario
  static Future<void> debugPrintUserInfo() async {
    final userInfo = await getUserInfo();
    final token = await getToken();
    print('=== DEBUG: Token Manager ===');
    print('Token existe: ${token != null}');
    print('Token length: ${token?.length ?? 0}');
    print('User info: $userInfo');
    print('============================');
  }
}
