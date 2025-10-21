import 'package:flutter/foundation.dart';
import 'package:wesrugby/data/services/api_service.dart';

class EstudianteService extends ChangeNotifier {
  static final EstudianteService _instance = EstudianteService._internal();
  factory EstudianteService() => _instance;
  EstudianteService._internal();

  // Lista global de estudiantes para simular base de datos
  static List<Map<String, dynamic>> _estudiantes = [];

  // Obtener todos los estudiantes
  List<Map<String, dynamic>> getAllStudents() {
    return List.from(_estudiantes);
  }

  // Obtener estadísticas de estudiantes
  Map<String, dynamic> getStudentStatistics() {
    int total = _estudiantes.length;
    int activos =
        _estudiantes
            .where(
              (e) =>
                  e['validez']?.toLowerCase() == 'activo' ||
                  e['validez']?.toLowerCase() == 'vigente',
            )
            .length;
    int inactivos = total - activos;

    // Estadísticas por curso
    Map<String, int> porCurso = {};
    for (var estudiante in _estudiantes) {
      String curso = estudiante['curso'] ?? 'Sin curso';
      porCurso[curso] = (porCurso[curso] ?? 0) + 1;
    }

    return {
      'total': total,
      'activos': activos,
      'inactivos': inactivos,
      'porCurso': porCurso,
    };
  }

  // Obtener todos los estudiantes (para entrenadores/directiva)
  Future<List<Map<String, dynamic>>> getAllStudentsFromAPI() async {
    try {
      final response = await ApiService.getAllEstudiantes();

      if (kDebugMode) {
        print('🔍 Response status code: ${response.statusCode}');
        print('🔍 Response data type: ${response.data.runtimeType}');
      }

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic> &&
            response.data['success'] == true) {
          final estudiantes = List<Map<String, dynamic>>.from(
            response.data['data'],
          );
          if (kDebugMode) {
            print('✅ Todos los estudiantes obtenidos: ${estudiantes.length}');
          }
          return estudiantes;
        } else if (response.data is List) {
          final estudiantes = List<Map<String, dynamic>>.from(response.data);
          if (kDebugMode) {
            print(
              '✅ Estudiantes obtenidos directamente: ${estudiantes.length}',
            );
          }
          return estudiantes;
        }
      }
      throw Exception(response.message ?? 'Error al obtener estudiantes');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener todos los estudiantes: $e');
      }
      throw Exception('Error al obtener estudiantes');
    }
  }

  // Obtener estudiantes asignados a un apoderado
  Future<List<Map<String, dynamic>>> getMisEstudiantes() async {
    try {
      // Agregar timestamp para evitar cache
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await ApiService.get(
        '/estudiantes/mis-estudiantes?t=$timestamp',
      );

      if (kDebugMode) {
        print('🔍 Response status code: ${response.statusCode}');
        print('🔍 Response data: ${response.data}');
        print('🔍 Response data type: ${response.data.runtimeType}');
      }

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic> &&
            response.data['success'] == true) {
          final estudiantes = List<Map<String, dynamic>>.from(
            response.data['data'],
          );
          if (kDebugMode) {
            print(
              '✅ Estudiantes parsed from success response: ${estudiantes.length}',
            );
            print('📊 Estudiantes data: $estudiantes');
          }
          return estudiantes;
        } else if (response.data is List) {
          final estudiantes = List<Map<String, dynamic>>.from(response.data);
          if (kDebugMode) {
            print(
              '✅ Estudiantes parsed from direct list: ${estudiantes.length}',
            );
            print('📊 Estudiantes data: $estudiantes');
          }
          return estudiantes;
        }
      }
      throw Exception(response.message ?? 'Error al obtener estudiantes');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener mis estudiantes: $e');
      }
      throw Exception('Error al obtener estudiantes asignados');
    }
  }

  // Importar estudiantes desde Excel (datos procesados)
  Future<Map<String, dynamic>> importStudentsFromExcel(
    List<Map<String, dynamic>> excelData,
  ) async {
    try {
      if (excelData.isEmpty) {
        throw Exception('No hay datos para importar');
      }

      // Preparar datos para enviar al backend
      List<Map<String, dynamic>> estudiantesParaImportar = [];

      for (var row in excelData) {
        if (_validateStudentData(row)) {
          // Extraer datos del estudiante (dos campos separados: nombreCompleto y run)
          String nombreCompleto = _cleanString(
            row['nombreCompleto'] ?? row['Nombre Completo'] ?? '',
          );
          String run = _cleanString(row['run'] ?? row['RUN'] ?? '');
          String curso = _cleanString(row['curso'] ?? row['Curso'] ?? '');
          String nombreMadre = _cleanString(
            row['nombreMadre'] ?? row['Nombre Madre'] ?? '',
          );
          String telefonoMadre = _cleanString(
            row['telefonoMadre'] ?? row['Telefono Madre'] ?? '',
          );
          String nombrePadre = _cleanString(
            row['nombrePadre'] ?? row['Nombre Padre'] ?? '',
          );
          String telefonoPadre = _cleanString(
            row['telefonoPadre'] ?? row['Telefono Padre'] ?? '',
          );
          String validez = _cleanString(row['validez'] ?? row['Validez'] ?? '');
          String responsable = _cleanString(
            row['responsable'] ?? row['Responsable'] ?? '',
          );
          String runResponsable = _cleanString(
            row['runResponsable'] ?? row['RUN Responsable'] ?? '',
          );

          // Preparar datos del estudiante para el backend (campos separados)
          Map<String, dynamic> estudianteData = {
            'nombreCompleto': nombreCompleto,
            'run': run,
            'curso': curso,
            'nombreMadre': nombreMadre.isNotEmpty ? nombreMadre : null,
            'telefonoMadre': telefonoMadre.isNotEmpty ? telefonoMadre : null,
            'nombrePadre': nombrePadre.isNotEmpty ? nombrePadre : null,
            'telefonoPadre': telefonoPadre.isNotEmpty ? telefonoPadre : null,
            'validez': validez,
            'responsable': responsable,
            'runResponsable': runResponsable,
          };

          estudiantesParaImportar.add(estudianteData);
        }
      }

      if (estudiantesParaImportar.isEmpty) {
        throw Exception('No se encontraron estudiantes válidos para importar');
      }

      print(
        '� Enviando ${estudiantesParaImportar.length} estudiantes al backend...',
      );

      // Enviar al backend usando la API de importación masiva
      final response = await ApiService.importEstudiantesFromExcel(
        estudiantesParaImportar,
      );

      if (response.statusCode == 201 && response.data != null) {
        final results = response.data['data'];

        // Actualizar la lista local con los estudiantes creados
        if (results['estudiantesCreados'] != null) {
          for (var estudiante in results['estudiantesCreados']) {
            _estudiantes.add(_adaptEstudianteFromBackend(estudiante));
          }
        }

        notifyListeners();

        print('✅ Importación completada:');
        print(
          '   - Estudiantes creados: ${results['estudiantesCreados']?.length ?? 0}',
        );
        print(
          '   - Apoderados creados: ${results['apoderadosCreados']?.length ?? 0}',
        );
        print('   - Errores: ${results['errores']?.length ?? 0}');

        return {
          'success': true,
          'estudiantesCreados': results['estudiantesCreados']?.length ?? 0,
          'apoderadosCreados': results['apoderadosCreados']?.length ?? 0,
          'errores': results['errores'] ?? [],
          'message':
              'Importación completada exitosamente. ${results['estudiantesCreados']?.length ?? 0} estudiantes y ${results['apoderadosCreados']?.length ?? 0} apoderados creados en la base de datos.',
        };
      } else {
        throw Exception('Error del servidor: ${response.message}');
      }
    } catch (e) {
      print('❌ Error importando estudiantes: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error durante la importación: $e',
      };
    }
  }

  // Adaptar estudiante del backend al formato del frontend
  Map<String, dynamic> _adaptEstudianteFromBackend(
    Map<String, dynamic> backendEstudiante,
  ) {
    return {
      'id': 'EST${_estudiantes.length + 1}',
      'rut': backendEstudiante['rut'] ?? '',
      'nombre': backendEstudiante['nombre'] ?? '',
      'curso': backendEstudiante['curso'] ?? '',
      'telefono': backendEstudiante['telefono'] ?? '',
      'direccion': backendEstudiante['direccion'] ?? '',
      'contactoEmergencia': backendEstudiante['contactoEmergencia'] ?? '',
      'telefonoEmergencia': backendEstudiante['telefonoEmergencia'] ?? '',
      'rutResponsable': backendEstudiante['rutResponsable'] ?? '',
      'responsable': backendEstudiante['nombreResponsable'] ?? '',
      'nombreMadre': _extractFromObservaciones(
        backendEstudiante['observaciones'],
        'Madre',
      ),
      'nombrePadre': _extractFromObservaciones(
        backendEstudiante['observaciones'],
        'Padre',
      ),
      'validez':
          backendEstudiante['estado'] == 'activo' ? 'Activo' : 'Inactivo',
      'estado': 'Registrado',
      'fechaRegistro': DateTime.now(),
    };
  }

  // Extraer información de las observaciones
  String _extractFromObservaciones(String? observaciones, String tipo) {
    if (observaciones == null) return '';

    final regex = RegExp('$tipo: ([^,]+)', caseSensitive: false);
    final match = regex.firstMatch(observaciones);

    if (match != null) {
      String value = match.group(1)?.trim() ?? '';
      return value != 'No especificada' && value != 'No especificado'
          ? value
          : '';
    }

    return '';
  }

  // Limpiar cadenas de texto
  String _cleanString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  // Validar datos de un estudiante (campos separados: nombreCompleto y run)
  bool _validateStudentData(Map<String, dynamic> data) {
    // Verificar campos obligatorios (dos campos separados)
    List<String> requiredFields = [
      'nombreCompleto',
      'run',
      'curso',
      'validez',
      'responsable',
      'runResponsable',
    ];

    // También verificar variantes de nombres de columnas
    Map<String, List<String>> fieldVariants = {
      'nombreCompleto': ['nombreCompleto', 'Nombre Completo', 'nombrecompeto'],
      'run': ['run', 'RUN', 'rut'],
      'curso': ['curso', 'Curso'],
      'validez': ['validez', 'Validez'],
      'responsable': ['responsable', 'Responsable'],
      'runResponsable': ['runResponsable', 'RUN Responsable', 'rutResponsable'],
    };

    for (String field in requiredFields) {
      bool fieldFound = false;
      List<String> variants = fieldVariants[field] ?? [field];

      for (String variant in variants) {
        if (data[variant] != null &&
            data[variant].toString().trim().isNotEmpty) {
          fieldFound = true;
          break;
        }
      }

      if (!fieldFound) {
        if (kDebugMode) {
          print('❌ Campo obligatorio faltante: $field (variantes: $variants)');
        }
        return false;
      }
    }

    // Validar formato de RUN del responsable (básico)
    String? runResponsable;
    for (String variant in fieldVariants['runResponsable']!) {
      if (data[variant] != null && data[variant].toString().trim().isNotEmpty) {
        runResponsable = data[variant].toString();
        break;
      }
    }

    if (runResponsable != null &&
        (!runResponsable.contains('-') || runResponsable.length < 9)) {
      if (kDebugMode) {
        print('❌ Formato de RUN inválido: $runResponsable');
      }
      return false;
    }

    // Validar validez
    String? validez;
    for (String variant in fieldVariants['validez']!) {
      if (data[variant] != null && data[variant].toString().trim().isNotEmpty) {
        validez = data[variant].toString().toLowerCase();
        break;
      }
    }

    if (validez != null) {
      List<String> validValidez = [
        'activo',
        'inactivo',
        'vigente',
        'no vigente',
        'válido',
        'vencido',
        'valido',
      ];
      if (!validValidez.contains(validez)) {
        if (kDebugMode) {
          print('❌ Validez inválida: $validez');
        }
        return false;
      }
    }

    return true;
  }

  // Agregar estudiante individual (mantiene compatibilidad con formato anterior)
  String addStudent({
    required String rut,
    required String nombre,
    String? padre,
    String? madre,
    required String curso,
    required String validez,
    required String responsable,
    required String rutResponsable,
    String? telefonoMadre,
    String? telefonoPadre,
  }) {
    try {
      // Verificar si el RUT ya existe
      bool exists = _estudiantes.any(
        (e) => e['rut']?.toString().toLowerCase() == rut.toLowerCase(),
      );

      if (exists) {
        throw Exception('El RUT ya está registrado en el sistema');
      }

      String newId =
          'EST${(_estudiantes.length + 1).toString().padLeft(4, '0')}';
      DateTime now = DateTime.now();

      Map<String, dynamic> newStudent = {
        'id': newId,
        'rut': rut,
        'nombre': nombre,
        'padre': padre ?? '',
        'madre': madre ?? '',
        'nombrePadre': padre ?? '', // Nuevo campo
        'nombreMadre': madre ?? '', // Nuevo campo
        'telefonoPadre': telefonoPadre ?? '', // Nuevo campo
        'telefonoMadre': telefonoMadre ?? '', // Nuevo campo
        'curso': curso,
        'validez': validez,
        'responsable': responsable,
        'rutResponsable': rutResponsable,
        'fechaRegistro': now,
        'estado': 'Registrado',
      };

      _estudiantes.add(newStudent);
      notifyListeners();

      print('📝 Estudiante registrado individualmente: $nombre ($rut)');
      return newId;
    } catch (e) {
      print('Error al registrar estudiante: $e');
      rethrow;
    }
  }

  // Buscar estudiantes
  List<Map<String, dynamic>> searchStudents({
    String? query,
    String? curso,
    String? validez,
  }) {
    List<Map<String, dynamic>> filtered = List.from(_estudiantes);

    if (query != null && query.isNotEmpty) {
      filtered =
          filtered.where((student) {
            return student['nombre']?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ==
                    true ||
                student['rut']?.toLowerCase().contains(query.toLowerCase()) ==
                    true ||
                student['padre']?.toLowerCase().contains(query.toLowerCase()) ==
                    true ||
                student['madre']?.toLowerCase().contains(query.toLowerCase()) ==
                    true;
          }).toList();
    }

    if (curso != null && curso != 'Todos') {
      filtered =
          filtered.where((student) => student['curso'] == curso).toList();
    }

    if (validez != null && validez != 'Todos') {
      filtered =
          filtered.where((student) => student['validez'] == validez).toList();
    }

    // Ordenar por fecha de registro (más recientes primero)
    filtered.sort(
      (a, b) => (b['fechaRegistro'] as DateTime).compareTo(
        a['fechaRegistro'] as DateTime,
      ),
    );

    return filtered;
  }

  // Obtener estudiante por ID
  Map<String, dynamic>? getStudentById(String id) {
    try {
      return _estudiantes.firstWhere((e) => e['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener estudiante por RUT
  Map<String, dynamic>? getStudentByRut(String rut) {
    try {
      return _estudiantes.firstWhere(
        (e) => e['rut']?.toString().toLowerCase() == rut.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Actualizar estudiante
  bool updateStudent(String id, Map<String, dynamic> updatedData) {
    try {
      int index = _estudiantes.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        // Preservar campos del sistema
        updatedData['id'] = _estudiantes[index]['id'];
        updatedData['fechaRegistro'] = _estudiantes[index]['fechaRegistro'];
        updatedData['fechaActualizacion'] = DateTime.now();

        _estudiantes[index] = updatedData;
        notifyListeners();

        print(
          '✏️ Estudiante actualizado: ${updatedData['nombre']} (${updatedData['rut']})',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error al actualizar estudiante: $e');
      return false;
    }
  }

  // Eliminar estudiante
  bool deleteStudent(String id) {
    try {
      int index = _estudiantes.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        Map<String, dynamic> deleted = _estudiantes.removeAt(index);
        notifyListeners();

        print(
          '🗑️ Estudiante eliminado: ${deleted['nombre']} (${deleted['rut']})',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error al eliminar estudiante: $e');
      return false;
    }
  }

  // Obtener cursos únicos
  List<String> getUniqueCourses() {
    Set<String> courses =
        _estudiantes.map((e) => e['curso'] as String? ?? 'Sin curso').toSet();
    return ['Todos', ...courses.toList()..sort()];
  }

  // Obtener estados de validez únicos
  List<String> getUniqueValidezStates() {
    Set<String> states =
        _estudiantes
            .map((e) => e['validez'] as String? ?? 'Sin estado')
            .toSet();
    return ['Todos', ...states.toList()..sort()];
  }

  // Exportar datos (simulado)
  List<Map<String, dynamic>> exportStudentsData({
    String? curso,
    String? validez,
  }) {
    return searchStudents(curso: curso, validez: validez);
  }

  // Limpiar todos los datos (para testing)
  void clearAllData() {
    _estudiantes.clear();
    notifyListeners();
    print('🧹 Todos los datos de estudiantes han sido limpiados');
  }
}
