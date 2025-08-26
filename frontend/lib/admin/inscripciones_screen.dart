import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../config/confGlobal.dart';
import '../services/api_service.dart';

class InscripcionesScreen extends StatefulWidget {
  const InscripcionesScreen({super.key});

  @override
  State<InscripcionesScreen> createState() => _InscripcionesScreenState();
}

class _InscripcionesScreenState extends State<InscripcionesScreen> {
  List<Map<String, dynamic>> inscripciones = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInscripciones();
  }

  Future<void> _loadInscripciones() async {
    try {
      setState(() => isLoading = true);
      final response = await ApiService.get('/inscripciones');
      if (response.statusCode == 200) {
        setState(() {
          inscripciones = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando inscripciones: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _aprobarInscripcion(String id) async {
    try {
      final response = await ApiService.put('/inscripciones/$id/aprobar');
      if (response.statusCode == 200) {
        _loadInscripciones();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscripción aprobada exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error aprobando inscripción: $e')),
      );
    }
  }

  Future<void> _rechazarInscripcion(String id) async {
    try {
      final response = await ApiService.put('/inscripciones/$id/rechazar');
      if (response.statusCode == 200) {
        _loadInscripciones();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscripción rechazada')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rechazando inscripción: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inscripciones'),
        backgroundColor: AppColors.verdePrincipal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInscripciones,
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.verdePrincipal,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInscripciones,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: inscripciones.length,
                itemBuilder: (context, index) {
                  final inscripcion = inscripciones[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(inscripcion['estado']),
                        child: Icon(
                          _getStatusIcon(inscripcion['estado']),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        '${inscripcion['nombres']} ${inscripcion['apellidos']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Categoría: ${inscripcion['categoria'] ?? 'No especificada'}'),
                          Text('Estado: ${inscripcion['estado']}'),
                          Text('Fecha: ${inscripcion['fechaInscripcion']}'),
                        ],
                      ),
                      trailing: _buildActionButtons(inscripcion),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> inscripcion) {
    if (inscripcion['estado'] == 'pendiente') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => _aprobarInscripcion(inscripcion['_id']),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _rechazarInscripcion(inscripcion['_id']),
          ),
        ],
      );
    }
    return Icon(_getStatusIcon(inscripcion['estado']));
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'aprobada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'inactiva':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.hourglass_empty;
      case 'aprobada':
        return Icons.check_circle;
      case 'rechazada':
        return Icons.cancel;
      case 'inactiva':
        return Icons.pause_circle;
      default:
        return Icons.info;
    }
  }

  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final nombresController = TextEditingController();
    final apellidosController = TextEditingController();
    final emailController = TextEditingController();
    final telefonoController = TextEditingController();
    String categoria = 'juvenil';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Inscripción'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombresController,
                  decoration: const InputDecoration(
                    labelText: 'Nombres',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: apellidosController,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Campo requerido';
                    if (!value!.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'juvenil', child: Text('Juvenil')),
                    DropdownMenuItem(value: 'senior', child: Text('Senior')),
                    DropdownMenuItem(value: 'veteranos', child: Text('Veteranos')),
                  ],
                  onChanged: (value) => categoria = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final response = await ApiService.post('/inscripciones', {
                    'nombres': nombresController.text,
                    'apellidos': apellidosController.text,
                    'email': emailController.text,
                    'telefono': telefonoController.text,
                    'categoria': categoria,
                  });
                  
                  if (response.statusCode == 201) {
                    Navigator.pop(context);
                    _loadInscripciones();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inscripción creada exitosamente')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creando inscripción: $e')),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
