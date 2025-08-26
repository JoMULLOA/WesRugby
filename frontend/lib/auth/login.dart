import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import './recuperacion.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/confGlobal.dart';
import '../config/colors.dart';
import '../services/tokenManager.dart';
import '../admin/directiva_dashboard.dart';
import '../admin/tesorera_dashboard.dart';
import '../admin/entrenador_dashboard.dart';
import '../admin/apoderado_dashboard.dart';

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
          // TokenManager.showSessionExpiredMessage(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión expirada. Por favor inicia sesión nuevamente.')),
          );
        }
        return;
      }

      // Verificar con el backend
      print('🔍 Verificando token con el backend...');
      final isValidInBackend = await _verifyTokenWithBackend(token);
      
      if (isValidInBackend) {
        print('✅ Token válido en backend, redirigiendo a dashboard');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DirectivaDashboard()),
          );
        }
      } else {
        print('❌ Token rechazado por el backend');
        await TokenManager.clearAuthData();
        if (mounted) {
          // TokenManager.showSessionExpiredMessage(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión expirada. Por favor inicia sesión nuevamente.')),
          );
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
          // TokenManager.showSessionExpiredMessage(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión expirada. Por favor inicia sesión nuevamente.')),
          );
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

          // Navegación según el rol del usuario Wessex Rugby
          switch (userRole) {
            case "directiva":
              // Directiva: Acceso completo a panel administrativo
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DirectivaDashboard()),
              );
              break;
            
            case "tesorera":
              // Tesorera: Panel financiero y administrativo limitado
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TesoreraDashboard()),
              );
              break;
            
            case "entrenador":
              // Entrenador: Panel de gestión deportiva
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const EntrenadorDashboard()),
              );
              break;
            
            case "apoderado":
              // Apoderado: Vista limitada del usuario regular
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ApoderadoDashboard()),
              );
              break;
            
            // Compatibilidad con roles antiguos
            case "admin":
            case "administrador":
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DirectivaDashboard()),
              );
              break;
            
            default:
              // Por defecto, enviar a dashboard de directiva
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DirectivaDashboard()),
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
        // await SocketService.instance.connect();
        
        // Inicializar WebSocketNotificationService para notificaciones
        // await WebSocketNotificationService.connectToSocket(userId);
        
        print('🔌 Servicios WebSocket inicializados correctamente');
      }
    } catch (e) {
      print('❌ Error inicializando servicios WebSocket: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;
    
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/icon/background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [WessexColors.midnightNavy, WessexColors.deepRoyalBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          // Dark overlay
          Container(
            color: WessexColors.darkGrape.withOpacity(0.3),
          ),
          // Login content
          SafeArea(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 500 : (isTablet ? 450 : double.infinity),
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : (isTablet ? 32 : 20),
                  vertical: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/icon/logosf.png',
                        height: isDesktop ? 200 : (isTablet ? 180 : 160),
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: isDesktop ? 120 : (isTablet ? 100 : 80),
                            width: isDesktop ? 120 : (isTablet ? 100 : 80),
                            decoration: BoxDecoration(
                              color: WessexColors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: WessexColors.darkGrape.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.sports_rugby,
                              size: isDesktop ? 60 : (isTablet ? 50 : 40),
                              color: WessexColors.deepRoyalBlue,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: isDesktop ? 24 : 20),
                      
                      // Title
                      Text(
                        "Wessex Rugby Club",
                        style: TextStyle(
                          color: WessexColors.white,
                          fontSize: isDesktop ? 32 : (isTablet ? 28 : 24),
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: WessexColors.darkGrape.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      
                      Text(
                        "Sistema de Gestión",
                        style: TextStyle(
                          color: WessexColors.white.withOpacity(0.9),
                          fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(
                              color: WessexColors.darkGrape.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isDesktop ? 40 : (isTablet ? 32 : 28)),
                      
                      // Login form
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 28 : 24)),
                        decoration: BoxDecoration(
                          color: WessexColors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: WessexColors.darkGrape.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Correo electrónico",
                                labelStyle: TextStyle(color: WessexColors.darkGrape),
                                prefixIcon: Icon(Icons.email, color: WessexColors.deepRoyalBlue),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: WessexColors.maximumGrayMint),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: WessexColors.deepRoyalBlue, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: WessexColors.maximumGrayMint),
                                ),
                                filled: true,
                                fillColor: WessexColors.mistyRoseGray,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isDesktop ? 16 : 14,
                                ),
                              ),
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: isDesktop ? 16 : 14,
                              ),
                            ),
                            SizedBox(height: 20),
                            
                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !verClave,
                              decoration: InputDecoration(
                                labelText: "Contraseña",
                                labelStyle: TextStyle(color: WessexColors.darkGrape),
                                prefixIcon: Icon(Icons.lock, color: WessexColors.deepRoyalBlue),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    verClave ? Icons.visibility : Icons.visibility_off,
                                    color: WessexColors.deepRoyalBlue,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      verClave = !verClave;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: WessexColors.maximumGrayMint),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: WessexColors.deepRoyalBlue, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: WessexColors.maximumGrayMint),
                                ),
                                filled: true,
                                fillColor: WessexColors.mistyRoseGray,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isDesktop ? 16 : 14,
                                ),
                              ),
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: isDesktop ? 16 : 14,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 32 : 24),
                            
                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: isDesktop ? 56 : (isTablet ? 50 : 48),
                              child: ElevatedButton(
                                onPressed: cargando ? null : login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WessexColors.crimsonAlert,
                                  foregroundColor: WessexColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  disabledBackgroundColor: WessexColors.maximumGrayMint,
                                ),
                                child: cargando
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: WessexColors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "Iniciar Sesión",
                                        style: TextStyle(
                                          fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: 16),
                            
                            // Forgot password link
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RecuperarContrasenaPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: WessexColors.deepRoyalBlue,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isDesktop ? 12 : 8,
                                ),
                              ),
                              child: Text(
                                "¿Olvidaste tu contraseña?",
                                style: TextStyle(
                                  fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}