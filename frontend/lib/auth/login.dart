import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Importa el decodificador JWT
import '../buscar/inicio.dart'; // Importar InicioScreen
import './recuperacion.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/confGlobal.dart';
import '../utils/token_manager.dart';
import '../services/socket_service.dart'; // Importar SocketService
import '../services/websocket_notification_service.dart'; // Importar WebSocket Notifications
import '../admin/admin_dashboard.dart'; // Importar AdminDashboard

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool cargando = false;
  bool verClave = false;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Configuración: cambiar a true para habilitar auto-login
  static const bool AUTO_LOGIN_ENABLED = false;

  @override
  void initState() {
    super.initState();
    
    if (AUTO_LOGIN_ENABLED) {
      _checkAndRedirectIfAuthenticated();
    } else {
      // Solo limpiar tokens expirados sin redireccionar automáticamente
      _cleanExpiredTokenOnly();
    }
  }

  // Verificar autenticación y redireccionar si es válida (solo si AUTO_LOGIN_ENABLED = true)
  Future<void> _checkAndRedirectIfAuthenticated() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      
      if (token == null) {
        print('🔒 No hay token almacenado');
        return;
      }

      // Verificar si el token ha expirado según el cliente
      if (JwtDecoder.isExpired(token)) {
        print('⏰ Token JWT expirado (verificación cliente)');
        await TokenManager.clearAuthData();
        if (mounted) {
          TokenManager.showSessionExpiredMessage(context);
        }
        return;
      }

      // Verificar con el backend
      print('🔍 Verificando token con el backend...');
      final isValidInBackend = await _verifyTokenWithBackend(token);
      
      if (isValidInBackend) {
        print('✅ Token válido en backend, redirigiendo a inicio');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const InicioScreen()),
          );
        }
      } else {
        print('❌ Token rechazado por el backend');
        await TokenManager.clearAuthData();
        if (mounted) {
          TokenManager.showSessionExpiredMessage(context);
        }
      }
    } catch (e) {
      print('❌ Error verificando token: $e');
      await TokenManager.clearAuthData();
    }
  }

  // Verificar token con el backend
  Future<bool> _verifyTokenWithBackend(String token) async {
    try {
      final response = await http.get(
        Uri.parse("${confGlobal.baseUrl}/user/detail/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error verificando token con backend: $e');
      return false;
    }
  }

  // Limpiar solo tokens expirados (sin redirección automática)
  Future<void> _cleanExpiredTokenOnly() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      
      if (token != null && JwtDecoder.isExpired(token)) {
        print('⏰ Token JWT expirado, limpiando datos...');
        await TokenManager.clearAuthData();
        if (mounted) {
          TokenManager.showSessionExpiredMessage(context);
        }
      }
    } catch (e) {
      print('❌ Error limpiando token expirado: $e');
    }
  }

  Future<void> login() async {
    // Validaciones
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todos los campos son obligatorios")),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${confGlobal.baseUrl}/auth/login/"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      print('📡 Status: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extraer datos de la respuesta - estructura correcta del backend
        final token = data["data"]["token"];
        
        // Decodificar el token para obtener información del usuario
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        final userEmail = decodedToken['email'];
        final userRole = decodedToken['rol'] ?? 'usuario'; // valor por defecto
        final userId = decodedToken['id'].toString();
        
        // Guardar token y datos de usuario
        await _storage.write(key: 'jwt_token', value: token);
        await _storage.write(key: 'user_id', value: userId);
        await _storage.write(key: 'user_email', value: userEmail);
        await _storage.write(key: 'user_role', value: userRole);
        
        // Guardar en SharedPreferences para compatibilidad
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLogged', true);
        await prefs.setString('email', userEmail);
        await prefs.setString('userId', userId);
        await prefs.setString('userRole', userRole);

        // Inicializar servicios WebSocket después del login exitoso
        await _initializeWebSocketServices();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Login exitoso"),
              backgroundColor: Color(0xFF057233), // Leaf Green
              duration: Duration(seconds: 2),
            ),
          );

          // Navegación según el rol del usuario
          if (userRole == "admin" || userRole == "administrador") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const InicioScreen()),
            );
          }
        }
      } else {
        // Manejo de errores mejorado
        final data = json.decode(response.body);
        String errorMessage = "Error desconocido";
        
        // 1. Verificar si hay un mensaje directo
        if (data.containsKey("message") && data["message"] != null) {
          errorMessage = data["message"];
        }
        // 2. Verificar si hay errores de validación
        else if (data.containsKey("errors") && data["errors"] != null) {
          final errors = data["errors"];
          if (errors is List && errors.isNotEmpty) {
            errorMessage = errors.first["msg"] ?? errors.first.toString();
          } else if (errors is Map) {
            errorMessage = errors.values.first.toString();
          }
        }
        // 3. Verificar si hay dataInfo (campos específicos)
        else if (data.containsKey("dataInfo")) {
          final errorData = data["dataInfo"];
          if (errorData is Map && errorData.containsKey("dataInfo")) {
            String field = errorData["dataInfo"] ?? "";
            String msg = errorData["message"] ?? "";
            errorMessage = field.isEmpty ? msg : "$field: $msg";
          }
          else {
            errorMessage = errorData.toString();
          }
        }
        // 4. Fallback al cuerpo completo de la respuesta
        else {
          errorMessage = response.body;
        }
        
        print('❌ Error de login: $errorMessage');
        print('📄 Estructura completa del error: $data');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ $errorMessage"),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFFB02A2E), // Crimson Alert
          ),
        );
      }
    } catch (e) {
      print('❌ Excepción durante el login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error de conexión: $e"),
          backgroundColor: const Color(0xFFB02A2E), // Crimson Alert
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  // Inicializar servicios WebSocket después del login exitoso
  Future<void> _initializeWebSocketServices() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final userId = await _storage.read(key: 'user_id');
      
      if (token != null && userId != null) {
        // Inicializar SocketService para chat
        await SocketService.instance.connect();
        
        // Inicializar WebSocketNotificationService para notificaciones
        await WebSocketNotificationService.connectToSocket(userId);
        
        print('🔌 Servicios WebSocket inicializados correctamente');
      }
    } catch (e) {
      print('❌ Error inicializando servicios WebSocket: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/icon/background.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: const Color.fromARGB(128, 0, 0, 0), // Overlay oscuro
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              margin: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icon/logosf.png',
                      height: 240,
                    ),
                    const Text(
                      "Wessex Rugby",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Sistema de Gestión Web",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 32),
                      
                    // Campo Email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        labelStyle: const TextStyle(color: Color(0xFF100B0D)), // Dark Grape
                        prefixIcon: const Icon(Icons.email, color: Color(0xFF090976)), // Deep Royal Blue
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFB02A2E), width: 2), // Crimson Alert
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD2DEDC)), // Maximum Gray Mint
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF0EAEB), // Misty Rose Gray
                      ),
                      style: const TextStyle(color: Color(0xFF100B0D)), // Dark Grape
                    ),
                    const SizedBox(height: 20),
                    
                    // Campo Password
                    TextField(
                      controller: _passwordController,
                      obscureText: !verClave,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        labelStyle: const TextStyle(color: Color(0xFF100B0D)), // Dark Grape
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF090976)), // Deep Royal Blue
                        suffixIcon: IconButton(
                          icon: Icon(
                            verClave ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF090976), // Deep Royal Blue
                          ),
                          onPressed: () {
                            setState(() {
                              verClave = !verClave;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFB02A2E), width: 2), // Crimson Alert
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD2DEDC)), // Maximum Gray Mint
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF0EAEB), // Misty Rose Gray
                      ),
                      style: const TextStyle(color: Color(0xFF100B0D)), // Dark Grape
                    ),
                    const SizedBox(height: 32),
                    
                    // Botón Login
                    ElevatedButton(
                      onPressed: cargando ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB02A2E), // Crimson Alert
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Iniciar Sesión",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Link recuperar contraseña
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecuperarContrasenaPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "¿Olvidaste tu contraseña?",
                        style: TextStyle(
                          color: Color(0xFF090976), // Deep Royal Blue para enlaces
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}