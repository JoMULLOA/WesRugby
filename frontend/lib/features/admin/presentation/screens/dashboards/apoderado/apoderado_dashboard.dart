import 'package:flutter/material.dart';
import 'package:wesrugby/shared/widgets/navigation/custom_drawer.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/features/admin/presentation/screens/pagos/voucher/voucher_pago_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/pagos/historial/historial_vouchers_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/justificantes/detalle/justificante_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/justificantes/historial/historial_justificantes_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/actas/visualizar/visualizar_actas_reunion_screen.dart';

class ApoderadoDashboard extends StatelessWidget {
  const ApoderadoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Panel Apoderado - Wessex Rugby',
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

                // Sección: Gestión de Pagos
                const WessexSectionTitle(
                  title: 'Gestión de Pagos',
                  subtitle: 'Vouchers y comprobantes de mensualidad',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Historial',
                        'Ver vouchers enviados',
                        Icons.history,
                        WessexColors.leafGreen,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const HistorialVouchersScreen(),
                          ),
                        ),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sección: Justificantes de Inasistencia
                const WessexSectionTitle(
                  title: 'Justificantes de Inasistencia',
                  subtitle: 'Justificar ausencias a entrenamientos o eventos',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Historial Justificantes',
                        'Ver justificantes enviados',
                        Icons.assignment_turned_in,
                        WessexColors.leafGreen,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const HistorialJustificantesScreen(),
                          ),
                        ),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                const WessexSectionTitle(
                  title: 'Documentos del Club',
                  subtitle: 'Material compartido con apoderados',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),

                _buildActionCard(
                  'Actas de Reunión',
                  'Ver actas publicadas',
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

}
