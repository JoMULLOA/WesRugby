import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/navbar_con_sos_dinamico.dart';
import './amistad_menu.dart';
import '../config/confGlobal.dart';
import 'editar_perfil.dart';
import 'saldo_tarjetas_screen.dart';
import '../utils/token_manager.dart';
import '../auth/login.dart';
import '../services/socket_service.dart';

class Perfil extends StatefulWidget {
  @override
  Perfil_ createState() => Perfil_();
}

class Perfil_ extends State<Perfil> {
  // Variables para almacenar datos del usuario
  String _userEmail = 'Cargando...';
  String _userName = 'Cargando...';
  String _userRut = 'Cargando...';
  String _userAge = 'Cargando...';
  String _userCareer = 'Cargando...';
  String _userGender = 'Cargando...'; // Nueva variable para género
  String _userRole = 'Cargando...'; // Nueva variable para rol
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Método específico para el refresh (pull to refresh)
  Future<void> _refreshUserData() async {
    await _loadUserDataInternal();
  }

  // Método público para cargar datos (inicial)
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserDataInternal();
  }

  // Método interno que hace la carga real de datos
  Future<void> _loadUserDataInternal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      
      if (email == null) {
        setState(() {
          _isLoading = false;
          _userEmail = 'Usuario no encontrado';
        });
        return;
      }

      // Llamada al backend con headers de autenticación
      final headers = await TokenManager.getAuthHeaders();
      if (headers == null) {
        setState(() {
          _isLoading = false;
          _userEmail = 'Error de autenticación';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${confGlobal.baseUrl}/user/busqueda?email=$email'),
        headers: {
          ...headers,
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Debug: imprimir la respuesta completa
        print('Respuesta completa del servidor: $data');
        
        // Verificar si existe 'success' y si es true
        if (data != null && data['success'] == true) {
          final userData = data['data'];
          print('Datos del usuario recibidos: $userData');
          
          // Calcular edad desde fechaNacimiento si existe
          String userAge = 'Edad no especificada';
          if (userData['fechaNacimiento'] != null) {
            try {
              DateTime birthDate = DateTime.parse(userData['fechaNacimiento']);
              int age = DateTime.now().year - birthDate.year;
              userAge = '$age';
            } catch (e) {
              print('Error calculando edad: $e');
            }
          }
          
          setState(() {
            _userEmail = userData['email'] ?? 'Sin email';
            _userName = userData['nombreCompleto'] ?? 'Nombre no especificado';
            _userRut = userData['rut'] ?? 'RUT no especificado';
            _userAge = userAge;
            _userCareer = userData['carrera'] ?? 'Carrera no especificada';
            _userGender = userData['genero'] ?? 'no_especificado'; // Cargar género
            _userRole = userData['rol'] ?? 'estudiante'; // Cargar rol
            _isLoading = false;
          });
        } else {
          print('Success no es true o data es null');
          setState(() {
            _isLoading = false;
            _userEmail = 'Error en la respuesta del servidor';
          });
        }
      } else if (response.statusCode == 304) {
        // Manejar caché del navegador
        print('Respuesta desde caché (304)');
        setState(() {
          _isLoading = false;
          _userEmail = 'Datos desde caché';
        });
      } else {
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Error del servidor: ${response.statusCode}');
    }} catch (error) {
      print('Error al cargar datos del usuario: $error');
      setState(() {
        _isLoading = false;
        _userEmail = 'Error al cargar datos';
      });
    }
  }

  // Función para navegar a la página de editar perfil
  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditarPerfilPage()),
    );
  }

  // Función para navegar a mis vehículos
  // Función para navegar a saldo y tarjetas
  void _navigateToSaldoTarjetas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SaldoTarjetasScreen()),
    );
  }

  // Mostrar diálogo de confirmación para cerrar sesión
  void _showLogoutDialog(BuildContext context) {
    final Color primario = Color(0xFF6B3B2D);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red[600]),
              SizedBox(width: 12),
              Text(
                'Cerrar Sesión',
                style: TextStyle(color: primario),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?\n\nTendrás que volver a iniciar sesión para acceder a tu cuenta.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  // Función para realizar el logout
  Future<void> _performLogout(BuildContext context) async {
    // Obtener una referencia al Navigator antes de operaciones async
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Verificar que el widget esté montado antes de mostrar diálogo
      if (!mounted) return;
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B3B2D)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cerrando sesión...',
                    style: TextStyle(
                      color: Color(0xFF6B3B2D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // IMPORTANTE: Desconectar WebSocket antes de limpiar datos
      print('🔌 Desconectando WebSocket...');
      SocketService.instance.disconnect();

      // Intentar hacer logout en el backend primero
      await _logoutFromBackend();

      // Limpiar todos los datos de autenticación locales
      await TokenManager.clearAuthData();

      // Limpiar cualquier otro dato local adicional si es necesario
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Esto limpia todas las preferencias compartidas

      // Cerrar el diálogo de carga
      if (mounted) {
        navigator.pop();
      }

      // Navegar al login y limpiar toda la pila de navegación
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }

      // Mostrar mensaje de confirmación
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Sesión cerrada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Cerrar el diálogo de carga en caso de error
      if (mounted) {
        navigator.pop();
      }
      
      print('Error durante el logout: $e');
      
      // IMPORTANTE: Incluso si hay error, asegurar desconexión del WebSocket
      print('🔌 Desconectando WebSocket por seguridad tras error...');
      SocketService.instance.disconnect();
      
      // Incluso si hay error en el backend, limpiar datos locales
      await TokenManager.clearAuthData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Navegar al login solo si el widget está montado
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      
        // Mostrar mensaje de advertencia pero continuar
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Sesión cerrada localmente (problema de conexión)')),
              ],
            ),
            backgroundColor: Colors.orange[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Función para hacer logout en el backend
  Future<void> _logoutFromBackend() async {
    try {
      // Obtener headers de autenticación
      final headers = await TokenManager.getAuthHeaders();
      
      if (headers != null) {
        final response = await http.post(
          Uri.parse('${confGlobal.baseUrl}/auth/logout'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          print('✅ Logout exitoso en el backend');
          final data = json.decode(response.body);
          print('Respuesta del servidor: ${data['message']}');
        } else {
          print('⚠️ Error en logout del backend: ${response.statusCode}');
          print('Respuesta: ${response.body}');
        }
      } else {
        print('⚠️ No hay token válido para logout en backend');
      }
    } catch (e) {
      print('❌ Error conectando con backend para logout: $e');
      // No lanzar excepción aquí - permitir que el logout local continúe
    }
  }

  // Función para obtener la imagen de perfil según el género
  String _getProfileImage() {
    // No mostrar imagen para administradores
    if (_userRut.isNotEmpty && _userRut != 'Cargando...' && _userRut != 'RUT no especificado') {
      // Puedes agregar lógica adicional aquí para detectar administradores si es necesario
    }
    
    switch (_userGender.toLowerCase()) {
      case 'masculino':
        return 'assets/profile/hombre.png';
      case 'femenino':
        return 'assets/profile/mujer.png';
      case 'no_binario':
        return 'assets/profile/nobin.png';
      case 'prefiero_no_decir':
        return 'assets/profile/nodice.png';
      default:
        return 'assets/profile/nodice.png'; // Imagen por defecto
    }
  }

  // Función para verificar si el usuario es administrador
  bool _esAdministrador() {
    return _userRole.toLowerCase() == 'administrador';
  }

  @override
  Widget build(BuildContext context) {
    final Color fondo = Color(0xFFF8F2EF);
    final Color primario = Color(0xFF6B3B2D);
    final Color secundario = Color(0xFF8D4F3A);

    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: secundario,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          //Botón de billetera/pagos
          IconButton(
            icon: Icon(Icons.account_balance_wallet),
            tooltip: 'Gestión de Pagos',
            onPressed: () => _navigateToSaldoTarjetas(context),
          ),
          //Botón de amistades
          IconButton(
            icon: Icon(Icons.people),
            tooltip: 'Amistades',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AmistadMenuScreen()),
              );
            },
          ),
          //Botón de logout
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primario),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshUserData,
              color: primario,
              backgroundColor: fondo,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(), // Permite scroll incluso si el contenido no es largo
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Tarjeta de perfil
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF8D4F3A), // Color secundario (marrón medio)
                            Color(0xFF6B3B2D), // Color primario (marrón oscuro)
                            Color(0xFFA0613B), // Marrón más claro para transición
                          ],
                          stops: [0.0, 0.7, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            spreadRadius: 2,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          // Ícono de editar flotante en la esquina superior derecha
                          Positioned(
                            top: -8,
                            right: -8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: secundario, 
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () => _navigateToEditProfile(context),
                                icon: Icon(Icons.edit, color: Colors.white, size: 20), // Ícono marrón
                                padding: EdgeInsets.all(8),
                                constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                                tooltip: 'Editar Perfil',
                              ),
                            ),
                          ),
                          // Contenido original de la tarjeta
                          Column(
                      children: [
                        CircleAvatar(
                          radius: 45, // Aumenté un poco el tamaño
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: _userName.isNotEmpty && !_esAdministrador()
                              ? AssetImage(_getProfileImage())
                              : null,
                          child: _userName.isEmpty || _esAdministrador()
                              ? Icon(Icons.person, size: 45, color: Colors.white70)
                              : null,
                        ),
                        SizedBox(height: 12),
                        Text(
                          _userName.isNotEmpty 
                            ? _userAge != 'Edad no especificada' 
                              ? '$_userName, $_userAge'  // Nombre + edad si existe
                              : _userName                // Solo nombre si no hay edad
                            : _userEmail,                // Email como fallback
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Texto blanco
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _userRut, 
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        if (_userEmail.isNotEmpty && _userName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              children: [
                                Text(
                                  _userEmail,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7), 
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ], // Cierra Row de clasificación
                        ), // Cierra Column del contenido del Stack
                      ], // Cierra children del Stack
                    ), // Cierra Stack
                  ), // Cierra Container

                  SizedBox(height: 20),

                  // Carrera
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carrera',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primario,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• $_userCareer',
                          style: TextStyle(color: secundario),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                ],
              ),
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Chat de soporte deshabilitado
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chat de soporte no disponible')),
          );
        },
        backgroundColor: primario,
        child: Icon(Icons.support_agent, color: Colors.white),
        tooltip: 'Soporte (Deshabilitado)',
      ),
      bottomNavigationBar: NavbarConSOSDinamico(
        currentIndex: 1, // Siempre será 1 para la pantalla de perfil
        onTap: (index) {
          // Navegación simplificada - solo Inicio (0) y Perfil (1)
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/inicio');
              break;
            case 1:
              // Ya estamos en perfil, no hacer nada
              break;
          }
        },
      ),
    );
  }
}