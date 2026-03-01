import 'package:flutter/foundation.dart';
import 'package:wesrugby/data/services/api_service.dart';

/// Servicio singleton para gestionar el fondo de la aplicación.
/// Notifica a todos los [WessexBackground] cuando cambia la URL.
class BackgroundService {
  BackgroundService._();
  static final BackgroundService instance = BackgroundService._();

  /// URL del fondo actual (null = usar asset por defecto)
  final ValueNotifier<String?> backgroundUrl = ValueNotifier<String?>(null);

  bool _loaded = false;

  /// Carga la URL del fondo desde el servidor (llamar al inicio de la app).
  Future<void> cargar() async {
    try {
      final response = await ApiService.get('/homepage/background');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final url = data?['backgroundImageUrl'] as String?;
        backgroundUrl.value = (url != null && url.isNotEmpty) ? url : null;
      }
    } catch (e) {
      debugPrint('BackgroundService: error al cargar fondo: $e');
    } finally {
      _loaded = true;
    }
  }

  /// Actualiza el fondo en el servidor y notifica localmente.
  Future<bool> actualizar(String? url) async {
    try {
      final response = await ApiService.post('/homepage/background', {
        'url': url ?? '',
      });
      if (response.statusCode == 200) {
        backgroundUrl.value = (url != null && url.isNotEmpty) ? url : null;
        return true;
      }
    } catch (e) {
      debugPrint('BackgroundService: error al actualizar fondo: $e');
    }
    return false;
  }

  bool get isLoaded => _loaded;
}
