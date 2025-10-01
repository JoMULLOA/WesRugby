import 'package:flutter/material.dart';
import '../config/colors.dart';

class ApoderadoDashboardSimple extends StatefulWidget {
  const ApoderadoDashboardSimple({super.key});

  @override
  State<ApoderadoDashboardSimple> createState() => _ApoderadoDashboardSimpleState();
}

class _ApoderadoDashboardSimpleState extends State<ApoderadoDashboardSimple> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WessexColors.mistyRoseGray,
      appBar: AppBar(
        title: Text(
          'Panel Apoderado - Wessex Rugby',
          style: TextStyle(
            color: WessexColors.white,
            fontSize: 20,
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
              Icons.family_restroom,
              size: 100,
              color: WessexColors.deepRoyalBlue,
            ),
            SizedBox(height: 20),
            Text(
              'Dashboard Apoderado',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: WessexColors.midnightNavy,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Panel de control para apoderados',
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
                    content: Text('Dashboard Apoderado funcionando correctamente!'),
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