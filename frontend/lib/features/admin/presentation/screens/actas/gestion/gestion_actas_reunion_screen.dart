import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

class GestionActasReunionScreen extends StatefulWidget {
  const GestionActasReunionScreen({super.key});

  @override
  State<GestionActasReunionScreen> createState() =>
      _GestionActasReunionScreenState();
}

class _GestionActasReunionScreenState extends State<GestionActasReunionScreen> {
  List<Map<String, dynamic>> _actas = [];
  bool _isLoading = false;
  String? _error;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _cargarActas();
  }

  Future<void> _cargarActas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.obtenerActasReunion(
        estado: _filtroEstado == 'todos' ? null : _filtroEstado,
      );

      if (response.success && response.data != null) {
        setState(() {
          _actas = List<Map<String, dynamic>>.from(
            response.data['data'] ?? response.data,
          );
        });
      } else {
        setState(() {
          _error = response.message ?? 'Error al cargar actas';
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

  void _mostrarDialogoCrearEditar({Map<String, dynamic>? acta}) {
    final isEditing = acta != null;
    final tituloController = TextEditingController(text: acta?['titulo'] ?? '');
    final descripcionController = TextEditingController(
      text: acta?['descripcion'] ?? '',
    );
    final lugarController = TextEditingController(text: acta?['lugar'] ?? '');
    final asistentesController = TextEditingController(
      text: acta?['asistentes'] ?? '',
    );
    final acuerdosController = TextEditingController(
      text: acta?['acuerdos'] ?? '',
    );
    final compromisosController = TextEditingController(
      text: acta?['proximosCompromiso'] ?? '',
    );

    DateTime fechaSeleccionada =
        acta != null ? DateTime.parse(acta['fecha']) : DateTime.now();
    TimeOfDay? horaInicio =
        acta?['horaInicio'] != null
            ? TimeOfDay.fromDateTime(
              DateFormat('HH:mm:ss').parse(acta!['horaInicio']),
            )
            : null;
    TimeOfDay? horaFin =
        acta?['horaFin'] != null
            ? TimeOfDay.fromDateTime(
              DateFormat('HH:mm:ss').parse(acta!['horaFin']),
            )
            : null;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              isEditing ? 'Editar Acta de Reunión' : 'Nueva Acta de Reunión',
              style: const TextStyle(
                color: WessexColors.deepNavyBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección: Información Básica
                    _buildSectionTitle('Información Básica'),
                    const SizedBox(height: 12),
                    
                    // Título
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título de la reunión *',
                        hintText: 'Ej: Reunión Mensual de Directiva',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fecha
                    StatefulBuilder(
                      builder:
                          (context, setDialogState) => InkWell(
                            onTap: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: fechaSeleccionada,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (fecha != null) {
                                setDialogState(() {
                                  fechaSeleccionada = fecha;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha de la reunión *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(fechaSeleccionada),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Horas
                    Row(
                      children: [
                        Expanded(
                          child: StatefulBuilder(
                            builder:
                                (context, setDialogState) => InkWell(
                                  onTap: () async {
                                    final hora = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          horaInicio ?? TimeOfDay.now(),
                                    );
                                    if (hora != null) {
                                      setDialogState(() {
                                        horaInicio = hora;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Hora inicio',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.access_time),
                                    ),
                                    child: Text(
                                      horaInicio?.format(context) ?? 'Seleccionar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: horaInicio == null
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatefulBuilder(
                            builder:
                                (context, setDialogState) => InkWell(
                                  onTap: () async {
                                    final hora = await showTimePicker(
                                      context: context,
                                      initialTime: horaFin ?? TimeOfDay.now(),
                                    );
                                    if (hora != null) {
                                      setDialogState(() {
                                        horaFin = hora;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Hora fin',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.access_time_filled),
                                    ),
                                    child: Text(
                                      horaFin?.format(context) ?? 'Seleccionar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: horaFin == null
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lugar
                    TextField(
                      controller: lugarController,
                      decoration: const InputDecoration(
                        labelText: 'Lugar de la reunión',
                        hintText: 'Ej: Sala de Reuniones, Club Wessex',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sección: Contenido de la Reunión
                    _buildSectionTitle('Contenido de la Reunión'),
                    const SizedBox(height: 12),

                    // Descripción
                    TextField(
                      controller: descripcionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción de la reunión *',
                        hintText: 'Describe brevemente el propósito y contexto de la reunión...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Asistentes
                    TextField(
                      controller: asistentesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Asistentes',
                        hintText: '• Juan Pérez - Presidente\n• María González - Tesorera\n• Carlos López - Secretario\n(Un asistente por línea)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.people),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sección: Resoluciones
                    _buildSectionTitle('Resoluciones y Compromisos'),
                    const SizedBox(height: 12),

                    // Acuerdos
                    TextField(
                      controller: acuerdosController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Acuerdos tomados',
                        hintText: '• Se aprobó el presupuesto para el torneo\n• Se acordó realizar evento benéfico\n• Se aprobó nueva camiseta\n(Un acuerdo por línea)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.check_circle_outline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Próximos compromisos
                    TextField(
                      controller: compromisosController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Próximos compromisos y fechas',
                        hintText: '• Organizar torneo - Fecha: 15/12/2024\n• Reunión con sponsors - Fecha: 20/11/2024\n• Entrega de uniformes - Fecha: 05/12/2024\n(Un compromiso por línea con fecha)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.event_note),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nota informativa
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Los campos marcados con * son obligatorios',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (tituloController.text.trim().isEmpty ||
                      descripcionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Título y descripción son obligatorios'),
                      ),
                    );
                    return;
                  }

                  final actaData = {
                    'titulo': tituloController.text.trim(),
                    'fecha': DateFormat('yyyy-MM-dd').format(fechaSeleccionada),
                    'horaInicio':
                        horaInicio != null
                            ? '${horaInicio!.hour.toString().padLeft(2, '0')}:${horaInicio!.minute.toString().padLeft(2, '0')}:00'
                            : null,
                    'horaFin':
                        horaFin != null
                            ? '${horaFin!.hour.toString().padLeft(2, '0')}:${horaFin!.minute.toString().padLeft(2, '0')}:00'
                            : null,
                    'lugar':
                        lugarController.text.trim().isEmpty
                            ? null
                            : lugarController.text.trim(),
                    'descripcion': descripcionController.text.trim(),
                    'asistentes':
                        asistentesController.text.trim().isEmpty
                            ? null
                            : asistentesController.text.trim(),
                    'acuerdos':
                        acuerdosController.text.trim().isEmpty
                            ? null
                            : acuerdosController.text.trim(),
                    'proximosCompromiso':
                        compromisosController.text.trim().isEmpty
                            ? null
                            : compromisosController.text.trim(),
                    'estado': 'borrador',
                  };

                  try {
                    final response =
                        isEditing
                            ? await ApiService.actualizarActaReunion(
                              acta['id'],
                              actaData,
                            )
                            : await ApiService.crearActaReunion(actaData);

                    if (response.success) {
                      Navigator.of(context).pop();
                      _cargarActas();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Acta actualizada exitosamente'
                                : 'Acta creada exitosamente',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            response.message ?? 'Error al guardar acta',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: Text(isEditing ? 'Actualizar' : 'Crear'),
              ),
            ],
          ),
    );
  }

  void _cambiarEstado(Map<String, dynamic> acta, String nuevoEstado) async {
    try {
      final response = await ApiService.cambiarEstadoActa(
        acta['id'],
        nuevoEstado,
      );

      if (response.success) {
        _cargarActas();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado cambiado a: $nuevoEstado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Error al cambiar estado'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _eliminarActa(Map<String, dynamic> acta) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que deseas eliminar el acta "${acta['titulo']}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmacion == true) {
      try {
        final response = await ApiService.eliminarActaReunion(acta['id']);

        if (response.success) {
          _cargarActas();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acta eliminada exitosamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Error al eliminar acta'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildActaCard(Map<String, dynamic> acta) {
    final fecha = DateTime.parse(acta['fecha']);
    final estado = acta['estado'] ?? 'borrador';

    Color estadoColor;
    IconData estadoIcon;
    switch (estado) {
      case 'publicada':
        estadoColor = Colors.green;
        estadoIcon = Icons.public;
        break;
      case 'archivada':
        estadoColor = Colors.grey;
        estadoIcon = Icons.archive;
        break;
      default:
        estadoColor = Colors.orange;
        estadoIcon = Icons.edit;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acta['titulo'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(fecha),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (acta['lugar'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              acta['lugar'],
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    border: Border.all(color: estadoColor),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, size: 16, color: estadoColor),
                      const SizedBox(width: 4),
                      Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                          color: estadoColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              acta['descripcion'],
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            
            // Botones de acción en horizontal
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Botón de Editar
                ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoCrearEditar(acta: acta),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.deepRoyalBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
                
                // Botón Publicar
                if (estado != 'publicada')
                  OutlinedButton.icon(
                    onPressed: () => _cambiarEstado(acta, 'publicada'),
                    icon: const Icon(Icons.public, size: 16, color: Colors.green),
                    label: const Text(
                      'Publicar',
                      style: TextStyle(color: Colors.green),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                
                // Botón Archivar
                if (estado != 'archivada')
                  OutlinedButton.icon(
                    onPressed: () => _cambiarEstado(acta, 'archivada'),
                    icon: const Icon(Icons.archive, size: 16, color: Colors.grey),
                    label: const Text(
                      'Archivar',
                      style: TextStyle(color: Colors.grey),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                
                // Botón Pasar a Borrador
                if (estado != 'borrador')
                  OutlinedButton.icon(
                    onPressed: () => _cambiarEstado(acta, 'borrador'),
                    icon: const Icon(Icons.edit_note, size: 16, color: Colors.orange),
                    label: const Text(
                      'Borrador',
                      style: TextStyle(color: Colors.orange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                
                // Botón Eliminar
                OutlinedButton.icon(
                  onPressed: () => _eliminarActa(acta),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(title: 'Actas de Reunión', elevation: 2),
      body: WessexBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Filtros y botón crear
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Filtro por estado
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroEstado,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por estado',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'todos',
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: 'borrador',
                            child: Text('Borradores'),
                          ),
                          DropdownMenuItem(
                            value: 'publicada',
                            child: Text('Publicadas'),
                          ),
                          DropdownMenuItem(
                            value: 'archivada',
                            child: Text('Archivadas'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filtroEstado = value;
                            });
                            _cargarActas();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoCrearEditar(),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva Acta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.leafGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de actas
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _cargarActas,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                        : _actas.isEmpty
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay actas de reunión',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Crea la primera acta de reunión',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _actas.length,
                          itemBuilder:
                              (context, index) => _buildActaCard(_actas[index]),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: WessexColors.deepRoyalBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: WessexColors.deepNavyBlue,
          ),
        ),
      ],
    );
  }
}
