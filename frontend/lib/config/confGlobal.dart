import 'package:flutter/material.dart';

class confGlobal {
  //static const String baseUrl = "http://10.0.2.2:3000/api";
  static const String baseUrl = "http://localhost:3000/api";
  //static const String baseUrl = "http://146.83.198.35:1245/api";
}

// Colores del Wessex Rugby Club
class AppColors {
  // Colores principales del club
  static const Color verdePrincipal = Color(0xFF2E7D32);  // Verde rugby principal
  static const Color verdeSecundario = Color(0xFF4CAF50);  // Verde más claro
  static const Color verdeOscuro = Color(0xFF1B5E20);     // Verde oscuro
  
  // Colores complementarios
  static const Color dorado = Color(0xFFFFB300);          // Dorado del club
  static const Color blancoCrema = Color(0xFFFAFAFA);     // Blanco crema
  static const Color grisClaro = Color(0xFFE0E0E0);       // Gris claro
  static const Color grisOscuro = Color(0xFF424242);      // Gris oscuro
  
  // Colores de estado
  static const Color success = Color(0xFF4CAF50);         // Verde éxito
  static const Color warning = Color(0xFFFF9800);         // Naranja advertencia
  static const Color error = Color(0xFFF44336);           // Rojo error
  static const Color info = Color(0xFF2196F3);            // Azul información
}