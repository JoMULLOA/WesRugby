import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userInfoKey = 'user_info';
  static const String _isLoggedInKey = 'is_logged_in';

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setBool(_isLoggedInKey, true);
      print('Token guardado exitosamente');
    } catch (e) {
      print('Error guardando token: $e');
      throw Exception('Error guardando token: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error obteniendo token: $e');
      return null;
    }
  }

  static Future<void> saveUserInfo(dynamic userInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      Map<String, dynamic> userMap;
      
      if (userInfo is Map<String, dynamic>) {
        userMap = userInfo;
      } else if (userInfo is Map) {
        userMap = Map<String, dynamic>.from(userInfo);
      } else {
        throw Exception('userInfo debe ser un Map');
      }
      
      if (userMap['id'] != null) {
        userMap['id'] = userMap['id'].toString();
      }
      if (userMap['rol'] != null) {
        userMap['rol'] = userMap['rol'].toString();
      }
      if (userMap['nombre'] != null) {
        userMap['nombre'] = userMap['nombre'].toString();
      }
      if (userMap['email'] != null) {
        userMap['email'] = userMap['email'].toString();
      }
      
      final userInfoString = jsonEncode(userMap);
      await prefs.setString(_userInfoKey, userInfoString);
      print('Información de usuario guardada exitosamente');
    } catch (e) {
      print('Error guardando información de usuario: $e');
      throw Exception('Error guardando información de usuario: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString(_userInfoKey);
      
      if (userInfoString != null) {
        final userInfo = jsonDecode(userInfoString) as Map<String, dynamic>;
        return userInfo;
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo información de usuario: $e');
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final token = prefs.getString(_tokenKey);
      
      return isLoggedIn && token != null && token.isNotEmpty;
    } catch (e) {
      print('Error verificando estado de login: $e');
      return false;
    }
  }

  static Future<String?> getUserRole() async {
    try {
      final userInfo = await getUserInfo();
      return userInfo?['rol']?.toString();
    } catch (e) {
      print('Error obteniendo rol de usuario: $e');
      return null;
    }
  }

  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userInfoKey);
      await prefs.setBool(_isLoggedInKey, false);
      print('Datos de autenticación limpiados exitosamente');
    } catch (e) {
      print('Error limpiando datos de autenticación: $e');
      throw Exception('Error limpiando datos de autenticación: $e');
    }
  }
}
