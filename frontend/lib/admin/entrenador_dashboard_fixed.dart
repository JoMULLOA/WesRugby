import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../config/colors.dart';
import 'gestion_asistencia_screen.dart';
import 'historial_asistencia_screen.dart';

class EntrenadorDashboard extends StatefulWidget {
  const EntrenadorDashboard({super.key});

  @override
  State<EntrenadorDashboard> createState() => _EntrenadorDashboardState();
}

class _EntrenadorDashboardState extends State<EntrenadorDashboard> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;
    
    return Scaffold(
      backgroundColor: WessexColors.mistyRoseGray,
      appBar: AppBar(
        title: Text(
          'Panel Entrenador - Wessex Rugby',
          style: TextStyle(
            color: WessexColors.white,
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WessexColors.midnightNavy,
        iconTheme: IconThemeData(color: WessexColors.white),
        elevation: 2,
        centerTitle: true,
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Welcome Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 28 : (isTablet ? 24 : 20)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [WessexColors.midnightNavy, WessexColors.deepRoyalBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: WessexColors.darkGrape.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 16 : 12)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.sports_rugby,
                      color: Colors.white,
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
                            color: Colors.white,
                            fontSize: isDesktop ? 28 : (isTablet ? 24 : 22),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Panel de gestión deportiva\nWessex Rugby Club',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: isDesktop ? 32 : (isTablet ? 28 : 24)),

            // Estadísticas rápidas
            Text(
              'Resumen Deportivo',
              style: TextStyle(
                fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
                fontWeight: FontWeight.bold,
                color: WessexColors.darkGrape,
              ),
            ),
            SizedBox(height: isDesktop ? 20 : (isTablet ? 18 : 16)),
            
            _buildStatsGrid(),
            
            SizedBox(height: isDesktop ? 32 : (isTablet ? 28 : 24)),

            // Acciones principales
            Text(
              'Gestión de Asistencia',
              style: TextStyle(
                fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
                fontWeight: FontWeight.bold,
                color: WessexColors.darkGrape,
              ),
            ),
            SizedBox(height: isDesktop ? 20 : (isTablet ? 18 : 16)),
            
            _buildMainActions(),
            
            SizedBox(height: isDesktop ? 32 : (isTablet ? 28 : 24)),

            // Módulos adicionales
            Text(
              'Módulos Deportivos',
              style: TextStyle(
                fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
                fontWeight: FontWeight.bold,
                color: WessexColors.darkGrape,
              ),
            ),
            SizedBox(height: isDesktop ? 20 : (isTablet ? 18 : 16)),
            
            _buildModulesGrid(),
            
            SizedBox(height: isDesktop ? 32 : (isTablet ? 28 : 24)),

            // Próximos eventos
            _buildUpcomingEvents(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        final childHeight = 120.0;
        final childWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
        final childAspectRatio = childWidth / childHeight;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard('Jugadores Activos', '32', 'En entrenamientos', Icons.groups, WessexColors.deepRoyalBlue),
            _buildStatCard('Asistencia Promedio', '85%', 'Última semana', Icons.check_circle, WessexColors.leafGreen),
            _buildStatCard('Próximos Eventos', '4', 'Este mes', Icons.event, WessexColors.crimsonAlert),
            _buildStatCard('Inscripciones', '8', 'Pendientes', Icons.pending, WessexColors.midnightNavy),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: WessexColors.darkGrape,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: WessexColors.darkGrape.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      children: [
        // Botones principales de asistencia
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Tomar Asistencia',
                'Iniciar nueva sesión',
                Icons.how_to_reg,
                WessexColors.leafGreen,
                () => _navigateToModule('tomar-asistencia'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Ver Historial',
                'Consultar registros',
                Icons.history,
                WessexColors.deepRoyalBlue,
                () => _navigateToModule('historial-asistencia'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Botón adicional de ancho completo
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            'Revisar Inscripciones Pendientes',
            'Gestionar solicitudes de nuevos jugadores',
            Icons.approval,
            WessexColors.crimsonAlert,
            () => _navigateToModule('aprobar-inscripciones'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onPressed) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: WessexColors.darkGrape.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: WessexColors.darkGrape.withOpacity(0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModulesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
        final childHeight = 100.0;
        final childWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
        final childAspectRatio = childWidth / childHeight;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: [
            _buildModuleCard('Eventos', 'Planificar entrenamientos', Icons.event_note, WessexColors.deepRoyalBlue),
            _buildModuleCard('Inscripciones', 'Gestionar alumnos', Icons.school, WessexColors.leafGreen),
            _buildModuleCard('Tienda', 'Venta de productos', Icons.shopping_cart, WessexColors.crimsonAlert),
          ],
        );
      },
    );
  }

  Widget _buildModuleCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToModule(title.toLowerCase()),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: WessexColors.darkGrape,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: WessexColors.darkGrape.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: WessexColors.deepRoyalBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Próximos Entrenamientos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.darkGrape,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEventItem('Entrenamiento Juvenil', 'Hoy 17:00', Icons.sports_rugby),
            _buildEventItem('Entrenamiento Senior', 'Mañana 19:00', Icons.sports_rugby),
            _buildEventItem('Partido vs. Los Leones', 'Sábado 15:00', Icons.sports_score),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _navigateToModule('calendario'),
                style: TextButton.styleFrom(
                  foregroundColor: WessexColors.deepRoyalBlue,
                ),
                child: const Text('Ver calendario completo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(String title, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WessexColors.mistyRoseGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: WessexColors.deepRoyalBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: WessexColors.darkGrape,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: WessexColors.darkGrape.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: WessexColors.darkGrape.withOpacity(0.3)),
        ],
      ),
    );
  }

  void _navigateToModule(String module) {
    switch (module) {
      case 'asistencia':
      case 'tomar-asistencia':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GestionAsistenciaScreen(),
          ),
        );
        break;
      case 'historial-asistencia':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HistorialAsistenciaScreen(),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Módulo $module - En desarrollo'),
            backgroundColor: WessexColors.deepRoyalBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        break;
    }
  }
}