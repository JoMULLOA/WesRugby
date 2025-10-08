import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import '../services/voucher_service.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show Blob, Url, AnchorElement, IFrameElement;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

class HistorialVouchersScreen extends StatefulWidget {
  const HistorialVouchersScreen({super.key});

  @override
  State<HistorialVouchersScreen> createState() => _HistorialVouchersScreenState();
}

class _HistorialVouchersScreenState extends State<HistorialVouchersScreen> {
  final VoucherService _voucherService = VoucherService();
  final String _usuarioActual = "Carlos Rodríguez"; // Simular usuario logueado
  
  String _filtroMes = 'Todos';
  String _filtroEstado = 'Todos';
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Historial de Vouchers',
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
                _buildStatsHeader(isDesktop, isTablet),
                
                const SizedBox(height: 24),
                
                // Filtros
                _buildFiltersSection(isDesktop, isTablet),
                
                const SizedBox(height: 24),
                
                // Lista de vouchers
                _buildVouchersList(isDesktop, isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(bool isDesktop, bool isTablet) {
    final vouchers = _voucherService.getVouchersByUser(_usuarioActual);
    final stats = _getStatsForUser(vouchers);

    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      'Mi Historial de Vouchers',
                      style: TextStyle(
                        color: WessexColors.darkGrape,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Revisa el estado de tus vouchers de pago enviados',
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
          
          const SizedBox(height: 20),
          
          // Estadísticas rápidas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats['total'].toString(),
                  Icons.receipt_long,
                  WessexColors.deepRoyalBlue,
                  isDesktop,
                  isTablet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  stats['pendientes'].toString(),
                  Icons.pending,
                  WessexColors.crimsonAlert,
                  isDesktop,
                  isTablet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Aprobados',
                  stats['aprobados'].toString(),
                  Icons.check_circle,
                  WessexColors.leafGreen,
                  isDesktop,
                  isTablet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rechazados',
                  stats['rechazados'].toString(),
                  Icons.cancel,
                  WessexColors.darkGrape,
                  isDesktop,
                  isTablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDesktop,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 14 : 12)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isDesktop ? 24 : (isTablet ? 22 : 20),
          ),
          SizedBox(height: isDesktop ? 8 : (isTablet ? 6 : 4)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: WessexColors.darkGrape.withOpacity(0.7),
              fontSize: isDesktop ? 12 : (isTablet ? 11 : 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(bool isDesktop, bool isTablet) {
    final vouchers = _voucherService.getVouchersByUser(_usuarioActual);
    final mesesDisponibles = _getMesesDisponibles(vouchers);

    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (isDesktop) ...[
            // Filtros en fila para desktop
            Row(
              children: [
                Expanded(
                  child: _buildMesDropdown(mesesDisponibles),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEstadoDropdown(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildSearchField(),
                ),
              ],
            ),
          ] else ...[
            // Filtros en columna para móvil/tablet
            _buildMesDropdown(mesesDisponibles),
            const SizedBox(height: 12),
            _buildEstadoDropdown(),
            const SizedBox(height: 12),
            _buildSearchField(),
          ],
        ],
      ),
    );
  }

  Widget _buildMesDropdown(List<String> meses) {
    return DropdownButtonFormField<String>(
      value: _filtroMes,
      decoration: InputDecoration(
        labelText: 'Filtrar por mes',
        prefixIcon: Icon(Icons.calendar_month, color: WessexColors.deepRoyalBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: meses.map((mes) {
        return DropdownMenuItem(
          value: mes,
          child: Text(mes),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _filtroMes = value!;
        });
      },
    );
  }

  Widget _buildEstadoDropdown() {
    const estados = ['Todos', 'Pendiente', 'Aprobado', 'Rechazado'];
    
    return DropdownButtonFormField<String>(
      value: _filtroEstado,
      decoration: InputDecoration(
        labelText: 'Filtrar por estado',
        prefixIcon: Icon(Icons.filter_list, color: WessexColors.deepRoyalBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: estados.map((estado) {
        IconData icon;
        Color color;
        
        switch (estado) {
          case 'Pendiente':
            icon = Icons.pending;
            color = WessexColors.crimsonAlert;
            break;
          case 'Aprobado':
            icon = Icons.check_circle;
            color = WessexColors.leafGreen;
            break;
          case 'Rechazado':
            icon = Icons.cancel;
            color = WessexColors.darkGrape;
            break;
          default:
            icon = Icons.filter_list;
            color = WessexColors.deepRoyalBlue;
        }
        
        return DropdownMenuItem(
          value: estado,
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(estado),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _filtroEstado = value!;
        });
      },
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Buscar por ID o descripción',
        prefixIcon: Icon(Icons.search, color: WessexColors.deepRoyalBlue),
        suffixIcon: _searchText.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchText = '';
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchText = value;
        });
      },
    );
  }

  Widget _buildVouchersList(bool isDesktop, bool isTablet) {
    final vouchers = _getFilteredVouchers();

    if (vouchers.isEmpty) {
      return WessexCard(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: WessexColors.darkGrape.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _hasAnyVouchers() ? 'No se encontraron vouchers' : 'No has enviado vouchers',
              style: TextStyle(
                color: WessexColors.darkGrape,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasAnyVouchers()
                  ? 'Intenta ajustar los filtros para encontrar los vouchers que buscas.'
                  : 'Cuando envíes vouchers de pago, aparecerán aquí con su estado de aprobación.',
              style: TextStyle(
                color: WessexColors.darkGrape.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_hasAnyVouchers()) ...[
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
          ],
        ),
      );
    }

    return Column(
      children: vouchers.map((voucher) => _buildVoucherCard(voucher, isDesktop, isTablet)).toList(),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher, bool isDesktop, bool isTablet) {
    final estado = voucher['estado'] as String;
    
    Color estadoColor;
    IconData estadoIcon;
    
    switch (estado) {
      case 'Aprobado':
        estadoColor = WessexColors.leafGreen;
        estadoIcon = Icons.check_circle;
        break;
      case 'Pendiente':
        estadoColor = WessexColors.crimsonAlert;
        estadoIcon = Icons.pending;
        break;
      case 'Rechazado':
        estadoColor = WessexColors.darkGrape;
        estadoIcon = Icons.cancel;
        break;
      default:
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voucher ${voucher['id']}',
                      style: TextStyle(
                        color: WessexColors.darkGrape,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mes: ${voucher['mes']}',
                      style: TextStyle(
                        color: WessexColors.deepRoyalBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
          
          // Detalles del voucher
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
                  'Método',
                  voucher['metodoPago'],
                  Icons.payment,
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
                  'Fecha Envío',
                  voucher['fechaEnvio'],
                  Icons.schedule,
                  WessexColors.crimsonAlert,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Archivo',
                  voucher['archivo'],
                  Icons.attachment,
                  WessexColors.darkGrape,
                ),
              ),
            ],
          ),
          
          if (voucher['descripcion'] != null && voucher['descripcion'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Descripción: ${voucher['descripcion']}',
              style: TextStyle(
                color: WessexColors.darkGrape.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          // Mostrar motivo de rechazo si existe
          if (estado == 'Rechazado' && voucher['motivoRechazo'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WessexColors.crimsonAlert.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WessexColors.crimsonAlert.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: WessexColors.crimsonAlert,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Motivo del rechazo:',
                          style: TextStyle(
                            color: WessexColors.crimsonAlert,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          voucher['motivoRechazo'],
                          style: TextStyle(
                            color: WessexColors.crimsonAlert,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          const Divider(color: WessexColors.mistyRoseGray),
          const SizedBox(height: 12),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewVoucher(voucher),
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('Ver Voucher'),
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
                  onPressed: () => _downloadVoucher(voucher),
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

  // Métodos auxiliares
  Map<String, int> _getStatsForUser(List<Map<String, dynamic>> vouchers) {
    int total = vouchers.length;
    int pendientes = vouchers.where((v) => v['estado'] == 'Pendiente').length;
    int aprobados = vouchers.where((v) => v['estado'] == 'Aprobado').length;
    int rechazados = vouchers.where((v) => v['estado'] == 'Rechazado').length;
    
    return {
      'total': total,
      'pendientes': pendientes,
      'aprobados': aprobados,
      'rechazados': rechazados,
    };
  }

  List<String> _getMesesDisponibles(List<Map<String, dynamic>> vouchers) {
    Set<String> meses = vouchers.map((v) => v['mes'] as String).toSet();
    List<String> mesesOrdenados = ['Todos', ...meses.toList()];
    
    // Ordenar meses (excepto 'Todos')
    final mesesEnOrden = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    mesesOrdenados.removeWhere((m) => m == 'Todos');
    mesesOrdenados.sort((a, b) {
      int indexA = mesesEnOrden.indexOf(a);
      int indexB = mesesEnOrden.indexOf(b);
      if (indexA == -1) indexA = 999;
      if (indexB == -1) indexB = 999;
      return indexA.compareTo(indexB);
    });
    
    return ['Todos', ...mesesOrdenados];
  }

  List<Map<String, dynamic>> _getFilteredVouchers() {
    List<Map<String, dynamic>> vouchers = _voucherService.getVouchersByUser(_usuarioActual);
    
    return vouchers.where((voucher) {
      bool matchesMes = _filtroMes == 'Todos' || voucher['mes'] == _filtroMes;
      bool matchesEstado = _filtroEstado == 'Todos' || voucher['estado'] == _filtroEstado;
      bool matchesSearch = _searchText.isEmpty || 
                          voucher['id'].toLowerCase().contains(_searchText.toLowerCase()) ||
                          (voucher['descripcion'] ?? '').toLowerCase().contains(_searchText.toLowerCase());
      
      return matchesMes && matchesEstado && matchesSearch;
    }).toList();
  }

  bool _hasAnyVouchers() {
    return _voucherService.getVouchersByUser(_usuarioActual).isNotEmpty;
  }

  // Funciones de acción
  void _viewVoucher(Map<String, dynamic> voucher) {
    if (voucher['archivoData'] != null) {
      String fileName = voucher['archivo'] as String;
      if (fileName.toLowerCase().endsWith('.pdf')) {
        _showPdfDialog(voucher);
      } else {
        _showImageDialog(voucher);
      }
    } else {
      _showFileInfoDialog(voucher);
    }
  }

  void _downloadVoucher(Map<String, dynamic> voucher) {
    try {
      if (kIsWeb && voucher['archivoData'] != null) {
        final blob = html.Blob([voucher['archivoData']]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        html.AnchorElement(href: url)
          ..setAttribute("download", voucher['archivo'])
          ..click();
        
        html.Url.revokeObjectUrl(url);
        
        _showSnackBar('Archivo descargado: ${voucher['archivo']}', WessexColors.leafGreen);
      } else {
        _showSnackBar('Descarga iniciada: ${voucher['archivo']}', WessexColors.leafGreen);
      }
      
    } catch (e) {
      print('Error al descargar archivo: $e');
      _showSnackBar('Error al descargar archivo', WessexColors.crimsonAlert);
    }
  }

  // Diálogos de visualización (reutilizando del gestion_vouchers_screen.dart)
  void _showPdfDialog(Map<String, dynamic> voucher) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 800,
          height: 700,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mi Voucher PDF - ${voucher['mes']}',
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Archivo: ${voucher['archivo']}',
                          style: TextStyle(
                            color: WessexColors.darkGrape.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _downloadVoucher(voucher),
                        icon: Icon(Icons.download),
                        tooltip: 'Descargar PDF',
                        style: IconButton.styleFrom(
                          backgroundColor: WessexColors.deepRoyalBlue.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: WessexColors.mistyRoseGray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WessexColors.mistyRoseGray),
                  ),
                  child: kIsWeb 
                    ? _buildPdfViewer(voucher)
                    : _buildPdfPlaceholder(voucher),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer(Map<String, dynamic> voucher) {
    try {
      if (voucher['archivoData'] != null) {
        final blob = html.Blob([voucher['archivoData']], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        final String viewId = 'pdf-viewer-${voucher['id']}-historial';
        
        ui_web.platformViewRegistry.registerViewFactory(
          viewId,
          (int viewId) {
            final iframe = html.IFrameElement()
              ..src = url
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%';
            return iframe;
          },
        );
        
        return HtmlElementView(viewType: viewId);
      } else {
        return _buildPdfPlaceholder(voucher);
      }
    } catch (e) {
      print('Error creando visor PDF: $e');
      return _buildPdfPlaceholder(voucher);
    }
  }

  Widget _buildPdfPlaceholder(Map<String, dynamic> voucher) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.picture_as_pdf,
          size: 64,
          color: WessexColors.crimsonAlert,
        ),
        const SizedBox(height: 16),
        Text(
          'Archivo PDF',
          style: TextStyle(
            color: WessexColors.darkGrape,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          voucher['archivo'],
          style: TextStyle(
            color: WessexColors.darkGrape.withOpacity(0.7),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        if (voucher['archivoData'] != null) ...[
          const SizedBox(height: 16),
          Text(
            'Tamaño: ${(voucher['archivoData'].length / 1024).toStringAsFixed(1)} KB',
            style: TextStyle(
              color: WessexColors.deepRoyalBlue,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _downloadVoucher(voucher),
          icon: Icon(Icons.download),
          label: Text('Descargar PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: WessexColors.deepRoyalBlue,
            foregroundColor: WessexColors.white,
          ),
        ),
      ],
    );
  }

  void _showImageDialog(Map<String, dynamic> voucher) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 800,
          height: 700,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mi Voucher - ${voucher['mes']}',
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Archivo: ${voucher['archivo']}',
                          style: TextStyle(
                            color: WessexColors.darkGrape.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _downloadVoucher(voucher),
                        icon: Icon(Icons.download),
                        tooltip: 'Descargar imagen',
                        style: IconButton.styleFrom(
                          backgroundColor: WessexColors.deepRoyalBlue.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: WessexColors.mistyRoseGray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WessexColors.mistyRoseGray),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      voucher['archivoData'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: WessexColors.crimsonAlert,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error al cargar la imagen',
                                style: TextStyle(
                                  color: WessexColors.darkGrape,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'El archivo podría estar dañado',
                                style: TextStyle(
                                  color: WessexColors.darkGrape.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFileInfoDialog(Map<String, dynamic> voucher) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Información del Voucher',
                    style: TextStyle(
                      color: WessexColors.darkGrape,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: WessexColors.mistyRoseGray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        size: 64,
                        color: WessexColors.deepRoyalBlue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Archivo: ${voucher['archivo']}',
                        style: TextStyle(
                          color: WessexColors.darkGrape,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${voucher['id']} - ${voucher['mes']}',
                        style: TextStyle(
                          color: WessexColors.darkGrape.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WessexColors.crimsonAlert.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Vista previa no disponible. Solo se guardó el nombre del archivo.',
                          style: TextStyle(
                            color: WessexColors.crimsonAlert,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}