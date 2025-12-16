import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class confGlobal {
  static const String _devHost = "http://localhost:3000";
  static const String _androidEmulatorHost = "http://10.0.2.2:3000"; // Host para emulador Android
  static const String _prodHost = "https://wesrugby.site";
  static const String _basePath = "/api";

  static String get _baseHost {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isEmpty || host == "localhost" || host == "127.0.0.1") {
        return _devHost;
      }
      final scheme = Uri.base.scheme.isEmpty ? "https" : Uri.base.scheme;
      final port =
          Uri.base.hasPort && Uri.base.port != 80 && Uri.base.port != 443
              ? ":${Uri.base.port}"
              : "";
      return "$scheme://$host$port";
    } else {
      // Mobile / Desktop application
      if (kDebugMode) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          // Cambiar esto por la IP de tu PC si usas dispositivo físico (ej: http://192.168.1.X:3000)
          return _androidEmulatorHost;
        }
        return _devHost;
      }
      return _prodHost;
    }
  }

  static String get baseUrl => "$_baseHost$_basePath";
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
