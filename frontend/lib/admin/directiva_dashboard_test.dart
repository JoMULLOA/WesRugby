import 'package:flutter/material.dart';
import '../config/colors.dart';

class DirectivaDashboardSimple extends StatefulWidget {
  const DirectivaDashboardSimple({super.key});

  @override
  State<DirectivaDashboardSimple> createState() => _DirectivaDashboardSimpleState();
}

class _DirectivaDashboardSimpleState extends State<DirectivaDashboardSimple> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      backgroundColor: WessexColors.mistyRoseGray,
      appBar: AppBar(
        title: Text(
          'Panel Directiva - Wessex Rugby',
          style: TextStyle(
            color: WessexColors.white,
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WessexColors.midnightNavy,
        iconTheme: IconThemeData(color: WessexColors.white),
        elevation: 2,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard,
              size: 100,
              color: WessexColors.deepRoyalBlue,
            ),
            SizedBox(height: 20),
            Text(
              'Dashboard Directiva',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: WessexColors.midnightNavy,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Panel de control para la directiva',
              style: TextStyle(
                fontSize: 16,
                color: WessexColors.deepRoyalBlue,
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dashboard Directiva funcionando correctamente!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WessexColors.deepRoyalBlue,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                'Probar Funcionalidad',
                style: TextStyle(
                  color: WessexColors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}