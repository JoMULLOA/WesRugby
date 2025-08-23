import 'package:flutter/material.dart';
import '../widgets/navbar_con_sos_dinamico.dart';

class ResultadosBusquedaScreen extends StatefulWidget {
  final String origen;
  final String destino;
  final DateTime? fecha;
  final int pasajeros;
  final double? origenLat;
  final double? origenLng;
  final double? destinoLat;
  final double? destinoLng;

  const ResultadosBusquedaScreen({
    super.key,
    required this.origen,
    required this.destino,
    this.fecha,
    required this.pasajeros,
    this.origenLat,
    this.origenLng,
    this.destinoLat,
    this.destinoLng,
  });

  @override
  State<ResultadosBusquedaScreen> createState() => _ResultadosBusquedaScreenState();
}

class _ResultadosBusquedaScreenState extends State<ResultadosBusquedaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de Búsqueda'),
        backgroundColor: const Color(0xFF6B3B2D),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Funcionalidad de viajes no disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La búsqueda de viajes ha sido deshabilitada',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B3B2D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavbarConSOSDinamico(
        currentIndex: 0, // Como viene de búsqueda, usar índice 0 (inicio)
        onTap: (int index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/inicio');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/perfil');
              break;
          }
        },
      ),
    );
  }
}
