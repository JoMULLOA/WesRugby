import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import 'gestion_vouchers_screen.dart';

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
                
                // Botones principales financieros
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Registrar Pago',
                        'Confirmar nuevo pago recibido',
                        Icons.payment,
                        WessexColors.leafGreen,
                        () => _showComingSoon(context, 'Registrar Pago'),
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
                        'Generar Reporte',
                        'Crear informe financiero',
                        Icons.assessment,
                        WessexColors.deepRoyalBlue,
                        () => _showComingSoon(context, 'Generar Reporte'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        'Control de Gastos',
                        'Supervisar egresos del club',
                        Icons.trending_down,
                        WessexColors.midnightNavy,
                        () => _showComingSoon(context, 'Control de Gastos'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Sección: Estadísticas Financieras
                const WessexSectionTitle(
                  title: 'Estadísticas Financieras',
                  subtitle: 'Resumen del estado actual',
                  titleColor: WessexColors.white,
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildModuleCard(
                        'Balance Total',
                        '\$22,140 - Balance actual',
                        Icons.account_balance,
                        WessexColors.crimsonAlert,
                        () => _showComingSoon(context, 'Balance Total'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModuleCard(
                        'Pagos Pendientes',
                        '\$12,800 - 5 pagos pendientes',
                        Icons.pending,
                        WessexColors.darkGrape,
                        () => _showComingSoon(context, 'Pagos Pendientes'),
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
                        'Estado de Cuenta',
                        'Ver balance detallado',
                        Icons.account_balance_wallet,
                        WessexColors.midnightNavy,
                        () => _showComingSoon(context, 'Estado de Cuenta'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModuleCard(
                        'Comprobantes',
                        'Gestión de documentos',
                        Icons.receipt,
                        WessexColors.leafGreen,
                        () => _showComingSoon(context, 'Comprobantes'),
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Transacciones recientes
                _buildTransactionsCard(isDesktop, isTablet),
                
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

  Widget _buildTransactionsCard(bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: WessexColors.deepRoyalBlue,
                size: isDesktop ? 28 : (isTablet ? 24 : 20),
              ),
              SizedBox(width: isDesktop ? 16 : (isTablet ? 14 : 12)),
              Text(
                'Transacciones Recientes',
                style: TextStyle(
                  fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                  fontWeight: FontWeight.bold,
                  color: WessexColors.darkGrape,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : (isTablet ? 18 : 16)),
          _buildTransactionItem('Cuota Mensual - Juan Pérez', '+\$280', Icons.add_circle, isDesktop, isTablet),
          _buildTransactionItem('Pago Equipamiento', '-\$1,200', Icons.remove_circle, isDesktop, isTablet),
          _buildTransactionItem('Cuota Mensual - María García', '+\$280', Icons.add_circle, isDesktop, isTablet),
          SizedBox(height: isDesktop ? 20 : (isTablet ? 18 : 16)),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: WessexColors.deepRoyalBlue,
              ),
              child: Text(
                'Ver historial completo',
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

  Widget _buildTransactionItem(String title, String amount, IconData icon, bool isDesktop, bool isTablet) {
    final isPositive = amount.startsWith('+');
    final color = isPositive ? WessexColors.leafGreen : WessexColors.crimsonAlert;
    
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
            color: color,
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
                  'Hoy 14:30',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                    color: WessexColors.darkGrape.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
