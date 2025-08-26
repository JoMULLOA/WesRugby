import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../config/confGlobal.dart';

class TesoreraDashboard extends StatefulWidget {
  const TesoreraDashboard({super.key});

  @override
  State<TesoreraDashboard> createState() => _TesoreraDashboardState();
}

class _TesoreraDashboardState extends State<TesoreraDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel Tesorera',
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
                  colors: [Colors.indigo, Colors.indigo.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenida Tesorera!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gestión financiera - Wessex Rugby Club',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Resumen financiero
            const Text(
              'Resumen Financiero',
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
                _buildFinancialCard(
                  'Ingresos del Mes',
                  '\$1.250.000',
                  'Total recaudado',
                  Icons.trending_up,
                  Colors.green,
                  isPositive: true,
                ),
                _buildFinancialCard(
                  'Comprobantes',
                  '23',
                  'Pendientes validación',
                  Icons.receipt_long,
                  Colors.orange,
                  isPositive: false,
                ),
                _buildFinancialCard(
                  'Inventario',
                  '\$350.000',
                  'Valor total productos',
                  Icons.inventory,
                  Colors.blue,
                  isPositive: true,
                ),
                _buildFinancialCard(
                  'Stock Bajo',
                  '5',
                  'Productos por reponer',
                  Icons.warning,
                  Colors.red,
                  isPositive: false,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Módulos financieros
            const Text(
              'Gestión Financiera',
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
                  'Planes de Pago',
                  'Gestionar mensualidades',
                  Icons.payment,
                  Colors.indigo,
                  () => _navigateToModule('planes-pago'),
                ),
                _buildModuleCard(
                  'Comprobantes',
                  'Validar pagos',
                  Icons.receipt,
                  Colors.amber,
                  () => _navigateToModule('comprobantes'),
                ),
                _buildModuleCard(
                  'Productos',
                  'Inventario y precios',
                  Icons.store,
                  Colors.pink,
                  () => _navigateToModule('productos'),
                ),
                _buildModuleCard(
                  'Ventas',
                  'Registro de ventas',
                  Icons.shopping_cart,
                  Colors.cyan,
                  () => _navigateToModule('ventas'),
                ),
                _buildModuleCard(
                  'Estadísticas',
                  'Reportes financieros',
                  Icons.analytics,
                  Colors.purple,
                  () => _navigateToModule('estadisticas'),
                ),
                _buildModuleCard(
                  'Informes',
                  'Reportes contables',
                  Icons.assessment,
                  Colors.teal,
                  () => _navigateToModule('informes'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Acciones rápidas
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToModule('validar-comprobantes'),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Validar Comprobantes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToModule('generar-reporte'),
                          icon: const Icon(Icons.file_download),
                          label: const Text('Generar Reporte'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
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
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(String title, String value, String subtitle, IconData icon, Color color, {required bool isPositive}) {
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
              Icon(
                isPositive ? Icons.trending_up : Icons.priority_high,
                color: isPositive ? Colors.green : Colors.orange,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
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
