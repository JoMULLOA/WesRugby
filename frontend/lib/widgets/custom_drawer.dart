import 'package:flutter/material.dart';
import '../config/confGlobal.dart';
import '../config/colors.dart';
import '../services/tokenManager.dart';
import '../admin/directiva_dashboard.dart';
import '../admin/tesorera_dashboard.dart';
import '../admin/entrenador_dashboard.dart';
import '../admin/apoderado_dashboard.dart';
import '../admin/inscripciones_screen.dart';
import '../auth/simple_login.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? userRole;
  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final tokenData = await TokenManager.getUserInfo();
    if (tokenData != null) {
      setState(() {
        userRole = tokenData['rol'];
        userName = '${tokenData['nombres']} ${tokenData['apellidos']}';
        userEmail = tokenData['email'];
      });
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
                CircleAvatar(
                  radius: isTablet ? 40 : 35,
                  backgroundColor: WessexColors.white,
                  child: Icon(
                    Icons.sports_rugby,
                    size: isTablet ? 45 : 40,
                    color: WessexColors.deepRoyalBlue,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  userName ?? 'Usuario',
                  style: TextStyle(
                    color: WessexColors.white,
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  userEmail ?? 'email@ejemplo.com',
                  style: TextStyle(
                    color: WessexColors.white.withOpacity(0.8),
                    fontSize: isTablet ? 15 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: WessexColors.crimsonAlert,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getRoleDisplayName(userRole),
                    style: TextStyle(
                      color: WessexColors.white,
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                top: BorderSide(
                  color: WessexColors.maximumGrayMint,
                  width: 1,
                ),
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
        leading: Icon(
          icon,
          color: color,
          size: isTablet ? 26 : 24,
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
      builder: (context) => AlertDialog(
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
      applicationLegalese: '© 2024 Wessex Rugby Club\nSistema de gestión integral',
      children: [
        const SizedBox(height: 16),
        const Text('Sistema de gestión para el club de rugby más importante de la región.'),
      ],
    );
  }
}
