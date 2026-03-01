import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/tokenManager.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/features/admin/presentation/screens/justificantes/entrenador/justificados_activos_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/asistencia/tomar/tomar_asistencia_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/asistencia/historial/historial_asistencia_screen_wessex.dart';
import 'package:wesrugby/features/auth/presentation/screens/simple_login/simple_login.dart' as login;

class EntrenadorDashboard extends StatefulWidget {
  const EntrenadorDashboard({super.key});

  @override
  State<EntrenadorDashboard> createState() => _EntrenadorDashboardState();
}

class _EntrenadorDashboardState extends State<EntrenadorDashboard> {
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
        final nombreCompleto = tokenData['nombreCompleto']?.toString() ?? tokenData['nombre']?.toString() ?? 'Usuario';
        // Extraer primer nombre
        final primerNombre = nombreCompleto.split(' ').first;
        _userName = primerNombre;
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
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final isCompact = screenWidth < 420;
    final maxDialogWidth = math.min(screenWidth * 0.9, 420.0);
    final avatarRadius = isCompact ? 38.0 : 50.0;
    final titleSize = isCompact ? 20.0 : 24.0;
    final chipFontSize = isCompact ? 12.0 : 14.0;
    final padding = EdgeInsets.all(isCompact ? 18 : 24);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 24,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxDialogWidth),
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: WessexColors.deepRoyalBlue.withOpacity(0.1),
                  backgroundImage:
                      _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: avatarRadius,
                          color: WessexColors.deepRoyalBlue,
                        )
                      : null,
                ),
                SizedBox(height: isCompact ? 16 : 20),
                Text(
                  _userName ?? 'Usuario',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.crestShadow,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isCompact ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'ENTRENADOR',
                    style: TextStyle(
                      fontSize: chipFontSize,
                      fontWeight: FontWeight.w600,
                      color: WessexColors.deepRoyalBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 18 : 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WessexColors.deepRoyalBlue,
                      padding: EdgeInsets.symmetric(
                        vertical: isCompact ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
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
          'Panel Entrenador - Wessex Rugby',
          style: TextStyle(
            color: WessexColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WessexColors.deepRoyalBlue,
        elevation: 2,
        automaticallyImplyLeading: false,
        actions: [
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Sección: Gestión de Asistencia
                const WessexSectionTitle(
                  title: 'Gestión de Asistencia',
                  subtitle: 'Control y seguimiento de entrenamientos',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 16),

                // Botones de gestión de asistencia
                _buildResponsiveGrid(
                  context,
                  [
                    _buildActionCard(
                      'Ver Historial',
                      'Consultar registros anteriores',
                      Icons.history,
                      WessexColors.deepRoyalBlue,
                      () => _navigateToHistorialAsistencia(context),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Tomar Asistencia',
                      'Iniciar nueva sesión de entrenamiento',
                      Icons.how_to_reg,
                      WessexColors.leafGreen,
                      () => _navigateToGestionAsistencia(context),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Alumnos Justificados',
                      'Ver alumnos con justificantes activos',
                      Icons.verified_user,
                      WessexColors.deepRoyalBlue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JustificadosActivosScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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


  void _navigateToGestionAsistencia(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TomarAsistenciaScreen()),
    );
  }

  void _navigateToHistorialAsistencia(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistorialAsistenciaScreen()),
    );
  }
}
