import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/services/refresh_service.dart';
import 'package:wesrugby/data/services/tokenManager.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  final TextEditingController _searchController = TextEditingController();
  late StreamSubscription _refreshSubscription;

  String _selectedRol = 'Todos';
  List<Map<String, dynamic>> _allUsuarios = [];
  List<Map<String, dynamic>> _filteredUsuarios = [];
  bool _isLoading = false;
  String? _error;

  final List<String> _roles = [
    'Todos',
    'directiva',
    'tesorera',
    'entrenador',
    'apoderado',
    'RamaExterna',
  ];

  @override
  void initState() {
    super.initState();
    _checkTokenOnInit();
    _loadUsuarios();
    // Escuchar cambios en los usuarios
    _refreshSubscription = RefreshService().usuariosStream.listen((_) {
      _loadUsuarios();
    });
  }

  Future<void> _checkTokenOnInit() async {
    final token = await TokenManager.getToken();
    debugPrint(
      '[DEBUG] GestionUsuarios initState - Token disponible: ${token != null ? "SI" : "NO"}',
    );
    if (token != null) {
      debugPrint(
        '[DEBUG] GestionUsuarios initState - Token (primeros 30 chars): ${token.substring(0, 30)}...',
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshSubscription.cancel();
    super.dispose();
  }

  // Cargar usuarios desde la API
  Future<void> _loadUsuarios() async {
    debugPrint('[DEBUG] GestionUsuarios - Iniciando carga de usuarios');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint(
        '[DEBUG] GestionUsuarios - Llamando a ApiService.getAllUsers()',
      );
      final response = await ApiService.getAllUsers();
      debugPrint(
        '[DEBUG] GestionUsuarios - Respuesta recibida: Status ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint(
          '[DEBUG] GestionUsuarios - Respuesta exitosa, procesando datos',
        );
        List<dynamic> usuariosData = response.data['data'] ?? response.data;

        setState(() {
          _allUsuarios =
              usuariosData
                  .map(
                    (usuario) => {
                      'rut': usuario['rut'] ?? '',
                      'nombreCompleto': usuario['nombreCompleto'] ?? '',
                      'email': usuario['email'] ?? '',
                      'rol': usuario['rol'] ?? '',
                      'fechaNacimiento': usuario['fechaNacimiento'],
                      'createdAt': usuario['createdAt'],
                      'updatedAt': usuario['updatedAt'],
                      'avatarUrl': usuario['avatarUrl'],
                      'avatarPath': usuario['avatarPath'],
                    },
                  )
                  .toList();
          _applyFilters();
        });
        debugPrint(
          '[DEBUG] GestionUsuarios - ${_allUsuarios.length} usuarios cargados exitosamente',
        );
      } else {
        debugPrint(
          '[DEBUG] GestionUsuarios - Error en respuesta: ${response.statusCode} - ${response.message}',
        );
        setState(() {
          _error = response.message ?? 'Error al cargar usuarios';
        });
      }
    } catch (e) {
      debugPrint('[DEBUG] GestionUsuarios - Excepcion capturada: $e');
      setState(() {
        _error = 'Error de conexion: $e';
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
      usuarios =
          usuarios
              .where(
                (u) =>
                    u['rol']?.toString().toLowerCase() ==
                    _selectedRol.toLowerCase(),
              )
              .toList();
    }

    // Aplicar busqueda
    String query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      usuarios =
          usuarios
              .where(
                (u) =>
                    (u['nombreCompleto']?.toString().toLowerCase().contains(
                          query,
                        ) ??
                        false) ||
                    (u['email']?.toString().toLowerCase().contains(query) ??
                        false) ||
                    (u['rut']?.toString().toLowerCase().contains(query) ??
                        false) ||
                    (u['rol']?.toString().toLowerCase().contains(query) ??
                        false),
              )
              .toList();
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
        title: 'Gestion de Usuarios - Directiva',
        elevation: 2,
      ),
      body: WessexBackground(
        child: SafeArea(
          child:
              _isLoading
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
                        // Header con estadisticas
                        _buildStatsCards(),

                        const SizedBox(height: 32),

                        // Controles de busqueda y filtros
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
    // Calcular estadisticas de usuarios
    int totalUsuarios = _allUsuarios.length;
    int directivas = _allUsuarios.where((u) => u['rol'] == 'directiva').length;
    int tesoreras = _allUsuarios.where((u) => u['rol'] == 'tesorera').length;
    int entrenadores =
        _allUsuarios.where((u) => u['rol'] == 'entrenador').length;
    int apoderados = _allUsuarios.where((u) => u['rol'] == 'apoderado').length;
    int coordinadores =
        _allUsuarios.where((u) => u['rol'] == 'RamaExterna').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WessexSectionTitle(
          title: 'Gestion de Usuarios',
          subtitle: 'Administre usuarios del sistema Wessex Rugby',
          titleColor: WessexColors.white,
        ),
        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount =
                constraints.maxWidth > 1200
                    ? 5
                    : constraints.maxWidth > 800
                    ? 3
                    : constraints.maxWidth > 600
                    ? 2
                    : 1;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Usuarios',
                  '$totalUsuarios',
                  Icons.people,
                  WessexColors.deepRoyalBlue,
                  constraints.maxWidth / crossAxisCount - 16,
                ),
                _buildStatCard(
                  'Directiva',
                  '$directivas',
                  Icons.admin_panel_settings,
                  WessexColors.crimsonAlert,
                  constraints.maxWidth / crossAxisCount - 16,
                ),
                _buildStatCard(
                  'Tesorera',
                  '$tesoreras',
                  Icons.account_balance_wallet,
                  WessexColors.midnightNavy,
                  constraints.maxWidth / crossAxisCount - 16,
                ),
                _buildStatCard(
                  'Entrenadores',
                  '$entrenadores',
                  Icons.sports_rugby,
                  WessexColors.leafGreen,
                  constraints.maxWidth / crossAxisCount - 16,
                ),
                _buildStatCard(
                  'Apoderados',
                  '$apoderados',
                  Icons.family_restroom,
                  WessexColors.maximumGrayMint,
                  constraints.maxWidth / crossAxisCount - 16,
                ),
                _buildStatCard(
                  'Coord. Rama',
                  '$coordinadores',
                  Icons.sports_soccer,
                  WessexColors.crimsonAlert,
                  constraints.maxWidth / crossAxisCount - 16,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Container(
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
                mainAxisSize: MainAxisSize.min,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items:
          _roles.map((rol) {
            return DropdownMenuItem(value: rol, child: Text(rol));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildUsuariosList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
          mainAxisSize: MainAxisSize.min,
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
              style: TextStyle(color: WessexColors.darkGrape.withOpacity(0.7)),
              textAlign: TextAlign.center,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
          Divider(
            height: 1,
            thickness: 1,
            color: WessexColors.mistyRoseGray.withOpacity(0.4),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = (constraints.maxWidth / 320).floor();
                if (crossAxisCount < 1) crossAxisCount = 1;
                if (crossAxisCount > 4) crossAxisCount = 4;

                final double cardWidth =
                    (constraints.maxWidth - (crossAxisCount - 1) * 20) /
                    crossAxisCount;

                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children:
                      _filteredUsuarios
                          .map(
                            (usuario) => SizedBox(
                              width: cardWidth,
                              child: _buildUsuarioCard(usuario),
                            ),
                          )
                          .toList(),
                );
              },
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
      case 'ramaexterna':
        color = const Color(0xFFFFA726); // Color naranja/amber para RamaExterna
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
        rol == 'RamaExterna' ? 'RAMA EXTERNA' : rol.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUsuarioCard(Map<String, dynamic> usuario) {
    final String nombre = usuario['nombreCompleto']?.toString() ?? 'Usuario';
    final String rut = usuario['rut']?.toString() ?? '';
    final String email = usuario['email']?.toString() ?? '';
    final String rol = usuario['rol']?.toString() ?? '';
    final String creado = _formatDate(usuario['createdAt']);
    final String actualizado = _formatDate(usuario['updatedAt']);
    final String? avatarUrl = _resolveUsuarioAvatar(usuario);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WessexColors.mistyRoseGray.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: WessexColors.mistyRoseGray.withOpacity(0.5),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child:
                    avatarUrl == null
                        ? Text(
                          _initialsForName(nombre),
                          style: TextStyle(
                            color: WessexColors.deepRoyalBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: WessexColors.darkGrape,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (rut.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.badge,
                            size: 14,
                            color: WessexColors.midnightNavy,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rut,
                              style: TextStyle(
                                color: WessexColors.midnightNavy,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (email.isNotEmpty) const SizedBox(height: 6),
                    if (email.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.mail_outline,
                            size: 14,
                            color: WessexColors.midnightNavy,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                color: WessexColors.midnightNavy.withOpacity(
                                  0.8,
                                ),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildRolChip(rol),
              _buildUsuarioInfoChip(
                icon: Icons.calendar_today,
                label: 'Creado: $creado',
              ),
              if (actualizado != 'N/A')
                _buildUsuarioInfoChip(
                  icon: Icons.update,
                  label: 'Actualizado: $actualizado',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => _showEditUserDialog(usuario),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Editar',
                color: WessexColors.deepRoyalBlue,
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(),
              ),
              IconButton(
                onPressed: () => _resetPassword(usuario),
                icon: const Icon(Icons.lock_reset, size: 20),
                tooltip: 'Resetear contrasena',
                color: WessexColors.maximumGrayMint,
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(),
              ),
              IconButton(
                onPressed: () => _deleteUser(usuario),
                icon: const Icon(Icons.delete, size: 20),
                tooltip: 'Eliminar',
                color: WessexColors.crimsonAlert,
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: WessexColors.mistyRoseGray.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: WessexColors.midnightNavy),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: WessexColors.midnightNavy.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveUsuarioAvatar(Map<String, dynamic> usuario) {
    final url = usuario['avatarUrl']?.toString();
    if (url != null && url.isNotEmpty) {
      return url;
    }
    final path = usuario['avatarPath']?.toString();
    if (path != null && path.isNotEmpty) {
      return ApiService.buildUploadUrl(path);
    }
    return null;
  }

  String _initialsForName(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first;
    final last = parts.last;
    return (first[0] + last[0]).toUpperCase();
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
    // TODO: Implementar reset de contrasena via API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidad de reset de contrasena en desarrollo'),
        backgroundColor: WessexColors.maximumGrayMint,
      ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> usuario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminacion'),
            content: Text(
              '?Esta seguro que desea eliminar al usuario ${usuario['nombreCompleto']}?\n\nEsta accion no se puede deshacer.',
            ),
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
              content: Text(
                'Usuario ${usuario['nombreCompleto']} eliminado exitosamente',
              ),
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
    final nombreController = TextEditingController(
      text: usuario?['nombreCompleto'] ?? '',
    );
    final emailController = TextEditingController(
      text: usuario?['email'] ?? '',
    );
    final passwordController = TextEditingController();
    String selectedRol = usuario?['rol'] ?? 'apoderado';

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                      enabled: !isEditing, // No editable en modo edicion
                      decoration: InputDecoration(
                        labelText: 'RUT',
                        hintText: '12.345.678-9',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        labelText: 'Correo Electronico',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El email es obligatorio';
                        }
                        if (!value.contains('@')) {
                          return 'Ingrese un email valido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Contrasena (solo para crear)
                    if (!isEditing)
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Contrasena',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La contrasena es obligatoria';
                          }
                          if (value.length < 6) {
                            return 'La contrasena debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                    if (!isEditing) const SizedBox(height: 16),

                    // Rol
                    DropdownButtonFormField<String>(
                      value:
                          [
                                'directiva',
                                'tesorera',
                                'entrenador',
                                'apoderado',
                                'RamaExterna',
                              ].contains(selectedRol)
                              ? selectedRol
                              : 'apoderado',
                      onChanged: (value) => selectedRol = value!,
                      decoration: InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          [
                                'directiva',
                                'tesorera',
                                'entrenador',
                                'apoderado',
                                'RamaExterna',
                              ]
                              .map(
                                (rol) => DropdownMenuItem(
                                  value: rol,
                                  child: Text(
                                    rol == 'RamaExterna'
                                        ? 'RAMA EXTERNA'
                                        : rol.toUpperCase(),
                                  ),
                                ),
                              )
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
                          onPressed:
                              () => _submitUserForm(
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
                            backgroundColor:
                                isEditing
                                    ? WessexColors.deepRoyalBlue
                                    : WessexColors.leafGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
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
