import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import 'voucher_pago_screen.dart';
import 'historial_vouchers_screen.dart';

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
                
                // Sección: Seguimiento de mi Hijo/a
                const WessexSectionTitle(
                  title: 'Seguimiento de mi Hijo/a',
                  subtitle: 'Progreso y desarrollo deportivo',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),
                
                // Botones principales de seguimiento
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Ver Asistencias',
                        'Historial de entrenamientos',
                        Icons.check_circle_outline,
                        WessexColors.leafGreen,
                        () => _showComingSoon(context, 'Ver Asistencias'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Estado de Cuenta',
                        'Ver pagos y deudas',
                        Icons.account_balance_wallet,
                        WessexColors.deepRoyalBlue,
                        () => _showComingSoon(context, 'Estado de Cuenta'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
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
                            builder: (context) => const HistorialVouchersScreen(),
                          ),
                        ),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Sección: Información del Jugador
                const WessexSectionTitle(
                  title: 'Información del Jugador',
                  subtitle: 'Carlos Rodríguez - Sub-16',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildModuleCard(
                        'Entrenamientos',
                        '15/18 este mes',
                        Icons.fitness_center,
                        WessexColors.crimsonAlert,
                        () => _showComingSoon(context, 'Entrenamientos'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModuleCard(
                        'Partidos',
                        '8/12 esta temporada',
                        Icons.sports_rugby,
                        WessexColors.darkGrape,
                        () => _showComingSoon(context, 'Partidos'),
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
                        'Contactar Entrenador',
                        'Enviar mensaje directo',
                        Icons.message,
                        WessexColors.midnightNavy,
                        () => _showComingSoon(context, 'Contactar Entrenador'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModuleCard(
                        'Calendario',
                        'Próximas actividades',
                        Icons.event,
                        WessexColors.leafGreen,
                        () => _showComingSoon(context, 'Calendario'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Próximas actividades
                _buildUpcomingActivitiesCard(isDesktop, isTablet),
                
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

  Widget _buildUpcomingActivitiesCard(bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: WessexColors.deepRoyalBlue,
                size: isDesktop ? 28 : (isTablet ? 24 : 20),
              ),
              SizedBox(width: isDesktop ? 16 : (isTablet ? 14 : 12)),
              Text(
                'Próximas Actividades',
                style: TextStyle(
                  fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                  fontWeight: FontWeight.bold,
                  color: WessexColors.darkGrape,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : (isTablet ? 18 : 16)),
          _buildActivityItem('Entrenamiento Juvenil', 'Hoy 17:00 - Campo Principal', Icons.sports_rugby, isDesktop, isTablet),
          _buildActivityItem('Pago Mensual', 'Vence en 3 días - \$280', Icons.payment, isDesktop, isTablet),
          _buildActivityItem('Torneo Regional', 'Sábado 15:00 - Cancha Sur', Icons.sports_score, isDesktop, isTablet),
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

  Widget _buildActivityItem(String title, String description, IconData icon, bool isDesktop, bool isTablet) {
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
                  description,
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
