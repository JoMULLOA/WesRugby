import 'package:flutter/material.dart';

/// Paleta de colores corporativos de Wessex Rugby
/// Basada en la guía de identidad visual 5.3.3
class WessexColors {
  // ========== COLORES PRINCIPALES ==========
  
  /// Crimson Alert (#B02A2E) - Para botones y elementos interactivos
  static const Color crimsonAlert = Color(0xFFB02A2E);
  
  /// Deep Royal Blue (#090976) - Para botones y enlaces
  static const Color deepRoyalBlue = Color(0xFF090976);
  
  /// Dark Grape (#100B0D) - Para textos principales
  static const Color darkGrape = Color(0xFF100B0D);
  
  /// Misty Rose Gray (#F0EAEB) - Para fondos de formularios suaves
  static const Color mistyRoseGray = Color(0xFFF0EAEB);

  // ========== COLORES SECUNDARIOS ==========
  
  /// Leaf Green (#057233) - Para acciones afirmativas (Enviar, Aceptar)
  static const Color leafGreen = Color(0xFF057233);
  
  /// Maximum Gray Mint (#D2DEDC) - Para elementos neutrales y tarjetas
  static const Color maximumGrayMint = Color(0xFFD2DEDC);
  
  /// Midnight Navy (#041540) - Para fondos y encabezados
  static const Color midnightNavy = Color(0xFF041540);

  // ========== COLORES UTILITARIOS ==========
  
  /// Blanco para contraste
  static const Color white = Colors.white;
  
  /// Negro para texto secundario
  static const Color black = Colors.black;
  
  /// Gris claro para divisores
  static const Color lightGray = Color(0xFFE5E5E5);

  // ========== TEMA PERSONALIZADO ==========
  
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: createMaterialColor(deepRoyalBlue),
      primaryColor: deepRoyalBlue,
      scaffoldBackgroundColor: mistyRoseGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: midnightNavy,
        foregroundColor: white,
        elevation: 2,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: crimsonAlert,
          foregroundColor: white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepRoyalBlue,
          side: const BorderSide(color: deepRoyalBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: deepRoyalBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 4,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: deepRoyalBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: crimsonAlert, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: darkGrape,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: darkGrape,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: darkGrape,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: darkGrape,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: darkGrape,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: darkGrape,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightGray,
        thickness: 1,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: white,
        elevation: 8,
      ),
    );
  }

  // Crear MaterialColor desde Color personalizado
  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

/// Extension para obtener colores de estado
extension WessexColorExtensions on WessexColors {
  /// Color para acciones exitosas
  static Color get success => WessexColors.leafGreen;
  
  /// Color para advertencias
  static Color get warning => const Color(0xFFFFA726);
  
  /// Color para errores
  static Color get error => WessexColors.crimsonAlert;
  
  /// Color para información
  static Color get info => WessexColors.deepRoyalBlue;
}
