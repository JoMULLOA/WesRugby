import 'package:flutter/foundation.dart';
import 'package:wesrugby/data/services/api_service.dart';

class UsuarioService extends ChangeNotifier {
  static final UsuarioService _instance = UsuarioService._internal();
  factory UsuarioService() => _instance;
  UsuarioService._internal();

  // Lista local de usuarios para cache
  final List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get usuarios => List.unmodifiable(_usuarios);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar todos los usuarios desde la base de datos
  Future<void> loadUsuarios() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.getAllUsers();

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> usersData = response.data['data'] ?? response.data;

        _usuarios.clear();
        for (var userData in usersData) {
          if (userData is Map<String, dynamic>) {
            // Adaptar los datos del backend al formato esperado por el frontend
            _usuarios.add(_adaptUserFromBackend(userData));
          }
        }

        print('✅ Usuarios cargados desde BD: ${_usuarios.length}');
      } else {
        _setError('Error al cargar usuarios: ${response.message}');
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      print('❌ Error cargando usuarios: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Adaptar datos del backend al formato del frontend
  Map<String, dynamic> _adaptUserFromBackend(Map<String, dynamic> backendUser) {
    return {
      'id': backendUser['rut'], // En el backend el ID es el RUT
      'rut': backendUser['rut'] ?? '',
      'nombre': backendUser['nombreCompleto'] ?? '',
      'email': backendUser['email'] ?? '',
      'rol': _adaptRole(backendUser['rol'] ?? ''),
      'telefono': backendUser['telefono'] ?? '',
      'direccion': backendUser['direccion'] ?? '',
      'genero': backendUser['genero'] ?? '',
      'fechaNacimiento': backendUser['fechaNacimiento'] ?? '',
      'estado': 'Activo', // Por defecto, los usuarios en BD están activos
      'fechaCreacion': DateTime.now(), // El backend no tiene este campo
      'ultimoAcceso': null,
      'intentosLogin': 0,
      'resetToken': null,
    };
  }

  // Adaptar roles del backend al frontend
  String _adaptRole(String backendRole) {
    switch (backendRole.toLowerCase()) {
      case 'directiva':
        return 'directiva';
      case 'tesorera':
        return 'tesoreria';
      case 'apoderado':
        return 'apoderado';
      case 'entrenador':
        return 'entrenador';
      default:
        return backendRole;
    }
  }

  // Crear nuevo usuario en la base de datos
  Future<String?> addUsuario({
    required String rut,
    required String nombre,
    required String email,
    required String rol,
    String? password,
    String? telefono,
    String? genero,
    String? fechaNacimiento,
    String? carrera,
    int? altura,
    int? peso,
    String? descripcion,
  }) async {
    try {
      print('🚀 Iniciando creación de usuario en BD...');
      print('   RUT: $rut');
      print('   Nombre: $nombre');
      print('   Email: $email');
      print('   Rol: $rol');

      _setLoading(true);
      _setError(null);

      // Preparar datos para el backend
      final userData = {
        'rut': rut,
        'nombreCompleto': nombre,
        'email': email,
        'password': password ?? 'wessex123',
        'rol': _adaptRoleToBackend(rol),
      };

      print('📤 Enviando datos al backend: $userData');

      final response = await ApiService.createUser(userData);

      print('📥 Respuesta del backend: Status ${response.statusCode}');
      print('📥 Datos de respuesta: ${response.data}');

      if (response.statusCode == 201 && response.data != null) {
        // Recargar la lista de usuarios
        await loadUsuarios();
        print('✅ Usuario creado exitosamente en BD: $nombre ($email)');
        return rut; // En el backend, el ID es el RUT
      } else {
        String errorMsg =
            'Error al crear usuario: ${response.message ?? 'Error desconocido'}';
        print('❌ $errorMsg');
        _setError(errorMsg);
        return null;
      }
    } catch (e) {
      String errorMsg = 'Error de conexión al crear usuario: $e';
      print('💥 $errorMsg');
      _setError(errorMsg);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Adaptar roles del frontend al backend
  String _adaptRoleToBackend(String frontendRole) {
    switch (frontendRole.toLowerCase()) {
      case 'directiva':
        return 'directiva';
      case 'tesoreria':
        return 'tesorera';
      case 'apoderado':
        return 'apoderado';
      case 'entrenador':
        return 'entrenador';
      default:
        return frontendRole;
    }
  }

  // Actualizar usuario en la base de datos
  Future<bool> updateUsuario(String rut, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _setError(null);

      // Adaptar datos al formato del backend
      final backendData = <String, dynamic>{};

      if (data.containsKey('nombre')) {
        backendData['nombreCompleto'] = data['nombre'];
      }
      if (data.containsKey('email')) {
        backendData['email'] = data['email'];
      }
      if (data.containsKey('rol')) {
        backendData['rol'] = _adaptRoleToBackend(data['rol']);
      }
      if (data.containsKey('telefono')) {
        backendData['telefono'] = data['telefono'];
      }
      if (data.containsKey('genero')) {
        backendData['genero'] = data['genero'];
      }
      if (data.containsKey('fechaNacimiento')) {
        backendData['fechaNacimiento'] = data['fechaNacimiento'];
      }
      if (data.containsKey('carrera')) {
        backendData['carrera'] = data['carrera'];
      }
      if (data.containsKey('altura')) {
        backendData['altura'] = data['altura'];
      }
      if (data.containsKey('peso')) {
        backendData['Peso'] =
            data['peso']; // Nota: En el backend es "Peso" con mayúscula
      }
      if (data.containsKey('descripcion')) {
        backendData['descripcion'] = data['descripcion'];
      }

      backendData['rut'] = rut; // Incluir RUT para identificar al usuario

      final response = await ApiService.updateUser(backendData);

      if (response.statusCode == 200) {
        // Recargar la lista de usuarios
        await loadUsuarios();
        print('✅ Usuario actualizado en BD: $rut');
        return true;
      } else {
        _setError('Error al actualizar usuario: ${response.message}');
        return false;
      }
    } catch (e) {
      _setError('Error al actualizar usuario: $e');
      print('❌ Error actualizando usuario: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar usuario de la base de datos
  Future<bool> deleteUsuario(String rut) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await ApiService.deleteUserByRut(rut);

      if (response.statusCode == 200) {
        // Recargar la lista de usuarios
        await loadUsuarios();
        print('✅ Usuario eliminado de BD: $rut');
        return true;
      } else {
        _setError('Error al eliminar usuario: ${response.message}');
        return false;
      }
    } catch (e) {
      _setError('Error al eliminar usuario: $e');
      print('❌ Error eliminando usuario: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cambiar rol de usuario
  Future<bool> changeUserRole(String rut, String newRole) async {
    try {
      _setLoading(true);
      _setError(null);

      final backendRole = _adaptRoleToBackend(newRole);
      final response = await ApiService.changeUserRole(rut, backendRole);

      if (response.statusCode == 200) {
        // Recargar la lista de usuarios
        await loadUsuarios();
        print('✅ Rol de usuario cambiado en BD: $rut -> $newRole');
        return true;
      } else {
        _setError('Error al cambiar rol: ${response.message}');
        return false;
      }
    } catch (e) {
      _setError('Error al cambiar rol: $e');
      print('❌ Error cambiando rol: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos de utilidad para búsqueda y filtrado (funcionan con cache local)
  List<Map<String, dynamic>> searchUsuarios(String query) {
    if (query.isEmpty) return _usuarios;

    String lowerQuery = query.toLowerCase();
    return _usuarios.where((usuario) {
      return usuario['nombre']?.toString().toLowerCase().contains(lowerQuery) ==
              true ||
          usuario['email']?.toString().toLowerCase().contains(lowerQuery) ==
              true ||
          usuario['rut']?.toString().toLowerCase().contains(lowerQuery) ==
              true ||
          usuario['rol']?.toString().toLowerCase().contains(lowerQuery) == true;
    }).toList();
  }

  List<Map<String, dynamic>> filterByRol(String rol) {
    if (rol.isEmpty || rol == 'Todos') return _usuarios;
    return _usuarios
        .where((u) => u['rol']?.toString().toLowerCase() == rol.toLowerCase())
        .toList();
  }

  List<Map<String, dynamic>> filterByEstado(String estado) {
    if (estado.isEmpty || estado == 'Todos') return _usuarios;
    return _usuarios
        .where(
          (u) => u['estado']?.toString().toLowerCase() == estado.toLowerCase(),
        )
        .toList();
  }

  // Obtener usuario por RUT
  Map<String, dynamic>? getUsuarioByRut(String rut) {
    try {
      return _usuarios.firstWhere(
        (u) => u['rut']?.toString().toLowerCase() == rut.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Obtener usuario por email
  Map<String, dynamic>? getUsuarioByEmail(String email) {
    try {
      return _usuarios.firstWhere(
        (u) => u['email']?.toString().toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Generar correo único (usado por EstudianteService)
  String generateUniqueEmail(String nombre, String rut) {
    // Limpiar nombre (solo letras y espacios)
    String cleanName =
        nombre.toLowerCase().replaceAll(RegExp(r'[^a-záéíóúñ\s]'), '').trim();

    // Tomar primer nombre y primer apellido
    List<String> words =
        cleanName.split(' ').where((w) => w.isNotEmpty).toList();
    String firstName = words.isNotEmpty ? words[0] : 'usuario';
    String lastName = words.length > 1 ? words[1] : '';

    // Generar email base con formato nombre.apellido0@wessex.cl
    String baseEmail =
        lastName.isNotEmpty ? '${firstName}.${lastName}0' : '${firstName}0';

    String email = '${baseEmail}@wessex.cl';

    // Verificar si el email ya existe y agregar número si es necesario
    int counter = 1;
    while (_usuarios.any((u) => u['email'] == email)) {
      String basePart =
          lastName.isNotEmpty
              ? '${firstName}.${lastName}${counter}'
              : '${firstName}${counter}';
      email = '${basePart}@wessex.cl';
      counter++;
    }

    return email;
  }

  // Obtener estadísticas de usuarios
  Map<String, dynamic> get estadisticas {
    int total = _usuarios.length;
    int activos =
        _usuarios
            .where((u) => u['estado']?.toString().toLowerCase() == 'activo')
            .length;
    int pendientes =
        _usuarios
            .where(
              (u) =>
                  u['estado']?.toString().toLowerCase() ==
                  'pendiente activación',
            )
            .length;
    int inactivos = total - activos - pendientes;

    // Estadísticas por rol
    Map<String, int> porRol = {};
    for (var usuario in _usuarios) {
      String rol = usuario['rol'] ?? 'Sin rol';
      porRol[rol] = (porRol[rol] ?? 0) + 1;
    }

    return {
      'total': total,
      'activos': activos,
      'pendientes': pendientes,
      'inactivos': inactivos,
      'porRol': porRol,
    };
  }

  // Métodos de estado privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Limpiar datos locales
  void clearCache() {
    _usuarios.clear();
    _setError(null);
    notifyListeners();
  }

  // Cambiar estado de usuario (para compatibilidad con la UI existente)
  Future<bool> changeUserStatus(String rut, String newStatus) async {
    // Por ahora, solo actualizar localmente ya que el backend no maneja estados específicos
    try {
      int index = _usuarios.indexWhere((u) => u['rut'] == rut);
      if (index != -1) {
        _usuarios[index]['estado'] = newStatus;
        _usuarios[index]['fechaActualizacion'] = DateTime.now();
        notifyListeners();
        print('✅ Estado de usuario actualizado localmente: $rut -> $newStatus');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error cambiando estado de usuario: $e');
      return false;
    }
  }

  // Resetear contraseña (simulado - en un entorno real esto requeriría endpoint específico)
  String resetPassword(String rut) {
    String newPassword =
        'wessex${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Actualizar localmente - en un entorno real esto debería llamar a un endpoint específico
    int index = _usuarios.indexWhere((u) => u['rut'] == rut);
    if (index != -1) {
      _usuarios[index]['resetToken'] =
          'reset_${DateTime.now().millisecondsSinceEpoch}';
      _usuarios[index]['fechaResetPassword'] = DateTime.now();
      notifyListeners();
      print('🔑 Contraseña reseteada para usuario: $rut');
    }

    return newPassword;
  }
}
