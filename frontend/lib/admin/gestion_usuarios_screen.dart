import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../services/api_service.dart';
import '../widgets/wessex_widgets.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedRol = 'Todos';
  List<Map<String, dynamic>> _allUsuarios = [];
  List<Map<String, dynamic>> _filteredUsuarios = [];
  bool _isLoading = false;
  String? _error;

  final List<String> _roles = ['Todos', 'directiva', 'tesorera', 'entrenador', 'apoderado'];

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Cargar usuarios desde la API
  Future<void> _loadUsuarios() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getAllUsers();
      
      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> usuariosData = response.data['data'] ?? response.data;
        
        setState(() {
          _allUsuarios = usuariosData.map((usuario) => {
            'rut': usuario['rut'] ?? '',
            'nombreCompleto': usuario['nombreCompleto'] ?? '',
            'email': usuario['email'] ?? '',
            'rol': usuario['rol'] ?? '',
            'fechaNacimiento': usuario['fechaNacimiento'],
            'createdAt': usuario['createdAt'],
            'updatedAt': usuario['updatedAt'],
          }).toList();
          _applyFilters();
        });
      } else {
        setState(() {
          _error = response.message ?? 'Error al cargar usuarios';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> usuarios = List.from(_allUsuarios);
    
    // Aplicar filtro de rol
    if (_selectedRol != 'Todos') {
      usuarios = usuarios.where((u) => 
        u['rol']?.toString().toLowerCase() == _selectedRol.toLowerCase()
      ).toList();
    }

    // Aplicar búsqueda
    String query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      usuarios = usuarios.where((u) => 
        (u['nombreCompleto']?.toString().toLowerCase().contains(query) ?? false) ||
        (u['email']?.toString().toLowerCase().contains(query) ?? false) ||
        (u['rut']?.toString().toLowerCase().contains(query) ?? false) ||
        (u['rol']?.toString().toLowerCase().contains(query) ?? false)
      ).toList();
    }

    setState(() {
      _filteredUsuarios = usuarios;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Gestión de Usuarios - Directiva',
        elevation: 2,
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
                        'Cargando usuarios...',
                        style: TextStyle(
                          color: WessexColors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: WessexCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                                _error!,
                                style: TextStyle(
                                  color: WessexColors.maximumGrayMint,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadUsuarios,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WessexColors.deepRoyalBlue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con estadísticas
                          _buildStatsCards(),
                          
                          const SizedBox(height: 32),
                          
                          // Controles de búsqueda y filtros
                          _buildSearchAndFilters(),
                          
                          const SizedBox(height: 24),
                          
                          // Lista de usuarios
                          _buildUsuariosList(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    // Calcular estadísticas de usuarios
    int totalUsuarios = _allUsuarios.length;
    int directivas = _allUsuarios.where((u) => u['rol'] == 'directiva').length;
    int tesoreras = _allUsuarios.where((u) => u['rol'] == 'tesorera').length;
    int entrenadores = _allUsuarios.where((u) => u['rol'] == 'entrenador').length;
    int apoderados = _allUsuarios.where((u) => u['rol'] == 'apoderado').length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WessexSectionTitle(
          title: 'Gestión de Usuarios',
          subtitle: 'Administre usuarios del sistema Wessex Rugby',
          titleColor: WessexColors.white,
        ),
        const SizedBox(height: 20),
        
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200 ? 5 : 
                                constraints.maxWidth > 800 ? 3 : 
                                constraints.maxWidth > 600 ? 2 : 1;
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildStatCard(
                  'Total Usuarios',
                  '$totalUsuarios',
                  Icons.people,
                  WessexColors.deepRoyalBlue,
                ),
                _buildStatCard(
                  'Directiva',
                  '$directivas',
                  Icons.admin_panel_settings,
                  WessexColors.crimsonAlert,
                ),
                _buildStatCard(
                  'Tesorera',
                  '$tesoreras',
                  Icons.account_balance_wallet,
                  WessexColors.midnightNavy,
                ),
                _buildStatCard(
                  'Entrenadores',
                  '$entrenadores',
                  Icons.sports_rugby,
                  WessexColors.leafGreen,
                ),
                _buildStatCard(
                  'Apoderados',
                  '$apoderados',
                  Icons.family_restroom,
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
                    Expanded(flex: 3, child: _buildSearchField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildRolDropdown()),
                    const SizedBox(width: 16),
                    _buildRefreshButton(),
                    const SizedBox(width: 16),
                    _buildCreateUserButton(),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 16),
                    _buildRolDropdown(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildRefreshButton()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCreateUserButton()),
                      ],
                    ),
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
      onChanged: (value) => _applyFilters(),
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
        _applyFilters();
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

  Widget _buildCreateUserButton() {
    return ElevatedButton.icon(
      onPressed: _showCreateUserDialog,
      icon: const Icon(Icons.person_add),
      label: const Text('Crear Usuario'),
      style: ElevatedButton.styleFrom(
        backgroundColor: WessexColors.leafGreen,
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
                DataColumn(label: Text('FECHA CREACIÓN', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _filteredUsuarios.map((usuario) {
                return DataRow(
                  cells: [
                    DataCell(Text(usuario['rut'] ?? '')),
                    DataCell(Text(usuario['nombreCompleto'] ?? '')),
                    DataCell(Text(usuario['email'] ?? '')),
                    DataCell(_buildRolChip(usuario['rol'] ?? '')),
                    DataCell(Text(_formatDate(usuario['createdAt']))),
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
      case 'directiva':
        color = WessexColors.crimsonAlert;
        break;
      case 'tesorera':
        color = WessexColors.midnightNavy;
        break;
      case 'entrenador':
        color = WessexColors.leafGreen;
        break;
      case 'apoderado':
        color = WessexColors.deepRoyalBlue;
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
    _showUserFormDialog();
  }

  void _showEditUserDialog(Map<String, dynamic> usuario) {
    _showUserFormDialog(usuario: usuario);
  }

  void _resetPassword(Map<String, dynamic> usuario) {
    // TODO: Implementar reset de contraseña via API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidad de reset de contraseña en desarrollo'),
        backgroundColor: WessexColors.maximumGrayMint,
      ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> usuario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro que desea eliminar al usuario ${usuario['nombreCompleto']}?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WessexColors.crimsonAlert,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.deleteUserByDirectiva(usuario['rut']);
        
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario ${usuario['nombreCompleto']} eliminado exitosamente'),
              backgroundColor: WessexColors.leafGreen,
            ),
          );
          _loadUsuarios(); // Recargar la lista
        } else {
          throw Exception(response.message ?? 'Error al eliminar usuario');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar usuario: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    }
  }

  void _showUserFormDialog({Map<String, dynamic>? usuario}) {
    final isEditing = usuario != null;
    final formKey = GlobalKey<FormState>();
    
    final rutController = TextEditingController(text: usuario?['rut'] ?? '');
    final nombreController = TextEditingController(text: usuario?['nombreCompleto'] ?? '');
    final emailController = TextEditingController(text: usuario?['email'] ?? '');
    final passwordController = TextEditingController();
    String selectedRol = usuario?['rol'] ?? 'apoderado';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Editar Usuario' : 'Crear Nuevo Usuario',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.darkGrape,
                  ),
                ),
                const SizedBox(height: 24),
                
                // RUT
                TextFormField(
                  controller: rutController,
                  enabled: !isEditing, // No editable en modo edición
                  decoration: InputDecoration(
                    labelText: 'RUT',
                    hintText: '12.345.678-9',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El RUT es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Nombre Completo
                TextFormField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El email es obligatorio';
                    }
                    if (!value.contains('@')) {
                      return 'Ingrese un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Contraseña (solo para crear)
                if (!isEditing) ...[
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La contraseña es obligatoria';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Rol
                DropdownButtonFormField<String>(
                  value: selectedRol,
                  onChanged: (value) => selectedRol = value!,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['directiva', 'tesorera', 'entrenador', 'apoderado']
                      .map((rol) => DropdownMenuItem(value: rol, child: Text(rol.toUpperCase())))
                      .toList(),
                ),
                const SizedBox(height: 24),
                
                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _submitUserForm(
                        context,
                        formKey,
                        isEditing,
                        rutController.text,
                        nombreController.text,
                        emailController.text,
                        passwordController.text,
                        selectedRol,
                        usuario,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEditing ? WessexColors.deepRoyalBlue : WessexColors.leafGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(isEditing ? 'Actualizar' : 'Crear'),
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

  Future<void> _submitUserForm(
    BuildContext context,
    GlobalKey<FormState> formKey,
    bool isEditing,
    String rut,
    String nombre,
    String email,
    String password,
    String rol,
    Map<String, dynamic>? usuario,
  ) async {
    if (!formKey.currentState!.validate()) return;

    try {
      if (isEditing) {
        // Actualizar usuario existente
        final response = await ApiService.updateUserByDirectiva({
          'rut': rut,
          'nombreCompleto': nombre,
          'email': email,
          'rol': rol,
        });
        
        if (response.statusCode == 200) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario actualizado exitosamente'),
              backgroundColor: WessexColors.leafGreen,
            ),
          );
          _loadUsuarios();
        } else {
          throw Exception(response.message ?? 'Error al actualizar usuario');
        }
      } else {
        // Crear nuevo usuario
        final response = await ApiService.createUserByDirectiva({
          'rut': rut.trim(),
          'nombreCompleto': nombre.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'rol': rol,
        });
        
        if (response.statusCode == 201) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario creado exitosamente'),
              backgroundColor: WessexColors.leafGreen,
            ),
          );
          _loadUsuarios();
        } else {
          throw Exception(response.message ?? 'Error al crear usuario');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }
}