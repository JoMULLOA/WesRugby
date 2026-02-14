import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/voucher_service.dart';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'package:wesrugby/core/utils/html.dart' as html;
// ignore: avoid_web_libraries_in_flutter
import 'package:wesrugby/core/utils/ui_web.dart' as ui_web;

class GestionVouchersScreen extends StatefulWidget {
  const GestionVouchersScreen({super.key});

  @override
  State<GestionVouchersScreen> createState() => _GestionVouchersScreenState();
}

class _GestionVouchersScreenState extends State<GestionVouchersScreen> {
  String _filtroUsuario = 'Todos';
  String _filtroEstado = 'Todos';
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  final VoucherService _voucherService = VoucherService();
  bool _cargando = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() { _cargando = true; _error = false; });
    final ok = await _voucherService.cargarListadoTesorera();
    if (!mounted) return;
    setState(() { _cargando = false; _error = !ok; });
  }

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
        title: 'Gestión de Vouchers - Tesorería',
        elevation: 2,
      ),
      body: WessexBackground(
        child: SafeArea(
          child: _cargando
              ? Center(child: CircularProgressIndicator(color: WessexColors.deepRoyalBlue))
              : _error
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: WessexColors.crimsonAlert),
                          const SizedBox(height: 12),
                          const Text('Error al cargar vouchers'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _cargarDatos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con estadísticas
                _buildStatsHeader(isDesktop, isTablet),

                const SizedBox(height: 24),

                // Filtros y búsqueda
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
                  Icons.receipt_long,
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
                      'Gestión de Vouchers de Pago - Tesorería',
                      style: TextStyle(
                        color: WessexColors.darkGrape,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Revisa, valida y aprueba los vouchers de pago de los apoderados',
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
                  '${_voucherService.getStats()['total']}',
                  WessexColors.deepRoyalBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  '${_voucherService.getStats()['pendientes']}',
                  WessexColors.crimsonAlert,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Aprobados',
                  '${_voucherService.getStats()['aprobados']}',
                  WessexColors.leafGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(bool isDesktop, bool isTablet) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros y Búsqueda',
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          if (isDesktop) ...[
            // Layout horizontal para desktop
            Row(
              children: [
                Expanded(flex: 2, child: _buildSearchField()),
                const SizedBox(width: 16),
                Expanded(child: _buildUserFilter()),
                const SizedBox(width: 16),
                Expanded(child: _buildStatusFilter()),
              ],
            ),
          ] else ...[
            // Layout vertical para móvil/tablet
            _buildSearchField(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildUserFilter()),
                const SizedBox(width: 12),
                Expanded(child: _buildStatusFilter()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre de usuario...',
        prefixIcon: Icon(Icons.search, color: WessexColors.deepRoyalBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: WessexColors.mistyRoseGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: WessexColors.deepRoyalBlue),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchText = value;
        });
      },
    );
  }

  Widget _buildUserFilter() {
    final usuarios = _voucherService.getUniqueUsers();

    return DropdownButtonFormField<String>(
      value: _filtroUsuario,
      decoration: InputDecoration(
        labelText: 'Filtrar por Usuario',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items:
          usuarios.map((usuario) {
            return DropdownMenuItem(value: usuario, child: Text(usuario));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _filtroUsuario = value!;
        });
      },
    );
  }

  Widget _buildStatusFilter() {
    final estados = ['Todos', 'Pendiente', 'Aprobado', 'Rechazado'];

    return DropdownButtonFormField<String>(
      value: _filtroEstado,
      decoration: InputDecoration(
        labelText: 'Filtrar por Estado',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items:
          estados.map((estado) {
            return DropdownMenuItem(value: estado, child: Text(estado));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _filtroEstado = value!;
        });
      },
    );
  }

  Widget _buildVouchersList(bool isDesktop, bool isTablet) {
    final vouchers = _getFilteredVouchers();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vouchers Recibidos (${vouchers.length})',
          style: TextStyle(
            color: WessexColors.darkGrape,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (vouchers.isEmpty) ...[
          // Estado vacío
          WessexCard(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: WessexColors.darkGrape.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay vouchers recibidos',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los vouchers enviados por los apoderados aparecerán aquí para su revisión y validación por tesorería.',
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
                    color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: WessexColors.deepRoyalBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Los apoderados pueden enviar vouchers desde su panel. Como tesorería, aquí puedes revisarlos, aprobarlos o rechazarlos.',
                          style: TextStyle(
                            color: WessexColors.deepRoyalBlue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Lista de vouchers cuando hay datos
          ...vouchers
              .map((voucher) => _buildVoucherCard(voucher, isDesktop, isTablet))
              .toList(),
        ],
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredVouchers() {
    return _voucherService.getFilteredVouchers(
      usuario: _filtroUsuario,
      estado: _filtroEstado,
      searchText: _searchText,
    );
  }

  Widget _buildVoucherCard(
    Map<String, dynamic> voucher,
    bool isDesktop,
    bool isTablet,
  ) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher['usuario'],
                    style: TextStyle(
                      color: WessexColors.darkGrape,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if ((voucher['alumno'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: WessexColors.deepRoyalBlue.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(
                          'Alumno: ${voucher['alumno']}',
                          style: TextStyle(
                            color: WessexColors.darkGrape.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Text(
                    voucher['rol'],
                    style: TextStyle(
                      color: WessexColors.deepRoyalBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(estadoIcon, color: estadoColor, size: 16),
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

          // Información del voucher
          Row(
            children: [
              Expanded(
                child: _buildVoucherDetailItem(
                  'ID Voucher',
                  voucher['id'].toString().length > 5 
                      ? voucher['id'].toString().substring(0, 5) 
                      : voucher['id'],
                  Icons.receipt,
                  WessexColors.darkGrape,
                ),
              ),
              Expanded(
                child: _buildVoucherDetailItem(
                  'Mes',
                  voucher['mes'],
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
                child: _buildVoucherDetailItem(
                  'Monto',
                  '\$${voucher['monto'].toStringAsFixed(2)}',
                  Icons.attach_money,
                  WessexColors.leafGreen,
                ),
              ),
              Expanded(
                child: _buildVoucherDetailItem(
                  'Método',
                  voucher['metodoPago'],
                  Icons.payment,
                  WessexColors.crimsonAlert,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildVoucherDetailItem(
                  'Fecha Envío',
                  _formatFecha(voucher['fechaEnvio']),
                  Icons.schedule,
                  WessexColors.darkGrape,
                ),
              ),
              Expanded(
                child: _buildVoucherDetailItem(
                  'Archivo',
                  'Adjunto',
                  Icons.attachment,
                  WessexColors.deepRoyalBlue,
                ),
              ),
            ],
          ),

          if (voucher['descripcion'] != null) ...[
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
                  label: Text('Ver Archivo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WessexColors.deepRoyalBlue,
                    side: BorderSide(color: WessexColors.deepRoyalBlue),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (estado == 'Pendiente') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveVoucher(voucher),
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WessexColors.leafGreen,
                      foregroundColor: WessexColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectVoucher(voucher),
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Rechazar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WessexColors.crimsonAlert,
                      foregroundColor: WessexColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
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

  void _viewVoucher(Map<String, dynamic> voucher) async {
    // 1. Si ya tenemos los datos en cache, usarlos
    if (voucher['archivoData'] != null) {
      final String fileName = voucher['archivo'] as String;
      if (fileName.toLowerCase().endsWith('.pdf')) {
        _showPdfDialog(voucher);
      } else {
        _showImageDialog(voucher);
      }
      return;
    }

    // 2. Ver si hay URL para descargar
    final archivoUrl = (voucher['archivoUrl'] ?? voucher['archivo'] ?? '').toString();
    if (archivoUrl.isEmpty) {
      _showFileInfoDialog(voucher);
      return;
    }

    final isPdf = archivoUrl.toLowerCase().endsWith('.pdf');

    // 3. En web: usar iframe directamente sin descargar bytes
    if (kIsWeb) {
      if (isPdf) {
        _openPdfInDialog(archivoUrl, voucher);
      } else {
        _openImageInDialog(archivoUrl);
      }
      return;
    }

    // 4. En mobile/desktop: descargar bytes primero
    try {
      final resp = await http.get(Uri.parse(archivoUrl));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        voucher['archivoData'] = resp.bodyBytes;
        if (isPdf) {
          _showPdfDialog(voucher);
        } else {
          _showImageDialog(voucher);
        }
      } else {
        _showSnackBar('No se pudo cargar archivo (status ${resp.statusCode})', WessexColors.crimsonAlert);
      }
    } catch (e) {
      print('Error descargando archivo: $e');
      _showSnackBar('Error al cargar archivo', WessexColors.crimsonAlert);
    }
  }

  void _openPdfInDialog(String url, Map<String, dynamic> voucher) {
    if (!kIsWeb) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                          'Voucher PDF - ${voucher['usuario'] ?? ''}',
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Voucher de Pago',
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
                        onPressed: () => _downloadFile(voucher),
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
                  child: _buildWebPdfViewer(url, voucher),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebPdfViewer(String url, Map<String, dynamic> voucher) {
    try {
      final String viewId = 'pdf-viewer-${voucher['id']}-gestion-${DateTime.now().millisecondsSinceEpoch}';
      
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      });

      return HtmlElementView(viewType: viewId);
    } catch (e) {
      print('Error creando visor PDF: $e');
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: WessexColors.crimsonAlert),
          const SizedBox(height: 16),
          Text(
            'Error al cargar PDF',
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _downloadFile(voucher),
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
  }

  void _openImageInDialog(String url) {
    if (!kIsWeb) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                  Text(
                    'Vista de Imagen',
                    style: TextStyle(
                      color: WessexColors.darkGrape,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    tooltip: 'Cerrar',
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
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPdfDialog(Map<String, dynamic> voucher) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
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
                              'Voucher PDF - ${voucher['usuario']}',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Voucher de Pago',
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
                            onPressed: () => _downloadFile(voucher),
                            icon: Icon(Icons.download),
                            tooltip: 'Descargar PDF',
                            style: IconButton.styleFrom(
                              backgroundColor: WessexColors.deepRoyalBlue
                                  .withOpacity(0.1),
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
                      child:
                          kIsWeb
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
        // Crear un blob URL para el PDF
        final blob = html.Blob([voucher['archivoData']], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Registrar el view factory para el iframe
        final String viewId = 'pdf-viewer-${voucher['id']}';

        // ignore: undefined_prefixed_name
        ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
          final iframe =
              html.IFrameElement()
                ..src = url
                ..style.border = 'none'
                ..style.width = '100%'
                ..style.height = '100%';
          return iframe;
        });

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
        Icon(Icons.picture_as_pdf, size: 64, color: WessexColors.crimsonAlert),
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
        const SizedBox(height: 16),
        if (voucher['archivoData'] != null) ...[
          Text(
            'Tamaño: ${(voucher['archivoData'].length / 1024).toStringAsFixed(1)} KB',
            style: TextStyle(color: WessexColors.deepRoyalBlue, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WessexColors.deepRoyalBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: WessexColors.deepRoyalBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Vista previa no disponible en esta plataforma',
                  style: TextStyle(
                    color: WessexColors.deepRoyalBlue,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _downloadFile(voucher),
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
      builder:
          (context) => Dialog(
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
                              'Voucher - ${voucher['usuario']}',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Voucher de Pago',
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
                            onPressed: () => _downloadFile(voucher),
                            icon: Icon(Icons.download),
                            tooltip: 'Descargar imagen',
                            style: IconButton.styleFrom(
                              backgroundColor: WessexColors.deepRoyalBlue
                                  .withOpacity(0.1),
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
                                    'El archivo podría no ser una imagen válida o estar dañado',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _downloadFile(voucher),
                                    icon: Icon(Icons.download),
                                    label: Text('Descargar archivo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          WessexColors.deepRoyalBlue,
                                      foregroundColor: WessexColors.white,
                                    ),
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
      builder:
          (context) => Dialog(
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
                            'Voucher de Pago',
                            style: TextStyle(
                              color: WessexColors.darkGrape,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enviado por: ${voucher['usuario']}',
                            style: TextStyle(
                              color: WessexColors.darkGrape.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fecha: ${voucher['fechaEnvio']}',
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
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  color: WessexColors.crimsonAlert,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Archivo no disponible para vista previa. Solo se almacenó el nombre del archivo.',
                                    style: TextStyle(
                                      color: WessexColors.crimsonAlert,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
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

  void _downloadFile(Map<String, dynamic> voucher) {
    try {
      if (kIsWeb && voucher['archivoData'] != null) {
        // Crear blob con los datos del archivo
        final blob = html.Blob([voucher['archivoData']]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Crear elemento anchor para descargar
        html.AnchorElement(href: url)
          ..setAttribute("download", voucher['archivo'])
          ..click();

        // Limpiar URL
        html.Url.revokeObjectUrl(url);

        _showSnackBar(
          'Archivo descargado: ${voucher['archivo']}',
          WessexColors.leafGreen,
        );
      } else {
        _showSnackBar(
          'Descarga iniciada: ${voucher['archivo']}',
          WessexColors.leafGreen,
        );
      }
    } catch (e) {
      print('Error al descargar archivo: $e');
      _showSnackBar('Error al descargar archivo', WessexColors.crimsonAlert);
    }
  }

  void _approveVoucher(Map<String, dynamic> voucher) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Aprobar Voucher'),
            content: Text(
              '¿Estás seguro de que deseas aprobar el voucher de ${voucher['usuario']}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  bool success = await _voucherService.approveVoucher(voucher['id']);
                  if (success) {
                    _voucherService.sendElectronicReceipt(
                      voucher['id'],
                      '${voucher['usuario'].toLowerCase().replaceAll(' ', '.')}@email.com',
                    );
                    _showSnackBar(
                      'Voucher aprobado correctamente',
                      WessexColors.leafGreen,
                    );
                    setState(() {
                      // Actualizar UI
                    });
                  } else {
                    _showSnackBar(
                      'Error al aprobar voucher',
                      WessexColors.crimsonAlert,
                    );
                  }
                },
                child: Text('Aprobar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.leafGreen,
                ),
              ),
            ],
          ),
    );
  }

  void _rejectVoucher(Map<String, dynamic> voucher) {
    final TextEditingController motivoController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Rechazar Voucher'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿Estás seguro de que deseas rechazar el voucher de ${voucher['usuario']}?',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: motivoController,
                  decoration: InputDecoration(
                    labelText: 'Motivo del rechazo (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  bool success = await _voucherService.rejectVoucher(
                    voucher['id'],
                    motivoController.text,
                  );
                  if (success) {
                    _showSnackBar(
                      'Voucher rechazado',
                      WessexColors.crimsonAlert,
                    );
                    setState(() {
                      // Actualizar UI
                    });
                  } else {
                    _showSnackBar(
                      'Error al rechazar voucher',
                      WessexColors.crimsonAlert,
                    );
                  }
                },
                child: Text('Rechazar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.crimsonAlert,
                ),
              ),
            ],
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

  String _formatFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    } catch (e) {
      return fecha;
    }
  }
}
