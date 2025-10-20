import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  /// Seleccionar archivo de imagen usando HTML File Input (solo web)
  static Future<Map<String, dynamic>?> pickImageFile() async {
    if (!kIsWeb) {
      throw UnsupportedError('File picking is only supported on web');
    }

    try {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      // Crear un Completer para manejar la respuesta asíncrona
      final completer = Completer<Map<String, dynamic>?>();

      uploadInput.onChange.listen((event) async {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          
          // Validar tamaño (5MB máximo)
          if (file.size > 5 * 1024 * 1024) {
            completer.complete(null);
            return;
          }

          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          
          reader.onLoadEnd.listen((event) {
            final bytes = reader.result as Uint8List;
            completer.complete({
              'name': file.name,
              'bytes': bytes,
              'size': file.size,
              'type': file.type,
            });
          });

          reader.onError.listen((event) {
            completer.complete(null);
          });
        } else {
          completer.complete(null);
        }
      });

      // Si no se selecciona nada en 30 segundos, cancelar
      Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  /// Subir imagen al servidor
  static Future<Map<String, dynamic>?> uploadImage({
    required String filename,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      // Convertir bytes a base64
      final base64String = base64Encode(bytes);
      final dataUrl = 'data:$mimeType;base64,$base64String';

      final response = await ApiService.post('/uploads/imagen', {
        'filename': filename,
        'fileData': dataUrl,
        'mimeType': mimeType,
      });

      print('Upload response: success=${response.success}, statusCode=${response.statusCode}, data=${response.data}, message=${response.message}'); // Debug log

      if (response.success && response.data != null) {
        return response.data;
      } else {
        print('Error uploading image: ${response.message}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Eliminar imagen del servidor
  static Future<bool> deleteImage(String filename) async {
    try {
      final response = await ApiService.delete('/uploads/imagen/$filename');
      return response.success;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Obtener URL completa de la imagen
  static String getImageUrl(String filename) {
    return '${ApiService.baseUrl}/uploads/imagen/$filename';
  }

  /// Formatear tamaño de archivo en formato legible
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Validar tipo de archivo
  static bool isValidImageType(String mimeType) {
    const allowedTypes = [
      'image/jpeg',
      'image/jpg', 
      'image/png',
      'image/gif',
      'image/webp'
    ];
    return allowedTypes.contains(mimeType.toLowerCase());
  }
}