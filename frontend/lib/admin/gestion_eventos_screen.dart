import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/colors.dart';

class GestionEventosScreen extends StatefulWidget {
  @override
  _GestionEventosScreenState createState() => _GestionEventosScreenState();
}

class _GestionEventosScreenState extends State<GestionEventosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _eventos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarEventos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarEventos() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await ApiService.obtenerEventos();
      print('✅ DEBUG Eventos cargados: $response');

      if (mounted) {
        setState(() {
          _eventos = response['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ ERROR cargando eventos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar eventos: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WessexColors.lightGray,
      appBar: AppBar(
        title: Text(
          'Gestión de Eventos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WessexColors.darkGrape,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.event), text: 'Eventos'),
            Tab(icon: Icon(Icons.analytics), text: 'Estadísticas'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventosTab(),
          _buildEstadisticasTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoEvento(),
        backgroundColor: WessexColors.leafGreen,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEventosTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(WessexColors.darkGrape),
        ),
      );
    }

    if (_eventos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: WessexColors.darkGrape.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No hay eventos creados',
              style: TextStyle(
                fontSize: 18,
                color: WessexColors.darkGrape,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Crea tu primer evento tocando el botón +',
              style: TextStyle(
                fontSize: 14,
                color: WessexColors.midnightNavy.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarEventos,
      color: WessexColors.darkGrape,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _eventos.length,
        itemBuilder: (context, index) {
          final evento = _eventos[index];
          return _buildEventoCard(evento);
        },
      ),
    );
  }

  Widget _buildEventoCard(Map<String, dynamic> evento) {
    final fecha = DateTime.parse(evento['fecha']);
    final fechaFormateada = '${fecha.day}/${fecha.month}/${fecha.year}';
    final estado = evento['estado'] ?? 'activo';
    
    Color estadoColor;
    IconData estadoIcon;
    
    switch (estado) {
      case 'activo':
        estadoColor = WessexColors.leafGreen;
        estadoIcon = Icons.event_available;
        break;
      case 'finalizado':
        estadoColor = WessexColors.midnightNavy;
        estadoIcon = Icons.event_note;
        break;
      case 'cancelado':
        estadoColor = WessexColors.crimsonAlert;
        estadoIcon = Icons.event_busy;
        break;
      default:
        estadoColor = WessexColors.darkGrape;
        estadoIcon = Icons.event;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetallesEvento(evento),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      evento['nombre'] ?? 'Sin nombre',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: WessexColors.darkGrape,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: estadoColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(estadoIcon, size: 16, color: estadoColor),
                        SizedBox(width: 4),
                        Text(
                          estado.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: estadoColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _accionEvento(value, evento),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: WessexColors.darkGrape),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'participaciones',
                        child: Row(
                          children: [
                            Icon(Icons.people, size: 20, color: WessexColors.leafGreen),
                            SizedBox(width: 8),
                            Text('Ver Participaciones'),
                          ],
                        ),
                      ),
                      if (estado == 'activo') ...[
                        PopupMenuItem(
                          value: 'finalizar',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 20, color: WessexColors.midnightNavy),
                              SizedBox(width: 8),
                              Text('Finalizar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'cancelar',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, size: 20, color: WessexColors.crimsonAlert),
                              SizedBox(width: 8),
                              Text('Cancelar'),
                            ],
                          ),
                        ),
                      ],
                      PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: WessexColors.crimsonAlert),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: WessexColors.midnightNavy),
                  SizedBox(width: 8),
                  Text(
                    fechaFormateada,
                    style: TextStyle(
                      fontSize: 14,
                      color: WessexColors.midnightNavy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.group, size: 16, color: WessexColors.leafGreen),
                  SizedBox(width: 4),
                  Text(
                    '${evento['totalParticipaciones'] ?? 0} participaciones',
                    style: TextStyle(
                      fontSize: 14,
                      color: WessexColors.leafGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (evento['descripcion'] != null && evento['descripcion'].toString().isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  evento['descripcion'],
                  style: TextStyle(
                    fontSize: 14,
                    color: WessexColors.midnightNavy.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadisticasTab() {
    if (_eventos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: WessexColors.darkGrape.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No hay datos para mostrar',
              style: TextStyle(
                fontSize: 18,
                color: WessexColors.darkGrape,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final eventosActivos = _eventos.where((e) => e['estado'] == 'activo').length;
    final eventosFinalizados = _eventos.where((e) => e['estado'] == 'finalizado').length;
    final eventosCancelados = _eventos.where((e) => e['estado'] == 'cancelado').length;
    final totalParticipaciones = _eventos.fold<int>(0, (sum, e) => sum + ((e['totalParticipaciones'] ?? 0) as int));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCard('Total de Eventos', _eventos.length.toString(), Icons.event, WessexColors.darkGrape),
          SizedBox(height: 12),
          _buildStatsCard('Eventos Activos', eventosActivos.toString(), Icons.event_available, WessexColors.leafGreen),
          SizedBox(height: 12),
          _buildStatsCard('Eventos Finalizados', eventosFinalizados.toString(), Icons.event_note, WessexColors.midnightNavy),
          SizedBox(height: 12),
          _buildStatsCard('Eventos Cancelados', eventosCancelados.toString(), Icons.event_busy, WessexColors.crimsonAlert),
          SizedBox(height: 12),
          _buildStatsCard('Total Participaciones', totalParticipaciones.toString(), Icons.group, WessexColors.leafGreen),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String titulo, String valor, IconData icono, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      color: WessexColors.midnightNavy.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  void _mostrarDialogoEvento({Map<String, dynamic>? evento}) {
    final isEditing = evento != null;
    final nombreController = TextEditingController(text: evento?['nombre'] ?? '');
    final descripcionController = TextEditingController(text: evento?['descripcion'] ?? '');
    DateTime fechaSeleccionada = evento != null 
        ? DateTime.parse(evento['fecha']) 
        : DateTime.now().add(Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            padding: EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Editar Evento' : 'Crear Nuevo Evento',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Nombre del evento
                  TextFormField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Evento',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.event),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Fecha
                  InkWell(
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: fechaSeleccionada,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (fecha != null) {
                        setState(() {
                          fechaSeleccionada = fecha;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 12),
                          Text(
                            'Fecha: ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Descripción
                  TextFormField(
                    controller: descripcionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción (Opcional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 24),
                  
                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar'),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _guardarEvento(
                          isEditing,
                          evento?['id'],
                          nombreController.text,
                          fechaSeleccionada,
                          descripcionController.text,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WessexColors.leafGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      ),
    );
  }

  Future<void> _guardarEvento(bool isEditing, int? eventoId, String nombre, DateTime fecha, String descripcion) async {
    if (nombre.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El nombre del evento es obligatorio'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
      return;
    }

    try {
      final Map<String, dynamic> datos = {
        'nombre': nombre.trim(),
        'fecha': fecha.toIso8601String(),
        'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
      };

      if (isEditing) {
        await ApiService.actualizarEvento(eventoId!, datos);
      } else {
        await ApiService.crearEvento(datos);
      }

      Navigator.pop(context);
      await _cargarEventos();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Evento actualizado exitosamente' : 'Evento creado exitosamente'),
          backgroundColor: WessexColors.leafGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  void _accionEvento(String accion, Map<String, dynamic> evento) {
    switch (accion) {
      case 'editar':
        _mostrarDialogoEvento(evento: evento);
        break;
      case 'participaciones':
        _mostrarParticipaciones(evento);
        break;
      case 'finalizar':
        _cambiarEstadoEvento(evento['id'], 'finalizado');
        break;
      case 'cancelar':
        _cambiarEstadoEvento(evento['id'], 'cancelado');
        break;
      case 'eliminar':
        _confirmarEliminarEvento(evento);
        break;
    }
  }

  Future<void> _cambiarEstadoEvento(int eventoId, String nuevoEstado) async {
    try {
      await ApiService.actualizarEvento(eventoId, {'estado': nuevoEstado});
      await _cargarEventos();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evento ${nuevoEstado} exitosamente'),
          backgroundColor: WessexColors.leafGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  void _confirmarEliminarEvento(Map<String, dynamic> evento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar el evento \"${evento['nombre']}\"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarEvento(evento['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: WessexColors.crimsonAlert),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarEvento(int eventoId) async {
    try {
      await ApiService.eliminarEvento(eventoId);
      await _cargarEventos();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evento eliminado exitosamente'),
          backgroundColor: WessexColors.leafGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar evento: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  void _mostrarParticipaciones(Map<String, dynamic> evento) {
    // TODO: Implementar vista de participaciones
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidad de participaciones en desarrollo'),
        backgroundColor: WessexColors.darkGrape,
      ),
    );
  }

  void _mostrarDetallesEvento(Map<String, dynamic> evento) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                evento['nombre'] ?? 'Sin nombre',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: WessexColors.darkGrape,
                ),
              ),
              SizedBox(height: 16),
              
              Row(
                children: [
                  Icon(Icons.calendar_today, color: WessexColors.midnightNavy),
                  SizedBox(width: 8),
                  Text(
                    'Fecha: ${DateTime.parse(evento['fecha']).day}/${DateTime.parse(evento['fecha']).month}/${DateTime.parse(evento['fecha']).year}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(Icons.info, color: WessexColors.midnightNavy),
                  SizedBox(width: 8),
                  Text(
                    'Estado: ${evento['estado']?.toUpperCase() ?? 'ACTIVO'}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(Icons.group, color: WessexColors.leafGreen),
                  SizedBox(width: 8),
                  Text(
                    'Participaciones: ${evento['totalParticipaciones'] ?? 0}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              
              if (evento['descripcion'] != null && evento['descripcion'].toString().isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Descripción:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.darkGrape,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  evento['descripcion'],
                  style: TextStyle(fontSize: 14),
                ),
              ],
              
              SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cerrar'),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _mostrarDialogoEvento(evento: evento);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WessexColors.darkGrape,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Editar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}