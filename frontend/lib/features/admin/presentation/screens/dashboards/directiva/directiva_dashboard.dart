import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/tokenManager.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/features/admin/presentation/screens/justificantes/gestion/gestion_justificantes_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/usuarios/registro/registro_datos_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/usuarios/registro_formularios/registro_formularios_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/usuarios/gestion/gestion_usuarios_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/usuarios/base_datos/base_datos_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/eventos/gestion/gestion_eventos_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/actas/gestion/gestion_actas_reunion_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/informacion_publica/gestion_informacion_publica_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/eventos/multimedia/multimedia_overview_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/pagos/resumen/pagos_resumen_screen.dart';
import 'package:wesrugby/features/inventory/presentation/screens/management/inventory_management_screen.dart';
import 'package:wesrugby/features/auth/presentation/screens/simple_login/simple_login.dart' as login;
import 'package:wesrugby/features/admin/presentation/screens/terminos/terminos_gestion_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/asistencia/estadisticas/estadisticas_asistencia_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/configuracion/configuracion_fondo_screen.dart';

class DirectivaDashboard extends StatefulWidget {
  const DirectivaDashboard({super.key});

  @override
  State<DirectivaDashboard> createState() => _DirectivaDashboardState();
}

class _DirectivaDashboardState extends State<DirectivaDashboard> {
  String? _avatarUrl;
  String? _userName;
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
        _userName = tokenData['nombreCompleto']?.toString() ??
            tokenData['nombre']?.toString() ??
            'Usuario';
        _avatarUrl = _resolveAvatarUrl(tokenData) ?? _avatarUrl;
      });
    }

    if (!refreshRemote) return;

    try {
      final response = await ApiService.getProfile();
      final payload = response.data;
      final data = response.success && payload is Map<String, dynamic>
          ? payload['data'] ?? payload
          : null;
      if (mounted && data is Map<String, dynamic>) {
        final resolved = _resolveAvatarUrl(data);
        setState(() {
          _userName = data['nombreCompleto']?.toString() ?? _userName;
          _avatarUrl = resolved ?? _avatarUrl;
        });
        await TokenManager.saveUserInfo(data);
      }
    } catch (e) {
      // Ignorar errores de red
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

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo leer el archivo seleccionado.'),
            backgroundColor: WessexColors.alertRed,
          ),
        );
      }
      return;
    }

    setState(() => _avatarUploading = true);

    try {
      final response = await ApiService.uploadAvatar(
        bytes: bytes,
        fileName: file.name,
        mimeType: _mimeTypeFromExtension(file.extension),
      );

      final newUrl = response['avatarUrl']?.toString() ??
          (response['avatarPath'] != null
              ? ApiService.buildUploadUrl(response['avatarPath'].toString())
              : null);

      if (mounted) {
        setState(() => _avatarUrl = newUrl ?? _avatarUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada.'),
            backgroundColor: WessexColors.secondaryAction,
          ),
        );
      }

      await _loadUserInfo(refreshRemote: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar la foto: $e'),
            backgroundColor: WessexColors.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _avatarUploading = false);
      }
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: WessexColors.deepRoyalBlue.withOpacity(0.1),
                backgroundImage:
                    _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: WessexColors.deepRoyalBlue,
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              // Nombre
              Text(
                _userName ?? 'Usuario',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: WessexColors.crestShadow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Rol
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'DIRECTIVA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: WessexColors.deepRoyalBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.deepRoyalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await TokenManager.clearAuthData();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const login.LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WessexColors.primaryAction,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Panel Directiva - Wessex Rugby',
          style: TextStyle(
            color: WessexColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WessexColors.deepRoyalBlue,
        elevation: 2,
        automaticallyImplyLeading: false,
        actions: [
          // Menú de perfil en la esquina superior derecha
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              child: Row(
                children: [
                  if (isTablet)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        _userName ?? 'Usuario',
                        style: const TextStyle(
                          color: WessexColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: WessexColors.white,
                    backgroundImage:
                        _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 20,
                            color: WessexColors.deepRoyalBlue,
                          )
                        : null,
                  ),
                ],
              ),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'perfil',
                  child: Row(
                    children: const [
                      Icon(Icons.person, color: WessexColors.deepRoyalBlue),
                      SizedBox(width: 12),
                      Text('Ver Perfil'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'cambiar_foto',
                  enabled: !_avatarUploading,
                  child: Row(
                    children: [
                      if (_avatarUploading)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              WessexColors.deepRoyalBlue,
                            ),
                          ),
                        )
                      else
                        const Icon(Icons.camera_alt, color: WessexColors.deepRoyalBlue),
                      const SizedBox(width: 12),
                      Text(_avatarUploading ? 'Subiendo...' : 'Cambiar Foto'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: WessexColors.primaryAction),
                      SizedBox(width: 12),
                      Text(
                        'Cerrar Sesión',
                        style: TextStyle(color: WessexColors.primaryAction),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'perfil':
                    _showProfileDialog();
                    break;
                  case 'cambiar_foto':
                    _changeAvatar();
                    break;
                  case 'logout':
                    _showLogoutDialog();
                    break;
                }
              },
            ),
          ),
        ],
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Sección: Gestión Administrativa
                const WessexSectionTitle(
                  title: 'Gestión Administrativa',
                  subtitle: 'Control y administración del club',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 16),

                _buildResponsiveGrid(
                  context,
                  [
                    _buildActionCard(
                      'Registro de Datos',
                      'Importar estudiantes desde Excel',
                      Icons.upload_file,
                      WessexColors.primaryAction,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistroDatosScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Formularios de Registro',
                      'Importar formularios de inscripción',
                      Icons.assignment,
                      WessexColors.leafGreen,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RegistroFormulariosScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Gestión de Usuarios',
                      'Administrar miembros del club',
                      Icons.people,
                      WessexColors.secondaryAction,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GestionUsuariosScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Base de Datos',
                      'Consultar estudiantes registrados',
                      Icons.storage,
                      WessexColors.secondaryAction,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BaseDatosScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Inventario y Ventas',
                      'Gestionar productos, ventas y códigos',
                      Icons.storefront,
                      WessexColors.leafGreen,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const InventoryManagementScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Gestión de Justificantes',
                      'Evaluar justificantes de inasistencia',
                      Icons.assignment_turned_in,
                      WessexColors.primaryAction,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const GestionJustificantesScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Gestión de Eventos',
                      'Administrar eventos deportivos',
                      Icons.event,
                      WessexColors.primaryAction,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GestionEventosScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Estadísticas de Asistencia',
                      'Ver análisis y tendencias de asistencia',
                      Icons.analytics,
                      WessexColors.deepRoyalBlue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const EstadisticasAsistenciaScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Resumen de Pagos',
                      'Consultar estado de pagos de estudiantes',
                      Icons.payments,
                      WessexColors.leafGreen,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PagosResumenScreen(
                            canSendNotifications: false,
                          ),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Actas de Reunión',
                      'Gestionar actas y minutas de reuniones',
                      Icons.description,
                      WessexColors.accentAction,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const GestionActasReunionScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Información Pública',
                      'Gestionar noticias, auspiciadores y entrenadores',
                      Icons.public,
                      WessexColors.secondaryAction,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const GestionInformacionPublicaScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Multimedia',
                      'Gestionar fotos y videos de eventos',
                      Icons.photo_library,
                      WessexColors.deepRoyalBlue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MultimediaOverviewScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Términos y Condiciones',
                      'Gestionar términos y condiciones del club',
                      Icons.description,
                      WessexColors.leafGreen,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TerminosGestionScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Fondo de la App',
                      'Personalizar imagen de fondo de la aplicación',
                      Icons.wallpaper,
                      WessexColors.accentAction,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ConfiguracionFondoScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(BuildContext context, List<Widget> children) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    double childAspectRatio = 1.8; // Adjusted for mobile to prevent overflow

    if (width > 1200) {
      crossAxisCount = 3;
      childAspectRatio = 1.5;
    } else if (width > 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.6;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: children,
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    required bool isDesktop,
    required bool isTablet,
  }) {
    return WessexCard(
      margin: const EdgeInsets.only(bottom: 0),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 14 : 12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 12 : (isTablet ? 10 : 8)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isDesktop ? 28 : (isTablet ? 24 : 20),
                ),
              ),
              SizedBox(height: isDesktop ? 12 : (isTablet ? 10 : 8)),
              Text(
                title,
                style: TextStyle(
                  fontSize: isDesktop ? 16 : (isTablet ? 14 : 13),
                  fontWeight: FontWeight.bold,
                  color: WessexColors.darkGrape,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isDesktop ? 13 : (isTablet ? 12 : 11),
                  color: WessexColors.darkGrape.withOpacity(0.7),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }


}
