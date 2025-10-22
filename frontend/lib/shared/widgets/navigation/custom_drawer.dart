import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wesrugby/core/config/confGlobal.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/tokenManager.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/directiva/directiva_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/tesorera/tesorera_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/entrenador/entrenador_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/dashboards/apoderado/apoderado_dashboard.dart';
import 'package:wesrugby/features/admin/presentation/screens/inscripciones/inscripciones_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/eventos/multimedia/multimedia_overview_screen.dart';
import 'package:wesrugby/features/auth/presentation/screens/simple_login/simple_login.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? userRole;
  String? userName;
  String? userEmail;
  String? _avatarUrl;
  bool _avatarUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo({bool refreshRemote = true}) async {
    final tokenData = await TokenManager.getUserInfo();
    if (mounted && tokenData != null) {
      setState(() {
        userRole = tokenData['rol']?.toString();
        userName =
            tokenData['nombreCompleto']?.toString() ??
            tokenData['nombre']?.toString() ??
            'Usuario';
        userEmail = tokenData['email']?.toString();
        _avatarUrl = _resolveAvatarUrl(tokenData) ?? _avatarUrl;
      });
    }

    if (!refreshRemote) return;

    try {
      final response = await ApiService.getProfile();
      final payload = response.data;
      final data =
          response.success && payload is Map<String, dynamic>
              ? payload['data'] ?? payload
              : null;
      if (mounted && data is Map<String, dynamic>) {
        final resolved = _resolveAvatarUrl(data);
        setState(() {
          userRole = data['rol']?.toString() ?? userRole;
          userName = data['nombreCompleto']?.toString() ?? userName;
          userEmail = data['email']?.toString() ?? userEmail;
          _avatarUrl = resolved ?? _avatarUrl;
        });
        await TokenManager.saveUserInfo(data);
      }
    } catch (e) {
      // Ignorar errores de red para mantener datos locales
    }
  }

  String? _resolveAvatarUrl(Map<String, dynamic>? data) {
    if (data == null) return null;
    final providedUrl = data['avatarUrl']?.toString();
    if (providedUrl != null && providedUrl.isNotEmpty) {
      return providedUrl;
    }
    final path = data['avatarPath']?.toString();
    if (path == null || path.isEmpty) {
      return null;
    }
    return ApiService.buildUploadUrl(path);
  }

  String _mimeTypeFromExtension(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _changeAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo leer el archivo seleccionado.'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
      return;
    }

    setState(() {
      _avatarUploading = true;
    });

    try {
      final response = await ApiService.uploadAvatar(
        bytes: bytes,
        fileName: file.name,
        mimeType: _mimeTypeFromExtension(file.extension),
      );

      final newUrl =
          response['avatarUrl']?.toString() ??
          (response['avatarPath'] != null
              ? ApiService.buildUploadUrl(response['avatarPath'].toString())
              : null);

      if (mounted) {
        setState(() {
          _avatarUrl = newUrl ?? _avatarUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada.'),
            backgroundColor: WessexColors.leafGreen,
          ),
        );
      }

      await _loadUserInfo(refreshRemote: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar la foto: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _avatarUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Drawer(
      backgroundColor: WessexColors.white,
      width: isTablet ? 320 : 280,
      child: Column(
        children: [
          // Header del drawer
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [WessexColors.midnightNavy, WessexColors.deepRoyalBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _avatarUploading ? null : _changeAvatar,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: isTablet ? 42 : 38,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                _avatarUrl != null
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                            child:
                                _avatarUrl == null
                                    ? Icon(
                                      Icons.person,
                                      size: isTablet ? 42 : 36,
                                      color: WessexColors.deepRoyalBlue,
                                    )
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: WessexColors.crimsonAlert,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child:
                                  _avatarUploading
                                      ? const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Icon(
                                        Icons.camera_alt,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName ?? 'Usuario',
                            style: TextStyle(
                              color: WessexColors.white,
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (userEmail != null)
                            Text(
                              userEmail!,
                              style: TextStyle(
                                color: WessexColors.white.withOpacity(0.85),
                                fontSize: isTablet ? 15 : 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _getRoleDisplayName(userRole),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _avatarUploading ? null : _changeAvatar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Actualizar foto de perfil'),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: Container(
              color: WessexColors.white,
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8),
                children: _buildMenuItems(),
              ),
            ),
          ),

          // Footer - Cerrar sesión
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: WessexColors.maximumGrayMint, width: 1),
              ),
              color: WessexColors.mistyRoseGray,
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: WessexColors.crimsonAlert),
              title: Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: WessexColors.crimsonAlert,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _showLogoutDialog(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    List<Widget> items = [
      _buildMenuItem(
        icon: Icons.dashboard,
        title: 'Panel Principal',
        color: WessexColors.deepRoyalBlue,
        onTap: () {
          Navigator.pop(context);
          _navigateToDashboard();
        },
        isTablet: isTablet,
      ),
      Divider(color: WessexColors.maximumGrayMint, thickness: 1),
    ];

    // Menús específicos por rol
    switch (userRole) {
      case 'directiva':
        items.addAll(_getDirectivaMenuItems());
        break;
      case 'tesorera':
        items.addAll(_getTesoreraMenuItems());
        break;
      case 'entrenador':
        items.addAll(_getEntrenadorMenuItems());
        break;
      case 'apoderado':
        items.addAll(_getApoderadoMenuItems());
        break;
    }

    items.addAll([
      Divider(color: WessexColors.maximumGrayMint, thickness: 1),
      _buildMenuItem(
        icon: Icons.settings,
        title: 'Configuración',
        color: WessexColors.darkGrape,
        onTap: () {
          Navigator.pop(context);
          _showNotImplemented('Configuración');
        },
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.info,
        title: 'Acerca de',
        color: WessexColors.darkGrape,
        onTap: () {
          Navigator.pop(context);
          _showAboutDialog();
        },
        isTablet: isTablet,
      ),
    ]);

    return items;
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isTablet,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? WessexColors.mistyRoseGray : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: isTablet ? 26 : 24),
        title: Text(
          title,
          style: TextStyle(
            color: WessexColors.darkGrape,
            fontSize: isTablet ? 16 : 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 8 : 4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  List<Widget> _getDirectivaMenuItems() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return [
      _buildMenuItem(
        icon: Icons.school,
        title: 'Inscripciones',
        color: WessexColors.leafGreen,
        onTap: () => _navigateToModule('inscripciones'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.payment,
        title: 'Planes de Pago',
        color: WessexColors.crimsonAlert,
        onTap: () => _navigateToModule('planes-pago'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.check_circle_outline,
        title: 'Asistencia',
        color: WessexColors.deepRoyalBlue,
        onTap: () => _navigateToModule('asistencia'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.receipt,
        title: 'Comprobantes',
        color: WessexColors.midnightNavy,
        onTap: () => _navigateToModule('comprobantes'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.event,
        title: 'Eventos',
        color: WessexColors.leafGreen,
        onTap: () => _navigateToModule('eventos'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.photo_library,
        title: 'Multimedia',
        color: WessexColors.deepRoyalBlue,
        onTap: () => _navigateToModule('multimedia'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.store,
        title: 'Productos',
        color: WessexColors.deepRoyalBlue,
        onTap: () => _navigateToModule('productos'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.shopping_cart,
        title: 'Ventas',
        color: WessexColors.crimsonAlert,
        onTap: () => _navigateToModule('ventas'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.admin_panel_settings,
        title: 'Gestión Directiva',
        color: WessexColors.midnightNavy,
        onTap: () => _navigateToModule('directiva'),
        isTablet: isTablet,
      ),
    ];
  }

  List<Widget> _getTesoreraMenuItems() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return [
      _buildMenuItem(
        icon: Icons.payment,
        title: 'Planes de Pago',
        color: WessexColors.crimsonAlert,
        onTap: () => _navigateToModule('planes-pago'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.receipt,
        title: 'Comprobantes',
        color: WessexColors.midnightNavy,
        onTap: () => _navigateToModule('comprobantes'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.store,
        title: 'Productos',
        color: WessexColors.deepRoyalBlue,
        onTap: () => _navigateToModule('productos'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.shopping_cart,
        title: 'Ventas',
        color: WessexColors.leafGreen,
        onTap: () => _navigateToModule('ventas'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.analytics,
        title: 'Estadísticas',
        color: WessexColors.deepRoyalBlue,
        onTap: () => _navigateToModule('estadisticas'),
        isTablet: isTablet,
      ),
    ];
  }

  List<Widget> _getEntrenadorMenuItems() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return [
      _buildMenuItem(
        icon: Icons.school,
        title: 'Inscripciones',
        color: WessexColors.leafGreen,
        onTap: () => _navigateToModule('inscripciones'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.check_circle_outline,
        title: 'Asistencia',
        color: WessexColors.deepRoyalBlue,
        onTap: () => _navigateToModule('asistencia'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.event,
        title: 'Eventos',
        color: WessexColors.crimsonAlert,
        onTap: () => _navigateToModule('eventos'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.shopping_cart,
        title: 'Ventas',
        color: WessexColors.midnightNavy,
        onTap: () => _navigateToModule('ventas'),
        isTablet: isTablet,
      ),
    ];
  }

  List<Widget> _getApoderadoMenuItems() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return [
      _buildMenuItem(
        icon: Icons.school,
        title: 'Mis Inscripciones',
        color: WessexColors.leafGreen,
        onTap: () => _navigateToModule('mis-inscripciones'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.check_circle_outline,
        title: 'Asistencia',
        color: WessexColors.deepRoyalBlue,
        onTap: () => _navigateToModule('asistencia'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.receipt,
        title: 'Mis Pagos',
        color: WessexColors.crimsonAlert,
        onTap: () => _navigateToModule('mis-pagos'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.event,
        title: 'Eventos',
        color: WessexColors.midnightNavy,
        onTap: () => _navigateToModule('eventos'),
        isTablet: isTablet,
      ),
      _buildMenuItem(
        icon: Icons.store,
        title: 'Tienda',
        color: WessexColors.deepRoyalBlue,
        onTap: () => _navigateToModule('tienda'),
        isTablet: isTablet,
      ),
    ];
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'directiva':
        return 'DIRECTIVA';
      case 'tesorera':
        return 'TESORERA';
      case 'entrenador':
        return 'ENTRENADOR';
      case 'apoderado':
        return 'APODERADO';
      case 'RamaExterna':
        return 'RAMA EXTERNA';
      default:
        return 'USUARIO';
    }
  }

  void _navigateToModule(String module) {
    Navigator.pop(context);

    switch (module) {
      case 'inscripciones':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InscripcionesScreen()),
        );
        break;
      case 'multimedia':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MultimediaOverviewScreen(),
          ),
        );
        break;
      default:
        _showNotImplemented(module);
    }
  }

  void _showNotImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - En desarrollo'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context); // Cerrar drawer

                  // Limpiar token
                  await TokenManager.clearAuthData();

                  // Navegar a login
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _navigateToDashboard() {
    switch (userRole) {
      case 'directiva':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DirectivaDashboard()),
        );
        break;
      case 'tesorera':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TesoreraDashboard()),
        );
        break;
      case 'entrenador':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EntrenadorDashboard()),
        );
        break;
      case 'apoderado':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ApoderadoDashboard()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Dashboard - En desarrollo'),
            backgroundColor: AppColors.verdePrincipal,
          ),
        );
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Wessex Rugby Club',
      applicationVersion: '1.0.0',
      applicationLegalese:
          '© 2025 Wessex Rugby Club\nSistema de gestión integral',
      children: [
        const SizedBox(height: 16),
        const Text('Sistema de gestión para el colegio bilingüe Wessex.'),
      ],
    );
  }
}
