import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/tipo_evento_model.dart';

class AdminTiposEventoScreen extends StatefulWidget {
  const AdminTiposEventoScreen({Key? key}) : super(key: key);

  @override
  State<AdminTiposEventoScreen> createState() => _AdminTiposEventoScreenState();
}

class _AdminTiposEventoScreenState extends State<AdminTiposEventoScreen> {
  List<TipoEvento> _tiposEvento = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarTiposEvento();
  }

  Future<void> _cargarTiposEvento() async {
    setState(() => _isLoading = true);
    try {
      final tiposData = await ApiService.obtenerTodosTiposEvento();
      final tipos = tiposData.map((data) => TipoEvento.fromJson(data)).toList();
      setState(() {
        _tiposEvento = tipos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar tipos de evento: ${e.toString()}');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _mostrarDialogoCrearTipo() async {
    final TextEditingController nombreController = TextEditingController();
    bool esDeportivo = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Crear Nuevo Tipo de Evento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del tipo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: esDeportivo,
                        onChanged: (value) {
                          setStateDialog(() {
                            esDeportivo = value ?? false;
                          });
                        },
                      ),
                      const Text('Es deportivo'),
                    ],
                  ),
                  if (esDeportivo)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Los tipos deportivos mostrarán la selección de categorías',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nombreController.text.trim().isEmpty) {
                      _mostrarError('El nombre es requerido');
                      return;
                    }

                    try {
                      await ApiService.crearTipoEvento(
                        nombreController.text.trim(),
                        esDeportivo,
                      );
                      Navigator.of(context).pop();
                      _mostrarExito('Tipo de evento creado exitosamente');
                      _cargarTiposEvento();
                    } catch (e) {
                      _mostrarError('Error al crear tipo: ${e.toString()}');
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDialogoEditarTipo(TipoEvento tipo) async {
    final TextEditingController nombreController = TextEditingController(text: tipo.nombre);
    bool esDeportivo = tipo.esDeportivo;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Tipo de Evento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del tipo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: esDeportivo,
                        onChanged: (value) {
                          setStateDialog(() {
                            esDeportivo = value ?? false;
                          });
                        },
                      ),
                      const Text('Es deportivo'),
                    ],
                  ),
                  if (esDeportivo)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Los tipos deportivos mostrarán la selección de categorías',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nombreController.text.trim().isEmpty) {
                      _mostrarError('El nombre es requerido');
                      return;
                    }

                    try {
                      await ApiService.actualizarTipoEvento(
                        tipo.id,
                        nombreController.text.trim(),
                        esDeportivo,
                        tipo.activo,
                      );
                      Navigator.of(context).pop();
                      _mostrarExito('Tipo de evento actualizado exitosamente');
                      _cargarTiposEvento();
                    } catch (e) {
                      _mostrarError('Error al actualizar tipo: ${e.toString()}');
                    }
                  },
                  child: const Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cambiarEstadoTipo(TipoEvento tipo) async {
    try {
      if (tipo.activo) {
        await ApiService.eliminarTipoEvento(tipo.id);
        _mostrarExito('Tipo de evento desactivado');
      } else {
        await ApiService.reactivarTipoEvento(tipo.id);
        _mostrarExito('Tipo de evento reactivado');
      }
      _cargarTiposEvento();
    } catch (e) {
      _mostrarError('Error al cambiar estado: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Tipos de Evento'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarTiposEvento,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gestión de Tipos de Evento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Los tipos deportivos mostrarán la selección de categorías al crear eventos. Los tipos no deportivos ocultarán esta opción.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _mostrarDialogoCrearTipo,
                            icon: const Icon(Icons.add),
                            label: const Text('Crear Nuevo Tipo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._tiposEvento.map((tipo) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tipo.esDeportivo ? Colors.green : Colors.orange,
                        child: Icon(
                          tipo.esDeportivo ? Icons.sports_soccer : Icons.event,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        tipo.nombre,
                        style: TextStyle(
                          decoration: tipo.activo ? null : TextDecoration.lineThrough,
                          color: tipo.activo ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tipo.esDeportivo ? 'Deportivo' : 'No deportivo'),
                          Text(
                            tipo.activo ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              color: tipo.activo ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _mostrarDialogoEditarTipo(tipo),
                            icon: const Icon(Icons.edit, color: Colors.blue),
                          ),
                          IconButton(
                            onPressed: () => _cambiarEstadoTipo(tipo),
                            icon: Icon(
                              tipo.activo ? Icons.visibility_off : Icons.visibility,
                              color: tipo.activo ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
    );
  }
}