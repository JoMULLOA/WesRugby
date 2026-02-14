import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/services/tokenManager.dart';
import 'package:wesrugby/core/config/confGlobal.dart';

class JustificanteService extends ChangeNotifier {
  static final JustificanteService _instance = JustificanteService._internal();
  factory JustificanteService() => _instance;
  JustificanteService._internal();

  // Cache en memoria de los justificantes obtenidos del backend
  static List<Map<String, dynamic>> _justificantes = [];
  bool _cargando = false;

  // Helper para construir URL completa del archivo
  static String _construirUrlArchivo(String? rutaRelativa) {
    if (rutaRelativa == null || rutaRelativa.isEmpty) return '';
    
    // Si ya es una URL completa (S3 o externa), devolverla tal cual
    if (rutaRelativa.startsWith('http://') || rutaRelativa.startsWith('https://')) {
      return rutaRelativa;
    }
    
    // Construir URL completa usando la configuración global
    final baseUrl = confGlobal.baseUrl.replaceAll('/api', '');
    final rutaLimpia = rutaRelativa.startsWith('/') ? rutaRelativa : '/$rutaRelativa';
    return '$baseUrl$rutaLimpia';
  }

  // Cargar justificantes del apoderado desde el backend
  // GET /api/asistencia/apoderado/justificaciones
  Future<bool> cargarJustificantesApoderado({
    String estado = 'Todos',
    int pagina = 1,
    int limite = 50,
  }) async {
    if (_cargando) return false;
    _cargando = true;
    try {
      final params = <String, String>{
        'pagina': pagina.toString(),
        'limite': limite.toString(),
      };
      // Backend acepta: justificado|ausente|tardanza
      if (estado.isNotEmpty && estado.toLowerCase() != 'todos') {
        params['estado'] = estado;
      }

      final query = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final endpoint = '/asistencia/apoderado/justificaciones?$query';
      final resp = await ApiService.get(endpoint);

      if (!resp.success) {
        print('❌ Error obteniendo justificaciones (${resp.statusCode}): ${resp.message ?? resp.data}');
        notifyListeners();
        return false;
      }

      final data = resp.data;
      if (data is Map<String, dynamic>) {
        final List<dynamic> justificaciones = data['justificaciones'] is List ? data['justificaciones'] : [];
        _justificantes = justificaciones.map((raw) {
          if (raw is! Map<String, dynamic>) return <String, dynamic>{};

          // Mapear estado backend -> frontend (Pendiente|Aprobado|Rechazado)
          final String estadoBackend = (raw['estado'] ?? 'justificado').toString();
          String estadoFrontend;
          switch (estadoBackend) {
            case 'justificado':
              estadoFrontend = 'Aprobado';
              break;
            case 'ausente':
              estadoFrontend = 'Rechazado';
              break;
            case 'tardanza':
              estadoFrontend = 'Pendiente';
              break;
            default:
              estadoFrontend = 'Pendiente';
          }

          final rutaRelativa = raw['archivoJustificacion']?['url']?.toString() ?? '';
          final alumno = raw['inscripcion'] is Map<String, dynamic> ? raw['inscripcion'] : null;
          final nombreAlumno = alumno != null
              ? (alumno['nombreCompleto'] ?? '${alumno['nombre'] ?? ''} ${alumno['apellidos'] ?? ''}').toString().trim()
              : 'desconocido';

          return <String, dynamic>{
            'id': raw['id'],
            'usuario': nombreAlumno,
            'rol': 'Apoderado',
            'tipoJustificante': raw['tipoActividad'] ?? 'justificacion',
            'fechaInasistencia': DateTime.tryParse(raw['fecha'] ?? '') ?? DateTime.now(),
            'motivo': raw['justificacion'] ?? raw['observaciones'] ?? '',
            'descripcion': raw['justificacion'] ?? '',
            'fechaCreacion': DateTime.tryParse(raw['createdAt'] ?? '') ?? DateTime.now(),
            'estado': estadoFrontend,
            'archivo': rutaRelativa,
            'archivoUrl': _construirUrlArchivo(rutaRelativa),
            'archivoData': null,
            'alumno': nombreAlumno,
            'alumnoInfo': alumno,
          };
        }).where((m) => m.isNotEmpty).toList();
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Excepción cargando justificantes: $e');
      notifyListeners();
      return false;
    } finally {
      _cargando = false;
    }
  }

  // Cargar listado para Directiva (todos los justificantes)
  Future<bool> cargarJustificantesDirectiva({
    String estado = 'Todos',
    int pagina = 1,
    int limite = 50,
  }) async {
    if (_cargando) return false;
    _cargando = true;
    try {
      final params = <String, String>{
        'pagina': pagina.toString(),
        'limite': limite.toString(),
      };
      if (estado.isNotEmpty && estado.toLowerCase() != 'todos') {
        params['estado'] = estado;
      }

      final query = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final endpoint = '/asistencia/apoderado/justificaciones${query.isNotEmpty ? '?$query' : ''}';
      final resp = await ApiService.get(endpoint);

      if (!resp.success) {
        print('❌ Error obteniendo justificaciones directiva (${resp.statusCode}): ${resp.message ?? resp.data}');
        notifyListeners();
        return false;
      }

      final payload = resp.data;
      List<dynamic> items = [];
      if (payload is List) {
        items = payload;
      } else if (payload is Map<String, dynamic>) {
        if (payload['justificaciones'] is List) {
          items = payload['justificaciones'];
        } else if (payload['data'] is List) {
          items = payload['data'];
        } else if (payload['data'] is Map<String, dynamic>) {
          final inner = payload['data'] as Map<String, dynamic>;
          items = (inner['justificaciones'] is List) ? inner['justificaciones'] : (inner['items'] as List? ?? []);
        }
      }

      _justificantes = items.map((raw) {
        if (raw is! Map<String, dynamic>) return <String, dynamic>{};

        final String estadoBackend = (raw['estado'] ?? 'justificado').toString();
        String estadoFrontend;
        switch (estadoBackend) {
          case 'justificado':
            estadoFrontend = 'Aprobado';
            break;
          case 'ausente':
            estadoFrontend = 'Rechazado';
            break;
          case 'tardanza':
            estadoFrontend = 'Pendiente';
            break;
          default:
            estadoFrontend = 'Pendiente';
        }

        final rutaRelativa = raw['archivoJustificacion']?['url']?.toString() ?? '';
        final alumno = raw['inscripcion'] is Map<String, dynamic> ? raw['inscripcion'] : null;
        final nombreAlumno = alumno != null
            ? (alumno['nombreCompleto'] ?? '${alumno['nombre'] ?? ''} ${alumno['apellidos'] ?? ''}').toString().trim()
            : '';
        final rutAlumno = alumno != null ? (alumno['rut'] ?? '').toString() : '';

        return <String, dynamic>{
          'id': raw['id'],
          'usuario': nombreAlumno,
          'rut': rutAlumno,
          'rol': 'Apoderado',
          'tipoJustificante': raw['tipoActividad'] ?? 'justificacion',
          'fechaInasistencia': DateTime.tryParse(raw['fecha'] ?? '') ?? DateTime.now(),
          'motivo': raw['justificacion'] ?? raw['observaciones'] ?? '',
          'descripcion': raw['justificacion'] ?? '',
          'fechaCreacion': DateTime.tryParse(raw['createdAt'] ?? '') ?? DateTime.now(),
          'estado': estadoFrontend,
          'archivo': rutaRelativa,
          'archivoUrl': _construirUrlArchivo(rutaRelativa),
          'archivoData': null,
          'alumno': nombreAlumno,
          'alumnoInfo': alumno,
        };
      }).where((m) => m.isNotEmpty).toList();

      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Excepción cargando justificantes directiva: $e');
      notifyListeners();
      return false;
    } finally {
      _cargando = false;
    }
  }

  // Obtener asistencias pendientes de justificación
  Future<List<Map<String, dynamic>>> obtenerAsistenciasPendientes() async {
    try {
      final endpoint = '/asistencia/apoderado/asistencias-pendientes';
      final resp = await ApiService.get(endpoint);

      if (!resp.success) {
        print('❌ Error obteniendo asistencias pendientes (${resp.statusCode}): ${resp.message ?? resp.data}');
        return [];
      }

      final payload = resp.data;
      if (payload is Map<String, dynamic> && payload['asistencias'] is List) {
        final List<dynamic> items = payload['asistencias'];
        return items.map((raw) {
          if (raw is! Map<String, dynamic>) return <String, dynamic>{};
          
          final alumno = raw['inscripcion'] is Map<String, dynamic> ? raw['inscripcion'] : null;
          final nombreAlumno = alumno != null
              ? (alumno['nombreCompleto'] ?? '').toString().trim()
              : '';

          return <String, dynamic>{
            'id': raw['id'],
            'fecha': raw['fecha'],
            'tipoActividad': raw['tipoActividad'] ?? '',
            'categoria': raw['categoria'] ?? '',
            'estado': raw['estado'] ?? '',
            'observaciones': raw['observaciones'] ?? '',
            'alumno': nombreAlumno,
            'alumnoRut': alumno?['rutAlumno'] ?? '',
            'alumnoInfo': alumno,
          };
        }).where((m) => m.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      print('❌ Excepción obteniendo asistencias pendientes: $e');
      return [];
    }
  }

  // Subir justificante a una asistencia
  Future<Map<String, dynamic>> subirJustificante({
    required String asistenciaId,
    required String justificacion,
    dynamic archivoBytes,
    String? archivoNombre,
  }) async {
    try {
      final endpoint = '/asistencia/$asistenciaId/justificacion';
      final url = Uri.parse('${ApiService.baseUrl}$endpoint');
      
      if (archivoBytes != null && archivoNombre != null) {
        // Subir con archivo usando multipart
        var request = http.MultipartRequest('POST', url);

        // Headers de autenticación
        final token = await TokenManager.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        // Campo de texto
        request.fields['justificacion'] = justificacion;

        // Archivo desde bytes (compatible con web)
        var multipartFile = http.MultipartFile.fromBytes(
          'justificante',
          archivoBytes,
          filename: archivoNombre,
        );
        request.files.add(multipartFile);

        // Enviar request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        print('🔍 Response subir justificante:');
        print('  - statusCode: ${response.statusCode}');
        print('  - body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Justificante subido exitosamente');
          final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
          return {'success': true, 'data': data};
        } else {
          print('❌ Error subiendo justificante: ${response.body}');
          return {'success': false, 'error': response.body};
        }
      } else {
        // Subir solo texto sin archivo usando POST regular
        final resp = await ApiService.post(endpoint, {'justificacion': justificacion});
        
        if (resp.success) {
          print('✅ Justificante (solo texto) subido exitosamente');
          return {'success': true, 'data': resp.data};
        } else {
          print('❌ Error subiendo justificante: ${resp.message}');
          return {'success': false, 'error': resp.message ?? 'Error desconocido'};
        }
      }
    } catch (e) {
      print('❌ Excepción subiendo justificante: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Obtener todos los justificantes (copia de la cache)
  List<Map<String, dynamic>> getAllJustificantes() => List<Map<String, dynamic>>.from(_justificantes);

  // Obtener justificantes filtrados (filtrado local tras carga)
  List<Map<String, dynamic>> getFilteredJustificantes({
    String? estado,
    String? tipo,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? busqueda,
  }) {
    List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(_justificantes);

    if (estado != null && estado.toLowerCase() != 'todos') {
      filtered = filtered.where((j) => j['estado'] == estado).toList();
    }

    if (tipo != null && tipo.toLowerCase() != 'todos') {
      filtered = filtered.where((j) => j['tipoJustificante'] == tipo).toList();
    }

    if (fechaDesde != null) {
      filtered = filtered.where((j) {
        final fecha = j['fechaInasistencia'];
        return fecha is DateTime && fecha.isAfter(fechaDesde.subtract(const Duration(days: 1)));
      }).toList();
    }

    if (fechaHasta != null) {
      filtered = filtered.where((j) {
        final fecha = j['fechaInasistencia'];
        return fecha is DateTime && fecha.isBefore(fechaHasta.add(const Duration(days: 1)));
      }).toList();
    }

    if (busqueda != null && busqueda.isNotEmpty) {
      final lower = busqueda.toLowerCase();
      filtered = filtered.where((j) {
        final usuario = (j['usuario'] ?? '').toString().toLowerCase();
        final motivo = (j['motivo'] ?? '').toString().toLowerCase();
        return usuario.contains(lower) || motivo.contains(lower);
      }).toList();
    }

    // Ordenar por fecha de creación (más recientes primero)
    filtered.sort((a, b) {
      final dateA = a['fechaCreacion'];
      final dateB = b['fechaCreacion'];
      if (dateA is DateTime && dateB is DateTime) return dateB.compareTo(dateA);
      return 0;
    });

    return filtered;
  }

  // Obtener estadísticas para la directiva
  Map<String, int> getDirectivaStatistics() {
    final pendientes = _justificantes.where((j) => j['estado'] == 'Pendiente').length;
    final aprobados = _justificantes.where((j) => j['estado'] == 'Aprobado').length;
    final rechazados = _justificantes.where((j) => j['estado'] == 'Rechazado').length;

    return {
      'pendientes': pendientes,
      'aprobados': aprobados,
      'rechazados': rechazados,
      'total': _justificantes.length,
    };
  }

  // Métodos de simulación o utilidades conservadas
  String addJustificante({
    required String usuario,
    required String rol,
    required String tipoJustificante,
    required DateTime fechaInasistencia,
    required String motivo,
    String? descripcion,
    String? archivo,
    dynamic archivoData,
  }) {
    final newId = 'J${(_justificantes.length + 1).toString().padLeft(3, '0')}';
    final now = DateTime.now();

    print('🔍 (Mock) GUARDANDO JUSTIFICANTE: $newId');

    final newJustificante = <String, dynamic>{
      'id': newId,
      'usuario': usuario,
      'rol': rol,
      'tipoJustificante': tipoJustificante,
      'fechaInasistencia': fechaInasistencia,
      'motivo': motivo,
      'descripcion': descripcion ?? '',
      'fechaCreacion': now,
      'estado': 'Pendiente',
      'archivo': archivo,
      'archivoData': archivoData,
    };

    _justificantes.insert(0, newJustificante);
    notifyListeners();

    print('✅ (Mock) Justificante guardado exitosamente');
    return newId;
  }

  // Aprobar justificante - llamada real al backend (actualiza estado de asistencia)
  Future<bool> approveJustificante(String justificanteId) async {
    try {
      // En backend, aprobar es cambiar el estado de la asistencia a 'justificado'
      final resp = await ApiService.put(
        '/asistencia/$justificanteId',
        {
          'estado': 'justificado',
        },
      );
      
      if (resp.success) {
        // Actualizar cache local
        final index = _justificantes.indexWhere((j) => j['id'].toString() == justificanteId.toString());
        if (index != -1) {
          _justificantes[index]['estado'] = 'Aprobado';
          _justificantes[index]['fechaAprobacion'] = DateTime.now();
          _justificantes[index]['evaluadoPor'] = 'Directiva';
        }
        notifyListeners();
        print('✅ Justificante $justificanteId aprobado en backend');
        return true;
      }
      print('❌ Error aprobando justificante: ${resp.message}');
      return false;
    } catch (e) {
      print('❌ Excepción aprobando justificante: $e');
      return false;
    }
  }

  // Rechazar justificante - llamada real al backend
  Future<bool> rejectJustificante(String justificanteId, String motivo) async {
    try {
      // En backend, rechazar es cambiar el estado de la asistencia a 'ausente' con observaciones
      final resp = await ApiService.put(
        '/asistencia/$justificanteId',
        {
          'estado': 'ausente',
          'observaciones': motivo,
        },
      );
      
      if (resp.success) {
        // Actualizar cache local
        final index = _justificantes.indexWhere((j) => j['id'].toString() == justificanteId.toString());
        if (index != -1) {
          _justificantes[index]['estado'] = 'Rechazado';
          _justificantes[index]['fechaRechazo'] = DateTime.now();
          _justificantes[index]['evaluadoPor'] = 'Directiva';
          _justificantes[index]['motivoRechazo'] = motivo;
        }
        notifyListeners();
        print('✅ Justificante $justificanteId rechazado en backend');
        return true;
      }
      print('❌ Error rechazando justificante: ${resp.message}');
      return false;
    } catch (e) {
      print('❌ Excepción rechazando justificante: $e');
      return false;
    }
  }

  // ================= PERSISTENCIA NUEVA (tabla justificantes) =================

  Map<String, dynamic> _mapPersistente(Map<String, dynamic> raw) {
    final archivoMap = raw['archivo'];
    String rutaRelativa = '';
    if (archivoMap is Map<String, dynamic>) {
      rutaRelativa = (archivoMap['url'] ?? '').toString();
    } else if (raw['rutaArchivo'] != null) {
      rutaRelativa = raw['rutaArchivo'].toString();
    }

    final estadoBackend = (raw['estado'] ?? 'pendiente').toString();
    String estadoFrontend;
    switch (estadoBackend) {
      case 'aprobado':
        estadoFrontend = 'Aprobado';
        break;
      case 'rechazado':
        estadoFrontend = 'Rechazado';
        break;
      case 'observado':
        estadoFrontend = 'Observado';
        break;
      default:
        estadoFrontend = 'Pendiente';
    }

    return <String, dynamic>{
      'id': raw['id'],
      'usuario': raw['estudianteRut'] ?? 'Estudiante',
      'rol': 'Apoderado',
      'tipoJustificante': raw['tipo'] ?? 'justificante',
      'fechaInasistencia': DateTime.tryParse(raw['fechaInicio'] ?? '') ?? DateTime.now(),
      'motivo': raw['motivo'] ?? '',
      'descripcion': raw['descripcion'] ?? '',
      'fechaCreacion': DateTime.tryParse(raw['fechaSubida'] ?? raw['createdAt'] ?? '') ?? DateTime.now(),
      'estado': estadoFrontend,
      'archivo': rutaRelativa,
      'archivoUrl': _construirUrlArchivo(rutaRelativa),
      'fechaInicio': raw['fechaInicio'],
      'fechaFin': raw['fechaFin'],
      'motivoRechazo': raw['motivoRechazo'],
      'observacionesDirectiva': raw['observacionesDirectiva'],
      'evaluadoPor': raw['revisadoPorRut'],
      'mesesExencion': (raw['mesesExencion'] is List) ? List<String>.from(raw['mesesExencion'].map((e) => e.toString())) : <String>[],
    };
  }

  Future<Map<String, dynamic>> crearJustificantePersistente({
    required String estudianteRut,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    required String tipo,
    required String motivo,
    String? descripcion,
    Uint8List? archivoBytes,
    String? archivoNombre,
  }) async {
    try {
      final endpoint = '/justificantes/apoderado';
      final url = Uri.parse('${ApiService.baseUrl}$endpoint');
      if (archivoBytes != null && archivoNombre != null) {
        var request = http.MultipartRequest('POST', url);
        final token = await TokenManager.getToken();
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
        request.fields['estudianteRut'] = estudianteRut;
        request.fields['fechaInicio'] = fechaInicio.toIso8601String().split('T')[0];
        if (fechaFin != null) request.fields['fechaFin'] = fechaFin.toIso8601String().split('T')[0];
        request.fields['tipo'] = tipo;
        request.fields['motivo'] = motivo;
        if (descripcion != null && descripcion.isNotEmpty) request.fields['descripcion'] = descripcion;
        final file = http.MultipartFile.fromBytes('justificante', archivoBytes, filename: archivoNombre);
        request.files.add(file);
        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        if (response.statusCode == 201) {
          final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
          return {'success': true, 'data': data};
        }
        return {'success': false, 'error': response.body};
      } else {
        final body = {
          'estudianteRut': estudianteRut,
          'fechaInicio': fechaInicio.toIso8601String().split('T')[0],
          'fechaFin': fechaFin != null ? fechaFin.toIso8601String().split('T')[0] : null,
          'tipo': tipo,
          'motivo': motivo,
          if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        };
        final resp = await ApiService.post(endpoint, body);
        if (resp.success) return {'success': true, 'data': resp.data};
        return {'success': false, 'error': resp.message ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> cargarJustificantesPersistentesApoderado({int pagina = 1, int limite = 50, String estado = 'Todos'}) async {
    try {
      final params = <String, String>{ 'pagina': '$pagina', 'limite': '$limite' };
      if (estado.toLowerCase() != 'todos') params['estado'] = estado;
      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final endpoint = '/justificantes/apoderado/mis?$query';
      print('🔍 DEBUG cargarJustificantesPersistentesApoderado - endpoint: $endpoint');
      final resp = await ApiService.get(endpoint);
      print('🔍 DEBUG cargarJustificantesPersistentesApoderado - resp.success: ${resp.success}');
      if (!resp.success) return false;
      
      // resp.data contiene {success, message, data: {justificantes, paginacion}}
      final responseData = resp.data;
      print('🔍 DEBUG cargarJustificantesPersistentesApoderado - responseData type: ${responseData.runtimeType}');
      
      List<dynamic> items = [];
      if (responseData is Map<String, dynamic>) {
        // Accedemos a data.data.justificantes (el segundo 'data' es el payload)
        final payload = responseData['data'];
        if (payload is Map<String, dynamic>) {
          items = (payload['justificantes'] as List? ?? []);
          print('🔍 DEBUG cargarJustificantesPersistentesApoderado - items from payload: ${items.length}');
        }
      }
      
      _justificantes = items.map((e) => e is Map<String, dynamic> ? _mapPersistente(e) : <String, dynamic>{}).where((m) => m.isNotEmpty).toList();
      print('🔍 DEBUG cargarJustificantesPersistentesApoderado - _justificantes length: ${_justificantes.length}');
      print('🔍 DEBUG cargarJustificantesPersistentesApoderado - _justificantes: $_justificantes');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error cargando justificantes persistentes apoderado: $e');
      return false;
    }
  }

  Future<bool> cargarJustificantesPersistentesDirectiva({int pagina = 1, int limite = 50, String estado = 'Todos'}) async {
    try {
      final params = <String, String>{ 'pagina': '$pagina', 'limite': '$limite' };
      if (estado.toLowerCase() != 'todos') params['estado'] = estado;
      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final endpoint = '/justificantes/directiva?$query';
      final resp = await ApiService.get(endpoint);
      if (!resp.success) return false;
      
      // resp.data contiene {success, message, data: {justificantes, paginacion}}
      final responseData = resp.data;
      List<dynamic> items = [];
      if (responseData is Map<String, dynamic>) {
        // Accedemos a data.data.justificantes (el segundo 'data' es el payload)
        final payload = responseData['data'];
        if (payload is Map<String, dynamic>) {
          items = (payload['justificantes'] as List? ?? []);
        }
      }
      
      _justificantes = items.map((e) => e is Map<String, dynamic> ? _mapPersistente(e) : <String, dynamic>{}).where((m) => m.isNotEmpty).toList();
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error cargando justificantes persistentes directiva: $e');
      return false;
    }
  }

  // Obtener justificantes aprobados que cubren una fecha para un conjunto de estudiantes (directiva)
  Future<Map<String, List<Map<String, dynamic>>>> obtenerJustificadosPorFecha(String fechaISO, List<String> ruts) async {
    try {
      if (ruts.isEmpty) return {};
      final rutsParam = ruts.join(',');
      final endpoint = '/justificantes/fecha/$fechaISO?ruts=$rutsParam';
      final resp = await ApiService.get(endpoint);
      if (!resp.success) return {};
      final responseData = resp.data;
      if (responseData is! Map<String, dynamic>) return {};
      final payload = responseData['data'];
      if (payload is! Map<String, dynamic>) return {};
      final estudiantes = payload['estudiantes'] as List? ?? [];
      final resultado = <String, List<Map<String, dynamic>>>{};
      for (final e in estudiantes) {
        if (e is Map<String, dynamic>) {
          final rut = e['estudianteRut']?.toString();
          final lista = (e['justificantes'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(_mapPersistente)
              .toList();
          if (rut != null) resultado[rut] = lista;
        }
      }
      return resultado;
    } catch (e) {
      print('❌ Error obtenerJustificadosPorFecha: $e');
      return {};
    }
  }

  Future<bool> actualizarEstadoJustificantePersistente(String id, String nuevoEstado, {String? motivoRechazo, String? observaciones}) async {
    try {
      final body = {
        'estado': nuevoEstado,
        if (motivoRechazo != null) 'motivoRechazo': motivoRechazo,
        if (observaciones != null) 'observaciones': observaciones,
      };
      final resp = await ApiService.patch('/justificantes/$id/estado', body);
      if (!resp.success) return false;
      // Refrescar item en cache
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        final mapped = _mapPersistente(data);
        final idx = _justificantes.indexWhere((j) => j['id'] == id);
        if (idx != -1) {
          _justificantes[idx] = {..._justificantes[idx], ...mapped};
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error actualizando estado justificante persistente: $e');
      return false;
    }
  }

  Future<bool> actualizarMesesExencion(String id, List<String> meses) async {
    try {
      final body = { 'meses': meses };
      final resp = await ApiService.patch('/justificantes/$id/exenciones-meses', body);
      if (!resp.success) return false;
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        final mapped = _mapPersistente(data);
        final idx = _justificantes.indexWhere((j) => j['id'] == id);
        if (idx != -1) {
          _justificantes[idx] = mapped;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error actualizando meses exención: $e');
      return false;
    }
  }

  Map<String, dynamic>? getJustificanteById(String justificanteId) {
    try {
      return _justificantes.firstWhere((j) => j['id'].toString() == justificanteId.toString());
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> getJustificantesByUser(String usuario) => _justificantes.where((j) => j['usuario'] == usuario).toList();

  void notifyDirectiva(String justificanteId) {
    print('📧 (Mock) Notificación Directiva por justificante $justificanteId');
  }

  void notifyEntrenador(String justificanteId) {
    print('📧 (Mock) Notificación Entrenador por justificante $justificanteId');
  }
}