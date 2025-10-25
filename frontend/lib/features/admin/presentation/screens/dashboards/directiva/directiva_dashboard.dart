import 'package:flutter/material.dart';
import 'package:wesrugby/shared/widgets/navigation/custom_drawer.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/features/admin/presentation/screens/justificantes/gestion/gestion_justificantes_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/usuarios/registro/registro_datos_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/usuarios/gestion/gestion_usuarios_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/usuarios/base_datos/base_datos_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/eventos/gestion/gestion_eventos_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/eventos/tipos/admin_tipos_evento_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/actas/gestion/gestion_actas_reunion_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/informacion_publica/gestion_informacion_publica_screen.dart';

class DirectivaDashboard extends StatelessWidget {
  const DirectivaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Panel Directiva - Wessex Rugby',
        elevation: 2,
      ),
      drawer: const CustomDrawer(),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              WessexColors.secondaryAction,
                              WessexColors.primaryAction,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
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
                              '¡Bienvenido Directiva!',
                              style: TextStyle(
                                color: WessexColors.crestShadow,
                                fontSize: isDesktop ? 28 : (isTablet ? 24 : 22),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Panel de administración\nWessex Rugby Club',
                              style: TextStyle(
                                color: WessexColors.crestSlate.withOpacity(0.75),
                                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sección: Gestión Administrativa
                const WessexSectionTitle(
                  title: 'Gestión Administrativa',
                  subtitle: 'Control y administración del club',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),

                // Botones principales de administración
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
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
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Control Financiero',
                        'Supervisar ingresos y gastos',
                        Icons.account_balance_wallet,
                        WessexColors.accentAction,
                        () => _showComingSoon(context, 'Control Financiero'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
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
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Fila para gestión de justificantes
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Gestión de Justificantes',
                        'Evaluar justificantes de inasistencia',
                        Icons.assignment_turned_in,
                        WessexColors.primaryAction,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const GestionJustificantesScreen(),
                          ),
                        ),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Estadísticas Club',
                        'Métricas y análisis general',
                        Icons.bar_chart,
                        WessexColors.secondaryAction,
                        () => _showComingSoon(context, 'Estadísticas del Club'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Fila para reportes y gestión administrativa
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Reportes',
                        'Generar reportes del club',
                        Icons.assessment,
                        WessexColors.secondaryAction,
                        () => _showComingSoon(context, 'Reportes'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
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
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Fila para tipos de evento y actas de reunión
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Tipos de Evento',
                        'Administrar tipos de eventos deportivos/no deportivos',
                        Icons.category,
                        WessexColors.secondaryAction,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminTiposEventoScreen(),
                          ),
                        ),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Actas de Reunión',
                        'Gestionar actas y minutas de reuniones',
                        Icons.description,
                        WessexColors.accentAction,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const GestionActasReunionScreen(),
                          ),
                        ),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Fila para información pública
                _buildActionCard(
                  'Información Pública',
                  'Gestionar noticias, auspiciadores y merchandising',
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

                const SizedBox(height: 12),

                _buildActionCard(
                  'Configuración',
                  'Ajustes generales del sistema',
                  Icons.settings,
                  WessexColors.secondaryAction,
                  () => _showComingSoon(
                    context,
                    'Configuración del Sistema',
                  ),
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),

                const SizedBox(height: 32),

                // Sección: Módulos de Gestión
                const WessexSectionTitle(
                  title: 'Módulos de Gestión',
                  subtitle: 'Herramientas administrativas',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildModuleCard(
                        'Eventos',
                        'Planificar actividades del club',
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModuleCard(
                        'Reportes',
                        'Análisis y estadísticas',
                        Icons.analytics,
                        WessexColors.secondaryAction,
                        () => _showComingSoon(context, 'Reportes'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildModuleCard(
                        'Comunicaciones',
                        'Mensajería y notificaciones',
                        Icons.message,
                        WessexColors.accentAction,
                        () => _showComingSoon(context, 'Comunicaciones'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModuleCard(
                        'Configuración',
                        'Ajustes del sistema',
                        Icons.settings,
                        WessexColors.secondaryAction,
                        () => _showComingSoon(context, 'Configuración'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
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
          padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 16 : 14)),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 14 : 12)),
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
              SizedBox(width: isDesktop ? 20 : (isTablet ? 16 : 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                        fontWeight: FontWeight.bold,
                        color: WessexColors.crestShadow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                        color: WessexColors.crestSlate.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: WessexColors.crestSlate.withOpacity(0.3),
                size: isDesktop ? 20 : (isTablet ? 18 : 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
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
          padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 16 : 14)),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 14 : 12)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isDesktop ? 32 : (isTablet ? 28 : 24),
                ),
              ),
              SizedBox(height: isDesktop ? 16 : (isTablet ? 14 : 12)),
              Text(
                title,
                style: TextStyle(
                  fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                  fontWeight: FontWeight.bold,
                  color: WessexColors.crestShadow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                  color: WessexColors.crestSlate.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$module - En desarrollo'),
  backgroundColor: WessexColors.primaryAction,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
