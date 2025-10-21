import 'dart:async';

class RefreshService {
  static final RefreshService _instance = RefreshService._internal();
  factory RefreshService() => _instance;
  RefreshService._internal();

  // StreamController para notificar cambios en usuarios
  final StreamController<void> _usuariosController =
      StreamController<void>.broadcast();

  // Stream para escuchar cambios en usuarios
  Stream<void> get usuariosStream => _usuariosController.stream;

  // Método para notificar que los usuarios han cambiado
  void notifyUsuariosChanged() {
    print('🔄 RefreshService: Notificando cambio en usuarios');
    _usuariosController.add(null);
  }

  void dispose() {
    _usuariosController.close();
  }
}
