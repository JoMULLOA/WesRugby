import 'package:flutter/material.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import '../services/voucher_service.dart';

class HistorialVouchersScreen extends StatelessWidget {
  const HistorialVouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VoucherService voucherService = VoucherService();
    final String usuarioActual = "Carlos Rodríguez"; // Simular usuario logueado
    
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Historial de Pagos',
        elevation: 2,
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header informativo
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.history,
                          color: WessexColors.deepRoyalBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Historial de Vouchers',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Todos tus vouchers de pago enviados y su estado',
                              style: TextStyle(
                                color: WessexColors.darkGrape.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de vouchers
                ..._buildVouchersList(voucherService, usuarioActual, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVouchersList(VoucherService voucherService, String usuarioActual, BuildContext context) {
    final vouchers = voucherService.getVouchersByUser(usuarioActual);

    if (vouchers.isEmpty) {
      return [
        WessexCard(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: WessexColors.darkGrape.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No has enviado vouchers',
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cuando envíes vouchers de pago, aparecerán aquí con su estado de aprobación.',
                style: TextStyle(
                  color: WessexColors.darkGrape.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.upload_file, size: 16),
                label: Text('Subir Primer Voucher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.leafGreen,
                  foregroundColor: WessexColors.white,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return vouchers.map((voucher) => _buildVoucherCard(voucher)).toList();
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final estado = voucher['estado'] as String;
    final isAprobado = estado == 'Aprobado';
    final isPendiente = estado == 'Pendiente';
    
    Color estadoColor;
    IconData estadoIcon;
    
    if (isAprobado) {
      estadoColor = WessexColors.leafGreen;
      estadoIcon = Icons.check_circle;
    } else if (isPendiente) {
      estadoColor = WessexColors.crimsonAlert;
      estadoIcon = Icons.pending;
    } else {
      estadoColor = WessexColors.darkGrape;
      estadoIcon = Icons.help_outline;
    }

    return WessexCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del voucher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                voucher['mes'],
                style: TextStyle(
                  color: WessexColors.darkGrape,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      estadoIcon,
                      color: estadoColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      estado,
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Detalles del pago
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Monto',
                  '\$${voucher['monto'].toStringAsFixed(2)}',
                  Icons.attach_money,
                  WessexColors.leafGreen,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Fecha',
                  voucher['fecha'],
                  Icons.calendar_today,
                  WessexColors.deepRoyalBlue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Método',
                  voucher['metodo'],
                  Icons.payment,
                  WessexColors.crimsonAlert,
                ),
              ),
              if (voucher['comprobante'] != null)
                Expanded(
                  child: _buildDetailItem(
                    'Comprobante',
                    voucher['comprobante'],
                    Icons.receipt,
                    WessexColors.darkGrape,
                  ),
                ),
            ],
          ),
          
          if (isAprobado && voucher['comprobante'] != null) ...[
            const SizedBox(height: 16),
            const Divider(color: WessexColors.mistyRoseGray),
            const SizedBox(height: 12),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewComprobante(voucher['comprobante']),
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text('Ver Comprobante'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WessexColors.deepRoyalBlue,
                      side: BorderSide(color: WessexColors.deepRoyalBlue),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadComprobante(voucher['comprobante']),
                    icon: Icon(Icons.download, size: 16),
                    label: Text('Descargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WessexColors.leafGreen,
                      foregroundColor: WessexColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: WessexColors.darkGrape.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: WessexColors.darkGrape,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _viewComprobante(String comprobante) {
    // TODO: Implementar visualización del comprobante
    print('Ver comprobante: $comprobante');
  }

  void _downloadComprobante(String comprobante) {
    // TODO: Implementar descarga del comprobante
    print('Descargar comprobante: $comprobante');
  }
}