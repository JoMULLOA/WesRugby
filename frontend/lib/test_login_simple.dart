import 'package:flutter/material.dart';
import './admin/directiva_dashboard_test.dart';
import './admin/tesorera_dashboard_test.dart';
import './admin/entrenador_dashboard.dart';
import './admin/apoderado_dashboard_test.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Navigation',
      home: TestLoginPage(),
    );
  }
}

class TestLoginPage extends StatelessWidget {
  void _navigateToRol(BuildContext context, String rol) {
    print('🚀 NAVEGANDO A: $rol');
    
    Widget dashboard;
    switch (rol) {
      case 'directiva':
        dashboard = const DirectivaDashboardSimple();
        break;
      case 'tesorera':
        dashboard = const TesoreraDashboardSimple();
        break;
      case 'entrenador':
        dashboard = const EntrenadorDashboard();
        break;
      case 'apoderado':
        dashboard = const ApoderadoDashboardSimple();
        break;
      default:
        return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => dashboard),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Navigation')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _navigateToRol(context, 'directiva'),
              child: Text('Ir a Directiva Dashboard'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToRol(context, 'tesorera'),
              child: Text('Ir a Tesorera Dashboard'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToRol(context, 'entrenador'),
              child: Text('Ir a Entrenador Dashboard'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToRol(context, 'apoderado'),
              child: Text('Ir a Apoderado Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}