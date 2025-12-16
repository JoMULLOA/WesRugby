import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/justificante_service.dart';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import 'package:wesrugby/core/utils/platform/platform_view_registry.dart' as ui_web;

class EntrenadorJustificantesScreen extends StatefulWidget {
  const EntrenadorJustificantesScreen({super.key});

  @override
  State<EntrenadorJustificantesScreen> createState() =>
      _EntrenadorJustificantesScreenState();
}

class _EntrenadorJustificantesScreenState
    extends State<EntrenadorJustificantesScreen> {
  final JustificanteService _justificanteService = JustificanteService();

  // Filtros
  String _filtroEstado = 'Todos';
  String _filtroTipo = 'Todos';
  String _textoBusqueda = '';

  // Estado UI
  bool _mostrarFiltros = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Justificantes - Vista Entrenador',
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
                _buildInfoSection(),
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

  Widget _buildInfoSection() {
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
                  color: WessexColors.leafGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sports_rugby,
                  color: WessexColors.leafGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Justificantes de Inasistencias',
                      style: TextStyle(
                        color: WessexColors.darkGrape,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Vista informativa para el entrenador - Solo lectura',
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

          // Información importante
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WessexColors.deepRoyalBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: WessexColors.deepRoyalBlue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: WessexColors.deepRoyalBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Los justificantes son evaluados únicamente por la Directiva. Aquí puedes consultar el estado de las inasistencias de tus jugadores.',
                    style: TextStyle(
                      color: WessexColors.deepRoyalBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Resumen estadístico
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats['total'].toString(),
                  Icons.assignment,
                  WessexColors.darkGrape,
                ),
              ),
              const SizedBox(width: 12),
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
                  'Resueltos',
                  (stats['aprobados']! + stats['rechazados']!).toString(),
                  Icons.check_circle,
                  WessexColors.leafGreen,
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
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
                      color: WessexColors.leafGreen,
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
                  color: WessexColors.leafGreen,
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
                'Los justificantes de tus jugadores aparecerán aquí',
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
                              color: WessexColors.leafGreen,
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
                              color: WessexColors.leafGreen,
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
                                color: WessexColors.leafGreen,
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
                                color: WessexColors.leafGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Archivo adjunto: ${justificante['archivo']}',
                                style: TextStyle(
                                  color: WessexColors.leafGreen,
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

                  // Botones de visualización (solo lectura)
                  Row(
                    children: [
                      if (justificante['archivo'] != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _viewJustificante(justificante),
                            icon: Icon(Icons.visibility, size: 16),
                            label: Text('Ver Archivo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: WessexColors.leafGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: WessexColors.leafGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility,
                                color: WessexColors.leafGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Vista Solo Lectura',
                                style: TextStyle(
                                  color: WessexColors.leafGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Información de fecha/hora
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WessexColors.leafGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: WessexColors.leafGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Enviado: ${justificante['fechaCreacion'].toString().substring(0, 16)}',
                          style: TextStyle(
                            color: WessexColors.leafGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
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
        return WessexColors.leafGreen;
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
      _textoBusqueda = '';
    });
  }

  Future<void> _viewJustificante(Map<String, dynamic> justificante) async {
    if (justificante['archivoData'] != null && kIsWeb) {
      _showFileDialog(justificante);
    } else {
      _showErrorSnackBar('No hay archivo disponible para mostrar');
    }
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
                      color: WessexColors.leafGreen,
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
                              backgroundColor: WessexColors.leafGreen,
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
      ui_web.platformViewRegistry.registerViewFactory(
        'pdf-viewer-entrenador-$fileName',
        (int viewId) {
          final iframe =
              html.IFrameElement()
                ..src = url
                ..style.border = 'none'
                ..style.width = '100%'
                ..style.height = '100%';

          return iframe;
        },
      );

      return kIsWeb ? HtmlElementView(viewType: 'pdf-viewer-entrenador-$fileName') : const Center(child: Text('Vista previa no disponible en móvil'));
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
