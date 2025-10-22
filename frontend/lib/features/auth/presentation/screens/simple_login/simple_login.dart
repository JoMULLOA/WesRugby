import 'package:flutter/material.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/services/tokenManager.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/directiva/directiva_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/tesorera/tesorera_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/entrenador/entrenador_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/apoderado/apoderado_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/rama_externa/rama_externa_screen.dart';
import 'package:wesrugby/features/auth/presentation/screens/recuperacion/recuperacion.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _hasStoredSession = false;
  Map<String, dynamic>? _storedUser;
  bool _clearingStoredSession = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final isValid = await TokenManager.isLoggedIn();
    final userInfo = isValid ? await TokenManager.getUserInfo() : null;

    if (!mounted) return;

    if (isValid && userInfo != null) {
      setState(() {
        _hasStoredSession = true;
        _storedUser = Map<String, dynamic>.from(userInfo);
        final email = userInfo['email']?.toString();
        if (email != null && email.isNotEmpty) {
          _emailController.text = email;
        }
      });
    } else {
      setState(() {
        _hasStoredSession = false;
        _storedUser = null;
      });
    }
  }

  Future<void> _continuarSesionGuardada() async {
    final rol = _storedUser?['rol'];
    if (rol == null) return;
    _navigateToRoleDashboard(rol);
  }

  Future<void> _borrarSesionGuardada() async {
    setState(() {
      _clearingStoredSession = true;
    });

    try {
      await TokenManager.clearAuthData();
      if (!mounted) return;
      setState(() {
        _hasStoredSession = false;
        _storedUser = null;
        _emailController.clear();
        _passwordController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo limpiar la sesión guardada: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _clearingStoredSession = false;
        });
      }
    }
  }

  Widget _buildStoredSessionCard() {
    final nombre =
        _storedUser?['nombreCompleto']?.toString() ??
        _storedUser?['nombre']?.toString() ??
        'Mi cuenta';
    final email = _storedUser?['email']?.toString() ?? '';
    final rol = _storedUser?['rol']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        color: Colors.white.withOpacity(0.92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_open,
                    color: WessexColors.deepRoyalBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sesión guardada',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: WessexColors.deepRoyalBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              color: WessexColors.midnightNavy.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rol.toUpperCase(),
                      style: const TextStyle(
                        color: WessexColors.deepRoyalBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _continuarSesionGuardada,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.deepRoyalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Continuar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _clearingStoredSession ? null : _borrarSesionGuardada,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WessexColors.darkGrape,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: WessexColors.darkGrape.withOpacity(0.4),
                        ),
                      ),
                      child:
                          _clearingStoredSession
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    WessexColors.darkGrape,
                                  ),
                                ),
                              )
                              : const Text('Olvidar sesión'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      print('🔍 DEBUG Login - Status Code: ${response.statusCode}');
      print('🔍 DEBUG Login - Response Data: ${response.data}');
      print('🔍 DEBUG Login - Data.data: ${response.data?['data']}');
      print(
        '🔍 DEBUG Login - Token existe: ${response.data?['data']?['token'] != null}',
      );
      print('🔍 DEBUG Login - Status es 200: ${response.statusCode == 200}');

      // Acceder correctamente a los datos anidados
      final responseData = response.data?['data'];
      final token = responseData?['token'];
      final user = responseData?['user'];

      print('🔍 DEBUG Login - Token extraído: $token');
      print('🔍 DEBUG Login - User extraído: $user');
      print(
        '🔍 DEBUG Login - Condición completa: ${response.statusCode == 200 && token != null}',
      );
      print(
        '🔍 DEBUG Login - Evaluando condiciones: StatusCode=${response.statusCode}, TokenNotNull=${token != null}',
      );

      if (response.statusCode == 200 && token != null) {
        print('🟢 DEBUG - Entrando al bloque de login exitoso');

        // Guardar token y información del usuario
        await TokenManager.saveToken(token);
        await TokenManager.saveUserInfo(user);
        print('🟢 DEBUG - Token y user info guardados');

        if (mounted) {
          setState(() {
            _hasStoredSession = true;
            _storedUser = Map<String, dynamic>.from(user);
          });
        }

        // Verificar inmediatamente que el token se guardó correctamente
        final tokenVerification = await TokenManager.getToken();
        print(
          '🔍 DEBUG Login - Verificación inmediata del token: ${tokenVerification != null ? "ENCONTRADO" : "NO ENCONTRADO"}',
        );
        if (tokenVerification != null) {
          print(
            '🔍 DEBUG Login - Token verificado (primeros 30 chars): ${tokenVerification.substring(0, 30)}...',
          );
        }

        // Verificar información del usuario
        print('🔍 DEBUG User Info completo: $user');
        print('🔍 DEBUG User Info tipo: ${user.runtimeType}');

        // Navegar según el rol
        final rol = user['rol'];
        print('🔍 DEBUG Rol detectado: $rol');
        print('🔍 DEBUG Rol tipo: ${rol.runtimeType}');
        print('🔍 DEBUG Widget montado: $mounted');

        // Pequeña pausa para asegurar que el contexto esté listo
        print('🟢 DEBUG - Programando navegación...');
        Future.delayed(Duration(milliseconds: 100), () async {
          // Verificar token antes de navegar
          final tokenAntesNavegacion = await TokenManager.getToken();
          print(
            '🔍 DEBUG Login - Token antes de navegación: ${tokenAntesNavegacion != null ? "ENCONTRADO" : "NO ENCONTRADO"}',
          );

          print('🟢 DEBUG - Ejecutando navegación para rol: $rol');
          _navigateToRoleDashboard(rol);
        });
      } else {
        print('❌ DEBUG Login failed - Status: ${response.statusCode}');
        print('❌ DEBUG - Token extraído: $token');
        print('❌ DEBUG - Datos completos de respuesta: ${response.data}');
        print('❌ DEBUG - Mensaje de respuesta: ${response.message}');
        _showError(response.message ?? 'Credenciales incorrectas');
      }
    } catch (e) {
      print('❌ DEBUG Login error: $e');
      _showError('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRoleDashboard(String rol) {
    print('🚀 DEBUG Iniciando navegación para rol: $rol');
    print('🚀 DEBUG Widget mounted: $mounted');

    if (!mounted) {
      print('❌ Widget no está montado, cancelando navegación');
      return;
    }

    try {
      print('🔄 Intentando navegar...');

      switch (rol) {
        case 'directiva':
          print('📊 Navegando a DirectivaDashboard...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                print('📊 Construyendo DirectivaDashboard');
                return const DirectivaDashboard();
              },
            ),
          );
          break;
        case 'tesorera':
          print('💰 Navegando a TesoreraDashboard...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                print('💰 Construyendo TesoreraDashboard');
                return const TesoreraDashboard();
              },
            ),
          );
          break;
        case 'entrenador':
          print('🏃 Navegando a EntrenadorDashboard...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                print('🏃 Construyendo EntrenadorDashboard');
                return const EntrenadorDashboard();
              },
            ),
          );
          break;
        case 'apoderado':
          print('👨‍👩‍👧‍👦 Navegando a ApoderadoDashboard...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                print('👨‍👩‍👧‍👦 Construyendo ApoderadoDashboard');
                return const ApoderadoDashboard();
              },
            ),
          );
          break;
        case 'RamaExterna':
          print('🏆 Navegando a RamaExternaScreen...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                print('🏆 Construyendo RamaExternaScreen');
                return RamaExternaScreen();
              },
            ),
          );
          break;
        default:
          print('❌ Rol no reconocido: $rol');
          _showError('Rol no reconocido: $rol');
          return;
      }
      print('✅ Comando de navegación ejecutado para $rol');
    } catch (e, stackTrace) {
      print('❌ ERROR CRÍTICO en navegación: $e');
      print('❌ Stack trace: $stackTrace');
      _showError('Error crítico al navegar: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
                    colors: [
                      WessexColors.midnightNavy,
                      WessexColors.deepRoyalBlue,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          // Dark overlay
          Container(color: WessexColors.darkGrape.withOpacity(0.3)),
          // Login content
          SafeArea(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth:
                      isDesktop ? 500 : (isTablet ? 450 : double.infinity),
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : (isTablet ? 32 : 20),
                  vertical: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_hasStoredSession) _buildStoredSessionCard(),
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
                                  color: WessexColors.darkGrape.withOpacity(
                                    0.3,
                                  ),
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
                        padding: EdgeInsets.all(
                          isDesktop ? 32 : (isTablet ? 28 : 24),
                        ),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  hintText: "usuario@wessexrugby.com",
                                  labelStyle: TextStyle(
                                    color: WessexColors.darkGrape,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email,
                                    color: WessexColors.deepRoyalBlue,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: WessexColors.maximumGrayMint,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: WessexColors.deepRoyalBlue,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: WessexColors.maximumGrayMint,
                                    ),
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
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Por favor ingrese su email';
                                  }
                                  if (!value!.contains('@')) {
                                    return 'Por favor ingrese un email válido';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: "Contraseña",
                                  labelStyle: TextStyle(
                                    color: WessexColors.darkGrape,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: WessexColors.deepRoyalBlue,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: WessexColors.deepRoyalBlue,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: WessexColors.maximumGrayMint,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: WessexColors.deepRoyalBlue,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: WessexColors.maximumGrayMint,
                                    ),
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
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Por favor ingrese su contraseña';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 12),

                              // Forgot password link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                const RecuperarContrasenaPage(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: WessexColors.deepRoyalBlue,
                                  ),
                                  child: Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      fontSize:
                                          isDesktop ? 14 : (isTablet ? 13 : 12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 24),

                              // Login button
                              SizedBox(
                                width: double.infinity,
                                height: isDesktop ? 56 : (isTablet ? 50 : 48),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WessexColors.crimsonAlert,
                                    foregroundColor: WessexColors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    disabledBackgroundColor:
                                        WessexColors.maximumGrayMint,
                                  ),
                                  child:
                                      _isLoading
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
                                              fontSize:
                                                  isDesktop
                                                      ? 16
                                                      : (isTablet ? 15 : 14),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                ),
                              ),
                              SizedBox(height: 24),

                              // Footer
                              Text(
                                '© 2025 Wessex Rugby Club',
                                style: TextStyle(
                                  color: WessexColors.darkGrape.withOpacity(
                                    0.6,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
