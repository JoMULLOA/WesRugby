import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import '../services/justificante_service.dart';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class HistorialJustificantesScreen extends StatefulWidget {
  const HistorialJustificantesScreen({super.key});

  @override
  State<HistorialJustificantesScreen> createState() => _HistorialJustificantesScreenState();
}

class _HistorialJustificantesScreenState extends State<HistorialJustificantesScreen> {
  final JustificanteService _justificanteService = JustificanteService();
  
  // Filtros
  String _selectedYear = DateTime.now().year.toString();
  String _selectedMonth = 'Todos';
  String _selectedEstado = 'Todos';
  
  // Usuario simulado
  final String _nombreUsuario = "Carlos Rodríguez";

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Historial de Justificantes',
        elevation: 2,
      ),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con información del usuario
                _buildHeaderSection(isDesktop, isTablet),
                const SizedBox(height: 24),
                
                // Estadísticas del usuario
                _buildStatsSection(isDesktop, isTablet),
                const SizedBox(height: 24),
                
                // Filtros
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

  Widget _buildHeaderSection(bool isDesktop, bool isTablet) {
    return WessexCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WessexColors.deepRoyalBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_turned_in,
              color: WessexColors.deepRoyalBlue,
              size: isDesktop ? 32 : (isTablet ? 28 : 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historial de Justificantes',
                  style: TextStyle(
                    color: WessexColors.darkGrape,
                    fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Justificantes enviados por: $_nombreUsuario',
                  style: TextStyle(
                    color: WessexColors.darkGrape.withOpacity(0.7),
                    fontSize: isDesktop ? 16 : (isTablet ? 14 : 12),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: WessexColors.leafGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: WessexColors.leafGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Apoderado - Sub-16',
                    style: TextStyle(
                      color: WessexColors.leafGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isDesktop, bool isTablet) {
    final userJustificantes = _justificanteService.getJustificantesByUser(_nombreUsuario);
    
    int total = userJustificantes.length;
    int pendientes = userJustificantes.where((j) => j['estado'] == 'Pendiente').length;
    int aprobados = userJustificantes.where((j) => j['estado'] == 'Aprobado').length;
    int rechazados = userJustificantes.where((j) => j['estado'] == 'Rechazado').length;

    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Justificantes',
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Grid de estadísticas
          if (isDesktop || isTablet) ...[
            Row(
              children: [
                Expanded(child: _buildStatCard('Total', total.toString(), Icons.assignment, WessexColors.darkGrape)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Pendientes', pendientes.toString(), Icons.pending_actions, WessexColors.deepRoyalBlue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Aprobados', aprobados.toString(), Icons.check_circle, WessexColors.leafGreen)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Rechazados', rechazados.toString(), Icons.cancel, WessexColors.crimsonAlert)),
              ],
            ),
          ] else ...[
            // Layout móvil - 2x2
            Row(
              children: [
                Expanded(child: _buildStatCard('Total', total.toString(), Icons.assignment, WessexColors.darkGrape)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Pendientes', pendientes.toString(), Icons.pending_actions, WessexColors.deepRoyalBlue)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Aprobados', aprobados.toString(), Icons.check_circle, WessexColors.leafGreen)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Rechazados', rechazados.toString(), Icons.cancel, WessexColors.crimsonAlert)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
            textAlign: TextAlign.center,
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
            'Filtros de Búsqueda',
            style: TextStyle(
              color: WessexColors.darkGrape,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (isDesktop) ...[
            // Layout desktop - una fila
            Row(
              children: [
                Expanded(flex: 2, child: _buildYearDropdown()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildMonthDropdown()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildEstadoDropdown()),
                const SizedBox(width: 16),
                Expanded(child: _buildClearButton()),
              ],
            ),
          ] else if (isTablet) ...[
            // Layout tablet - dos filas
            Row(
              children: [
                Expanded(child: _buildYearDropdown()),
                const SizedBox(width: 16),
                Expanded(child: _buildMonthDropdown()),
                const SizedBox(width: 16),
                Expanded(child: _buildEstadoDropdown()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildClearButton()),
              ],
            ),
          ] else ...[
            // Layout móvil - columna
            _buildYearDropdown(),
            const SizedBox(height: 12),
            _buildMonthDropdown(),
            const SizedBox(height: 12),
            _buildEstadoDropdown(),
            const SizedBox(height: 16),
            _buildClearButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedYear,
      decoration: InputDecoration(
        labelText: 'Año',
        prefixIcon: Icon(Icons.calendar_today, color: WessexColors.deepRoyalBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: _getAvailableYears().map((year) {
        return DropdownMenuItem(value: year, child: Text(year));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedYear = value!;
        });
      },
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMonth,
      decoration: InputDecoration(
        labelText: 'Mes',
        prefixIcon: Icon(Icons.event, color: WessexColors.deepRoyalBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: _getMonthOptions().map((month) {
        return DropdownMenuItem(value: month, child: Text(month));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedMonth = value!;
        });
      },
    );
  }

  Widget _buildEstadoDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedEstado,
      decoration: InputDecoration(
        labelText: 'Estado',
        prefixIcon: Icon(Icons.info, color: WessexColors.deepRoyalBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: ['Todos', 'Pendiente', 'Aprobado', 'Rechazado'].map((estado) {
        return DropdownMenuItem(value: estado, child: Text(estado));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedEstado = value!;
        });
      },
    );
  }

  Widget _buildClearButton() {
    return ElevatedButton.icon(
      onPressed: _clearFilters,
      icon: Icon(Icons.clear_all),
      label: Text('Limpiar Filtros'),
      style: ElevatedButton.styleFrom(
        backgroundColor: WessexColors.crimsonAlert,
        foregroundColor: WessexColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildJustificantesList(bool isDesktop, bool isTablet) {
    final filteredJustificantes = _getFilteredJustificantes();

    if (filteredJustificantes.isEmpty) {
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
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Intenta cambiar los filtros o envía tu primer justificante',
                style: TextStyle(
                  color: WessexColors.darkGrape.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    return Column(
      children: filteredJustificantes.map((justificante) {
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
                      color: _getStatusColor(justificante['estado']).withOpacity(0.1),
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
                          justificante['tipoJustificante'],
                          style: TextStyle(
                            color: WessexColors.darkGrape,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Enviado: ${_formatDate(justificante['fechaCreacion'])}',
                          style: TextStyle(
                            color: WessexColors.darkGrape.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        Icon(Icons.calendar_today, size: 16, color: WessexColors.deepRoyalBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Fecha de Inasistencia: ${_formatDate(justificante['fechaInasistencia'])}',
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
                        Icon(Icons.edit_note, size: 16, color: WessexColors.deepRoyalBlue),
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
                    if (justificante['descripcion'] != null && justificante['descripcion'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.description, size: 16, color: WessexColors.deepRoyalBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Descripción: ${justificante['descripcion']}',
                              style: TextStyle(
                                color: WessexColors.darkGrape.withOpacity(0.7),
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
                          Icon(Icons.attachment, size: 16, color: WessexColors.deepRoyalBlue),
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
              
              // Mostrar información de evaluación si existe
              if (justificante['estado'] != 'Pendiente') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(justificante['estado']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(justificante['estado']).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            justificante['estado'] == 'Aprobado' ? Icons.check_circle : Icons.cancel,
                            color: _getStatusColor(justificante['estado']),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Evaluado por: ${justificante['evaluadoPor'] ?? 'Directiva'}',
                            style: TextStyle(
                              color: _getStatusColor(justificante['estado']),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (justificante['motivoRechazo'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Motivo del rechazo: ${justificante['motivoRechazo']}',
                          style: TextStyle(
                            color: WessexColors.crimsonAlert,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Botones de acción
              if (justificante['archivo'] != null) ...[
                Row(
                  children: [
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
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  List<String> _getAvailableYears() {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => (currentYear - index).toString());
  }

  List<String> _getMonthOptions() {
    return [
      'Todos', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
  }

  void _clearFilters() {
    setState(() {
      _selectedYear = DateTime.now().year.toString();
      _selectedMonth = 'Todos';
      _selectedEstado = 'Todos';
    });
  }

  List<Map<String, dynamic>> _getFilteredJustificantes() {
    final userJustificantes = _justificanteService.getJustificantesByUser(_nombreUsuario);
    
    return userJustificantes.where((justificante) {
      // Filtro por año
      final fechaCreacion = justificante['fechaCreacion'] as DateTime;
      if (fechaCreacion.year.toString() != _selectedYear) {
        return false;
      }
      
      // Filtro por mes
      if (_selectedMonth != 'Todos') {
        final monthIndex = _getMonthOptions().indexOf(_selectedMonth);
        if (fechaCreacion.month != monthIndex) {
          return false;
        }
      }
      
      // Filtro por estado
      if (_selectedEstado != 'Todos') {
        if (justificante['estado'] != _selectedEstado) {
          return false;
        }
      }
      
      return true;
    }).toList()
      ..sort((a, b) => (b['fechaCreacion'] as DateTime).compareTo(a['fechaCreacion'] as DateTime));
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

  String _formatDate(DateTime date) {
    final months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month]} ${date.year}';
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
      builder: (context) => Dialog(
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
                child: isPdf ? _buildPdfViewer(fileData, fileName) : _buildImageViewer(fileData),
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
                        child: Text('Cerrar', style: TextStyle(color: WessexColors.white)),
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
        'pdf-viewer-historial-$fileName',
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = url
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%';
          
          return iframe;
        },
      );

      return HtmlElementView(viewType: 'pdf-viewer-historial-$fileName');
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