import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:intl/intl.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:wesrugby/core/utils/html.dart' as html;

class BaseDatosScreen extends StatefulWidget {
  const BaseDatosScreen({super.key});

  @override
  State<BaseDatosScreen> createState() => _BaseDatosScreenState();
}

class _BaseDatosScreenState extends State<BaseDatosScreen> {
  final EstudianteService _estudianteService = EstudianteService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCurso = 'Todos';
  List<Map<String, dynamic>> _filteredEstudiantes = [];
  bool _isLoading = false;
  
  // Paginación
  int _currentPage = 0;
  static const int _estudiantesPerPage = 9;

  final List<String> _cursos = [
    'Todos',
    'Kínder',
    '1°A',
    '2°A',
    '3°A',
    '4°A',
    'Sub-14',
    'Sub-16',
    'Sub-18',
  ];

  @override
  void initState() {
    super.initState();
    _estudianteService.addListener(_updateEstudiantes);
    _loadEstudiantesFromAPI();
  }

  @override
  void dispose() {
    _estudianteService.removeListener(_updateEstudiantes);
    _searchController.dispose();
    super.dispose();
  }

  void _updateEstudiantes() {
    if (mounted) {
      _loadEstudiantes();
    }
  }

  Future<void> _loadEstudiantesFromAPI() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _estudianteService.refreshStudentsFromAPI();
      _loadEstudiantes();
    } catch (e) {
      print('❌ Error al cargar estudiantes desde API: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadEstudiantes() {
    setState(() {
      _isLoading = true;
    });

    final query = _searchController.text.trim();
    List<Map<String, dynamic>> estudiantes;

    if (query.isNotEmpty) {
      estudiantes = _estudianteService.searchStudents(query: query);
    } else {
      estudiantes = _estudianteService.getAllStudents();
    }

    if (_selectedCurso != 'Todos') {
      final normalizedCurso = _selectedCurso.toLowerCase();
      estudiantes =
          estudiantes
              .where(
                (estudiante) =>
                    estudiante['curso']?.toString().toLowerCase() ==
                    normalizedCurso,
              )
              .toList();
    }

    setState(() {
      _filteredEstudiantes = estudiantes;
      _isLoading = false;
      _currentPage = 0; // Reset pagination when filters change
    });
  }

  @override
  Widget build(BuildContext context) {
    final estadisticas = _estudianteService.getStudentStatistics();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: WessexAppBar(
        title: 'Base de Datos - Estudiantes',
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.download),
            tooltip: 'Exportar a Excel',
          ),
        ],
      ),
      body: WessexBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: WessexColors.deepRoyalBlue,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cargando estudiantes...',
                        style: TextStyle(
                          color: WessexColors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con estadísticas
                      _buildStatsCards(estadisticas),

                      const SizedBox(height: 32),

                      // Controles de búsqueda y filtros
                      _buildSearchAndFilters(),

                      const SizedBox(height: 24),

                      // Lista de estudiantes
                      _buildEstudiantesList(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WessexSectionTitle(
          title: 'Base de Datos de Estudiantes',
          subtitle: 'Administre el registro completo de estudiantes del club',
          titleColor: WessexColors.white,
        ),
        const SizedBox(height: 20),

        // Tarjetas responsivas en una sola fila horizontal con scroll
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStatCard(
                'Total Estudiantes',
                '${stats['total']}',
                Icons.school,
                WessexColors.deepRoyalBlue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Activos',
                '${stats['activos']}',
                Icons.check_circle,
                WessexColors.leafGreen,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Inactivos',
                '${stats['inactivos']}',
                Icons.cancel,
                WessexColors.crimsonAlert,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Cursos',
                '${(stats['porCurso'] as Map).length}',
                Icons.class_,
                WessexColors.maximumGrayMint,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.darkGrape,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: WessexColors.darkGrape.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WessexColors.deepRoyalBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buscar y Filtrar Estudiantes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WessexColors.darkGrape,
            ),
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;

              if (isDesktop) {
                return Row(
                  children: [
                    Expanded(flex: 2, child: _buildSearchField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCursoDropdown()),
                    const SizedBox(width: 16),
                    _buildRefreshButton(),
                  ],
                );
              }

              return Column(
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 16),
                  Row(children: [Expanded(child: _buildCursoDropdown())]),
                  const SizedBox(height: 16),
                  _buildRefreshButton(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => _loadEstudiantes(),
      decoration: InputDecoration(
        labelText: 'Buscar estudiantes...',
        hintText: 'Nombre, RUT, padre, madre, responsable',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildCursoDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCurso,
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedCurso = value;
        });
        _loadEstudiantes();
      },
      decoration: InputDecoration(
        labelText: 'Filtrar por Curso',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items:
          _cursos.map((curso) {
            return DropdownMenuItem(value: curso, child: Text(curso));
          }).toList(),
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: _loadEstudiantes,
      icon: const Icon(Icons.refresh),
      label: const Text('Actualizar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: WessexColors.deepRoyalBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEstudiantesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredEstudiantes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WessexColors.mistyRoseGray),
        ),
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: WessexColors.mistyRoseGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron estudiantes',
              style: TextStyle(
                fontSize: 18,
                color: WessexColors.darkGrape,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba cambiar los filtros o importar datos desde Excel',
              style: TextStyle(color: WessexColors.darkGrape.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    // Calcular paginación
    final int totalPages = (_filteredEstudiantes.length / _estudiantesPerPage).ceil();
    final int startIndex = _currentPage * _estudiantesPerPage;
    final int endIndex = (startIndex + _estudiantesPerPage).clamp(0, _filteredEstudiantes.length);
    final List<Map<String, dynamic>> paginatedEstudiantes = _filteredEstudiantes.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WessexColors.deepRoyalBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Text(
                  'Registro de Estudiantes (${_filteredEstudiantes.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.darkGrape,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddStudentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Estudiante'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.leafGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: WessexColors.mistyRoseGray.withOpacity(0.4),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  WessexColors.deepRoyalBlue.withOpacity(0.1),
                ),
                dataRowMaxHeight: 60,
                columnSpacing: 20,
                columns: const [
                DataColumn(
                  label: Text(
                    'RUT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'NOMBRE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CURSO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'RESPONSABLE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CORREO APODERADO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'INFO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'ACCIONES',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
              rows:
                  paginatedEstudiantes.map((estudiante) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            estudiante['rut'] ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: Text(
                              estudiante['nombre'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(_buildCursoChip(estudiante['curso'] ?? '')),
                        DataCell(_buildResponsableCell(estudiante)),
                        DataCell(
                          Text(
                            _formatValue(estudiante['correoApoderadoGenerado']),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Container(
                            decoration: BoxDecoration(
                              color: WessexColors.deepRoyalBlue.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed:
                                  () => _showStudentInfoDialog(estudiante),
                              icon: const Icon(Icons.info_outline),
                              tooltip: 'Ver información completa',
                              color: WessexColors.deepRoyalBlue,
                              iconSize: 20,
                            ),
                          ),
                        ),
                        DataCell(_buildActionButtons(estudiante)),
                      ],
                    );
                  }).toList(),
              ),
            ),
          ),

          // Controles de paginación
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Página anterior',
                  ),
                  const SizedBox(width: 8),
                  
                  // Mostrar botones de página
                  ...List.generate(
                    totalPages > 7 ? 7 : totalPages,
                    (index) {
                      if (totalPages <= 7) {
                        return _buildPageButton(index, totalPages);
                      } else {
                        // Lógica para mostrar páginas con puntos suspensivos
                        if (index == 0) return _buildPageButton(0, totalPages);
                        if (index == 1 && _currentPage > 3) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text('...', style: TextStyle(fontSize: 18)),
                          );
                        }
                        if (index == 5 && _currentPage < totalPages - 4) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text('...', style: TextStyle(fontSize: 18)),
                          );
                        }
                        if (index == 6) return _buildPageButton(totalPages - 1, totalPages);
                        
                        // Mostrar páginas alrededor de la actual
                        int pageToShow;
                        if (_currentPage <= 3) {
                          pageToShow = index;
                        } else if (_currentPage >= totalPages - 4) {
                          pageToShow = totalPages - 7 + index;
                        } else {
                          pageToShow = _currentPage - 3 + index;
                        }
                        
                        if (pageToShow >= 0 && pageToShow < totalPages) {
                          return _buildPageButton(pageToShow, totalPages);
                        }
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Página siguiente',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageButton(int pageIndex, int totalPages) {
    final isCurrentPage = pageIndex == _currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() => _currentPage = pageIndex),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentPage
                ? WessexColors.deepRoyalBlue
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentPage
                  ? WessexColors.deepRoyalBlue
                  : WessexColors.deepRoyalBlue.withOpacity(0.3),
            ),
          ),
          child: Text(
            '${pageIndex + 1}',
            style: TextStyle(
              color: isCurrentPage
                  ? Colors.white
                  : WessexColors.darkGrape,
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCursoChip(String curso) {
    Color color = WessexColors.deepRoyalBlue;

    if (curso.toLowerCase().contains('sub')) {
      color = WessexColors.leafGreen;
    } else if (curso.toLowerCase().contains('kinder')) {
      color = WessexColors.crimsonAlert;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        curso.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResponsableCell(Map<String, dynamic> estudiante) {
    final responsable = _formatValue(
      estudiante['nombreResponsable'] ?? estudiante['responsable'],
    );
    final telefonoResponsable = _formatValue(
      estudiante['telefonoResponsable'] ??
          estudiante['telefono'] ??
          estudiante['telefonoEmergencia'],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          responsable,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: WessexColors.darkGrape,
          ),
        ),
        if (telefonoResponsable != 'Sin información')
          Text(
            'Tel: $telefonoResponsable',
            style: TextStyle(
              fontSize: 11,
              color: WessexColors.darkGrape.withOpacity(0.7),
            ),
          ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'Sin información';
    final stringValue = value.toString().trim();
    if (stringValue.isEmpty) return 'Sin información';
    final normalized = stringValue.toLowerCase();
    if (normalized == 'n/a' || normalized == 'null') {
      return 'Sin información';
    }
    return stringValue;
  }

  String _formatFicha(dynamic value) {
    if (value == null) return 'Sin información';
    if (value is bool) {
      return value ? 'Sí' : 'No';
    }
    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'n/a') {
      return 'Sin información';
    }
    if (['si', 'sí', 'true', '1'].contains(normalized)) {
      return 'Sí';
    }
    if (['no', 'false', '0'].contains(normalized)) {
      return 'No';
    }
    return value.toString();
  }

  String _formatEstado(dynamic value) {
    final estado = _formatValue(value);
    if (estado == 'Sin información') {
      return estado;
    }
    return estado[0].toUpperCase() + estado.substring(1).toLowerCase();
  }

  String _formatContactBlock(dynamic nombre, dynamic telefono, dynamic correo) {
    final parts = <String>[];
    final nombreFmt = _formatValue(nombre);
    if (nombreFmt != 'Sin información') {
      parts.add(nombreFmt);
    }
    final telefonoFmt = _formatValue(telefono);
    if (telefonoFmt != 'Sin información') {
      parts.add('Tel: $telefonoFmt');
    }
    final correoFmt = _formatValue(correo);
    if (correoFmt != 'Sin información') {
      parts.add('Mail: $correoFmt');
    }
    if (parts.isEmpty) {
      return 'Sin información';
    }
    return parts.join('\n');
  }

  Widget _buildActionButtons(Map<String, dynamic> estudiante) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _showEditStudentDialog(estudiante),
          icon: const Icon(Icons.edit),
          tooltip: 'Editar estudiante',
          color: WessexColors.deepRoyalBlue,
          iconSize: 20,
        ),
        IconButton(
          onPressed: () => _deleteStudent(estudiante),
          icon: const Icon(Icons.delete),
          tooltip: 'Eliminar estudiante',
          color: WessexColors.crimsonAlert,
          iconSize: 20,
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Sin información';

    if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    final raw = date.toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'n/a') {
      return 'Sin información';
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    }

    return raw;
  }

  void _exportToExcel() {
    if (_filteredEstudiantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hay estudiantes para exportar'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
      return;
    }

    try {
      // Crear un nuevo libro de Excel
      final excel = excel_lib.Excel.createExcel();
      final sheet = excel['Estudiantes'];

      // Definir los encabezados
      final headers = [
        'RUT',
        'NOMBRE',
        'CURSO',
        'FECHA NACIMIENTO',
        'DIRECCIÓN',
        'TELÉFONO',
        'EMAIL',
        'RESPONSABLE',
        'TELÉFONO RESPONSABLE',
        'CORREO APODERADO',
        'CONTACTO EMERGENCIA',
        'TELÉFONO EMERGENCIA',
        'OBSERVACIONES',
      ];

      // Agregar encabezados con estilo
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = excel_lib.TextCellValue(headers[i]);
        cell.cellStyle = excel_lib.CellStyle(
          bold: true,
          backgroundColorHex: excel_lib.ExcelColor.fromHexString('#4A5568'),
          fontColorHex: excel_lib.ExcelColor.white,
        );
      }

      // Agregar los datos filtrados
      for (var i = 0; i < _filteredEstudiantes.length; i++) {
        final estudiante = _filteredEstudiantes[i];
        final rowIndex = i + 1;

        final rowData = [
          estudiante['rut']?.toString() ?? '',
          estudiante['nombre']?.toString() ?? '',
          estudiante['curso']?.toString() ?? '',
          estudiante['fechaNacimiento']?.toString() ?? '',
          estudiante['direccion']?.toString() ?? '',
          estudiante['telefono']?.toString() ?? '',
          estudiante['email']?.toString() ?? '',
          estudiante['nombreResponsable']?.toString() ?? '',
          estudiante['telefonoResponsable']?.toString() ?? '',
          estudiante['correoApoderadoGenerado']?.toString() ?? '',
          estudiante['contactoEmergencia']?.toString() ?? '',
          estudiante['telefonoEmergencia']?.toString() ?? '',
          estudiante['observaciones']?.toString() ?? '',
        ];

        for (var j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            excel_lib.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = excel_lib.TextCellValue(rowData[j]);
        }
      }

      // Ajustar ancho de columnas
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      // Generar el archivo Excel
      final fileBytes = excel.encode();
      if (fileBytes == null) {
        throw Exception('Error al generar el archivo Excel');
      }

      // Generar nombre del archivo con fecha y filtros aplicados
      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
      final cursoFilter = _selectedCurso != 'Todos' ? '_$_selectedCurso' : '';
      final searchFilter =
          _searchController.text.isNotEmpty ? '_busqueda' : '';
      final fileName = 'estudiantes$cursoFilter$searchFilter\_$dateStr.xlsx';

      // Descargar el archivo
      final blob = html.Blob([fileBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Excel descargado: ${_filteredEstudiantes.length} estudiantes',
          ),
          backgroundColor: WessexColors.leafGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  void _showAddStudentDialog() {
    _showStudentFormDialog(isEdit: false);
  }

  void _showEditStudentDialog(Map<String, dynamic> estudiante) {
    _showStudentFormDialog(isEdit: true, estudiante: estudiante);
  }

  void _showStudentFormDialog({
    required bool isEdit,
    Map<String, dynamic>? estudiante,
  }) async {
    final formKey = GlobalKey<FormState>();
    
    // Cargar lista de usuarios apoderados
    List<Map<String, dynamic>> apoderados = [];
    try {
      final response = await ApiService.getAllUsers();
      if (response.statusCode == 200 && response.data != null) {
        final usuarios = response.data is Map 
            ? List<Map<String, dynamic>>.from(response.data['data'] ?? [])
            : List<Map<String, dynamic>>.from(response.data ?? []);
        apoderados = usuarios.where((u) => u['rol'] == 'apoderado').toList();
      }
    } catch (e) {
      print('Error al cargar apoderados: $e');
    }
    
    final rutController = TextEditingController(
      text: isEdit ? (estudiante?['rut'] ?? '') : '',
    );
    final nombreController = TextEditingController(
      text: isEdit ? (estudiante?['nombre'] ?? '') : '',
    );
    final cursoController = TextEditingController(
      text: isEdit ? (estudiante?['curso'] ?? '') : '',
    );
    
    // Parse fecha de nacimiento si existe
    DateTime? selectedDate;
    if (isEdit && estudiante?['fechaNacimiento'] != null) {
      try {
        selectedDate = DateTime.parse(estudiante!['fechaNacimiento'].toString());
      } catch (e) {
        selectedDate = null;
      }
    }
    
    final direccionController = TextEditingController(
      text: isEdit ? (estudiante?['direccion'] ?? '') : '',
    );
    final telefonoController = TextEditingController(
      text: isEdit ? (estudiante?['telefono'] ?? '') : '',
    );
    final emailController = TextEditingController(
      text: isEdit ? (estudiante?['email'] ?? '') : '',
    );
    final nombreResponsableController = TextEditingController(
      text: isEdit ? (estudiante?['nombreResponsable'] ?? '') : '',
    );
    final rutResponsableController = TextEditingController(
      text: isEdit ? (estudiante?['rutResponsable'] ?? '') : '',
    );
    final telefonoResponsableController = TextEditingController(
      text: isEdit ? (estudiante?['telefonoResponsable'] ?? '') : '',
    );
    final contactoEmergenciaController = TextEditingController(
      text: isEdit ? (estudiante?['contactoEmergencia'] ?? '') : '',
    );
    final telefonoEmergenciaController = TextEditingController(
      text: isEdit ? (estudiante?['telefonoEmergencia'] ?? '') : '',
    );
    final observacionesController = TextEditingController(
      text: isEdit ? (estudiante?['observaciones'] ?? '') : '',
    );
    
    // Variable para seleccionar apoderado existente
    String? selectedApoderadoRut = isEdit && estudiante != null ? estudiante['rutResponsable'] : null;
    bool useExistingApoderado = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 720),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit : Icons.person_add,
                          color: WessexColors.deepRoyalBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          isEdit ? 'Editar Estudiante' : 'Agregar Estudiante',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: WessexColors.darkGrape.withOpacity(0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Información Personal'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildValidatedTextField(
                                  controller: rutController,
                                  label: 'RUT *',
                                  icon: Icons.badge,
                                  enabled: !isEdit,
                                  hint: 'Ej: 12.345.678-9',
                                  onChanged: (value) {
                                    final formatted = _formatRut(value);
                                    if (formatted != value) {
                                      rutController.value = TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(
                                          offset: formatted.length,
                                        ),
                                      );
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'RUT es obligatorio';
                                    }
                                    if (!_isValidRut(value)) {
                                      return 'RUT inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildValidatedTextField(
                                  controller: nombreController,
                                  label: 'Nombre Completo *',
                                  icon: Icons.person,
                                  hint: 'Ej: Juan Pérez González',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Nombre es obligatorio';
                                    }
                                    if (value.trim().length < 3) {
                                      return 'Nombre muy corto';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildValidatedTextField(
                                  controller: cursoController,
                                  label: 'Curso (máx. 10 car.) *',
                                  icon: Icons.class_,
                                  hint: 'Ej: 1°A, Sub-14',
                                  maxLength: 10,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Curso es obligatorio';
                                    }
                                    if (value.length > 10) {
                                      return 'Máximo 10 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate ?? DateTime(2010, 1, 1),
                                      firstDate: DateTime(1990),
                                      lastDate: DateTime.now(),
                                      locale: const Locale('es', 'ES'),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: WessexColors.deepRoyalBlue,
                                              onPrimary: Colors.white,
                                              onSurface: WessexColors.darkGrape,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        selectedDate = picked;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Fecha Nacimiento',
                                      prefixIcon: const Icon(Icons.calendar_today, size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      helperText: 'Seleccione desde el calendario',
                                      helperStyle: TextStyle(
                                        fontSize: 11,
                                        color: WessexColors.deepRoyalBlue.withOpacity(0.7),
                                      ),
                                    ),
                                    child: Text(
                                      selectedDate != null
                                          ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                                          : 'Seleccione una fecha',
                                      style: TextStyle(
                                        color: selectedDate != null
                                            ? WessexColors.darkGrape
                                            : WessexColors.darkGrape.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildValidatedTextField(
                            controller: direccionController,
                            label: 'Dirección',
                            icon: Icons.home,
                            hint: 'Ej: Av. Principal 123, Viña del Mar',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildValidatedTextField(
                                  controller: telefonoController,
                                  label: 'Teléfono',
                                  icon: Icons.phone,
                                  hint: '+56912345678 (solo números)',
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!_isValidPhone(value)) {
                                        return 'Solo números y + opcional';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildValidatedTextField(
                                  controller: emailController,
                                  label: 'Email',
                                  icon: Icons.email,
                                  hint: 'Ej: estudiante@email.com',
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!_isValidEmail(value)) {
                                        return 'Email inválido';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Información del Apoderado (Obligatorio)'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: WessexColors.deepRoyalBlue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: WessexColors.deepRoyalBlue.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: WessexColors.deepRoyalBlue,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Todo estudiante debe tener un apoderado asignado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: WessexColors.deepRoyalBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Selector de apoderado existente o crear nuevo
                          if (!isEdit && apoderados.isNotEmpty) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: const Text('Seleccionar apoderado existente'),
                                    value: true,
                                    groupValue: useExistingApoderado,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        useExistingApoderado = value ?? false;
                                        if (useExistingApoderado) {
                                          nombreResponsableController.clear();
                                          rutResponsableController.clear();
                                          telefonoResponsableController.clear();
                                        }
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: const Text('Crear nuevo apoderado'),
                                    value: false,
                                    groupValue: useExistingApoderado,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        useExistingApoderado = !(value ?? false);
                                        if (!useExistingApoderado) {
                                          selectedApoderadoRut = null;
                                        }
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            if (useExistingApoderado) ...[
                              DropdownButtonFormField<String>(
                                value: selectedApoderadoRut,
                                decoration: InputDecoration(
                                  labelText: 'Seleccionar Apoderado *',
                                  hintText: 'Buscar por nombre o RUT',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('-- Seleccione un apoderado --'),
                                  ),
                                  ...apoderados.map(
                                    (apoderado) => DropdownMenuItem<String>(
                                      value: apoderado['rut'],
                                      child: Text(
                                        '${apoderado['nombreCompleto']} (${apoderado['rut']})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedApoderadoRut = value;
                                    if (value != null) {
                                      final apoderado = apoderados.firstWhere(
                                        (a) => a['rut'] == value,
                                      );
                                      rutResponsableController.text = apoderado['rut'] ?? '';
                                      nombreResponsableController.text = apoderado['nombreCompleto'] ?? '';
                                    }
                                  });
                                },
                                validator: (value) {
                                  if (useExistingApoderado && value == null) {
                                    return 'Debe seleccionar un apoderado';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Mostrar info del apoderado seleccionado (solo lectura)
                              if (selectedApoderadoRut != null) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: nombreResponsableController,
                                        decoration: InputDecoration(
                                          labelText: 'Nombre Apoderado',
                                          prefixIcon: const Icon(Icons.person_outline),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                        ),
                                        enabled: false,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: rutResponsableController,
                                        decoration: InputDecoration(
                                          labelText: 'RUT Apoderado',
                                          prefixIcon: const Icon(Icons.badge_outlined),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                        ),
                                        enabled: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ] else ...[
                              _buildValidatedTextField(
                                controller: nombreResponsableController,
                                label: 'Nombre Responsable *',
                                icon: Icons.person_outline,
                                hint: 'Ej: María González',
                                validator: (value) {
                                  if (!useExistingApoderado && (value == null || value.trim().isEmpty)) {
                                    return 'Nombre del responsable es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildValidatedTextField(
                                      controller: rutResponsableController,
                                      label: 'RUT Responsable *',
                                      icon: Icons.badge_outlined,
                                      hint: 'Ej: 12.345.678-9',
                                      onChanged: (value) {
                                        if (!useExistingApoderado) {
                                          final formatted = _formatRut(value);
                                          if (formatted != value) {
                                            rutResponsableController.value = TextEditingValue(
                                              text: formatted,
                                              selection: TextSelection.collapsed(
                                                offset: formatted.length,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      validator: (value) {
                                        if (!useExistingApoderado) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'RUT del responsable es obligatorio';
                                          }
                                          if (!_isValidRut(value)) {
                                            return 'RUT inválido';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildValidatedTextField(
                                      controller: telefonoResponsableController,
                                      label: 'Teléfono Responsable',
                                      icon: Icons.phone_outlined,
                                      hint: '+56912345678 (solo números)',
                                      validator: (value) {
                                        if (value != null && value.isNotEmpty) {
                                          if (!_isValidPhone(value)) {
                                            return 'Solo números y + opcional';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ] else if (!isEdit) ...[
                            Text(
                              'No hay apoderados registrados. Los datos se ingresarán manualmente.',
                              style: TextStyle(
                                fontSize: 12,
                                color: WessexColors.maximumGrayMint,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildValidatedTextField(
                              controller: nombreResponsableController,
                              label: 'Nombre Responsable *',
                              icon: Icons.person_outline,
                              hint: 'Ej: María González',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nombre del responsable es obligatorio';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildValidatedTextField(
                                    controller: rutResponsableController,
                                    label: 'RUT Responsable *',
                                    icon: Icons.badge_outlined,
                                    hint: 'Ej: 12.345.678-9',
                                    onChanged: (value) {
                                      final formatted = _formatRut(value);
                                      if (formatted != value) {
                                        rutResponsableController.value = TextEditingValue(
                                          text: formatted,
                                          selection: TextSelection.collapsed(
                                            offset: formatted.length,
                                          ),
                                        );
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'RUT del responsable es obligatorio';
                                      }
                                      if (!_isValidRut(value)) {
                                        return 'RUT inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildValidatedTextField(
                                    controller: telefonoResponsableController,
                                    label: 'Teléfono Responsable',
                                    icon: Icons.phone_outlined,
                                    hint: '+56912345678 (solo números)',
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (!_isValidPhone(value)) {
                                          return 'Solo números y + opcional';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Modo edición: mostrar campos normales
                            _buildValidatedTextField(
                              controller: nombreResponsableController,
                              label: 'Nombre Responsable *',
                              icon: Icons.person_outline,
                              hint: 'Ej: María González',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nombre del responsable es obligatorio';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildValidatedTextField(
                                    controller: rutResponsableController,
                                    label: 'RUT Responsable *',
                                    icon: Icons.badge_outlined,
                                    hint: 'Ej: 12.345.678-9',
                                    onChanged: (value) {
                                      final formatted = _formatRut(value);
                                      if (formatted != value) {
                                        rutResponsableController.value = TextEditingValue(
                                          text: formatted,
                                          selection: TextSelection.collapsed(
                                            offset: formatted.length,
                                          ),
                                        );
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'RUT del responsable es obligatorio';
                                      }
                                      if (!_isValidRut(value)) {
                                        return 'RUT inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildValidatedTextField(
                                    controller: telefonoResponsableController,
                                    label: 'Teléfono Responsable',
                                    icon: Icons.phone_outlined,
                                    hint: '+56912345678 (solo números)',
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (!_isValidPhone(value)) {
                                          return 'Solo números y + opcional';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                          _buildSectionTitle('Información de Emergencia'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildValidatedTextField(
                                  controller: contactoEmergenciaController,
                                  label: 'Contacto Emergencia',
                                  icon: Icons.emergency,
                                  hint: 'Nombre del contacto',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildValidatedTextField(
                                  controller: telefonoEmergenciaController,
                                  label: 'Teléfono Emergencia',
                                  icon: Icons.phone_in_talk,
                                  hint: '+56912345678 (solo números)',
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!_isValidPhone(value)) {
                                        return 'Solo números y + opcional';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildValidatedTextField(
                            controller: observacionesController,
                            label: 'Observaciones',
                            icon: Icons.notes,
                            hint: 'Notas adicionales sobre el estudiante',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          print('🔍 DEBUG - Validando formulario...');
                          if (!formKey.currentState!.validate()) {
                            print('❌ DEBUG - Validación falló');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Por favor corrija los errores en el formulario',
                                ),
                                backgroundColor: WessexColors.crimsonAlert,
                              ),
                            );
                            return;
                          }

                          print('✅ DEBUG - Validación exitosa');
                          print('📝 DEBUG - useExistingApoderado: $useExistingApoderado');
                          print('📝 DEBUG - selectedApoderadoRut: $selectedApoderadoRut');

                          // Generar email del apoderado si se va a crear nuevo
                          String? correoApoderadoGenerado;
                          if (!isEdit && 
                              !useExistingApoderado && 
                              nombreResponsableController.text.trim().isNotEmpty) {
                            
                            // Normalizar nombre: quitar acentos, minúsculas, espacios por puntos
                            final nombreNormalizado = nombreResponsableController.text.trim()
                                .toLowerCase()
                                .replaceAll(RegExp(r'[áàäâ]'), 'a')
                                .replaceAll(RegExp(r'[éèëê]'), 'e')
                                .replaceAll(RegExp(r'[íìïî]'), 'i')
                                .replaceAll(RegExp(r'[óòöô]'), 'o')
                                .replaceAll(RegExp(r'[úùüû]'), 'u')
                                .replaceAll(RegExp(r'[ñ]'), 'n')
                                .replaceAll(RegExp(r'\s+'), '.');
                            
                            correoApoderadoGenerado = '${nombreNormalizado}0@wessex.cl';
                            print('📧 Email apoderado generado: $correoApoderadoGenerado');
                          }

                          final data = {
                            'rut': rutController.text.trim(),
                            'nombre': nombreController.text.trim(),
                            'curso': cursoController.text.trim(),
                            'fechaNacimiento': selectedDate != null
                                ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                                : '',
                            'direccion': direccionController.text.trim(),
                            'telefono': telefonoController.text.trim(),
                            'email': emailController.text.trim(),
                            'nombreResponsable':
                                nombreResponsableController.text.trim(),
                            'rutResponsable': rutResponsableController.text.trim(),
                            'telefonoResponsable':
                                telefonoResponsableController.text.trim(),
                            'contactoEmergencia':
                                contactoEmergenciaController.text.trim(),
                            'telefonoEmergencia':
                                telefonoEmergenciaController.text.trim(),
                            'observaciones': observacionesController.text.trim(),
                            if (correoApoderadoGenerado != null)
                              'correoApoderadoGenerado': correoApoderadoGenerado,
                          };

                          print('📤 DEBUG - Enviando datos: $data');

                          try {
                            print('🚀 DEBUG - Llamando API...');
                            final response = isEdit
                                ? await ApiService.updateEstudiante(
                                    estudiante!['rut'],
                                    data,
                                  )
                                : await ApiService.createEstudiante(data);
                            
                            print('📥 DEBUG - Respuesta recibida: ${response.statusCode}');

                            if (response.statusCode == 200 ||
                                response.statusCode == 201) {
                              
                              // Si no es edición y se proporcionó info del apoderado, crear usuario
                              if (!isEdit && 
                                  !useExistingApoderado && 
                                  data['rutResponsable'] != null && 
                                  data['rutResponsable'] != '' &&
                                  data['nombreResponsable'] != null &&
                                  data['nombreResponsable'] != '' &&
                                  correoApoderadoGenerado != null) {
                                
                                print('🔵 Creando usuario apoderado...');
                                
                                final apoderadoData = {
                                  'rut': data['rutResponsable'],
                                  'nombreCompleto': data['nombreResponsable'],
                                  'email': correoApoderadoGenerado,
                                  'password': 'wessex123',
                                  'rol': 'apoderado',
                                };
                                
                                try {
                                  final apoderadoResponse = await ApiService.createUserByDirectiva(apoderadoData);
                                  if (apoderadoResponse.statusCode == 200 || 
                                      apoderadoResponse.statusCode == 201) {
                                    print('✅ Usuario apoderado creado: $correoApoderadoGenerado');
                                  }
                                } catch (apoderadoError) {
                                  print('⚠️ Error al crear apoderado (puede que ya exista): $apoderadoError');
                                  // No fallar si el apoderado ya existe
                                }
                              }
                              
                              Navigator.pop(context);
                              await _loadEstudiantesFromAPI();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEdit
                                          ? 'Estudiante actualizado exitosamente'
                                          : 'Estudiante creado exitosamente',
                                    ),
                                    backgroundColor: WessexColors.leafGreen,
                                  ),
                                );
                              }
                            } else {
                              throw Exception(response.message ?? 'Error desconocido');
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: WessexColors.crimsonAlert,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WessexColors.leafGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isEdit ? 'Guardar Cambios' : 'Crear Estudiante'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatRut(String rut) {
    // Remover todo excepto números y K
    String cleaned = rut.replaceAll(RegExp(r'[^0-9Kk]'), '');
    if (cleaned.isEmpty) return '';
    
    // Si termina en K, convertir a mayúscula
    if (cleaned.toLowerCase().endsWith('k')) {
      cleaned = cleaned.substring(0, cleaned.length - 1) + 'K';
    }
    
    // Separar número y dígito verificador
    if (cleaned.length < 2) return cleaned;
    
    String dv = cleaned.substring(cleaned.length - 1);
    String numbers = cleaned.substring(0, cleaned.length - 1);
    
    // Formatear con puntos
    String formatted = '';
    int count = 0;
    for (int i = numbers.length - 1; i >= 0; i--) {
      if (count == 3) {
        formatted = '.$formatted';
        count = 0;
      }
      formatted = numbers[i] + formatted;
      count++;
    }
    
    return '$formatted-$dv';
  }

  bool _isValidRut(String rut) {
    // Remover puntos y guión
    String cleanRut = rut.replaceAll('.', '').replaceAll('-', '');
    if (cleanRut.length < 2) return false;
    
    // Validar formato básico (números y puede terminar en K)
    final rutPattern = RegExp(r'^\d{7,8}[0-9Kk]$');
    return rutPattern.hasMatch(cleanRut);
  }

  bool _isValidPhone(String phone) {
    // Solo números y opcionalmente + al principio
    final phonePattern = RegExp(r'^\+?\d+$');
    if (!phonePattern.hasMatch(phone.replaceAll(' ', ''))) {
      return false;
    }
    // Si tiene +, debe tener al menos 10 dígitos
    if (phone.startsWith('+')) {
      final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
      return digits.length >= 10;
    }
    // Sin +, debe tener al menos 9 dígitos
    return phone.length >= 9;
  }

  bool _isValidEmail(String email) {
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailPattern.hasMatch(email);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: WessexColors.deepRoyalBlue,
      ),
    );
  }

  Widget _buildValidatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    int? maxLength,
    String? hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: !enabled,
        fillColor: enabled ? null : WessexColors.mistyRoseGray.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        helperText: hint != null ? 'Formato: $hint' : null,
        helperStyle: TextStyle(
          fontSize: 11,
          color: WessexColors.deepRoyalBlue.withOpacity(0.7),
        ),
        counterText: maxLength != null ? '' : null,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: !enabled,
        fillColor: enabled ? null : WessexColors.mistyRoseGray.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  void _showStudentInfoDialog(Map<String, dynamic> estudiante) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person,
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
                            estudiante['nombre'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                          Text(
                            'RUT: ${estudiante['rut'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: WessexColors.darkGrape.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: WessexColors.darkGrape.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoSection(
                  'Información Académica',
                  Icons.school,
                  WessexColors.deepRoyalBlue,
                  [
                    _buildInfoRow('Curso:', estudiante['curso']),
                    _buildInfoRow('Categoría:', estudiante['categoria']),
                    _buildInfoRow(
                      'Ficha médica:',
                      _formatFicha(estudiante['ficha']),
                    ),
                    _buildInfoRow(
                      'Fecha nacimiento:',
                      _formatDate(estudiante['fechaNacimiento']),
                    ),
                    _buildInfoRow(
                      'Fecha registro:',
                      _formatDate(estudiante['fechaRegistro']),
                    ),
                    _buildInfoRow(
                      'Estado registro:',
                      _formatEstado(estudiante['estado']),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoSection(
                  'Información de Padres',
                  Icons.family_restroom,
                  WessexColors.leafGreen,
                  [
                    _buildInfoRow(
                      'Madre:',
                      _formatContactBlock(
                        estudiante['nombreMadre'],
                        estudiante['telefonoMadre'],
                        estudiante['emailMadre'],
                      ),
                    ),
                    _buildInfoRow(
                      'Padre:',
                      _formatContactBlock(
                        estudiante['nombrePadre'],
                        estudiante['telefonoPadre'],
                        estudiante['emailPadre'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoSection(
                  'Representante/Apoderado',
                  Icons.contact_phone,
                  WessexColors.maximumGrayMint,
                  [
                    _buildInfoRow('Nombre:', estudiante['nombreResponsable'] ?? estudiante['responsable']),
                    _buildInfoRow(
                      'Correo institucional:',
                      estudiante['correoApoderadoGenerado'],
                    ),
                    _buildInfoRow(
                      'Teléfono:',
                      estudiante['telefonoResponsable'] ??
                          estudiante['telefono'] ??
                          estudiante['telefonoEmergencia'],
                    ),
                    _buildInfoRow(
                      'Contacto emergencia:',
                      estudiante['contactoEmergencia'],
                    ),
                    _buildInfoRow(
                      'Observaciones:',
                      estudiante['observaciones'],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditStudentDialog(estudiante);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.deepRoyalBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    final displayValue = _formatValue(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: WessexColors.darkGrape,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                color: WessexColors.darkGrape.withOpacity(0.8),
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(Map<String, dynamic> estudiante) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar a ${estudiante['nombre']}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  _estudianteService.deleteStudent(estudiante['id']);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Estudiante ${estudiante['nombre']} eliminado',
                      ),
                      backgroundColor: WessexColors.crimsonAlert,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.crimsonAlert,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }
}
