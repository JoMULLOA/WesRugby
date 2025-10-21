import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wesrugby/features/auth/presentation/screens/simple_login/simple_login.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/directiva/directiva_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/tesorera/tesorera_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/entrenador/entrenador_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/apoderado/apoderado_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/rama_externa/rama_externa_screen.dart';
import 'package:wesrugby/core/config/colors.dart';

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
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      locale: const Locale('es', 'ES'),
      theme: WessexColors.lightTheme,
      initialRoute: '/login',
      routes: {
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
