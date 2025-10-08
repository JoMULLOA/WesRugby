import 'package:flutter/foundation.dart';

class JustificanteService extends ChangeNotifier {
  static final JustificanteService _instance = JustificanteService._internal();
  factory JustificanteService() => _instance;
  JustificanteService._internal();

  // Lista global de justificantes para simular base de datos
  static List<Map<String, dynamic>> _justificantes = [];

  // Obtener todos los justificantes
  List<Map<String, dynamic>> getAllJustificantes() {
    return List.from(_justificantes);
  }

  // Obtener justificantes filtrados
  List<Map<String, dynamic>> getFilteredJustificantes({
    String? estado,
    String? tipo,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? busqueda,
  }) {
    List<Map<String, dynamic>> filtered = List.from(_justificantes);
    
    if (estado != null) {
      filtered = filtered.where((j) => j['estado'] == estado).toList();
    }
    
    if (tipo != null) {
      filtered = filtered.where((j) => j['tipoJustificante'] == tipo).toList();
    }
    
    if (fechaDesde != null) {
      filtered = filtered.where((j) {
        return j['fechaInasistencia'] is DateTime 
            ? j['fechaInasistencia'].isAfter(fechaDesde.subtract(Duration(days: 1)))
            : true;
      }).toList();
    }
    
    if (fechaHasta != null) {
      filtered = filtered.where((j) {
        return j['fechaInasistencia'] is DateTime 
            ? j['fechaInasistencia'].isBefore(fechaHasta.add(Duration(days: 1)))
            : true;
      }).toList();
    }
    
    if (busqueda != null && busqueda.isNotEmpty) {
      filtered = filtered.where((j) => 
        j['usuario'].toLowerCase().contains(busqueda.toLowerCase()) ||
        j['motivo'].toLowerCase().contains(busqueda.toLowerCase())
      ).toList();
    }
    
    // Ordenar por fecha de creación (más recientes primero)
    filtered.sort((a, b) => b['fechaCreacion'].compareTo(a['fechaCreacion']));
    
    return filtered;
  }

  // Obtener estadísticas para la directiva
  Map<String, int> getDirectivaStatistics() {
    int pendientes = _justificantes.where((j) => j['estado'] == 'Pendiente').length;
    int aprobados = _justificantes.where((j) => j['estado'] == 'Aprobado').length;
    int rechazados = _justificantes.where((j) => j['estado'] == 'Rechazado').length;
    
    return {
      'pendientes': pendientes,
      'aprobados': aprobados,
      'rechazados': rechazados,
      'total': _justificantes.length,
    };
  }

  // Agregar nuevo justificante (desde el apoderado)
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
    String newId = 'J${(_justificantes.length + 1).toString().padLeft(3, '0')}';
    DateTime now = DateTime.now();
    
    print('🔍 GUARDANDO JUSTIFICANTE:');
    print('   - ID: $newId');
    print('   - Archivo: ${archivo ?? 'Sin archivo'}');
    print('   - Datos del archivo: ${archivoData != null ? 'SÍ (${archivoData.runtimeType})' : 'NO'}');
    if (archivoData != null) {
      print('   - Tamaño de datos: ${archivoData.length} bytes');
    }
    
    Map<String, dynamic> newJustificante = {
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
    
    print('✅ Justificante guardado exitosamente');
    return newId;
  }

  // Aprobar justificante (solo directiva)
  bool approveJustificante(String justificanteId) {
    int index = _justificantes.indexWhere((j) => j['id'] == justificanteId);
    if (index != -1) {
      _justificantes[index]['estado'] = 'Aprobado';
      _justificantes[index]['fechaAprobacion'] = DateTime.now();
      _justificantes[index]['evaluadoPor'] = 'Directiva';
      notifyListeners();
      return true;
    }
    return false;
  }

  // Rechazar justificante (solo directiva)
  bool rejectJustificante(String justificanteId, String motivo) {
    int index = _justificantes.indexWhere((j) => j['id'] == justificanteId);
    if (index != -1) {
      _justificantes[index]['estado'] = 'Rechazado';
      _justificantes[index]['fechaRechazo'] = DateTime.now();
      _justificantes[index]['evaluadoPor'] = 'Directiva';
      _justificantes[index]['motivoRechazo'] = motivo;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Obtener justificante por ID
  Map<String, dynamic>? getJustificanteById(String justificanteId) {
    try {
      return _justificantes.firstWhere((j) => j['id'] == justificanteId);
    } catch (e) {
      return null;
    }
  }

  // Obtener justificantes por usuario (para historial del apoderado)
  List<Map<String, dynamic>> getJustificantesByUser(String usuario) {
    return _justificantes.where((j) => j['usuario'] == usuario).toList();
  }

  // Simular notificación a directiva
  void notifyDirectiva(String justificanteId) {
    print('📧 NOTIFICACIÓN A DIRECTIVA: Nuevo justificante recibido');
    print('   - ID del justificante: $justificanteId');
    print('   - Requiere evaluación');
  }

  // Simular notificación a entrenador
  void notifyEntrenador(String justificanteId) {
    print('📧 NOTIFICACIÓN A ENTRENADOR: Justificante informativo');
    print('   - ID del justificante: $justificanteId');
    print('   - Solo para conocimiento (sin evaluación)');
  }
}