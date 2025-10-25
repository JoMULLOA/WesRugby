import 'package:flutter/material.dart';

/// Paleta de colores corporativos inspirada en el escudo de Wessex Rugby.
class WessexColors {
  // ========== PALETA BASE ==========

  /// Verde principal del escudo (#1F4D2C)
  static const Color crestPrimaryGreen = Color(0xFF1F4D2C);

  /// Verde profundo complementario (#12361F)
  static const Color crestDeepGreen = Color(0xFF12361F);

  /// Azul marino de la camiseta (#0B2E57)
  static const Color crestNavyBlue = Color(0xFF0B2E57);

  /// Azul celeste de la franja (#1B86B6)
  static const Color crestSkyBlue = Color(0xFF1B86B6);

  /// Marfil claro para fondos (#F6F7F1)
  static const Color crestIvory = Color(0xFFF6F7F1);

  /// Gris pizarra para textos (#4E5A54)
  static const Color crestSlate = Color(0xFF4E5A54);

  /// Negro suave para alto contraste (#1D2320)
  static const Color crestShadow = Color(0xFF1D2320);

  /// Rojo institucional para alertas (#B02A2E)
  static const Color alertRed = Color(0xFFB02A2E);

  // ========== ACCIONES Y ESTADOS ==========

  /// Color principal para acciones y botones
  static const Color primaryAction = crestNavyBlue;

  /// Color secundario para acciones alternativas
  static const Color secondaryAction = crestPrimaryGreen;

  /// Color de realce para elementos destacados
  static const Color accentAction = crestSkyBlue;

  /// Alias manteniendo compatibilidad retroactiva
  static const Color crimsonAlert = primaryAction;
  static const Color deepRoyalBlue = crestNavyBlue;
  static const Color darkGrape = crestShadow;
  static const Color mistyRoseGray = crestIvory;
  static const Color leafGreen = crestPrimaryGreen;
  static const Color maximumGrayMint = Color(0xFFD6DED6);
  static const Color midnightNavy = crestDeepGreen;

  // ========== COLORES UTILITARIOS ==========

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color lightGray = Color(0xFFE5E5E5);
  static const Color charcoalGray = Color(0xFF414A46);
  static const Color ashGray = Color(0xFF8A938E);
  static const Color goldenYellow = Color(0xFFE7C46A);
  static const Color deepNavyBlue = crestNavyBlue;

  // ========== TEMA PERSONALIZADO ==========

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: crestPrimaryGreen,
        primary: crestPrimaryGreen,
        secondary: crestSkyBlue,
        tertiary: crestNavyBlue,
        surface: white,
        background: crestIvory,
        onPrimary: white,
        onSecondary: white,
        onTertiary: white,
        onSurface: crestShadow,
        onBackground: crestShadow,
        error: alertRed,
        onError: white,
      ),
      primarySwatch: createMaterialColor(crestPrimaryGreen),
      primaryColor: crestPrimaryGreen,
      scaffoldBackgroundColor: crestIvory,
      appBarTheme: const AppBarTheme(
        backgroundColor: crestDeepGreen,
        foregroundColor: white,
        elevation: 2,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAction,
          foregroundColor: white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryAction,
          side: const BorderSide(color: secondaryAction, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentAction,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 4,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: maximumGrayMint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: maximumGrayMint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryAction, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: alertRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: crestShadow,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: crestShadow,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: crestShadow,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: crestSlate,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: crestSlate,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: crestSlate,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      dividerTheme: const DividerThemeData(color: maximumGrayMint, thickness: 1),
      drawerTheme: const DrawerThemeData(backgroundColor: white, elevation: 8),
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
  static Color get error => WessexColors.alertRed;

  /// Color para información
  static Color get info => WessexColors.deepRoyalBlue;
}
