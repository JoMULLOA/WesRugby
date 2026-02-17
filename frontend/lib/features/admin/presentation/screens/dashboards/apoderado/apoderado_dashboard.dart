import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/tokenManager.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/features/admin/presentation/screens/pagos/voucher/voucher_pago_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/pagos/historial/historial_vouchers_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/justificantes/detalle/justificante_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/justificantes/historial/historial_justificantes_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/actas/visualizar/visualizar_actas_reunion_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/usuarios/editar_estudiante_apoderado/editar_estudiante_apoderado_screen.dart';
import 'package:wesrugby/features/auth/presentation/screens/simple_login/simple_login.dart' as login;
import 'package:wesrugby/shared/widgets/terminos_condiciones_dialog.dart';
import 'package:wesrugby/features/admin/presentation/screens/asistencia/apoderado/asistencia_apoderado_screen.dart';
import 'package:wesrugby/data/services/notificacion_service.dart';
import 'package:wesrugby/data/models/notificacion_model.dart';

class ApoderadoDashboard extends StatefulWidget {
  const ApoderadoDashboard({super.key});

  @override
  State<ApoderadoDashboard> createState() => _ApoderadoDashboardState();
}

class _ApoderadoDashboardState extends State<ApoderadoDashboard> {
  String? _avatarUrl;
  String? _userName;
  bool _avatarUploading = false;
  List<Notificacion> _notificaciones = [];
  bool _hasUnreadDebtNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkNotifications();
    // Verificar términos y condiciones después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      verificarYMostrarTerminos(context);
    });
  }

  Future<void> _checkNotifications() async {
    try {
      final response = await NotificacionService.obtenerNotificacionesPendientes();
      if (mounted && response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _notificaciones = data.map((json) => Notificacion.fromJson(json)).toList();
          _hasUnreadDebtNotifications = _notificaciones.any((n) => 
            !n.leida && (n.datos?['tipoDeuda'] != null)
          );
        });
      }
    } catch (e) {
      print('Error al cargar notificaciones: $e');
    }
  }

  Future<void> _eliminarNotificacion(String id, StateSetter setDialogState) async {
    // Optimistic update: Remove immediately from UI
    setState(() {
      _notificaciones.removeWhere((n) => n.id == id);
      _hasUnreadDebtNotifications = _notificaciones.any((n) => 
        !n.leida && (n.datos?['tipoDeuda'] != null)
      );
    });
    
    // Update dialog UI immediately
    setDialogState(() {});

    // Close dialog if empty
    if (_notificaciones.isEmpty && mounted) {
      Navigator.of(context).pop();
    }

    try {
      // Call API in background
      final response = await NotificacionService.eliminarNotificacion(id);
      if (response['success'] != true) {
        print('Error deleting notification: ${response['message']}');
      }
    } catch (e) {
      print('Error al eliminar notificación: $e');
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(24),
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notificaciones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_notificaciones.isEmpty)
                    const Text('No tienes notificaciones pendientes.')
                  else
                    ..._notificaciones.where((n) => !n.leida).map((n) {
                      String mensaje = n.mensaje;
                      if (n.datos != null && n.datos!['tipoDeuda'] != null) {
                        final anio = n.datos!['anio'] ?? 2025; // Año por defecto si no está especificado
                        if (n.datos!['tipoDeuda'] == 'matricula') {
                          mensaje = 'Debes matrícula $anio';
                        } else if (n.datos!['tipoDeuda'] == 'mes') {
                          final mes = n.datos!['mes'] ?? '';
                          mensaje = 'Debes mes $mes $anio';
                        }
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WessexColors.crimsonAlert.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: WessexColors.crimsonAlert.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: WessexColors.crimsonAlert),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                mensaje,
                                style: TextStyle(
                                  color: WessexColors.darkGrape,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _eliminarNotificacion(n.id, setDialogState),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: WessexColors.darkGrape.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          );
        }
      ),
    );
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
                  'APODERADO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: WessexColors.deepRoyalBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
          'Panel Apoderado - Wessex Rugby',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showNotificationsDialog,
        backgroundColor: WessexColors.deepRoyalBlue,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications, color: Colors.white),
            if (_hasUnreadDebtNotifications)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: WessexColors.leafGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header de bienvenida con diseño Wessex
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          isDesktop ? 20 : (isTablet ? 16 : 12),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              WessexColors.crimsonAlert,
                              WessexColors.deepRoyalBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.family_restroom,
                          color: WessexColors.white,
                          size: isDesktop ? 48 : (isTablet ? 40 : 32),
                        ),
                      ),
                      SizedBox(width: isDesktop ? 24 : (isTablet ? 20 : 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Bienvenido Apoderado!',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: isDesktop ? 28 : (isTablet ? 24 : 22),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Panel de seguimiento\nWessex Rugby Club',
                              style: TextStyle(
                                color: WessexColors.darkGrape.withOpacity(0.7),
                                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sección: Mis Estudiantes
                const WessexSectionTitle(
                  title: 'Mis Estudiantes',
                  subtitle: 'Visualizar y editar información de estudiantes',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 16),

                _buildResponsiveGrid(
                  context,
                  [
                    _buildActionCard(
                      'Gestionar Estudiantes',
                      'Ver y editar información de mis estudiantes',
                      Icons.school,
                      WessexColors.deepRoyalBlue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const EditarEstudianteApoderadoScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Sección: Gestión de Pagos
                const WessexSectionTitle(
                  title: 'Gestión de Pagos',
                  subtitle: 'Vouchers y comprobantes de mensualidad',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 16),

                _buildResponsiveGrid(
                  context,
                  [
                    _buildActionCard(
                      'Subir Voucher',
                      'Adjuntar comprobante de pago',
                      Icons.upload_file,
                      WessexColors.crimsonAlert,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VoucherPagoScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Historial',
                      'Ver vouchers enviados',
                      Icons.history,
                      WessexColors.leafGreen,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistorialVouchersScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Sección: Justificantes
                const WessexSectionTitle(
                  title: 'Justificantes de Inasistencia',
                  subtitle: 'Justificar ausencias a entrenamientos o eventos',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 16),

                _buildResponsiveGrid(
                  context,
                  [
                    _buildActionCard(
                      'Subir Justificante',
                      'Justificar una inasistencia',
                      Icons.medical_information,
                      WessexColors.deepRoyalBlue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JustificanteScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                    _buildActionCard(
                      'Historial Justificantes',
                      'Ver justificantes enviados',
                      Icons.assignment_turned_in,
                      WessexColors.leafGreen,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HistorialJustificantesScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Sección: Asistencia
                const WessexSectionTitle(
                  title: 'Asistencia',
                  subtitle: 'Seguimiento de asistencia de mi hijo/a',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 16),

                _buildResponsiveGrid(
                  context,
                  [
                    _buildActionCard(
                      'Ver Asistencia',
                      'Historial de asistencia a entrenamientos',
                      Icons.fact_check,
                      WessexColors.leafGreen,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AsistenciaApoderadoScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Sección: Documentos
                const WessexSectionTitle(
                  title: 'Documentos del Club',
                  subtitle: 'Material compartido con apoderados',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 16),

                _buildResponsiveGrid(
                  context,
                  [
                    _buildActionCard(
                      'Actas de Reunión',
                      'Ver actas publicadas',
                      Icons.description,
                      WessexColors.deepRoyalBlue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const VisualizarActasReunionScreen(),
                        ),
                      ),
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
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
