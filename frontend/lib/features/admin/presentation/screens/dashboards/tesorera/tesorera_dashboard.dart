import 'package:flutter/material.dart';
import 'package:wesrugby/shared/widgets/navigation/custom_drawer.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/features/admin/presentation/screens/pagos/gestion/gestion_vouchers_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/pagos/resumen/pagos_resumen_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/actas/visualizar/visualizar_actas_reunion_screen.dart';
import 'package:wesrugby/features/inventory/presentation/screens/management/inventory_management_screen.dart';

class TesoreraDashboard extends StatelessWidget {
  const TesoreraDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Panel Tesorera - Wessex Rugby',
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
                              WessexColors.crimsonAlert,
                              WessexColors.deepRoyalBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
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
                              '¡Bienvenido Tesorera!',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: isDesktop ? 28 : (isTablet ? 24 : 22),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Panel de gestión financiera\nWessex Rugby Club',
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

                // Sección: Gestión Financiera
                const WessexSectionTitle(
                  title: 'Gestión Financiera',
                  subtitle: 'Control de ingresos y pagos',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),

                _buildActionCard(
                  'Gestión de Vouchers',
                  'Aprobar pagos de apoderados',
                  Icons.receipt_long,
                  WessexColors.crimsonAlert,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GestionVouchersScreen(),
                    ),
                  ),
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  'Resumen de Pagos',
                  'Ver matrícula y mensualidades por estudiante',
                  Icons.table_chart,
                  WessexColors.leafGreen,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PagosResumenScreen(),
                    ),
                  ),
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),

                const SizedBox(height: 16),

                _buildActionCard(
                  'Inventario y Ventas',
                  'Visualizar ventas y administrar productos',
                  Icons.store,
                  WessexColors.primaryAction,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventoryManagementScreen(),
                    ),
                  ),
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),

                const SizedBox(height: 32),

                const WessexSectionTitle(
                  title: 'Documentos del Club',
                  subtitle: 'Material accesible para tesorería',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),

                _buildActionCard(
                  'Actas de Reunión',
                  'Ver actas del club',
                  Icons.description,
                  WessexColors.deepRoyalBlue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const VisualizarActasReunionScreen(),
                    ),
                  ),
                  isDesktop: isDesktop,
                  isTablet: isTablet,
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
                color: WessexColors.darkGrape.withOpacity(0.3),
                size: isDesktop ? 20 : (isTablet ? 18 : 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
