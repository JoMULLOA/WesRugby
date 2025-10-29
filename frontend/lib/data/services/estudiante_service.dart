import 'package:flutter/foundation.dart';
import 'package:wesrugby/data/services/api_service.dart';

class EstudianteService extends ChangeNotifier {
  static final EstudianteService _instance = EstudianteService._internal();
  factory EstudianteService() => _instance;
  EstudianteService._internal();

  static List<Map<String, dynamic>> _estudiantes = [];

  List<Map<String, dynamic>> getAllStudents() {
    return List<Map<String, dynamic>>.from(_estudiantes);
  }

  Map<String, dynamic> getStudentStatistics() {
    final total = _estudiantes.length;
    final conFicha =
        _estudiantes
            .where(
              (e) =>
                  (e['ficha'] == true) ||
                  (e['ficha'] is String &&
                      (e['ficha'] as String).toLowerCase() == 'si'),
            )
            .length;
    final sinFicha = total - conFicha;

    final Map<String, int> porCurso = {};
    final Map<String, int> porCategoria = {};
    final Map<String, int> porEstado = {};

    for (final estudiante in _estudiantes) {
      final curso = (estudiante['curso'] as String?)?.trim();
      if (curso != null && curso.isNotEmpty) {
        porCurso[curso] = (porCurso[curso] ?? 0) + 1;
      }

      final categoria = (estudiante['categoria'] as String?)?.trim();
      if (categoria != null && categoria.isNotEmpty) {
        porCategoria[categoria] = (porCategoria[categoria] ?? 0) + 1;
      }

      final estado = (estudiante['estado'] as String?)?.trim().toLowerCase();
      if (estado != null && estado.isNotEmpty) {
        porEstado[estado] = (porEstado[estado] ?? 0) + 1;
      }
    }

    final activos = porEstado['activo'] ?? 0;
    final inactivos = porEstado['inactivo'] ?? 0;

    return {
      'total': total,
      'conFicha': conFicha,
      'sinFicha': sinFicha,
      'porCurso': porCurso,
      'porCategoria': porCategoria,
      'porEstado': porEstado,
      'activos': activos,
      'inactivos': inactivos,
    };
  }

  Future<void> refreshStudentsFromAPI() async {
    final estudiantes = await getAllStudentsFromAPI();
    _estudiantes = estudiantes.map(_adaptEstudianteFromBackend).toList();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getAllStudentsFromAPI() async {
    try {
      final response = await ApiService.getAllEstudiantes();

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic> &&
            response.data['success'] == true) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        }
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }
      throw Exception(response.message ?? 'Error al obtener estudiantes');
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error al obtener estudiantes: $error');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMisEstudiantes() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get(
        '/estudiantes/mis-estudiantes?t=$timestamp',
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic> &&
            response.data['success'] == true) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        }
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }
      throw Exception(response.message ?? 'Error al obtener estudiantes');
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error al obtener mis estudiantes: $error');
      }
      throw Exception('Error al obtener estudiantes asignados');
    }
  }

  Future<Map<String, dynamic>> importStudentsFromExcel(
    List<Map<String, dynamic>> excelData,
  ) async {
    try {
      if (excelData.isEmpty) {
        throw Exception('No hay datos para importar');
      }

      final List<Map<String, dynamic>> estudiantesParaImportar = [];
      for (final fila in excelData) {
        if (_validateStudentData(fila)) {
          estudiantesParaImportar.add(Map<String, dynamic>.from(fila));
        }
      }

      if (estudiantesParaImportar.isEmpty) {
        throw Exception('No se encontraron estudiantes válidos para importar');
      }

      final response = await ApiService.importEstudiantesFromExcel(
        estudiantesParaImportar,
      );

      if (response.statusCode == 201 && response.data != null) {
        final results = Map<String, dynamic>.from(response.data['data'] ?? {});
        await refreshStudentsFromAPI();

        final creados =
            (results['estudiantesCreados'] as List<dynamic>? ?? []).length;
        final actualizados =
            (results['estudiantesActualizados'] as List<dynamic>? ?? []).length;
        final errores = List<Map<String, dynamic>>.from(
          results['errores'] as List<dynamic>? ?? [],
        );
        final advertencias = List<Map<String, dynamic>>.from(
          results['advertencias'] as List<dynamic>? ?? [],
        );
        final apoderadosGenerados = results['apoderadosCreados'] is num
            ? (results['apoderadosCreados'] as num).toInt()
            : 0;
        final correosApoderado = results['correosApoderadoGenerados'] is num
            ? (results['correosApoderadoGenerados'] as num).toInt()
            : apoderadosGenerados;
    final hermanosSincronizados = results['hermanosSincronizados'] is num
      ? (results['hermanosSincronizados'] as num).toInt()
      : 0;

        return {
          'success': true,
          'estudiantesCreados': creados,
          'estudiantesActualizados': actualizados,
          'apoderadosCreados': apoderadosGenerados,
          'correosApoderadoGenerados': correosApoderado,
      'hermanosSincronizados': hermanosSincronizados,
          'errores': errores,
          'advertencias': advertencias,
          'message':
        'Importación completada. Nuevos: $creados, actualizados: $actualizados, correos de apoderado generados: $correosApoderado, cuentas de apoderado nuevas: $apoderadosGenerados, hermanos sincronizados: $hermanosSincronizados.',
        };
      }

      throw Exception(response.message ?? 'Error del servidor');
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error importando estudiantes: $error');
      }
      return {
        'success': false,
        'message': 'Error durante la importación: $error',
        'error': error.toString(),
      };
    }
  }

  Map<String, dynamic> _adaptEstudianteFromBackend(
    Map<String, dynamic> backendEstudiante,
  ) {
    final pagos =
        backendEstudiante['pagos'] is Map
            ? Map<String, dynamic>.from(backendEstudiante['pagos'])
            : <String, dynamic>{};
    final equipamiento =
        backendEstudiante['equipamiento'] is Map
            ? Map<String, dynamic>.from(backendEstudiante['equipamiento'])
            : <String, dynamic>{};

    DateTime? fechaNacimiento;
    final fechaRaw = backendEstudiante['fechaNacimiento'];
    if (fechaRaw is String && fechaRaw.isNotEmpty) {
      fechaNacimiento = DateTime.tryParse(fechaRaw);
    } else if (fechaRaw is DateTime) {
      fechaNacimiento = fechaRaw;
    }

    DateTime? fechaRegistro;
    final createdRaw = backendEstudiante['createdAt'];
    if (createdRaw is String && createdRaw.isNotEmpty) {
      fechaRegistro = DateTime.tryParse(createdRaw);
    } else if (createdRaw is DateTime) {
      fechaRegistro = createdRaw;
    }

    DateTime? fechaActualizacion;
    final updatedRaw = backendEstudiante['updatedAt'];
    if (updatedRaw is String && updatedRaw.isNotEmpty) {
      fechaActualizacion = DateTime.tryParse(updatedRaw);
    } else if (updatedRaw is DateTime) {
      fechaActualizacion = updatedRaw;
    }

    return {
      'id': backendEstudiante['rut'] ?? '',
      'rut': backendEstudiante['rut'] ?? '',
      'nombre': backendEstudiante['nombre'] ?? '',
      'fechaNacimiento': fechaNacimiento,
      'categoria': backendEstudiante['categoria'] ?? '',
      'ficha': backendEstudiante['ficha'],
      'curso': backendEstudiante['curso'] ?? '',
      'correoApoderadoGenerado':
          backendEstudiante['correoApoderadoGenerado'] ?? '',
      'telefono': backendEstudiante['telefono'] ?? '',
      'contactoEmergencia': backendEstudiante['contactoEmergencia'] ?? '',
      'telefonoEmergencia': backendEstudiante['telefonoEmergencia'] ?? '',
      'nombreResponsable': backendEstudiante['nombreResponsable'] ?? '',
      'nombreMadre': backendEstudiante['nombreMadre'] ?? '',
      'telefonoMadre': backendEstudiante['telefonoMadre'] ?? '',
      'emailMadre': backendEstudiante['emailMadre'] ?? '',
      'nombrePadre': backendEstudiante['nombrePadre'] ?? '',
      'telefonoPadre': backendEstudiante['telefonoPadre'] ?? '',
      'emailPadre': backendEstudiante['emailPadre'] ?? '',
      'telefonoResponsable': backendEstudiante['telefono'] ?? '',
      'hermanos': List<String>.from(
        backendEstudiante['hermanos'] as List<dynamic>? ?? const [],
      ),
      'enfermedad': backendEstudiante['enfermedad'] ?? '',
      'talla': backendEstudiante['talla'] ?? '',
      'dorsalNombre': backendEstudiante['dorsalNombre'] ?? '',
      'alumnoNuevo': backendEstudiante['alumnoNuevo'] ?? '',
      'asistencia': backendEstudiante['asistencia'] ?? '',
      'pagos': pagos,
      'equipamiento': equipamiento,
      'estado': backendEstudiante['estado'] ?? '',
      'observaciones': backendEstudiante['observaciones'] ?? '',
      'fechaRegistro': fechaRegistro ?? DateTime.now(),
      'fechaActualizacion': fechaActualizacion,
    };
  }

  bool _validateStudentData(Map<String, dynamic> data) {
    const requiredKeys = [
      'nombre',
      'fechanacimiento',
      'rut',
      'categoria',
      'curso',
    ];

    for (final key in requiredKeys) {
      final candidateKeys = <String>{key, _toTitleCase(key)};

      if (key == 'fechanacimiento') {
        candidateKeys.addAll({'fechaNacimiento', 'FechaNacimiento'});
      }

      dynamic value;
      for (final candidate in candidateKeys) {
        if (!data.containsKey(candidate)) {
          continue;
        }

        final candidateValue = data[candidate];
        if (candidateValue != null &&
            candidateValue.toString().trim().isNotEmpty) {
          value = candidateValue;
          break;
        }
      }

      if (value == null || value.toString().trim().isEmpty) {
        if (kDebugMode) {
          print('❌ Campo obligatorio faltante: $key');
        }
        return false;
      }
    }
    return true;
  }

  String _toTitleCase(String value) {
    if (value.isEmpty) return value;
    return value.substring(0, 1).toUpperCase() + value.substring(1);
  }

  String addStudent({
    required String rut,
    required String nombre,
    required String curso,
    String? categoria,
    bool ficha = false,
  }) {
    final exists = _estudiantes.any(
      (e) => e['rut']?.toString().toLowerCase() == rut.toLowerCase(),
    );
    if (exists) {
      throw Exception('El RUT ya está registrado en el sistema');
    }

    final newStudent = {
      'id': rut,
      'rut': rut,
      'nombre': nombre,
      'curso': curso,
      'categoria': categoria ?? '',
      'ficha': ficha,
      'fechaRegistro': DateTime.now(),
      'estado': 'registrado',
      'pagos': <String, dynamic>{},
      'equipamiento': <String, dynamic>{},
    };

    _estudiantes.add(newStudent);
    notifyListeners();
    return rut;
  }

  List<Map<String, dynamic>> searchStudents({
    String? query,
    String? curso,
    String? ficha,
  }) {
    var filtered = List<Map<String, dynamic>>.from(_estudiantes);

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filtered =
          filtered.where((student) {
            final nombre = student['nombre']?.toString().toLowerCase() ?? '';
            final rut = student['rut']?.toString().toLowerCase() ?? '';
            final categoria =
                student['categoria']?.toString().toLowerCase() ?? '';
            final cursoVal = student['curso']?.toString().toLowerCase() ?? '';
            final madre =
                student['nombreMadre']?.toString().toLowerCase() ?? '';
            final padre =
                student['nombrePadre']?.toString().toLowerCase() ?? '';
            final responsable =
                student['nombreResponsable']?.toString().toLowerCase() ?? '';
            final correoApoderado =
                student['correoApoderadoGenerado']?.toString().toLowerCase() ??
                '';
            return nombre.contains(lowerQuery) ||
                rut.contains(lowerQuery) ||
                categoria.contains(lowerQuery) ||
                cursoVal.contains(lowerQuery) ||
                madre.contains(lowerQuery) ||
                padre.contains(lowerQuery) ||
                responsable.contains(lowerQuery) ||
                correoApoderado.contains(lowerQuery);
          }).toList();
    }

    if (curso != null && curso != 'Todos') {
      filtered =
          filtered
              .where(
                (student) =>
                    student['curso']?.toString().toLowerCase() ==
                    curso.toLowerCase(),
              )
              .toList();
    }

    if (ficha != null && ficha != 'Todos') {
      filtered =
          filtered.where((student) {
            final hasFicha =
                student['ficha'] == true ||
                (student['ficha'] is String &&
                    (student['ficha'] as String).toLowerCase() == 'si');
            if (ficha == 'Con ficha') return hasFicha;
            if (ficha == 'Sin ficha') return !hasFicha;
            return true;
          }).toList();
    }

    filtered.sort((a, b) {
      final fechaA = a['fechaRegistro'] as DateTime? ?? DateTime(2000, 1, 1);
      final fechaB = b['fechaRegistro'] as DateTime? ?? DateTime(2000, 1, 1);
      return fechaB.compareTo(fechaA);
    });

    return filtered;
  }

  Map<String, dynamic>? getStudentById(String id) {
    try {
      return _estudiantes.firstWhere((e) => e['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? getStudentByRut(String rut) {
    try {
      return _estudiantes.firstWhere(
        (e) => e['rut']?.toString().toLowerCase() == rut.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  bool updateStudent(String id, Map<String, dynamic> updatedData) {
    final index = _estudiantes.indexWhere((e) => e['id'] == id);
    if (index == -1) return false;

    updatedData['id'] = _estudiantes[index]['id'];
    updatedData['fechaRegistro'] =
        _estudiantes[index]['fechaRegistro'] ?? DateTime.now();
    updatedData['fechaActualizacion'] = DateTime.now();

    _estudiantes[index] = updatedData;
    notifyListeners();
    return true;
  }

  bool deleteStudent(String id) {
    final index = _estudiantes.indexWhere((e) => e['id'] == id);
    if (index == -1) return false;
    _estudiantes.removeAt(index);
    notifyListeners();
    return true;
  }

  List<String> getUniqueCourses() {
    final courses =
        _estudiantes
            .map((e) => e['curso'] as String? ?? 'Sin curso')
            .toSet()
            .toList()
          ..sort();
    return ['Todos', ...courses];
  }

  List<String> getUniqueFichaStates() {
    return const ['Todos', 'Con ficha', 'Sin ficha'];
  }

  List<Map<String, dynamic>> exportStudentsData({
    String? curso,
    String? ficha,
  }) {
    return searchStudents(curso: curso, ficha: ficha);
  }

  void clearAllData() {
    _estudiantes.clear();
    notifyListeners();
  }
}
