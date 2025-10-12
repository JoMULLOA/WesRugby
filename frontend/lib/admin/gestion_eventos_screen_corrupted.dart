import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/colors.dart';

// Versión 2.0 - Con gestión de categorías mejorada

class GestionEventosScreen extends StatefulWidget {
  @override
  _GestionEventosScreenState createState() => _GestionEventosScreenState();
}

class _GestionEventosScreenState extends State<GestionEventosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _eventos = [];
  bool _isLoading = false;
  List<String> _categorias = ['sub-11', 'sub-12', 'sub-13'];

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
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.obtenerEventosDeportivos();
      setState(() {
        _eventos = response['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar eventos: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  void _mostrarParticipaciones(Map<String, dynamic> evento) async {
    try {
      final response = await ApiService.obtenerParticipacionesEvento(evento['id']);
      final datos = response['data'];
      final estadisticasPorRama = datos['estadisticasPorRama'] as List;
      final totalGeneral = datos['totalGeneral'] ?? 0;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 800,
            height: 600,
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Participaciones - ${evento['nombre']}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WessexColors.leafGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WessexColors.leafGreen, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group, color: WessexColors.leafGreen),
                      SizedBox(width: 8),
                      Text(
                        'Total: $totalGeneral niños participantes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.leafGreen,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${estadisticasPorRama.length} ramas deportivas',
                        style: TextStyle(
                          fontSize: 14,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                Expanded(
                  child: estadisticasPorRama.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: WessexColors.darkGrape.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay participaciones registradas',
                              style: TextStyle(
                                fontSize: 16,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: estadisticasPorRama.length,
                        itemBuilder: (context, index) {
                          return _buildRamaCard(estadisticasPorRama[index]);
                        },
                      ),
                ),
                
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WessexColors.darkGrape,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar participaciones: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  Widget _buildRamaCard(Map<String, dynamic> ramaData) {
    final nombreRama = ramaData['nombreRama'] ?? 'Rama sin nombre';
    final totalRama = ramaData['totalRama'] ?? 0;
    final totalPorCategoria = ramaData['totalPorCategoria'] as Map<String, dynamic>;
    final participaciones = ramaData['participaciones'] as List;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: WessexColors.darkGrape,
          child: Text(
            nombreRama.substring(0, 1).toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          nombreRama,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: WessexColors.darkGrape,
          ),
        ),
        subtitle: Text(
          'Total: $totalRama niños en ${totalPorCategoria.length} categorías',
          style: TextStyle(
            fontSize: 14,
            color: WessexColors.midnightNavy,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribución por categorías:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: WessexColors.darkGrape,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: totalPorCategoria.entries.map((entry) => Chip(
                    label: Text(
                      '${entry.key.toString().toUpperCase()}: ${entry.value}',
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: WessexColors.leafGreen.withOpacity(0.2),
                    side: BorderSide(color: WessexColors.leafGreen, width: 1),
                  )).toList(),
                ),
                SizedBox(height: 12),
                
                Text(
                  'Detalle de participaciones:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: WessexColors.darkGrape,
                  ),
                ),
                SizedBox(height: 8),
                ...participaciones.map((participacion) => Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WessexColors.lightGray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WessexColors.darkGrape.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            participacion['categoria'].toString().toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '${participacion['cantidadNinos']} niños',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: WessexColors.leafGreen,
                            ),
                          ),
                        ],
                      ),
                      if (participacion['listaInvitados'] != null && 
                          participacion['listaInvitados'].toString().isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          'Invitados: ${participacion['listaInvitados']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: WessexColors.midnightNavy.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarGestionCategorias() {
    final _nuevaCategoriaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            height: 600,
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Gestionar Categorías',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                Text(
                  'Categorías disponibles:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: WessexColors.darkGrape,
                  ),
                ),
                SizedBox(height: 12),
                
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: _categorias.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: WessexColors.leafGreen,
                              child: Text(
                                _categorias[index].substring(0, 1).toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              _categorias[index].toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: WessexColors.crimsonAlert),
                              onPressed: () {
                                setDialogState(() {
                                  _categorias.removeAt(index);
                                });
                                setState(() {}); // Actualizar el estado principal
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                Text(
                  'Agregar nueva categoría:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: WessexColors.darkGrape,
                  ),
                ),
                SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nuevaCategoriaController,
                        decoration: InputDecoration(
                          hintText: 'ej: sub-20, veteranos',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: WessexColors.leafGreen),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final nuevaCategoria = _nuevaCategoriaController.text.trim().toLowerCase();
                        if (nuevaCategoria.isNotEmpty && !_categorias.contains(nuevaCategoria)) {
                          setDialogState(() {
                            _categorias.add(nuevaCategoria);
                            _categorias.sort(); // Ordenar alfabéticamente
                          });
                          setState(() {}); // Actualizar el estado principal
                          _nuevaCategoriaController.clear();
                        } else if (_categorias.contains(nuevaCategoria)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Esta categoría ya existe'),
                              backgroundColor: WessexColors.crimsonAlert,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.leafGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Agregar'),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WessexColors.darkGrape,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoCrearEvento() {
    final _formKey = GlobalKey<FormState>();
    final _tituloController = TextEditingController();
    final _descripcionController = TextEditingController();
    final _lugarController = TextEditingController();
    DateTime? _fechaSeleccionada;
    List<String> _categoriasSeleccionadas = [];
    String _tipoEvento = 'entrenamiento';
    TimeOfDay? _horaInicio;
    TimeOfDay? _horaFin;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Crear Nuevo Evento',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  TextFormField(
                    controller: _tituloController,
                    decoration: InputDecoration(
                      labelText: 'Título del evento *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: WessexColors.leafGreen),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa el título del evento';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _tipoEvento,
                    decoration: InputDecoration(
                      labelText: 'Tipo de evento *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: WessexColors.leafGreen),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 'entrenamiento', child: Text('Entrenamiento')),
                      DropdownMenuItem(value: 'partido', child: Text('Partido')),
                      DropdownMenuItem(value: 'torneo', child: Text('Torneo')),
                      DropdownMenuItem(value: 'reunion', child: Text('Reunión')),
                      DropdownMenuItem(value: 'evento_social', child: Text('Evento Social')),
                      DropdownMenuItem(value: 'viaje', child: Text('Viaje')),
                      DropdownMenuItem(value: 'otro', child: Text('Otro')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _tipoEvento = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Categorías disponibles:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                        ),
                        Container(
                          height: 120,
                          child: SingleChildScrollView(
                            child: Column(
                              children: _categorias.map((categoria) => CheckboxListTile(
                                title: Text(
                                  categoria.toUpperCase(),
                                  style: TextStyle(fontSize: 14),
                                ),
                                value: _categoriasSeleccionadas.contains(categoria),
                                activeColor: WessexColors.leafGreen,
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      _categoriasSeleccionadas.add(categoria);
                                    } else {
                                      _categoriasSeleccionadas.remove(categoria);
                                    }
                                  });
                                },
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                              )).toList(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Seleccionadas: ${_categoriasSeleccionadas.length > 0 ? _categoriasSeleccionadas.map((c) => c.toUpperCase()).join(', ') : 'Ninguna'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descripcionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: WessexColors.leafGreen),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _lugarController,
                    decoration: InputDecoration(
                      labelText: 'Lugar *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: WessexColors.leafGreen),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa el lugar del evento';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final hora = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: WessexColors.darkGrape,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (hora != null) {
                              setDialogState(() {
                                _horaInicio = hora;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: WessexColors.darkGrape),
                                SizedBox(width: 8),
                                Text(
                                  _horaInicio == null
                                      ? 'Hora inicio'
                                      : _horaInicio!.format(context),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _horaInicio == null 
                                        ? Colors.grey[600] 
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final hora = await showTimePicker(
                              context: context,
                              initialTime: _horaInicio != null 
                                ? TimeOfDay(hour: (_horaInicio!.hour + 1) % 24, minute: _horaInicio!.minute)
                                : TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: WessexColors.darkGrape,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (hora != null) {
                              setDialogState(() {
                                _horaFin = hora;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: WessexColors.darkGrape),
                                SizedBox(width: 8),
                                Text(
                                  _horaFin == null
                                      ? 'Hora fin'
                                      : _horaFin!.format(context),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _horaFin == null 
                                        ? Colors.grey[600] 
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  InkWell(
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: WessexColors.darkGrape,
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (fecha != null) {
                        setDialogState(() {
                          _fechaSeleccionada = fecha;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: WessexColors.darkGrape),
                          SizedBox(width: 8),
                          Text(
                            _fechaSeleccionada == null
                                ? 'Seleccionar fecha del evento *'
                                : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
                            style: TextStyle(
                              fontSize: 16,
                              color: _fechaSeleccionada == null 
                                  ? Colors.grey[600] 
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (_fechaSeleccionada == null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Por favor selecciona la fecha del evento',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(color: WessexColors.darkGrape),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && _fechaSeleccionada != null) {
                            await _crearEventoDeportivo(
                              _tituloController.text.trim(),
                              _descripcionController.text.trim(),
                              _lugarController.text.trim(),
                              _tipoEvento,
                              _categoriasSeleccionadas,
                              _fechaSeleccionada!,
                              _horaInicio,
                              _horaFin,
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WessexColors.leafGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Crear Evento'),
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

  Future<void> _crearEventoDeportivo(String titulo, String descripcion, String lugar, 
      String tipoEvento, List<String> categorias, DateTime fecha, TimeOfDay? horaInicio, TimeOfDay? horaFin) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Construir fechaInicio con hora
      DateTime fechaInicio = fecha;
      if (horaInicio != null) {
        fechaInicio = DateTime(
          fecha.year, 
          fecha.month, 
          fecha.day, 
          horaInicio.hour, 
          horaInicio.minute
        );
      }

      // Construir fechaFin con hora
      DateTime? fechaFin;
      if (horaFin != null) {
        fechaFin = DateTime(
          fecha.year, 
          fecha.month, 
          fecha.day, 
          horaFin.hour, 
          horaFin.minute
        );
      }

      final eventoData = {
        'titulo': titulo,
        'descripcion': descripcion.isEmpty ? null : descripcion,
        'tipoEvento': tipoEvento,
        'categoria': categorias.isNotEmpty ? categorias.join(',') : null,
        'categorias': categorias, // Enviamos también como array
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin?.toIso8601String(),
        'lugar': lugar,
        'estado': 'programado',
        'inscripcionRequerida': false,
        'notificarParticipantes': true,
      };

      await ApiService.crearEventoDeportivo(eventoData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evento creado exitosamente'),
          backgroundColor: WessexColors.leafGreen,
        ),
      );

      // Recargar la lista de eventos
      await _cargarEventos();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear evento: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gestión de eventos con menú de categorías y formulario mejorado - v2.0
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Eventos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WessexColors.darkGrape,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              print('DEBUG: Menu seleccionado: $value'); // Debug
              if (value == 'categorias') {
                print('DEBUG: Mostrando gestión de categorías'); // Debug
                _mostrarGestionCategorias();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'categorias',
                child: Row(
                  children: [
                    Icon(Icons.category, color: WessexColors.darkGrape),
                    SizedBox(width: 8),
                    Text('Gestionar Categorías'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Eventos Activos'),
            Tab(text: 'Eventos Pasados'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoCrearEvento,
        backgroundColor: WessexColors.leafGreen,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Crear nuevo evento',
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(WessexColors.darkGrape),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEventosActivos(),
                _buildEventosPasados(),
              ],
            ),
    );
  }

  Widget _buildEventosActivos() {
    final eventosActivos = _eventos.where((evento) {
      final fechaEvento = DateTime.parse(evento['fechaInicio']);
      return fechaEvento.isAfter(DateTime.now());
    }).toList();

    if (eventosActivos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event,
              size: 64,
              color: WessexColors.darkGrape.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No hay eventos activos',
              style: TextStyle(
                fontSize: 18,
                color: WessexColors.darkGrape,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: eventosActivos.length,
      itemBuilder: (context, index) {
        return _buildEventoCard(eventosActivos[index]);
      },
    );
  }

  Widget _buildEventosPasados() {
    final eventosPasados = _eventos.where((evento) {
      final fechaEvento = DateTime.parse(evento['fechaInicio']);
      return fechaEvento.isBefore(DateTime.now());
    }).toList();

    if (eventosPasados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: WessexColors.darkGrape.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No hay eventos pasados',
              style: TextStyle(
                fontSize: 18,
                color: WessexColors.darkGrape,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: eventosPasados.length,
      itemBuilder: (context, index) {
        return _buildEventoCard(eventosPasados[index]);
      },
    );
  }

  Widget _buildEventoCard(Map<String, dynamic> evento) {
    final fechaEvento = DateTime.parse(evento['fechaInicio']);
    final esEventoPasado = fechaEvento.isBefore(DateTime.now());
    final estado = evento['estado'] ?? 'programado';
    final tipoEvento = evento['tipoEvento'] ?? 'evento';
    final categoria = evento['categoria'];

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    evento['titulo'] ?? 'Sin título',
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
                    color: esEventoPasado 
                        ? WessexColors.crimsonAlert.withOpacity(0.1)
                        : WessexColors.leafGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: esEventoPasado 
                          ? WessexColors.crimsonAlert
                          : WessexColors.leafGreen,
                    ),
                  ),
                  child: Text(
                    estado.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: esEventoPasado 
                          ? WessexColors.crimsonAlert
                          : WessexColors.leafGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // Tipo de evento y categorías
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: WessexColors.darkGrape.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tipoEvento.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                ),
                // Mostrar múltiples categorías
                if (categoria != null && categoria.toString().isNotEmpty)
                  ...categoria.toString().split(',').map((cat) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: WessexColors.leafGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cat.trim().toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: WessexColors.leafGreen,
                      ),
                    ),
                  )).toList(),
              ],
            ),
            
            if (evento['descripcion'] != null && evento['descripcion'].isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                evento['descripcion'],
                style: TextStyle(
                  fontSize: 14,
                  color: WessexColors.midnightNavy,
                ),
              ),
            ],
            
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: WessexColors.darkGrape),
                SizedBox(width: 4),
                Text(
                  '${fechaEvento.day}/${fechaEvento.month}/${fechaEvento.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: WessexColors.darkGrape,
                  ),
                ),
                if (fechaEvento.hour != 0 || fechaEvento.minute != 0) ...[
                  SizedBox(width: 8),
                  Icon(Icons.access_time, size: 16, color: WessexColors.darkGrape),
                  SizedBox(width: 4),
                  Text(
                    '${fechaEvento.hour.toString().padLeft(2, '0')}:${fechaEvento.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                ],
                SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: WessexColors.darkGrape),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    evento['lugar'] ?? 'Sin ubicación',
                    style: TextStyle(
                      fontSize: 14,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _mostrarParticipaciones(evento),
                  icon: Icon(Icons.people, color: WessexColors.leafGreen),
                  label: Text(
                    'Ver Participaciones',
                    style: TextStyle(color: WessexColors.leafGreen),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}