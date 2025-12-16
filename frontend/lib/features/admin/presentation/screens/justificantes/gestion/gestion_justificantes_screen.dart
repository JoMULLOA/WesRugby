import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/justificante_service.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import 'package:wesrugby/core/utils/platform/platform_view_registry.dart' as ui_web;

class GestionJustificantesScreen extends StatefulWidget {
  const GestionJustificantesScreen({super.key});

  @override
  State<GestionJustificantesScreen> createState() =>
      _GestionJustificantesScreenState();
}

class _GestionJustificantesScreenState
    extends State<GestionJustificantesScreen> {
  final JustificanteService _justificanteService = JustificanteService();

  // Filtros
  String _filtroEstado = 'Todos';
  String _filtroTipo = 'Todos';
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;
  String _textoBusqueda = '';

  // Estado UI
  bool _mostrarFiltros = false;
  bool _cargando = true;
  bool _error = false;

  // Estado local para selección de meses de exención por justificante
  final Map<String, Set<String>> _exencionMesesSeleccionados = {};
  final Map<String, bool> _exencionGuardando = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = false;
    });
    final exito = await _justificanteService.cargarJustificantesPersistentesDirectiva();
    setState(() {
      _cargando = false;
      _error = !exito;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Gestión de Justificantes',
        elevation: 2,
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con estadísticas
                _buildStatsSection(),
                const SizedBox(height: 24),

                // Filtros y búsqueda
                _buildFiltersSection(isDesktop, isTablet),
                const SizedBox(height: 24),

                // Lista de justificantes
                _buildJustificantesList(isDesktop, isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _justificanteService.getDirectivaStatistics();

    return WessexCard(
      margin: const EdgeInsets.only(bottom: 16),
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
                  Icons.assignment_turned_in,
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
                      'Panel de Justificantes',
                      style: TextStyle(
                        color: WessexColors.darkGrape,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gestiona y evalúa los justificantes de inasistencia',
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

          // Estadísticas en fila
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  stats['pendientes'].toString(),
                  Icons.pending_actions,
                  WessexColors.deepRoyalBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Aprobados',
                  stats['aprobados'].toString(),
                  Icons.check_circle,
                  WessexColors.leafGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rechazados',
                  stats['rechazados'].toString(),
                  Icons.cancel,
                  WessexColors.crimsonAlert,
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
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: WessexColors.darkGrape,
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
        children: [
          // Header de filtros
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por estudiante o motivo...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: WessexColors.deepRoyalBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _textoBusqueda = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  setState(() {
                    _mostrarFiltros = !_mostrarFiltros;
                  });
                },
                icon: Icon(
                  _mostrarFiltros ? Icons.filter_list_off : Icons.filter_list,
                  color: WessexColors.deepRoyalBlue,
                ),
                tooltip:
                    _mostrarFiltros ? 'Ocultar filtros' : 'Mostrar filtros',
              ),
            ],
          ),

          // Filtros expandibles
          if (_mostrarFiltros) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // Filtro por estado
                SizedBox(
                  width: isDesktop ? 200 : (isTablet ? 180 : double.infinity),
                  child: DropdownButtonFormField<String>(
                    value: _filtroEstado,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items:
                        ['Todos', 'Pendiente', 'Aprobado', 'Rechazado']
                            .map(
                              (estado) => DropdownMenuItem(
                                value: estado,
                                child: Text(estado),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _filtroEstado = value!;
                      });
                    },
                  ),
                ),

                // Filtro por tipo
                SizedBox(
                  width: isDesktop ? 200 : (isTablet ? 180 : double.infinity),
                  child: DropdownButtonFormField<String>(
                    value: _filtroTipo,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items:
                        [
                              'Todos',
                              'Médico',
                              'Académico',
                              'Familiar',
                              'Laboral',
                              'Otro',
                            ]
                            .map(
                              (tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(tipo),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _filtroTipo = value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _limpiarFiltros,
                    icon: Icon(Icons.clear_all),
                    label: Text('Limpiar Filtros'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJustificantesList(bool isDesktop, bool isTablet) {
    final justificantes = _justificanteService.getFilteredJustificantes(
      estado: _filtroEstado == 'Todos' ? null : _filtroEstado,
      tipo: _filtroTipo == 'Todos' ? null : _filtroTipo,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      busqueda: _textoBusqueda.isNotEmpty ? _textoBusqueda : null,
    );

    if (justificantes.isEmpty) {
      return WessexCard(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: WessexColors.darkGrape.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay justificantes que mostrar',
                style: TextStyle(
                  color: WessexColors.darkGrape.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Los justificantes aparecerán aquí cuando sean enviados',
                style: TextStyle(
                  color: WessexColors.darkGrape.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    return Column(
      children:
          justificantes.map((justificante) {
            return WessexCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del justificante
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            justificante['estado'],
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getStatusIcon(justificante['estado']),
                          color: _getStatusColor(justificante['estado']),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              justificante['usuario'],
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${justificante['rol']} • ${justificante['tipoJustificante']}',
                              style: TextStyle(
                                color: WessexColors.darkGrape.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(justificante['estado']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          justificante['estado'],
                          style: TextStyle(
                            color: WessexColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Información del justificante
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WessexColors.mistyRoseGray.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: WessexColors.deepRoyalBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Fecha de Inasistencia: ${justificante['fechaInasistencia'].toString().substring(0, 10)}',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              size: 16,
                              color: WessexColors.deepRoyalBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Motivo: ${justificante['motivo']}',
                                style: TextStyle(
                                  color: WessexColors.darkGrape,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (justificante['descripcion'] != null &&
                            justificante['descripcion'].isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.description,
                                size: 16,
                                color: WessexColors.deepRoyalBlue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Descripción: ${justificante['descripcion']}',
                                  style: TextStyle(
                                    color: WessexColors.darkGrape.withOpacity(
                                      0.7,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (justificante['archivo'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.attachment,
                                size: 16,
                                color: WessexColors.deepRoyalBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Archivo adjunto: ${justificante['archivo']}',
                                style: TextStyle(
                                  color: WessexColors.deepRoyalBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botones de acción
                  Row(
                    children: [
                      if (justificante['archivo'] != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _viewJustificante(justificante),
                            icon: Icon(Icons.visibility, size: 16),
                            label: Text('Ver Archivo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: WessexColors.deepRoyalBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      if (justificante['estado'] == 'Pendiente') ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => _approveJustificante(justificante['id']),
                            icon: Icon(Icons.check, size: 16),
                            label: Text('Aprobar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WessexColors.leafGreen,
                              foregroundColor: WessexColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => _rejectJustificante(justificante['id']),
                            icon: Icon(Icons.close, size: 16),
                            label: Text('Rechazar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WessexColors.crimsonAlert,
                              foregroundColor: WessexColors.white,
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                justificante['estado'],
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getStatusIcon(justificante['estado']),
                                  color: _getStatusColor(
                                    justificante['estado'],
                                  ),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  justificante['estado'],
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      justificante['estado'],
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Información de fecha/hora
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WessexColors.deepRoyalBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: WessexColors.deepRoyalBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Enviado: ${justificante['fechaCreacion'].toString().substring(0, 16)}',
                          style: TextStyle(
                            color: WessexColors.deepRoyalBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sección meses de exención (solo aprobados)
                  if (justificante['estado'] == 'Aprobado') ...[
                    const SizedBox(height: 16),
                    _buildMesesExencionSection(justificante),
                  ],
                ],
              ),
            );
          }).toList(),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Pendiente':
        return WessexColors.deepRoyalBlue;
      case 'Aprobado':
        return WessexColors.leafGreen;
      case 'Rechazado':
        return WessexColors.crimsonAlert;
      default:
        return WessexColors.deepRoyalBlue;
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Icons.pending_actions;
      case 'Aprobado':
        return Icons.check_circle;
      case 'Rechazado':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroEstado = 'Todos';
      _filtroTipo = 'Todos';
      _filtroFechaDesde = null;
      _filtroFechaHasta = null;
      _textoBusqueda = '';
    });
  }

  Future<void> _viewJustificante(Map<String, dynamic> justificante) async {
    // 1. Si ya tiene datos en cache, usarlos
    if (justificante['archivoData'] != null) {
      _showFileDialog(justificante);
      return;
    }

    // 2. Ver si hay URL para descargar
    final archivoUrl = (justificante['archivoUrl'] ?? justificante['archivo'] ?? '').toString();
    if (archivoUrl.isEmpty) {
      _showErrorSnackBar('No hay archivo disponible');
      return;
    }

    final isPdf = archivoUrl.toLowerCase().endsWith('.pdf');

    // 3. En web: usar iframe directamente sin descargar bytes
    if (kIsWeb) {
      if (isPdf) {
        _openPdfInDialog(archivoUrl, justificante);
      } else {
        _openImageInDialog(archivoUrl);
      }
      return;
    }

    // 4. En mobile/desktop: descargar bytes primero
    try {
      final resp = await http.get(Uri.parse(archivoUrl));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        justificante['archivoData'] = resp.bodyBytes;
        _showFileDialog(justificante);
      } else {
        _showErrorSnackBar('No se pudo cargar archivo (status ${resp.statusCode})');
      }
    } catch (e) {
      print('Error descargando archivo: $e');
      _showErrorSnackBar('Error al cargar archivo');
    }
  }

  void _openPdfInDialog(String url, Map<String, dynamic> justificante) {
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
                          'Justificante PDF - ${justificante['alumno'] ?? ''}',
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Archivo: ${justificante['archivo'] ?? ''}',
                          style: TextStyle(
                            color: WessexColors.darkGrape.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
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
                  child: _buildWebPdfViewer(url, justificante),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebPdfViewer(String url, Map<String, dynamic> justificante) {
    try {
      final String viewId = 'pdf-viewer-${justificante['id']}-gestion-${DateTime.now().millisecondsSinceEpoch}';
      
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      });

      return kIsWeb ? HtmlElementView(viewType: viewId) : const Center(child: Text('Vista previa no disponible en móvil'));
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

  void _showFileDialog(Map<String, dynamic> justificante) {
    final fileName = justificante['archivo'] as String;
    final fileData = justificante['archivoData'] as Uint8List;
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WessexColors.deepRoyalBlue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attachment, color: WessexColors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: TextStyle(
                              color: WessexColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: WessexColors.white),
                        ),
                      ],
                    ),
                  ),

                  // Contenido
                  Expanded(
                    child:
                        isPdf
                            ? _buildPdfViewer(fileData, fileName)
                            : _buildImageViewer(fileData),
                  ),

                  // Footer con botones
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _downloadFile(fileData, fileName),
                            icon: Icon(Icons.download),
                            label: Text('Descargar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WessexColors.deepRoyalBlue,
                            ),
                            child: Text(
                              'Cerrar',
                              style: TextStyle(color: WessexColors.white),
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
    );
  }

  Widget _buildPdfViewer(Uint8List fileData, String fileName) {
    try {
      final blob = html.Blob([fileData], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Registrar el iframe para el PDF
      ui_web.platformViewRegistry.registerViewFactory('pdf-viewer-$fileName', (
        int viewId,
      ) {
        final iframe =
            html.IFrameElement()
              ..src = url
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%';

        return iframe;
      });

      return kIsWeb ? HtmlElementView(viewType: 'pdf-viewer-$fileName') : const Center(child: Text('Vista previa no disponible en móvil'));
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: WessexColors.crimsonAlert),
            const SizedBox(height: 16),
            Text('Error al cargar el PDF: $e'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _downloadFile(fileData, fileName),
              icon: Icon(Icons.download),
              label: Text('Descargar Archivo'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildImageViewer(Uint8List fileData) {
    return Center(
      child: Image.memory(
        fileData,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: WessexColors.crimsonAlert),
              const SizedBox(height: 16),
              Text('Error al cargar la imagen'),
            ],
          );
        },
      ),
    );
  }

  void _downloadFile(Uint8List fileData, String fileName) {
    try {
      final blob = html.Blob([fileData]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      _showSuccessSnackBar('Archivo descargado: $fileName');
    } catch (e) {
      _showErrorSnackBar('Error al descargar: $e');
    }
  }

  Future<void> _approveJustificante(String id) async {
    try {
      bool success = await _justificanteService.actualizarEstadoJustificantePersistente(id, 'aprobado');
      if (success) {
        // Optimistic update: recargar datos inmediatamente tras éxito
        await _cargarDatos();
        _showSuccessSnackBar('Justificante aprobado correctamente');
      } else {
        _showErrorSnackBar('Error al aprobar el justificante');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _rejectJustificante(String id) async {
    // Mostrar diálogo para motivo de rechazo
    String? motivo = await _showRejectDialog();
    if (motivo != null && motivo.isNotEmpty) {
      try {
        bool success = await _justificanteService.actualizarEstadoJustificantePersistente(id, 'rechazado', motivoRechazo: motivo);
        if (success) {
          // Recargar datos inmediatamente tras éxito
          await _cargarDatos();
          _showSuccessSnackBar('Justificante rechazado');
        } else {
          _showErrorSnackBar('Error al rechazar el justificante');
        }
      } catch (e) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  Widget _buildMesesExencionSection(Map<String, dynamic> justificante) {
    final id = justificante['id'].toString();
    final fechaInicioStr = justificante['fechaInicio']?.toString();
    final fechaFinStr = justificante['fechaFin']?.toString();
    if (fechaInicioStr == null || fechaInicioStr.isEmpty) {
      return const SizedBox();
    }
    final inicio = DateTime.tryParse(fechaInicioStr);
    final finTmp = DateTime.tryParse(fechaFinStr ?? fechaInicioStr);
    if (inicio == null) return const SizedBox();
    final fin = finTmp ?? inicio;
    final mesesRango = <String>[];
    var cursor = DateTime(inicio.year, inicio.month);
    final limite = DateTime(fin.year, fin.month);
    while (cursor.isBefore(limite.add(const Duration(days: 1)))) {
      final m = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}';
      mesesRango.add(m);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    final actuales = (justificante['mesesExencion'] as List?)?.map((e) => e.toString()).toSet() ?? <String>{};
    _exencionMesesSeleccionados.putIfAbsent(id, () => {...actuales});
    final seleccion = _exencionMesesSeleccionados[id]!;
    final hayCambios = seleccion.length != actuales.length || !seleccion.containsAll(actuales);
    final guardando = _exencionGuardando[id] == true;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WessexColors.leafGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WessexColors.leafGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_information, color: WessexColors.leafGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Exención de Pago (Cert. Médico): Selecciona meses del rango para eximir',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mesesRango.map((mes) {
              final seleccionado = seleccion.contains(mes);
              return FilterChip(
                label: Text(mes),
                selected: seleccionado,
                onSelected: guardando ? null : (v) {
                  setState(() {
                    if (v) {
                      seleccion.add(mes);
                    } else {
                      seleccion.remove(mes);
                    }
                  });
                },
                selectedColor: WessexColors.leafGreen,
                checkmarkColor: WessexColors.white,
                labelStyle: TextStyle(
                  color: seleccionado ? WessexColors.white : WessexColors.darkGrape,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: seleccionado ? WessexColors.leafGreen : WessexColors.leafGreen.withOpacity(0.15),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (!hayCambios || guardando)
                      ? null
                      : () async {
                          setState(() { _exencionGuardando[id] = true; });
                          final ok = await _justificanteService.actualizarMesesExencion(id, seleccion.toList()..sort());
                          setState(() { _exencionGuardando[id] = false; });
                          if (ok) {
                            _showSuccessSnackBar('Meses de exención guardados');
                          } else {
                            _showErrorSnackBar('Error guardando meses de exención');
                          }
                        },
                  icon: guardando ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : Icon(Icons.save, size: 16),
                  label: Text(hayCambios ? 'Guardar Exenciones' : 'Sin cambios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.leafGreen,
                    foregroundColor: WessexColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (hayCambios && !guardando)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() { _exencionMesesSeleccionados[id] = {...actuales}; });
                  },
                  icon: Icon(Icons.refresh, size: 16),
                  label: const Text('Reiniciar'),
                ),
            ],
          ),
          if (actuales.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Meses actualmente exentos: ${actuales.toList()..sort()}',
              style: TextStyle(color: WessexColors.darkGrape.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Future<String?> _showRejectDialog() async {
    final TextEditingController motivoController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Rechazar Justificante'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Proporciona un motivo para el rechazo:'),
                const SizedBox(height: 16),
                TextField(
                  controller: motivoController,
                  decoration: InputDecoration(
                    hintText: 'Motivo del rechazo...',
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
                onPressed: () {
                  if (motivoController.text.trim().isNotEmpty) {
                    Navigator.pop(context, motivoController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.crimsonAlert,
                ),
                child: Text(
                  'Rechazar',
                  style: TextStyle(color: WessexColors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WessexColors.leafGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WessexColors.crimsonAlert,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
