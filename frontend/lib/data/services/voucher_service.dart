import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/core/config/confGlobal.dart';

class VoucherService {
  static final VoucherService _instance = VoucherService._internal();
  factory VoucherService() => _instance;
  VoucherService._internal();

  // Cache en memoria de los vouchers obtenidos del backend
  static List<Map<String, dynamic>> _vouchers = [];
  bool _cargando = false;

  // Helper para construir URL completa del archivo
  static String _construirUrlArchivo(String? rutaRelativa) {
    if (rutaRelativa == null || rutaRelativa.isEmpty) return '';
    
    // Si ya es una URL completa (S3 o externa), devolverla tal cual
    if (rutaRelativa.startsWith('http://') || rutaRelativa.startsWith('https://')) {
      return rutaRelativa;
    }
    
    // Construir URL completa usando la configuración global
    // confGlobal.baseUrl ya incluye /api, necesitamos solo el host
    final baseUrl = confGlobal.baseUrl.replaceAll('/api', '');
    final rutaLimpia = rutaRelativa.startsWith('/') ? rutaRelativa : '/$rutaRelativa';
    return '$baseUrl$rutaLimpia';
  }

  // Cargar historial de vouchers del apoderado desde el backend
  // Filtros aceptan "Todos" para omitirlos
  Future<bool> cargarHistorialApoderado({
    String estado = 'Todos',
    String mes = 'Todos',
    String metodoPago = 'Todos',
    int pagina = 1,
    int limite = 50,
  }) async {
    if (_cargando) return false; // evitar llamadas paralelas
    _cargando = true;
    try {
      final params = <String, String>{
        'pagina': pagina.toString(),
        'limite': limite.toString(),
      };
      if (estado.isNotEmpty && estado.toLowerCase() != 'todos') {
        params['estado'] = estado; // backend espera: pendiente|validado|rechazado|observado
      }
      if (mes.isNotEmpty && mes.toLowerCase() != 'todos') {
        params['mesCorrespondiente'] = mes; // debe ir normalizado según backend
      }
      if (metodoPago.isNotEmpty && metodoPago.toLowerCase() != 'todos') {
        params['metodoPago'] = metodoPago; // transferencia|deposito|... según ensureMetodoPago
      }

      final query = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final endpoint = '/comprobantes-pago/apoderado/historial?$query';
      final resp = await ApiService.get(endpoint);
      if (!resp.success) {
        print('❌ Error obteniendo historial vouchers (${resp.statusCode}): ${resp.message ?? resp.data}');
        return false;
      }

      final data = resp.data;
      if (data is Map<String, dynamic>) {
        // La respuesta viene en data['data']['comprobantes']
        final dataPayload = data['data'] is Map<String, dynamic> ? data['data'] : data;
        final List<dynamic> comprobantes = dataPayload['comprobantes'] is List ? dataPayload['comprobantes'] : [];
        print('✅ Comprobantes recibidos: ${comprobantes.length}');
        _vouchers = comprobantes.map((raw) {
          if (raw is! Map<String, dynamic>) return <String, dynamic>{};

          // Mapear estados backend -> frontend (UI actual usa Pendiente/Aprobado/Rechazado)
          final String estadoBackend = (raw['estado'] ?? '').toString();
          String estadoFrontend;
            switch (estadoBackend) {
              case 'validado':
                estadoFrontend = 'Aprobado';
                break;
              case 'rechazado':
                estadoFrontend = 'Rechazado';
                break;
              case 'pendiente':
                estadoFrontend = 'Pendiente';
                break;
              default:
                // "observado" u otros
                estadoFrontend = estadoBackend.isEmpty ? 'Pendiente' : estadoBackend;
            }

          // Extraer información del alumno
          final alumno = raw['alumno'] is Map<String, dynamic> ? raw['alumno'] : null;
          final nombreAlumno = alumno != null 
            ? (alumno['nombreCompleto'] ?? '${alumno['nombre'] ?? ''} ${alumno['apellidos'] ?? ''}').toString().trim()
            : 'Desconocido';

          final rutaRelativa = raw['rutaComprobante']?.toString() ?? '';

          return <String, dynamic>{
            'id': raw['id']?.toString() ?? '',
            'usuario': raw['apoderadoEmail']?.toString() ?? raw['apoderadoRut']?.toString() ?? 'desconocido',
            'rol': 'Apoderado',
            'mes': raw['mesCorrespondiente']?.toString() ?? '',
            'monto': raw['montoTotal'] ?? 0,
            'metodoPago': raw['metodoPago']?.toString() ?? '',
            'fechaEnvio': raw['fechaSubida']?.toString() ?? raw['fechaPago']?.toString() ?? '',
            'estado': estadoFrontend,
            'archivo': rutaRelativa,
            'archivoUrl': _construirUrlArchivo(rutaRelativa),
            'descripcion': raw['observacionesApoderado']?.toString() ?? '',
            'motivoRechazo': raw['motivoRechazo']?.toString() ?? '',
            'tipoArchivo': raw['tipoArchivo']?.toString() ?? '',
            // Campos adicionales útiles si luego se extiende UI
            'numeroOperacion': raw['numeroOperacion']?.toString() ?? '',
            'bancoOrigen': raw['bancoOrigen']?.toString() ?? '',
            'tipoPago': raw['tipoPago']?.toString() ?? '',
            'numeroComprobante': raw['numeroComprobante']?.toString() ?? '',
            // Información del estudiante
            'estudianteRut': raw['estudianteRut']?.toString() ?? '',
            'alumno': nombreAlumno,
            'alumnoInfo': alumno,
          };
        }).where((m) => m.isNotEmpty).toList();
      }
      return true;
    } catch (e) {
      print('❌ Excepción cargando historial vouchers: $e');
      return false;
    } finally {
      _cargando = false;
    }
  }

  // Cargar listado para Tesorería (todos los vouchers visibles según permisos)
  Future<bool> cargarListadoTesorera({
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
      final endpoint = '/comprobantes-pago${query.isNotEmpty ? '?$query' : ''}';
      final resp = await ApiService.get(endpoint);
      if (!resp.success) {
        print('❌ Error obteniendo listado tesorería (${resp.statusCode}): ${resp.message ?? resp.data}');
        return false;
      }

      final payload = resp.data;
      List<dynamic> items = [];
      if (payload is List) {
        items = payload;
      } else if (payload is Map<String, dynamic>) {
        if (payload['data'] is List) {
          items = payload['data'];
        } else if (payload['comprobantes'] is List) {
          items = payload['comprobantes'];
        } else if (payload['data'] is Map<String, dynamic>) {
          final inner = payload['data'] as Map<String, dynamic>;
          items = (inner['comprobantes'] is List) ? inner['comprobantes'] : (inner['items'] as List? ?? []);
        }
      }

      _vouchers = items.map((raw) {
        if (raw is! Map<String, dynamic>) return <String, dynamic>{};

        final String estadoBackend = (raw['estado'] ?? '').toString();
        String estadoFrontend;
        switch (estadoBackend) {
          case 'validado':
            estadoFrontend = 'Aprobado';
            break;
          case 'rechazado':
            estadoFrontend = 'Rechazado';
            break;
          case 'pendiente':
            estadoFrontend = 'Pendiente';
            break;
          default:
            estadoFrontend = estadoBackend.isEmpty ? 'Pendiente' : estadoBackend;
        }

        final alumno = raw['alumno'] is Map<String, dynamic> ? raw['alumno'] : null;
        final nombreAlumno = alumno != null
            ? (alumno['nombreCompleto'] ?? '${alumno['nombre'] ?? ''} ${alumno['apellidos'] ?? ''}').toString().trim()
            : '';

        final rutaRelativa = raw['rutaComprobante']?.toString() ?? '';

        return <String, dynamic>{
          'id': raw['id']?.toString() ?? '',
          'usuario': raw['apoderadoEmail']?.toString() ?? raw['apoderadoRut']?.toString() ?? '',
          'rol': 'Apoderado',
          'mes': raw['mesCorrespondiente']?.toString() ?? '',
          'monto': raw['montoTotal'] ?? 0,
          'metodoPago': raw['metodoPago']?.toString() ?? '',
          'fechaEnvio': raw['fechaSubida']?.toString() ?? raw['fechaPago']?.toString() ?? '',
          'estado': estadoFrontend,
          'archivo': rutaRelativa,
          'archivoUrl': _construirUrlArchivo(rutaRelativa),
          'tipoArchivo': raw['tipoArchivo']?.toString() ?? '',
          'descripcion': raw['observacionesApoderado']?.toString() ?? '',
          'motivoRechazo': raw['motivoRechazo']?.toString() ?? '',
          'estudianteRut': raw['estudianteRut']?.toString() ?? '',
          'alumno': nombreAlumno,
          'alumnoInfo': alumno,
        };
      }).where((m) => m.isNotEmpty).toList();

      return true;
    } catch (e) {
      print('❌ Excepción cargando listado tesorería: $e');
      return false;
    } finally {
      _cargando = false;
    }
  }

  // Devuelve copia de la lista cargada
  List<Map<String, dynamic>> getAllVouchers() => List<Map<String, dynamic>>.from(_vouchers);

  // Filtrado local tras carga
  List<Map<String, dynamic>> getFilteredVouchers({
    String? usuario,
    String? estado,
    String? searchText,
  }) {
    return _vouchers.where((voucher) {
      final matchesUser = usuario == null || usuario == 'Todos' || voucher['usuario'] == usuario;
      final matchesStatus = estado == null || estado == 'Todos' || voucher['estado'] == estado;
      final matchesSearch = searchText == null || searchText.isEmpty || voucher['usuario']?.toString().toLowerCase().contains(searchText.toLowerCase()) == true;
      return matchesUser && matchesStatus && matchesSearch;
    }).toList();
  }

  List<String> getUniqueUsers() {
    final users = _vouchers.map((v) => v['usuario'] as String).where((e) => e.isNotEmpty).toSet();
    final list = users.toList()..sort();
    return ['Todos', ...list];
  }

  Map<String, int> getStats() {
    final total = _vouchers.length;
    final pendientes = _vouchers.where((v) => v['estado'] == 'Pendiente').length;
    final aprobados = _vouchers.where((v) => v['estado'] == 'Aprobado').length;
    final rechazados = _vouchers.where((v) => v['estado'] == 'Rechazado').length;
    return {
      'total': total,
      'pendientes': pendientes,
      'aprobados': aprobados,
      'rechazados': rechazados,
    };
  }

  Map<String, dynamic>? getVoucherById(String voucherId) {
    try {
      return _vouchers.firstWhere((v) => v['id'].toString() == voucherId.toString());
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> getVouchersByUser(String usuario) {
    return _vouchers.where((v) => v['usuario'] == usuario).toList();
  }

  // Agregar nuevo voucher (mock local - la subida real se hace vía POST multipart desde la pantalla)
  String addVoucher({
    required String usuario,
    required String rol,
    required String mes,
    required double monto,
    required String metodoPago,
    String? descripcion,
    required String archivo,
    required dynamic archivoData,
  }) {
    // Generar ID mock temporal
    final newId = 'V${(_vouchers.length + 1).toString().padLeft(3, '0')}';
    final now = DateTime.now();
    final fechaEnvio = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    print('📝 (Mock) Agregando voucher local: $newId');

    final newVoucher = <String, dynamic>{
      'id': newId,
      'usuario': usuario,
      'rol': rol,
      'mes': mes,
      'monto': monto,
      'metodoPago': metodoPago,
      'fechaEnvio': fechaEnvio,
      'estado': 'Pendiente',
      'archivo': archivo,
      'descripcion': descripcion ?? '',
      'archivoData': archivoData,
    };

    _vouchers.insert(0, newVoucher);
    print('✅ (Mock) Voucher agregado localmente: $newId');
    return newId;
  }

  // Aprobar voucher - llamada real al backend
  Future<bool> approveVoucher(String voucherId) async {
    try {
      final resp = await ApiService.patch(
        '/comprobantes-pago/$voucherId/validar',
        {
          'estado': 'validado',
        },
      );
      
      if (resp.success) {
        // Actualizar cache local
        final index = _vouchers.indexWhere((v) => v['id'].toString() == voucherId.toString());
        if (index != -1) {
          _vouchers[index]['estado'] = 'Aprobado';
          _vouchers[index]['fechaAprobacion'] = DateTime.now().toString();
        }
        print('✅ Voucher $voucherId aprobado en backend');
        return true;
      }
      print('❌ Error aprobando voucher: ${resp.message}');
      return false;
    } catch (e) {
      print('❌ Excepción aprobando voucher: $e');
      return false;
    }
  }

  // Rechazar voucher - llamada real al backend
  Future<bool> rejectVoucher(String voucherId, String? motivo) async {
    try {
      final resp = await ApiService.patch(
        '/comprobantes-pago/$voucherId/validar',
        {
          'estado': 'rechazado',
          'motivoRechazo': motivo ?? '',
        },
      );
      
      if (resp.success) {
        // Actualizar cache local
        final index = _vouchers.indexWhere((v) => v['id'].toString() == voucherId.toString());
        if (index != -1) {
          _vouchers[index]['estado'] = 'Rechazado';
          _vouchers[index]['fechaRechazo'] = DateTime.now().toString();
          if (motivo != null && motivo.isNotEmpty) {
            _vouchers[index]['motivoRechazo'] = motivo;
          }
        }
        print('✅ Voucher $voucherId rechazado en backend');
        return true;
      }
      print('❌ Error rechazando voucher: ${resp.message}');
      return false;
    } catch (e) {
      print('❌ Excepción rechazando voucher: $e');
      return false;
    }
  }

  // Métodos de simulación previos conservados como no-op o utilidades
  void notifyTesoreria(String voucherId) {
    print('📧 (Simulación) Notificación Tesorería por voucher $voucherId');
  }

  void sendElectronicReceipt(String voucherId, String userEmail) {
    print('📧 (Simulación) Envío comprobante electrónico voucher $voucherId a $userEmail');
  }
}
