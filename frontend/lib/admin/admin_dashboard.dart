import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/confGlobal.dart';
import '../utils/token_manager.dart';
import '../auth/login.dart';
import 'admin_profile.dart';

class AdminDashboard extends StatefulWidget {
  final int? initialTab;
  
  const AdminDashboard({super.key, this.initialTab});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, // Solo 2 tabs: Usuarios y Perfil
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final headers = await TokenManager.getAuthHeaders();
      if (headers == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse('${confGlobal.baseUrl}/user/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _users = data['data'];
            _isLoading = false;
          });
        } else {
          throw Exception('Error en la respuesta del servidor');
        }
      } else {
        throw Exception('Error : ');
      }
    } catch (e) {
      print('Error cargando usuarios: ');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando usuarios: ')),
        );
      }
    }
  }

  Future<void> _changeUserRole(String userRut, String newRole) async {
    try {
      final headers = await TokenManager.getAuthHeaders();
      if (headers == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.put(
        Uri.parse('${confGlobal.baseUrl}/user/changeRole'),
        headers: headers,
        body: json.encode({
          'rut': userRut,
          'nuevoRol': newRole,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rol actualizado exitosamente')),
          );
          _loadUsers(); // Recargar la lista
        } else {
          throw Exception(data['message'] ?? 'Error desconocido');
        }
      } else {
        throw Exception('Error ');
      }
    } catch (e) {
      print('Error cambiando rol: ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cambiando rol: ')),
      );
    }
  }

  Future<void> _deleteUser(String userRut) async {
    try {
      final headers = await TokenManager.getAuthHeaders();
      if (headers == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.delete(
        Uri.parse('${confGlobal.baseUrl}/user/delete/$userRut'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario eliminado exitosamente')),
          );
          _loadUsers(); // Recargar la lista
        } else {
          throw Exception(data['message'] ?? 'Error desconocido');
        }
      } else {
        throw Exception('Error ');
      }
    } catch (e) {
      print('Error eliminando usuario: ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando usuario: ')),
      );
    }
  }

  void _showUserActions(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Acciones para ',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(user['rol'] == 'administrador' 
                    ? 'Cambiar a Estudiante' 
                    : 'Cambiar a Administrador'),
                onTap: () {
                  Navigator.pop(context);
                  final newRole = user['rol'] == 'administrador' ? 'estudiante' : 'administrador';
                  _changeUserRole(user['rut'], newRole);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar Usuario', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteUser(user);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar al usuario ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteUser(user['rut']);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Usuarios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('No hay usuarios registrados'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user['rol'] == 'administrador' 
                                  ? Colors.red.shade100 
                                  : Colors.blue.shade100,
                              child: Icon(
                                user['rol'] == 'administrador' 
                                    ? Icons.admin_panel_settings 
                                    : Icons.person,
                                color: user['rol'] == 'administrador' 
                                    ? Colors.red.shade700 
                                    : Colors.blue.shade700,
                              ),
                            ),
                            title: Text(user['nombreCompleto'] ?? 'Sin nombre'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Email: '),
                                Text('RUT: '),
                                Text('Rol: '),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showUserActions(user),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return const AdminProfile();
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error durante logout: ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: const Color(0xFF6B3B2D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.group), text: 'Usuarios'),
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }
}
