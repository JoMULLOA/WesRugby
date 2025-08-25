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

  Future<void> _createUser(Map<String, String> userData) async {
    try {
      final headers = await TokenManager.getAuthHeaders();
      if (headers == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.post(
        Uri.parse('${confGlobal.baseUrl}/auth/register'),
        headers: headers,
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario creado exitosamente')),
          );
          _loadUsers(); // Recargar la lista
        } else {
          throw Exception(data['message'] ?? 'Error desconocido');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Error ${response.statusCode}');
      }
    } catch (e) {
      print('Error creando usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creando usuario: $e')),
      );
    }
  }

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    final rutController = TextEditingController();
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final carreraController = TextEditingController();
    String selectedGenero = 'masculino';
    String selectedRol = 'estudiante';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Crear Nuevo Usuario',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: Container(
                width: 500, // Ancho fijo para web
                constraints: const BoxConstraints(maxHeight: 600),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      TextFormField(
                        controller: rutController,
                        decoration: const InputDecoration(
                          labelText: 'RUT',
                          hintText: 'Ej: 12.345.678-9',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El RUT es obligatorio';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'usuario@ejemplo.cl',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El email es obligatorio';
                          }
                          if (!value.contains('@')) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La contraseña es obligatoria';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: carreraController,
                        decoration: const InputDecoration(
                          labelText: 'Carrera',
                          hintText: 'Ej: Ingeniería Civil en Informática',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La carrera es obligatoria';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedGenero,
                        decoration: const InputDecoration(labelText: 'Género'),
                        items: const [
                          DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                          DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
                          DropdownMenuItem(value: 'prefiero_no_decir', child: Text('Prefiero no decir')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedGenero = value!;
                          });
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedRol,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: const [
                          DropdownMenuItem(value: 'estudiante', child: Text('Estudiante')),
                          DropdownMenuItem(value: 'administrador', child: Text('Administrador')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRol = value!;
                          });
                        },
                      ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final userData = {
                        'rut': rutController.text.trim(),
                        'nombreCompleto': nombreController.text.trim(),
                        'email': emailController.text.trim(),
                        'password': passwordController.text.trim(),
                        'carrera': carreraController.text.trim(),
                        'genero': selectedGenero,
                        'rol': selectedRol,
                        'fechaNacimiento': '2000-01-01', // Fecha por defecto
                      };
                      Navigator.pop(context);
                      _createUser(userData);
                    }
                  },
                  child: const Text('Crear Usuario'),
                ),
              ],
            );
          },
        );
      },
    );
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
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showCreateUserDialog,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Crear Usuario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF057233), // Leaf Green para acción afirmativa
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadUsers,
                  ),
                ],
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
        title: const Text('Wessex Rugby - Panel de Administración'),
        backgroundColor: const Color(0xFF041540), // Midnight Navy
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFB02A2E), // Crimson Alert para indicador
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.group),
              text: 'Gestión de Usuarios',
            ),
            Tab(
              icon: Icon(Icons.person),
              text: 'Mi Perfil',
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF0EAEB), // Misty Rose Gray para fondo
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200), // Ancho máximo para web
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildProfileTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
