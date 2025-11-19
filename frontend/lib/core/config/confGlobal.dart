import 'package:flutter/material.dart';

class confGlobal {
  static const String _devHost = "http://localhost:3000";
  static const String _prodHost = "https://wesrugby.site";
  static const String _basePath = "/api";

  static bool get _runningOnLocalhost {
    final host = Uri.base.host;
    return host.isEmpty || host == "localhost" || host == "127.0.0.1";
  }

  static String get _baseHost {
    if (_runningOnLocalhost) {
      return _devHost;
    }
    final scheme = Uri.base.scheme.isEmpty ? "https" : Uri.base.scheme;
    final host = Uri.base.host;
    final port =
        Uri.base.hasPort && Uri.base.port != 80 && Uri.base.port != 443
            ? ":${Uri.base.port}"
            : "";
    return "$scheme://$host$port";
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
