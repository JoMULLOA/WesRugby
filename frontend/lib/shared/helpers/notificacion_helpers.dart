import 'package:flutter/material.dart';

class NotificacionHelpers {
  /// Muestra una notificación de éxito
  static void mostrarExito(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    Duration duracion = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(mensaje, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF854937),
        duration: duracion,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Muestra una notificación de error
  static void mostrarError(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    Duration duracion = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(mensaje, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: duracion,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Muestra una notificación de información
  static void mostrarInfo(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    Duration duracion = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(mensaje, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        duration: duracion,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Muestra una notificación de amistad específica
  static void mostrarSolicitudEnviada(
    BuildContext context,
    String nombreUsuario,
  ) {
    mostrarExito(
      context,
      titulo: '🤝 ¡Solicitud enviada!',
      mensaje:
          'Se ha notificado a $nombreUsuario sobre tu solicitud de amistad',
    );
  }

  /// Muestra una notificación de amistad aceptada
  static void mostrarAmistadAceptada(
    BuildContext context,
    String nombreUsuario,
  ) {
    mostrarExito(
      context,
      titulo: '🎉 ¡Nueva amistad!',
      mensaje: 'Ahora tú y $nombreUsuario son amigos',
      duracion: Duration(seconds: 5),
    );
  }

  /// Muestra una notificación de amistad rechazada
  static void mostrarAmistadRechazada(
    BuildContext context,
    String nombreUsuario,
  ) {
    mostrarInfo(
      context,
      titulo: '😔 Solicitud rechazada',
      mensaje: '$nombreUsuario ha rechazado tu solicitud de amistad',
    );
  }

  /// Muestra una notificación de solicitud recibida
  static void mostrarSolicitudRecibida(
    BuildContext context,
    String nombreUsuario,
  ) {
    mostrarInfo(
      context,
      titulo: '👋 Nueva solicitud',
      mensaje: '$nombreUsuario te ha enviado una solicitud de amistad',
      duracion: Duration(seconds: 5),
    );
  }

  /// Muestra una notificación cuando ya son amigos
  static void mostrarYaSonAmigos(BuildContext context, String nombreUsuario) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🤝 Ya son amigos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Tú y $nombreUsuario ya tienen una amistad establecida',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF854937), // Color café como el de la imagen
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
