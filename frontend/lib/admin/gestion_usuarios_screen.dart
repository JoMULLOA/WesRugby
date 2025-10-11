import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../services/usuario_service.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedRol = 'Todos';
  String _selectedEstado = 'Todos';
  List<Map<String, dynamic>> _filteredUsuarios = [];
  bool _isLoading = false;

  final List<String> _roles = ['Todos', 'admin', 'directiva', 'tesoreria', 'entrenador', 'apoderado'];
  final List<String> _estados = ['Todos', 'Activo', 'Pendiente activación', 'Inactivo', 'Suspendido'];

  @override
  void initState() {
    super.initState();
    _usuarioService.addListener(_updateUsuarios);
    _loadUsuariosFromDatabase();
  }

  @override
  void dispose() {
    _usuarioService.removeListener(_updateUsuarios);
    _searchController.dispose();
    super.dispose();
  }

  void _updateUsuarios() {
    if (mounted) {
      _loadUsuarios();
    }
  }

  // Cargar usuarios desde la base de datos
  Future<void> _loadUsuariosFromDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _usuarioService.loadUsuarios();
      _loadUsuarios(); // Aplicar filtros después de cargar
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    }
  }

  void _loadUsuarios() {
    List<Map<String, dynamic>> usuarios = _usuarioService.usuarios;
    
    // Aplicar filtros
    if (_selectedRol != 'Todos') {
      usuarios = usuarios.where((u) => 
        u['rol']?.toString().toLowerCase() == _selectedRol.toLowerCase()
      ).toList();
    }
    
    if (_selectedEstado != 'Todos') {
      usuarios = usuarios.where((u) => 
        u['estado']?.toString().toLowerCase() == _selectedEstado.toLowerCase()
      ).toList();
    }

    // Aplicar búsqueda
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      usuarios = _usuarioService.searchUsuarios(query);
    }

    setState(() {
      _filteredUsuarios = usuarios;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final estadisticas = _usuarioService.estadisticas;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: WessexColors.midnightNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsuariosFromDatabase,
            tooltip: 'Recargar usuarios',
          ),
        ],
      ),
      backgroundColor: WessexColors.mistyRoseGray,
      body: _usuarioService.isLoading && _filteredUsuarios.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: WessexColors.deepRoyalBlue,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando usuarios desde la base de datos...',
                    style: TextStyle(
                      color: WessexColors.darkGrape,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _usuarioService.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                          'Error al cargar usuarios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _usuarioService.error!,
                          style: TextStyle(
                            color: WessexColors.maximumGrayMint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsuariosFromDatabase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WessexColors.deepRoyalBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
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
                      
                      // Lista de usuarios
                      _buildUsuariosList(),
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
          'Resumen de Usuarios',
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
                  'Total Usuarios',
                  '${stats['total']}',
                  Icons.people,
                  WessexColors.deepRoyalBlue,
                ),
                _buildStatCard(
                  'Activos',
                  '${stats['activos']}',
                  Icons.check_circle,
                  WessexColors.leafGreen,
                ),
                _buildStatCard(
                  'Pendientes',
                  '${stats['pendientes']}',
                  Icons.pending,
                  WessexColors.maximumGrayMint,
                ),
                _buildStatCard(
                  'Inactivos',
                  '${stats['inactivos']}',
                  Icons.cancel,
                  WessexColors.crimsonAlert,
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
            'Buscar y Filtrar Usuarios',
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
                    Expanded(child: _buildRolDropdown()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildEstadoDropdown()),
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
                        Expanded(child: _buildRolDropdown()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildEstadoDropdown()),
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
      onChanged: (value) => _loadUsuarios(),
      decoration: InputDecoration(
        labelText: 'Buscar usuarios...',
        hintText: 'Nombre, email, RUT o rol',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildRolDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRol,
      onChanged: (value) {
        setState(() {
          _selectedRol = value!;
        });
        _loadUsuarios();
      },
      decoration: InputDecoration(
        labelText: 'Filtrar por Rol',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _roles.map((rol) {
        return DropdownMenuItem(
          value: rol,
          child: Text(rol),
        );
      }).toList(),
    );
  }

  Widget _buildEstadoDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedEstado,
      onChanged: (value) {
        setState(() {
          _selectedEstado = value!;
        });
        _loadUsuarios();
      },
      decoration: InputDecoration(
        labelText: 'Filtrar por Estado',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _estados.map((estado) {
        return DropdownMenuItem(
          value: estado,
          child: Text(estado),
        );
      }).toList(),
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: _loadUsuarios,
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

  Widget _buildUsuariosList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredUsuarios.isEmpty) {
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
              Icons.people_outline,
              size: 64,
              color: WessexColors.mistyRoseGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron usuarios',
              style: TextStyle(
                fontSize: 18,
                color: WessexColors.darkGrape,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba cambiar los filtros o crear nuevos usuarios',
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
                  'Lista de Usuarios (${_filteredUsuarios.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.darkGrape,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateUserDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Usuario'),
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
              columns: const [
                DataColumn(label: Text('RUT', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('NOMBRE', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('EMAIL', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ROL', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ESTADO', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ESTUDIANTE', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('FECHA CREACIÓN', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _filteredUsuarios.map((usuario) {
                return DataRow(
                  cells: [
                    DataCell(Text(usuario['rut'] ?? '')),
                    DataCell(Text(usuario['nombre'] ?? '')),
                    DataCell(Text(usuario['email'] ?? '')),
                    DataCell(_buildRolChip(usuario['rol'] ?? '')),
                    DataCell(_buildEstadoChip(usuario['estado'] ?? '')),
                    DataCell(Text(usuario['estudiante'] ?? 'N/A')),
                    DataCell(Text(_formatDate(usuario['fechaCreacion']))),
                    DataCell(_buildActionButtons(usuario)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolChip(String rol) {
    Color color;
    switch (rol.toLowerCase()) {
      case 'admin':
        color = WessexColors.crimsonAlert;
        break;
      case 'directiva':
        color = WessexColors.deepRoyalBlue;
        break;
      case 'tesoreria':
        color = WessexColors.midnightNavy;
        break;
      case 'entrenador':
        color = WessexColors.leafGreen;
        break;
      case 'apoderado':
        color = WessexColors.maximumGrayMint;
        break;
      default:
        color = WessexColors.mistyRoseGray;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        rol.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    switch (estado.toLowerCase()) {
      case 'activo':
        color = WessexColors.leafGreen;
        break;
      case 'pendiente activación':
        color = WessexColors.maximumGrayMint;
        break;
      case 'inactivo':
      case 'suspendido':
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
        estado.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> usuario) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _showEditUserDialog(usuario),
          icon: const Icon(Icons.edit),
          tooltip: 'Editar',
          color: WessexColors.deepRoyalBlue,
        ),
        IconButton(
          onPressed: () => _resetPassword(usuario),
          icon: const Icon(Icons.lock_reset),
          tooltip: 'Resetear contraseña',
          color: WessexColors.maximumGrayMint,
        ),
        IconButton(
          onPressed: () => _deleteUser(usuario),
          icon: const Icon(Icons.delete),
          tooltip: 'Eliminar',
          color: WessexColors.crimsonAlert,
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

  void _showCreateUserDialog() {
    // TODO: Implementar diálogo de creación de usuario
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de creación manual próximamente'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> usuario) {
    // TODO: Implementar diálogo de edición
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editar: ${usuario['nombre']}'),
        backgroundColor: WessexColors.deepRoyalBlue,
      ),
    );
  }

  void _resetPassword(Map<String, dynamic> usuario) {
    String newPassword = _usuarioService.resetPassword(usuario['id']);
    if (newPassword.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contraseña reseteada para ${usuario['nombre']}. Nueva contraseña: $newPassword'),
          backgroundColor: WessexColors.leafGreen,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _deleteUser(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${usuario['nombre']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _usuarioService.deleteUsuario(usuario['id']);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Usuario ${usuario['nombre']} eliminado'),
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