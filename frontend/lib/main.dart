import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'auth/simple_login.dart';
import 'home/home_screen.dart';
import 'admin/directiva_dashboard.dart';
import 'admin/tesorera_dashboard.dart';
import 'admin/entrenador_dashboard.dart';
import 'admin/apoderado_dashboard.dart';
import 'admin/rama_externa_screen.dart';
import 'config/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wessex Rugby Club - Sistema de Gestión',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
      theme: WessexColors.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginPage(),
        '/dashboard/directiva': (context) => const DirectivaDashboard(),
        '/dashboard/tesorera': (context) => const TesoreraDashboard(),
        '/dashboard/entrenador': (context) => const EntrenadorDashboard(),
        '/dashboard/apoderado': (context) => const ApoderadoDashboard(),
        '/dashboard/rama_externa': (context) => RamaExternaScreen(),
      },
    );
  }
}
