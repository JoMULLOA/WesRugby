import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../config/confGlobal.dart';

class EntrenadorDashboard extends StatefulWidget {
  const EntrenadorDashboard({super.key});

  @override
  State<EntrenadorDashboard> createState() => _EntrenadorDashboardState();
}

class _EntrenadorDashboardState extends State<EntrenadorDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel Entrenador',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.verdePrincipal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.teal.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido Entrenador!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gestión deportiva - Wessex Rugby Club',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Estadísticas deportivas
            const Text(
              'Resumen Deportivo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSportCard(
                  'Jugadores Activos',
                  '32',
                  'En entrenamientos',
                  Icons.groups,
                  Colors.blue,
                ),
                _buildSportCard(
                  'Asistencia Promedio',
                  '85%',
                  'Última semana',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildSportCard(
                  'Próximos Eventos',
                  '4',
                  'Este mes',
                  Icons.event,
                  Colors.orange,
                ),
                _buildSportCard(
                  'Inscripciones',
                  '8',
                  'Pendientes aprobación',
                  Icons.pending,
                  Colors.red,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Módulos deportivos
            const Text(
              'Gestión Deportiva',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                _buildModuleCard(
                  'Inscripciones',
                  'Gestionar alumnos',
                  Icons.school,
                  AppColors.verdePrincipal,
                  () => _navigateToModule('inscripciones'),
                ),
                _buildModuleCard(
                  'Asistencia',
                  'Control de presencia',
                  Icons.check_circle_outline,
                  Colors.teal,
                  () => _navigateToModule('asistencia'),
                ),
                _buildModuleCard(
                  'Eventos',
                  'Planificar entrenamientos',
                  Icons.event_note,
                  Colors.deepOrange,
                  () => _navigateToModule('eventos'),
                ),
                _buildModuleCard(
                  'Tienda',
                  'Venta de productos',
                  Icons.shopping_cart,
                  Colors.cyan,
                  () => _navigateToModule('tienda'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Acciones rápidas del entrenador
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateToModule('tomar-asistencia'),
                              icon: const Icon(Icons.how_to_reg),
                              label: const Text('Tomar Asistencia'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateToModule('crear-evento'),
                              icon: const Icon(Icons.add_circle),
                              label: const Text('Crear Evento'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.verdePrincipal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToModule('aprobar-inscripciones'),
                          icon: const Icon(Icons.approval),
                          label: const Text('Revisar Inscripciones Pendientes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Próximos eventos
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, color: Colors.teal, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Próximos Entrenamientos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEventItem('Entrenamiento Juvenil', 'Hoy 17:00', Icons.sports_rugby),
                  _buildEventItem('Entrenamiento Senior', 'Mañana 19:00', Icons.sports_rugby),
                  _buildEventItem('Partido vs. Los Leones', 'Sábado 15:00', Icons.sports_score),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _navigateToModule('calendario'),
                      child: const Text('Ver calendario completo'),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSportCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventItem(String title, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  void _navigateToModule(String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Módulo $module - En desarrollo'),
        backgroundColor: AppColors.verdePrincipal,
      ),
    );
    
    // TODO: Implementar navegación a módulos específicos
  }
}
