import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../config/colors.dart';

class DirectivaDashboard extends StatefulWidget {
  const DirectivaDashboard({super.key});

  @override
  State<DirectivaDashboard> createState() => _DirectivaDashboardState();
}

class _DirectivaDashboardState extends State<DirectivaDashboard> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;
    
    return Scaffold(
      backgroundColor: WessexColors.mistyRoseGray,
      appBar: AppBar(
        title: Text(
          'Panel Directiva - Wessex Rugby',
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Header Welcome Card - Fixed height
              Container(
                width: double.infinity,
                height: constraints.maxHeight * 0.25, // 25% del alto disponible
                margin: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
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
                    // Icon
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 16 : 12)),
                      decoration: BoxDecoration(
                        color: WessexColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.sports_rugby,
                        color: WessexColors.white,
                        size: isDesktop ? 48 : (isTablet ? 40 : 32),
                      ),
                    ),
                    SizedBox(width: isDesktop ? 24 : (isTablet ? 20 : 16)),
                    
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¡Bienvenido/a!',
                            style: TextStyle(
                              color: WessexColors.white,
                              fontSize: isDesktop ? 28 : (isTablet ? 24 : 22),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Panel de administración completo\nWessex Rugby Club',
                            style: TextStyle(
                              color: WessexColors.white.withOpacity(0.9),
                              fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Modules Grid - Takes remaining space
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: isDesktop ? 24 : (isTablet ? 20 : 16),
                    right: isDesktop ? 24 : (isTablet ? 20 : 16),
                    bottom: isDesktop ? 24 : (isTablet ? 20 : 16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title
                      Padding(
                        padding: EdgeInsets.only(
                          left: 8,
                          bottom: isDesktop ? 16 : (isTablet ? 14 : 12),
                        ),
                        child: Text(
                          'Módulos de Gestión',
                          style: TextStyle(
                            fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
                            fontWeight: FontWeight.bold,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                      ),
                      
                      // Modules grid - Fills remaining space, no scroll
                      Expanded(
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(), // Sin scroll
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _getCrossAxisCount(constraints.maxWidth),
                            crossAxisSpacing: isDesktop ? 16 : (isTablet ? 14 : 12),
                            mainAxisSpacing: isDesktop ? 16 : (isTablet ? 14 : 12),
                            childAspectRatio: _getChildAspectRatio(constraints.maxWidth),
                          ),
                          itemCount: 8,
                          itemBuilder: (context, index) {
                            final modules = _getModulesData();
                            final module = modules[index];
                            return _buildModuleCard(
                              module['title'] as String,
                              module['description'] as String,
                              module['icon'] as IconData,
                              module['color'] as Color,
                              () => _navigateToModule(module['module'] as String),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper methods for responsive grid
  int _getCrossAxisCount(double width) {
    if (width > 1200) return 4; // Desktop: 4 columns
    if (width > 800) return 3;  // Tablet large: 3 columns  
    if (width > 600) return 2;  // Tablet: 2 columns
    return 2;                   // Mobile: 2 columns
  }

  double _getChildAspectRatio(double width) {
    if (width > 1200) return 1.2;  // Desktop: wider cards
    if (width > 800) return 1.1;   // Tablet large: slightly wider
    if (width > 600) return 1.0;   // Tablet: square-ish
    return 0.9;                    // Mobile: slightly taller
  }

  List<Map<String, dynamic>> _getModulesData() {
    return [
      {
        'title': 'Inscripciones',
        'description': 'Gestionar alumnos y matrículas',
        'icon': Icons.school,
        'color': WessexColors.leafGreen,
        'module': 'inscripciones',
      },
      {
        'title': 'Planes de Pago',
        'description': 'Configurar mensualidades',
        'icon': Icons.payment,
        'color': WessexColors.crimsonAlert,
        'module': 'planes-pago',
      },
      {
        'title': 'Asistencia',
        'description': 'Control de asistencia',
        'icon': Icons.check_circle_outline,
        'color': WessexColors.deepRoyalBlue,
        'module': 'asistencia',
      },
      {
        'title': 'Comprobantes',
        'description': 'Gestión de pagos',
        'icon': Icons.receipt,
        'color': WessexColors.midnightNavy,
        'module': 'comprobantes',
      },
      {
        'title': 'Eventos',
        'description': 'Eventos deportivos',
        'icon': Icons.event_note,
        'color': WessexColors.leafGreen,
        'module': 'eventos',
      },
      {
        'title': 'Productos',
        'description': 'Catálogo de productos',
        'icon': Icons.store,
        'color': WessexColors.deepRoyalBlue,
        'module': 'productos',
      },
      {
        'title': 'Ventas',
        'description': 'Gestión de ventas',
        'icon': Icons.shopping_cart,
        'color': WessexColors.crimsonAlert,
        'module': 'ventas',
      },
      {
        'title': 'Directiva',
        'description': 'Gestión directiva',
        'icon': Icons.admin_panel_settings,
        'color': WessexColors.midnightNavy,
        'module': 'directiva',
      },
    ];
  }

  Widget _buildModuleCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;
    
    return Card(
      elevation: 6,
      shadowColor: WessexColors.darkGrape.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 16 : 12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 14 : (isTablet ? 12 : 10)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: isDesktop ? 32 : (isTablet ? 28 : 24),
                  color: color,
                ),
              ),
              SizedBox(height: isDesktop ? 14 : (isTablet ? 12 : 10)),
              Text(
                title,
                style: TextStyle(
                  fontSize: isDesktop ? 16 : (isTablet ? 14 : 13),
                  fontWeight: FontWeight.bold,
                  color: WessexColors.darkGrape,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: isDesktop ? 12 : (isTablet ? 11 : 10),
                  color: WessexColors.darkGrape.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
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

  void _navigateToModule(String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Módulo $module - En desarrollo'),
        backgroundColor: WessexColors.deepRoyalBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    
    // TODO: Implementar navegación a módulos específicos
    // switch (module) {
    //   case 'inscripciones':
    //     Navigator.push(context, MaterialPageRoute(builder: (_) => InscripcionesScreen()));
    //     break;
    //   case 'planes-pago':
    //     Navigator.push(context, MaterialPageRoute(builder: (_) => PlanesPagoScreen()));
    //     break;
    //   // ... etc
    // }
  }
}
