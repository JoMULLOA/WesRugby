import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/websocket_notification_service.dart';
import 'auth/login.dart';
import 'buscar/inicio.dart';
import 'perfil/perfil.dart';
import 'perfil/notificaciones.dart';
import 'perfil/amistad_menu.dart';
import 'services/navigation_service.dart';
import 'sos/sos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar sistema de notificaciones WebSocket
    await WebSocketNotificationService.initialize();
    
    // Configurar callback para diálogos in-app
    WebSocketNotificationService.setInAppDialogCallback((title, message, {action}) {
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (action == 'passenger_eliminated') {
                    // Redirigir a la pantalla de mis viajes después de eliminar
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/mis-viajes',
                      (route) => false,
                    );
                  }
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    });
    
    print('🔔 Sistema de notificaciones WebSocket inicializado');
  } catch (e) {
    print('❌ Error inicializando notificaciones: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'WesRugby - Sistema de Gestión Web',
      debugShowCheckedModeBanner: false, // Quitar banner de debug
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB02A2E), // Crimson Alert como color principal
          brightness: Brightness.light,
          primary: const Color(0xFFB02A2E), // Crimson Alert
          secondary: const Color(0xFF090976), // Deep Royal Blue
          surface: const Color(0xFFF0EAEB), // Misty Rose Gray
          background: const Color(0xFFF0EAEB), // Misty Rose Gray
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF100B0D), // Dark Grape para textos
          onBackground: const Color(0xFF100B0D), // Dark Grape para textos
        ),
        scaffoldBackgroundColor: const Color(0xFFF0EAEB), // Misty Rose Gray
        useMaterial3: true,
        // Configuración para web
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto', // Fuente más web-friendly
        appBarTheme: const AppBarTheme(
          elevation: 2,
          centerTitle: true,
          backgroundColor: Color(0xFF041540), // Midnight Navy
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          color: Color(0xFFD2DEDC), // Maximum Gray Mint para tarjetas
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB02A2E), // Crimson Alert
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF090976), // Deep Royal Blue para enlaces
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF0EAEB), // Misty Rose Gray para fondos de formulario
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD2DEDC)), // Maximum Gray Mint
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFB02A2E)), // Crimson Alert
          ),
        ),
        // Botón flotante para acciones afirmativas
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF057233), // Leaf Green para acciones afirmativas
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/login', // Ruta inicial
      routes: {
        '/': (context) => const InicioScreen(), // Ruta principal
        '/login': (context) => const LoginPage(),
        '/inicio': (context) => const InicioScreen(),
        '/sos': (context) => const SOSScreen(),
        '/perfil': (context) => Perfil(),
        '/amistades': (context) => AmistadMenuScreen(),
        '/solicitudes': (context) => NotificacionesScreen(),
      },
    );
  }
}

