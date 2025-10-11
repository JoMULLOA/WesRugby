import 'package:flutter/foundation.dart';
import 'usuario_service.dart';

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
    int activos = _estudiantes.where((e) => 
      e['validez']?.toLowerCase() == 'activo' || 
      e['validez']?.toLowerCase() == 'vigente'
    ).length;
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

  // Importar estudiantes desde Excel (datos procesados)
  Future<int> importStudentsFromExcel(List<Map<String, dynamic>> excelData) async {
    try {
      int imported = 0;
      Set<String> responsablesCreados = <String>{};
      DateTime now = DateTime.now();
      
      for (var row in excelData) {
        // Validar datos requeridos
        if (_validateStudentData(row)) {
          // Verificar si el RUT ya existe
          bool exists = _estudiantes.any((e) => 
            e['rut']?.toString().toLowerCase() == row['rut']?.toString().toLowerCase()
          );
          
          if (!exists) {
            // Agregar campos adicionales
            Map<String, dynamic> newStudent = Map.from(row);
            newStudent['fechaRegistro'] = now;
            newStudent['id'] = 'EST${(_estudiantes.length + 1).toString().padLeft(4, '0')}';
            newStudent['estado'] = 'Registrado';
            
            _estudiantes.add(newStudent);
            imported++;
            
            // Crear apoderado en la base de datos si no existe
            String rutResponsable = row['rutResponsable']?.toString() ?? '';
            String nombreResponsable = row['responsable']?.toString() ?? '';
            
            if (rutResponsable.isNotEmpty && nombreResponsable.isNotEmpty && !responsablesCreados.contains(rutResponsable)) {
              print('🔄 Creando cuenta para responsable: $nombreResponsable ($rutResponsable)');
              
              await _createApoderadoAccount(
                rut: rutResponsable,
                nombre: nombreResponsable,
                estudiante: row['nombre']?.toString() ?? '',
              );
              responsablesCreados.add(rutResponsable);
            } else if (rutResponsable.isNotEmpty && responsablesCreados.contains(rutResponsable)) {
              print('ℹ️ Responsable ya procesado: $rutResponsable');
            } else {
              print('⚠️ Datos incompletos del responsable para estudiante: ${row['nombre']}');
            }
            
            print('📝 Estudiante registrado: ${newStudent['nombre']} (${newStudent['rut']})');
          } else {
            print('⚠️ RUT duplicado ignorado: ${row['rut']}');
          }
        } else {
          print('❌ Datos inválidos para: ${row['nombre'] ?? 'Nombre faltante'}');
        }
      }
      
      notifyListeners();
      print('✅ Importación completada: $imported estudiantes registrados');
      print('👥 Apoderados creados en BD: ${responsablesCreados.length}');
      
      return imported;
    } catch (e) {
      print('Error en importación: $e');
      return 0;
    }
  }
  
  // Crear cuenta de apoderado automáticamente
  Future<void> _createApoderadoAccount({
    required String rut,
    required String nombre,
    required String estudiante,
  }) async {
    try {
      print('📞 Iniciando creación de cuenta para: $nombre ($rut)');
      
      final usuarioService = UsuarioService();
      
      // Primero verificar si el usuario ya existe en la base de datos
      await usuarioService.loadUsuarios(); // Cargar usuarios desde BD
      Map<String, dynamic>? existingUser = usuarioService.getUsuarioByRut(rut);
      
      if (existingUser != null) {
        print('ℹ️ Usuario ya existe en BD: $nombre ($rut)');
        return;
      }
      
      // Generar correo único basado en el nombre con formato wessex.cl
      String email = usuarioService.generateUniqueEmail(nombre, rut);
      print('📧 Email generado: $email');
      
      // Crear cuenta de apoderado usando el servicio que se conecta a la API
      String? userId = await usuarioService.addUsuario(
        rut: rut,
        nombre: nombre,
        email: email,
        rol: 'apoderado',
      );
      
      if (userId != null) {
        print('✅ Apoderado creado exitosamente en BD: $nombre ($email)');
      } else {
        print('❌ Error: No se pudo crear el apoderado en BD: $nombre');
      }
      
    } catch (e) {
      print('💥 Error crítico creando apoderado $nombre ($rut): $e');
      // No lanzar la excepción para no interrumpir la importación completa
    }
  }

  // Validar datos de un estudiante
  bool _validateStudentData(Map<String, dynamic> data) {
    // Verificar campos obligatorios
    List<String> requiredFields = ['rut', 'nombre', 'padre', 'madre', 'curso', 'validez', 'responsable', 'rutResponsable'];
    
    for (String field in requiredFields) {
      if (data[field] == null || data[field].toString().trim().isEmpty) {
        return false;
      }
    }
    
    // Validar formato de RUT del estudiante (básico)
    String rut = data['rut'].toString();
    if (!rut.contains('-') || rut.length < 9) {
      return false;
    }
    
    // Validar formato de RUT del responsable (básico)
    String rutResponsable = data['rutResponsable'].toString();
    if (!rutResponsable.contains('-') || rutResponsable.length < 9) {
      return false;
    }
    
    // Validar validez
    String validez = data['validez'].toString().toLowerCase();
    List<String> validValidez = ['activo', 'inactivo', 'vigente', 'no vigente', 'válido', 'vencido', 'valido'];
    if (!validValidez.contains(validez)) {
      return false;
    }
    
    return true;
  }

  // Agregar estudiante individual
  String addStudent({
    required String rut,
    required String nombre,
    required String padre,
    required String madre,
    required String curso,
    required String validez,
    required String responsable,
    required String rutResponsable,
  }) {
    try {
      // Verificar si el RUT ya existe
      bool exists = _estudiantes.any((e) => 
        e['rut']?.toString().toLowerCase() == rut.toLowerCase()
      );
      
      if (exists) {
        throw Exception('El RUT ya está registrado en el sistema');
      }
      
      String newId = 'EST${(_estudiantes.length + 1).toString().padLeft(4, '0')}';
      DateTime now = DateTime.now();
      
      Map<String, dynamic> newStudent = {
        'id': newId,
        'rut': rut,
        'nombre': nombre,
        'padre': padre,
        'madre': madre,
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
      filtered = filtered.where((student) {
        return student['nombre']?.toLowerCase().contains(query.toLowerCase()) == true ||
               student['rut']?.toLowerCase().contains(query.toLowerCase()) == true ||
               student['padre']?.toLowerCase().contains(query.toLowerCase()) == true ||
               student['madre']?.toLowerCase().contains(query.toLowerCase()) == true;
      }).toList();
    }
    
    if (curso != null && curso != 'Todos') {
      filtered = filtered.where((student) => student['curso'] == curso).toList();
    }
    
    if (validez != null && validez != 'Todos') {
      filtered = filtered.where((student) => student['validez'] == validez).toList();
    }
    
    // Ordenar por fecha de registro (más recientes primero)
    filtered.sort((a, b) => 
      (b['fechaRegistro'] as DateTime).compareTo(a['fechaRegistro'] as DateTime)
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
      return _estudiantes.firstWhere((e) => 
        e['rut']?.toString().toLowerCase() == rut.toLowerCase()
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
        
        print('✏️ Estudiante actualizado: ${updatedData['nombre']} (${updatedData['rut']})');
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
        
        print('🗑️ Estudiante eliminado: ${deleted['nombre']} (${deleted['rut']})');
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
    Set<String> courses = _estudiantes
        .map((e) => e['curso'] as String? ?? 'Sin curso')
        .toSet();
    return ['Todos', ...courses.toList()..sort()];
  }

  // Obtener estados de validez únicos
  List<String> getUniqueValidezStates() {
    Set<String> states = _estudiantes
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