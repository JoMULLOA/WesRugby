import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import 'gestion_asistencia_screen_wessex.dart';
import 'historial_asistencia_screen_wessex.dart';
import 'entrenador_justificantes_screen.dart';
import 'tomar_asistencia_screen.dart';
import 'historial_sesiones_screen.dart';

class EntrenadorDashboard extends StatelessWidget {
  const EntrenadorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Panel Entrenador - Wessex Rugby',
        elevation: 2,
      ),
      drawer: const CustomDrawer(),
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
                        padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 16 : 12)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [WessexColors.crimsonAlert, WessexColors.deepRoyalBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.sports_rugby,
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
                              '¡Bienvenido Entrenador!',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: isDesktop ? 28 : (isTablet ? 24 : 22),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Panel de gestión deportiva\nWessex Rugby Club',
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
                
                // Sección: Gestión de Asistencia
                const WessexSectionTitle(
                  title: 'Gestión de Asistencia',
                  subtitle: 'Control y seguimiento de entrenamientos',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),
                
                // Botones principales de asistencia
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Tomar Asistencia',
                        'Iniciar nueva sesión de entrenamiento',
                        Icons.how_to_reg,
                        WessexColors.leafGreen,
                        () => _navigateToGestionAsistencia(context),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        'Ver Historial',
                        'Consultar registros anteriores',
                        Icons.history,
                        WessexColors.deepRoyalBlue,
                        () => _navigateToHistorialAsistencia(context),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Fila adicional para justificantes
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Ver Justificantes',
                        'Consultar justificantes de jugadores',
                        Icons.assignment_outlined,
                        WessexColors.leafGreen,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EntrenadorJustificantesScreen(),
                          ),
                        ),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        'Evaluaciones',
                        'Rendimiento de jugadores',
                        Icons.assessment,
                        WessexColors.deepRoyalBlue,
                        () => _showComingSoon(context, 'Evaluaciones'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Botón de ancho completo
                _buildActionCard(
                  'Revisar Inscripciones Pendientes',
                  'Gestionar solicitudes de nuevos jugadores',
                  Icons.approval,
                  WessexColors.crimsonAlert,
                  () => _showComingSoon(context, 'Revisar Inscripciones'),
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                  fullWidth: true,
                ),
                
                const SizedBox(height: 32),
                
                // Sección: Estadísticas Rápidas
                const WessexSectionTitle(
                  title: 'Resumen Deportivo',
                  subtitle: 'Estadísticas del club',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),
                
                // Estadísticas en cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Jugadores\nActivos',
                        '32',
                        Icons.groups,
                        WessexColors.deepRoyalBlue,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Asistencia\nPromedio',
                        '85%',
                        Icons.check_circle,
                        WessexColors.leafGreen,
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
                      child: _buildStatCard(
                        'Próximos\nEventos',
                        '4',
                        Icons.event,
                        WessexColors.crimsonAlert,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Inscripciones\nPendientes',
                        '8',
                        Icons.pending,
                        WessexColors.midnightNavy,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Sección: Módulos Adicionales
                const WessexSectionTitle(
                  title: 'Módulos Deportivos',
                  subtitle: 'Herramientas adicionales',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildModuleCard(
                        'Eventos',
                        'Planificar entrenamientos y partidos',
                        Icons.event_note,
                        WessexColors.midnightNavy,
                        () => _showComingSoon(context, 'Gestión de Eventos'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModuleCard(
                        'Tienda',
                        'Venta de productos del club',
                        Icons.shopping_cart,
                        WessexColors.crimsonAlert,
                        () => _showComingSoon(context, 'Tienda'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Próximos eventos
                _buildUpcomingEventsCard(isDesktop, isTablet),
                
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
    bool fullWidth = false,
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
                        color: WessexColors.darkGrape,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                        color: WessexColors.darkGrape.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: WessexColors.darkGrape.withOpacity(0.5),
                size: isDesktop ? 24 : (isTablet ? 22 : 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    required bool isDesktop,
    required bool isTablet,
  }) {
    return WessexCard(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: isDesktop ? 36 : (isTablet ? 32 : 28),
          ),
          SizedBox(height: isDesktop ? 16 : (isTablet ? 14 : 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 32 : (isTablet ? 28 : 24),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isDesktop ? 8 : 6),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
              fontWeight: FontWeight.w600,
              color: WessexColors.darkGrape,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                  color: WessexColors.darkGrape,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                  color: WessexColors.darkGrape.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEventsCard(bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event,
                color: WessexColors.deepRoyalBlue,
                size: isDesktop ? 28 : (isTablet ? 24 : 20),
              ),
              SizedBox(width: isDesktop ? 16 : (isTablet ? 14 : 12)),
              Text(
                'Próximos Entrenamientos',
                style: TextStyle(
                  fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                  fontWeight: FontWeight.bold,
                  color: WessexColors.darkGrape,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : (isTablet ? 18 : 16)),
          _buildEventItem('Entrenamiento Juvenil', 'Hoy 17:00', Icons.sports_rugby, isDesktop, isTablet),
          _buildEventItem('Entrenamiento Senior', 'Mañana 19:00', Icons.sports_rugby, isDesktop, isTablet),
          _buildEventItem('Partido vs. Los Leones', 'Sábado 15:00', Icons.sports_score, isDesktop, isTablet),
          SizedBox(height: isDesktop ? 20 : (isTablet ? 18 : 16)),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: WessexColors.deepRoyalBlue,
              ),
              child: Text(
                'Ver calendario completo',
                style: TextStyle(
                  fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(String title, String time, IconData icon, bool isDesktop, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 14 : 12)),
      decoration: BoxDecoration(
        color: WessexColors.mistyRoseGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: WessexColors.deepRoyalBlue,
            size: isDesktop ? 24 : (isTablet ? 22 : 20),
          ),
          SizedBox(width: isDesktop ? 16 : (isTablet ? 14 : 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                    fontWeight: FontWeight.w600,
                    color: WessexColors.darkGrape,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                    color: WessexColors.darkGrape.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: WessexColors.darkGrape.withOpacity(0.3),
            size: isDesktop ? 20 : (isTablet ? 18 : 16),
          ),
        ],
      ),
    );
  }

  void _navigateToGestionAsistencia(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TomarAsistenciaScreen(),
      ),
    );
  }

  void _navigateToHistorialAsistencia(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistorialSesionesScreen(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$module - En desarrollo'),
        backgroundColor: WessexColors.deepRoyalBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}