import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class confGlobal {
  // Configuración de hosts
  static const String _androidDevHost = "http://10.0.2.2:3000";
  static const String _webDevHost = "http://localhost:3000";
  
  // 🔧 CAMBIAR SEGÚN ENTORNO:
  // Para pruebas locales: "http://localhost"
  // Para producción: "https://wesrugby.site"
  static const String _prodHost = "https://wesrugby.site"; // 👈 CAMBIAR ANTES DE DESPLEGAR
  
  static const String _basePath = "/api";

  // Retorna la URL base según la plataforma
  static String get baseUrl {
    String host;
    
    // En web usar el servidor de producción en release mode
    if (kIsWeb) {
      // Si estás en release mode (compilado), usa prod
      // Si estás en debug mode (flutter run), usa localhost con puerto
      host = kReleaseMode ? _prodHost : _webDevHost;
    } else {
      // En móvil/desktop usar 10.0.2.2 para Android emulator
      // Esto funciona para el emulador de Android
      host = _androidDevHost;
    }
    
    final url = "$host$_basePath";
    if (kDebugMode) {
      print('🔍 DEBUG confGlobal - kIsWeb: $kIsWeb, kReleaseMode: $kReleaseMode');
      print('🔍 DEBUG confGlobal - URL final: $url');
    }
    return url;
  }
}
// Colores del Wessex Rugby Club
class AppColors {
  // Colores principales del club
  static const Color verdePrincipal = Color(
    0xFF2E7D32,
  ); // Verde rugby principal
  static const Color verdeSecundario = Color(0xFF4CAF50); // Verde más claro
  static const Color verdeOscuro = Color(0xFF1B5E20); // Verde oscuro

  // Colores complementarios
  static const Color dorado = Color(0xFFFFB300); // Dorado del club
  static const Color blancoCrema = Color(0xFFFAFAFA); // Blanco crema
  static const Color grisClaro = Color(0xFFE0E0E0); // Gris claro
  static const Color grisOscuro = Color(0xFF424242); // Gris oscuro

  // Colores de estado
  static const Color success = Color(0xFF4CAF50); // Verde éxito
  static const Color warning = Color(0xFFFF9800); // Naranja advertencia
  static const Color error = Color(0xFFF44336); // Rojo error
  static const Color info = Color(0xFF2196F3); // Azul información
}