import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../services/estudiante_service.dart';

class BaseDatosScreen extends StatefulWidget {
  const BaseDatosScreen({super.key});

  @override
  State<BaseDatosScreen> createState() => _BaseDatosScreenState();
}

class _BaseDatosScreenState extends State<BaseDatosScreen> {
  final EstudianteService _estudianteService = EstudianteService();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCurso = 'Todos';
  String _selectedValidez = 'Todos';
  List<Map<String, dynamic>> _filteredEstudiantes = [];
  bool _isLoading = false;

  final List<String> _cursos = ['Todos', 'Kínder', '1°A', '2°A', '3°A', '4°A', 'Sub-14', 'Sub-16', 'Sub-18'];
  final List<String> _validezOptions = ['Todos', 'Válido', 'Vencido', 'Activo', 'Inactivo'];

  @override
  void initState() {
    super.initState();
    _estudianteService.addListener(_updateEstudiantes);
    _loadEstudiantes();
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

  void _loadEstudiantes() {
    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> estudiantes = _estudianteService.getAllStudents();
    
    // Aplicar filtros
    if (_selectedCurso != 'Todos') {
      estudiantes = estudiantes.where((e) => 
        e['curso']?.toString().toLowerCase() == _selectedCurso.toLowerCase()
      ).toList();
    }
    
    if (_selectedValidez != 'Todos') {
      estudiantes = estudiantes.where((e) => 
        e['validez']?.toString().toLowerCase() == _selectedValidez.toLowerCase()
      ).toList();
    }

    // Aplicar búsqueda
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      estudiantes = _estudianteService.searchStudents(query: query);
    }

    setState(() {
      _filteredEstudiantes = estudiantes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final estadisticas = _estudianteService.getStudentStatistics();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Base de Datos - Estudiantes'),
        backgroundColor: WessexColors.midnightNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.download),
            tooltip: 'Exportar a Excel',
          ),
        ],
      ),
      backgroundColor: WessexColors.mistyRoseGray,
      body: SingleChildScrollView(
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
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas de Estudiantes',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: WessexColors.darkGrape,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                                constraints.maxWidth > 800 ? 3 : 
                                constraints.maxWidth > 600 ? 2 : 1;
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3.5,
              children: [
                _buildStatCard(
                  'Total Estudiantes',
                  '${stats['total']}',
                  Icons.school,
                  WessexColors.deepRoyalBlue,
                ),
                _buildStatCard(
                  'Activos',
                  '${stats['activos']}',
                  Icons.check_circle,
                  WessexColors.leafGreen,
                ),
                _buildStatCard(
                  'Inactivos',
                  '${stats['inactivos']}',
                  Icons.cancel,
                  WessexColors.crimsonAlert,
                ),
                _buildStatCard(
                  'Cursos',
                  '${(stats['porCurso'] as Map).length}',
                  Icons.class_,
                  WessexColors.maximumGrayMint,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
              bool isDesktop = constraints.maxWidth > 800;
              
              if (isDesktop) {
                return Row(
                  children: [
                    Expanded(flex: 2, child: _buildSearchField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCursoDropdown()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildValidezDropdown()),
                    const SizedBox(width: 16),
                    _buildRefreshButton(),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildCursoDropdown()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildValidezDropdown()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRefreshButton(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => _loadEstudiantes(),
      decoration: InputDecoration(
        labelText: 'Buscar estudiantes...',
        hintText: 'Nombre, RUT, padre, madre, responsable',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildCursoDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCurso,
      onChanged: (value) {
        setState(() {
          _selectedCurso = value!;
        });
        _loadEstudiantes();
      },
      decoration: InputDecoration(
        labelText: 'Filtrar por Curso',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _cursos.map((curso) {
        return DropdownMenuItem(
          value: curso,
          child: Text(curso),
        );
      }).toList(),
    );
  }

  Widget _buildValidezDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedValidez,
      onChanged: (value) {
        setState(() {
          _selectedValidez = value!;
        });
        _loadEstudiantes();
      },
      decoration: InputDecoration(
        labelText: 'Filtrar por Validez',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _validezOptions.map((validez) {
        return DropdownMenuItem(
          value: validez,
          child: Text(validez),
        );
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEstudiantesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
              style: TextStyle(
                color: WessexColors.darkGrape.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

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
            padding: const EdgeInsets.all(24),
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
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                WessexColors.deepRoyalBlue.withOpacity(0.1),
              ),
              dataRowMaxHeight: 60,
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
                    'VALIDEZ',
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
              rows: _filteredEstudiantes.map((estudiante) {
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
                    DataCell(_buildValidezChip(estudiante['validez'] ?? '')),
                    DataCell(
                      Container(
                        decoration: BoxDecoration(
                          color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () => _showStudentInfoDialog(estudiante),
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
        ],
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

  Widget _buildValidezChip(String validez) {
    Color color;
    switch (validez.toLowerCase()) {
      case 'válido':
      case 'activo':
        color = WessexColors.leafGreen;
        break;
      case 'vencido':
      case 'inactivo':
        color = WessexColors.crimsonAlert;
        break;
      default:
        color = WessexColors.mistyRoseGray;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        validez.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
    if (date == null) return 'N/A';
    if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return date.toString();
  }

  void _exportToExcel() {
    // TODO: Implementar exportación a Excel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de exportación próximamente'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showAddStudentDialog() {
    // TODO: Implementar diálogo de agregar estudiante
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de creación manual próximamente'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showEditStudentDialog(Map<String, dynamic> estudiante) {
    // TODO: Implementar diálogo de edición
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editar: ${estudiante['nombre']}'),
        backgroundColor: WessexColors.deepRoyalBlue,
      ),
    );
  }

  void _showStudentInfoDialog(Map<String, dynamic> estudiante) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
              
              // Información Académica
              _buildInfoSection(
                'Información Académica',
                Icons.school,
                WessexColors.deepRoyalBlue,
                [
                  _buildInfoRow('Curso:', estudiante['curso']),
                  _buildInfoRow('Estado:', estudiante['validez']),
                  _buildInfoRow('Fecha Registro:', _formatDate(estudiante['fechaRegistro'])),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Información de Padres
              _buildInfoSection(
                'Información de Padres',
                Icons.family_restroom,
                WessexColors.leafGreen,
                [
                  _buildInfoRow('Padre:', estudiante['padre']),
                  _buildInfoRow('Madre:', estudiante['madre']),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Información del Representante
              _buildInfoSection(
                'Representante/Apoderado',
                Icons.contact_phone,
                WessexColors.maximumGrayMint,
                [
                  _buildInfoRow('Nombre:', estudiante['responsable']),
                  _buildInfoRow('RUT:', estudiante['rutResponsable']),
                  _buildInfoRow('Estado:', estudiante['estado'] ?? 'Registrado'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
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
    );
  }

  Widget _buildInfoSection(String title, IconData icon, Color color, List<Widget> children) {
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
              value?.toString() ?? 'N/A',
              style: TextStyle(
                color: WessexColors.darkGrape.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(Map<String, dynamic> estudiante) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${estudiante['nombre']}?'),
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
                  content: Text('Estudiante ${estudiante['nombre']} eliminado'),
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