import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/services/tokenManager.dart';

class ComprobantePago {
  final String id;
  final String numeroComprobante;
  final String tipoPago;
  final String metodoPago;
  final double montoTotal;
  final DateTime fechaPago;
  final String mesCorrespondiente;
  final String estado;
  final String? bancoOrigen;
  final String? numeroOperacion;
  final String? observacionesApoderado;
  final String? observacionesTesorera;
  final String? nombreArchivoOriginal;
  final DateTime fechaSubida;
  final DateTime? fechaValidacion;
  final bool notificacionEnviada;
  final Map<String, dynamic>? alumno;

  ComprobantePago({
    required this.id,
    required this.numeroComprobante,
    required this.tipoPago,
    required this.metodoPago,
    required this.montoTotal,
    required this.fechaPago,
    required this.mesCorrespondiente,
    required this.estado,
    this.bancoOrigen,
    this.numeroOperacion,
    this.observacionesApoderado,
    this.observacionesTesorera,
    this.nombreArchivoOriginal,
    required this.fechaSubida,
    this.fechaValidacion,
    required this.notificacionEnviada,
    this.alumno,
  });

  factory ComprobantePago.fromJson(Map<String, dynamic> json) {
    return ComprobantePago(
      id: json['id'],
      numeroComprobante: json['numeroComprobante'],
      tipoPago: json['tipoPago'],
      metodoPago: json['metodoPago'],
      montoTotal: double.parse(json['montoTotal'].toString()),
      fechaPago: DateTime.parse(json['fechaPago']),
      mesCorrespondiente: json['mesCorrespondiente'],
      estado: json['estado'],
      bancoOrigen: json['bancoOrigen'],
      numeroOperacion: json['numeroOperacion'],
      observacionesApoderado: json['observacionesApoderado'],
      observacionesTesorera: json['observacionesTesorera'],
      nombreArchivoOriginal: json['nombreArchivoOriginal'],
      fechaSubida: DateTime.parse(json['fechaSubida']),
      fechaValidacion:
          json['fechaValidacion'] != null
              ? DateTime.parse(json['fechaValidacion'])
              : null,
      notificacionEnviada: json['notificacionEnviada'] ?? false,
      alumno: json['alumno'],
    );
  }
}

class Inscripcion {
  final String id;
  final String nombre;
  final String apellidos;
  final String codigoAlumno;
  final DateTime fechaInscripcion;

  Inscripcion({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.codigoAlumno,
    required this.fechaInscripcion,
  });

  factory Inscripcion.fromJson(Map<String, dynamic> json) {
    try {
      return Inscripcion(
        id: json['id']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        apellidos: json['apellidos']?.toString() ?? '',
        codigoAlumno: json['codigoAlumno']?.toString() ?? '',
        fechaInscripcion:
            json['fechaInscripcion'] != null
                ? DateTime.tryParse(json['fechaInscripcion'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
      );
    } catch (e) {
      print('Error parseando Inscripcion: $e');
      // Retornar una inscripción por defecto en caso de error
      return Inscripcion(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        nombre: 'Error',
        apellidos: 'Parsing',
        codigoAlumno: 'ERROR',
        fechaInscripcion: DateTime.now(),
      );
    }
  }

  String get nombreCompleto => '$nombre $apellidos';
}

class HistorialPagos {
  final List<ComprobantePago> comprobantes;
  final List<Inscripcion> inscripciones;
  final Map<String, dynamic> paginacion;
  final Map<String, dynamic> estadisticas;

  HistorialPagos({
    required this.comprobantes,
    required this.inscripciones,
    required this.paginacion,
    required this.estadisticas,
  });

  factory HistorialPagos.fromJson(Map<String, dynamic> json) {
    return HistorialPagos(
      comprobantes:
          (json['comprobantes'] as List)
              .map((item) => ComprobantePago.fromJson(item))
              .toList(),
      inscripciones:
          (json['inscripciones'] as List)
              .map((item) => Inscripcion.fromJson(item))
              .toList(),
      paginacion: json['paginacion'],
      estadisticas: json['estadisticas'],
    );
  }
}

class PagosService {
  /// Subir voucher de mensualidad
  static Future<ApiResponse> subirVoucherMensualidad({
    required String inscripcionId,
    required String metodoPago,
    required double montoTotal,
    required DateTime fechaPago,
    String? mesCorrespondiente, // Opcional: null para matrículas
    required List<String> estudiantesSeleccionados,
    required bool aplicarATodos,
    String? bancoOrigen,
    String? numeroOperacion,
    String? observacionesApoderado,
    File? archivoVoucher,
    Map<String, dynamic>? detallesPago, // Nuevo: para pagos agrupados
  }) async {
    try {
      const endpoint = '/comprobantes-pago/apoderado/voucher-mensualidad';

      if (archivoVoucher != null) {
        // Usar multipart para subir archivo
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiService.baseUrl}$endpoint'),
        );

        // Agregar headers de autenticación
        final token = await TokenManager.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        // Agregar campos del formulario
        request.fields['inscripcionId'] = inscripcionId;
        request.fields['metodoPago'] = metodoPago;
        request.fields['montoTotal'] = montoTotal.toString();
        request.fields['fechaPago'] = fechaPago.toIso8601String().split('T')[0];
        // Solo agregar mes si está presente (no es matrícula)
        if (mesCorrespondiente != null) {
          request.fields['mesCorrespondiente'] = mesCorrespondiente;
        }
        request.fields['aplicarATodos'] = aplicarATodos ? 'true' : 'false';
        request.fields['estudiantesSeleccionados'] =
            jsonEncode(estudiantesSeleccionados);

        if (bancoOrigen != null) request.fields['bancoOrigen'] = bancoOrigen;
        if (numeroOperacion != null)
          request.fields['numeroOperacion'] = numeroOperacion;
        if (observacionesApoderado != null) {
          request.fields['observacionesApoderado'] = observacionesApoderado;
        }
        
        // Agregar detallesPago si está presente (pago agrupado)
        if (detallesPago != null) {
          request.fields['detallesPago'] = jsonEncode(detallesPago);
        }

        // Agregar archivo
        var stream = http.ByteStream(archivoVoucher.openRead());
        var length = await archivoVoucher.length();
        var multipartFile = http.MultipartFile(
          'voucher',
          stream,
          length,
          filename: archivoVoucher.path.split('/').last,
        );
        request.files.add(multipartFile);

        // Enviar request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        // Manejar respuesta manualmente
        final data = response.body.isNotEmpty ? response.body : null;
        return ApiResponse(
          statusCode: response.statusCode,
          data: data,
          message:
              response.statusCode == 200 || response.statusCode == 201
                  ? 'Voucher subido exitosamente'
                  : 'Error subiendo voucher',
        );
      } else {
        // Sin archivo, usar POST normal
        return ApiService.post(endpoint, {
          'inscripcionId': inscripcionId,
          'metodoPago': metodoPago,
          'montoTotal': montoTotal,
          'fechaPago': fechaPago.toIso8601String().split('T')[0],
          'mesCorrespondiente': mesCorrespondiente,
          'aplicarATodos': aplicarATodos,
          'estudiantesSeleccionados': estudiantesSeleccionados,
          'bancoOrigen': bancoOrigen,
          'numeroOperacion': numeroOperacion,
          'observacionesApoderado': observacionesApoderado,
        });
      }
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        message: 'Error subiendo voucher: $e',
      );
    }
  }

  /// Subir voucher de mensualidad (Web - acepta Uint8List)
  static Future<ApiResponse> subirVoucherMensualidadWeb({
    required String inscripcionId,
    required String metodoPago,
    required double montoTotal,
    required DateTime fechaPago,
    String? mesCorrespondiente, // Opcional: null para matrículas
    int? anioMatricula, // Año de la matrícula (solo para tipo matrícula)
    required List<String> estudiantesSeleccionados,
    required bool aplicarATodos,
    String? bancoOrigen,
    String? numeroOperacion,
    String? observacionesApoderado,
    Uint8List? archivoBytes,
    String? nombreArchivo,
    Map<String, dynamic>? detallesPago, // Nuevo: para pagos agrupados con múltiples meses
  }) async {
    try {
      const endpoint = '/comprobantes-pago/apoderado/voucher-mensualidad';

      print('🔍 DEBUG subirVoucherMensualidadWeb:');
      print('  - inscripcionId: $inscripcionId');
      print('  - metodoPago: $metodoPago');
      print('  - montoTotal: $montoTotal');
      print('  - fechaPago: ${fechaPago.toIso8601String()}');
      print('  - mesCorrespondiente: $mesCorrespondiente');
      print('  - anioMatricula: $anioMatricula');
      print('  - estudiantesSeleccionados: $estudiantesSeleccionados');
      print('  - aplicarATodos: $aplicarATodos');
      print('  - nombreArchivo: $nombreArchivo');
      print('  - archivoBytes length: ${archivoBytes?.length}');

      if (archivoBytes != null && nombreArchivo != null) {
        // Usar multipart para subir archivo desde bytes (web)
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiService.baseUrl}$endpoint'),
        );

        // Agregar headers de autenticación
        final token = await TokenManager.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        // Agregar campos del formulario
        request.fields['inscripcionId'] = inscripcionId;
        request.fields['metodoPago'] = metodoPago;
        request.fields['montoTotal'] = montoTotal.toString();
        request.fields['fechaPago'] = fechaPago.toIso8601String().split('T')[0];
        // Solo agregar mes si está presente (no es matrícula)
        if (mesCorrespondiente != null) {
          request.fields['mesCorrespondiente'] = mesCorrespondiente;
        }
        request.fields['aplicarATodos'] = aplicarATodos ? 'true' : 'false';
        request.fields['estudiantesSeleccionados'] =
            jsonEncode(estudiantesSeleccionados);

        if (bancoOrigen != null) request.fields['bancoOrigen'] = bancoOrigen;
        if (numeroOperacion != null)
          request.fields['numeroOperacion'] = numeroOperacion;
        if (observacionesApoderado != null) {
          request.fields['observacionesApoderado'] = observacionesApoderado;
        }
        
        // Agregar detallesPago si está presente (pago agrupado)
        if (detallesPago != null) {
          request.fields['detallesPago'] = jsonEncode(detallesPago);
        }

        // Agregar archivo desde bytes (compatible con web)
        var multipartFile = http.MultipartFile.fromBytes(
          'voucher',
          archivoBytes,
          filename: nombreArchivo,
        );
        request.files.add(multipartFile);

        // Enviar request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        print('🔍 DEBUG Response:');
        print('  - statusCode: ${response.statusCode}');
        print('  - body: ${response.body}');

        // Manejar respuesta
        final data = response.body.isNotEmpty ? response.body : null;
        return ApiResponse(
          statusCode: response.statusCode,
          data: data,
          message:
              response.statusCode == 200 || response.statusCode == 201
                  ? 'Voucher subido exitosamente'
                  : 'Error subiendo voucher',
        );
      } else {
        return ApiResponse(
          statusCode: 400,
          message: 'Se requiere archivo y nombre de archivo',
        );
      }
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        message: 'Error subiendo voucher: $e',
      );
    }
  }

  /// Obtener historial de pagos del apoderado
  static Future<ApiResponse> obtenerHistorialApoderado({
    int limite = 20,
    int pagina = 1,
    String? estado,
    String? mesCorrespondiente,
  }) async {
    try {
      String endpoint =
          '/comprobantes-pago/apoderado/historial?limite=$limite&pagina=$pagina';

      if (estado != null) {
        endpoint += '&estado=$estado';
      }

      if (mesCorrespondiente != null) {
        endpoint += '&mesCorrespondiente=$mesCorrespondiente';
      }

      return ApiService.get(endpoint);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        message: 'Error obteniendo historial: $e',
      );
    }
  }

  /// Obtener las inscripciones del apoderado
  static Future<ApiResponse> obtenerInscripcionesApoderado() async {
    return ApiService.get('/comprobantes-pago/apoderado/inscripciones');
  }

  /// Obtener meses no pagados de 2025 para los estudiantes del apoderado
  /// (LEGACY - mantener para compatibilidad)
  static Future<ApiResponse> obtenerMesesNoPagados2025({List<String>? rutEstudiantes}) async {
    return obtenerMesesNoPagados(rutEstudiantes: rutEstudiantes);
  }

  /// Obtener meses no pagados para los estudiantes del apoderado
  /// Si no se especifica año, devuelve TODOS los meses de TODOS los años (2025-2030)
  static Future<ApiResponse> obtenerMesesNoPagados({
    int? anio, // Opcional: si se omite, devuelve todos los años
    List<String>? rutEstudiantes,
  }) async {
    String endpoint = '/comprobantes-pago/apoderado/meses-no-pagados';
    
    List<String> params = [];
    
    // Si se especifica año, agregarlo como query param
    if (anio != null) {
      params.add('anio=$anio');
    }
    
    // Si se especifican RUTs, agregarlos como query param
    if (rutEstudiantes != null && rutEstudiantes.isNotEmpty) {
      final rutsParam = rutEstudiantes.join(',');
      params.add('rutEstudiantes=$rutsParam');
    }
    
    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }
    
    return ApiService.get(endpoint);
  }

  /// Reenviar comprobante electrónico
  static Future<ApiResponse> reenviarComprobanteElectronico(
    String comprobanteId,
  ) async {
    return ApiService.post(
      '/comprobantes-pago/apoderado/$comprobanteId/reenviar-comprobante',
      {},
    );
  }

  /// Obtener estadísticas del apoderado
  static Map<String, dynamic> calcularEstadisticasLocales(
    HistorialPagos historial,
  ) {
    final comprobantes = historial.comprobantes;

    double totalPagado = 0;
    int pendientes = 0;
    int validados = 0;
    int rechazados = 0;

    String ultimoPago = 'Sin pagos';
    String proximoVencimiento = 'Sin vencimientos';

    for (var comprobante in comprobantes) {
      totalPagado += comprobante.montoTotal;

      switch (comprobante.estado) {
        case 'pendiente':
          pendientes++;
          break;
        case 'validado':
          validados++;
          break;
        case 'rechazado':
          rechazados++;
          break;
      }
    }

    if (comprobantes.isNotEmpty) {
      // Ordenar por fecha de pago (más reciente primero)
      comprobantes.sort((a, b) => b.fechaPago.compareTo(a.fechaPago));
      ultimoPago = formatearFecha(comprobantes.first.fechaPago);

      // Calcular próximo vencimiento (asumiendo mensualidad)
      final ultimaFecha = comprobantes.first.fechaPago;
      final proximaFecha = DateTime(
        ultimaFecha.year,
        ultimaFecha.month + 1,
        ultimaFecha.day,
      );
      proximoVencimiento = formatearFecha(proximaFecha);
    }

    return {
      'totalPagado': totalPagado,
      'totalComprobantes': comprobantes.length,
      'pendientes': pendientes,
      'validados': validados,
      'rechazados': rechazados,
      'ultimoPago': ultimoPago,
      'proximoVencimiento': proximoVencimiento,
    };
  }

  static String formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  /// Obtener color del estado
  static String getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'validado':
        return '#4CAF50'; // Verde
      case 'pendiente':
        return '#FF9800'; // Naranja
      case 'rechazado':
        return '#F44336'; // Rojo
      case 'observado':
        return '#2196F3'; // Azul
      default:
        return '#757575'; // Gris
    }
  }

  /// Obtener icono del estado
  static String getEstadoIcono(String estado) {
    switch (estado.toLowerCase()) {
      case 'validado':
        return '✅';
      case 'pendiente':
        return '⏳';
      case 'rechazado':
        return '❌';
      case 'observado':
        return '👁️';
      default:
        return '❓';
    }
  }

  /// Obtener descripción del estado
  static String getEstadoDescripcion(String estado) {
    switch (estado.toLowerCase()) {
      case 'validado':
        return 'Pago confirmado y validado';
      case 'pendiente':
        return 'En revisión por tesorería';
      case 'rechazado':
        return 'Rechazado - Ver observaciones';
      case 'observado':
        return 'Con observaciones';
      default:
        return 'Estado desconocido';
    }
  }

  /// Formatear método de pago
  static String formatearMetodoPago(String metodo) {
    switch (metodo.toLowerCase()) {
      case 'transferencia':
        return 'Transferencia Bancaria';
      case 'deposito':
        return 'Depósito Bancario';
      case 'efectivo':
        return 'Efectivo';
      case 'cheque':
        return 'Cheque';
      case 'tarjeta':
        return 'Tarjeta';
      default:
        return metodo;
    }
  }

  /// Formatear monto en pesos chilenos
  static String formatearMonto(double monto) {
    return '\$${monto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} CLP';
  }
}
