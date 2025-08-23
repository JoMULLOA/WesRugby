import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Verificar y solicitar permisos de ubicación
  static Future<bool> checkAndRequestLocationPermission() async {
    try {
      // Verificar permisos del sistema
      PermissionStatus permission = await Permission.location.status;
      
      if (permission.isDenied) {
        permission = await Permission.location.request();
      }
      
      if (permission.isPermanentlyDenied) {
        // El usuario negó permanentemente los permisos
        return false;
      }
      
      return permission.isGranted;
    } catch (e) {
      print('❌ Error verificando permisos de ubicación: $e');
      return false;
    }
  }
  
  /// Obtener la ubicación actual del usuario (deshabilitada)
  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    // Funcionalidad de ubicación deshabilitada
    print('ℹ️ Funcionalidad de ubicación deshabilitada');
    return null;
  }
  
  /// Formatear coordenadas para mostrar al usuario
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
  
  /// Generar URL de Google Maps
  static String generateGoogleMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }
  
  /// Calcular distancia entre dos puntos (deshabilitada)
  static double calculateDistance(
    double lat1, double lon1, 
    double lat2, double lon2
  ) {
    // Funcionalidad de cálculo de distancia deshabilitada
    return 0.0;
  }
  
  /// Formatear distancia para mostrar al usuario
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}
