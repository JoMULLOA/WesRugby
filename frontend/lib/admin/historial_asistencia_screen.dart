import 'package:flutter/material.dart';
import '../models/asistencia_model.dart';
import '../services/asistencia_service.dart';
import '../config/colors.dart';

class HistorialAsistenciaScreen extends StatefulWidget {
  const HistorialAsistenciaScreen({super.key});

  @override
  State<HistorialAsistenciaScreen> createState() => _HistorialAsistenciaScreenState();
}

class _HistorialAsistenciaScreenState extends State<HistorialAsistenciaScreen> {
  List<SesionEntrenamiento> _sesiones = [];
  List<String> _categorias = [];
  String? _categoriaSeleccionada;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      // Cargar categorías y historial
      final categorias = await AsistenciaService.obtenerCategorias();
      final sesiones = await AsistenciaService.obtenerHistorialSesiones();

      setState(() {
        _categorias = categorias;
        _sesiones = sesiones;
      });
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _aplicarFiltros() async {
    setState(() {
      _cargando = true;
    });

    try {
      final sesiones = await AsistenciaService.obtenerHistorialSesiones(
        categoria: _categoriaSeleccionada,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );

      setState(() {
        _sesiones = sesiones;
      });
    } catch (e) {
      _mostrarError('Error al aplicar filtros: $e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: WessexColors.deepRoyalBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: WessexColors.darkGrape,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _categoriaSeleccionada = null;
      _fechaInicio = null;
      _fechaFin = null;
    });
    _aplicarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WessexColors.mistyRoseGray,
      appBar: AppBar(
        title: const Text(
          'Historial de Asistencia',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WessexColors.midnightNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel de filtros activos
          if (_tienesFiltrosActivos()) _buildFiltrosActivos(),
          
          // Lista de sesiones
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _sesiones.isEmpty
                    ? _buildEstadoVacio()
                    : _buildListaSesiones(),
          ),
        ],
      ),
    );
  }

  bool _tienesFiltrosActivos() {
    return _categoriaSeleccionada != null || _fechaInicio != null || _fechaFin != null;
  }

  Widget _buildFiltrosActivos() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WessexColors.deepRoyalBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WessexColors.deepRoyalBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: WessexColors.deepRoyalBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filtros activos:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: WessexColors.deepRoyalBlue,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _limpiarFiltros,
                child: Text(
                  'Limpiar',
                  style: TextStyle(color: WessexColors.deepRoyalBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (_categoriaSeleccionada != null)
                _buildChipFiltro('Categoría: $_categoriaSeleccionada'),
              if (_fechaInicio != null)
                _buildChipFiltro('Desde: ${_formatearFecha(_fechaInicio!)}'),
              if (_fechaFin != null)
                _buildChipFiltro('Hasta: ${_formatearFecha(_fechaFin!)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipFiltro(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: WessexColors.deepRoyalBlue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: WessexColors.deepRoyalBlue,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: WessexColors.darkGrape.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay sesiones registradas',
            style: TextStyle(
              fontSize: 18,
              color: WessexColors.darkGrape.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las sesiones de entrenamiento aparecerán aquí una vez que sean finalizadas',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WessexColors.darkGrape.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaSesiones() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sesiones.length,
      itemBuilder: (context, index) {
        final sesion = _sesiones[index];
        return _buildTarjetaSesion(sesion);
      },
    );
  }

  Widget _buildTarjetaSesion(SesionEntrenamiento sesion) {
    final estadisticas = sesion.estadisticas;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la sesión
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sports_rugby,
                    color: WessexColors.deepRoyalBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sesion.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                      Text(
                        sesion.categoria,
                        style: TextStyle(
                          color: WessexColors.darkGrape.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sesion.finalizada 
                        ? WessexColors.leafGreen.withOpacity(0.1)
                        : WessexColors.crimsonAlert.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sesion.finalizada ? 'Finalizada' : 'En curso',
                    style: TextStyle(
                      color: sesion.finalizada 
                          ? WessexColors.leafGreen
                          : WessexColors.crimsonAlert,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // Información de fecha y entrenador
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: WessexColors.darkGrape.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(
                  _formatearFechaHora(sesion.fechaInicio),
                  style: TextStyle(
                    color: WessexColors.darkGrape.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 16, color: WessexColors.darkGrape.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(
                  sesion.entrenadorNombre,
                  style: TextStyle(
                    color: WessexColors.darkGrape.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            if (sesion.descripcion != null) ...[
              const SizedBox(height: 8),
              Text(
                sesion.descripcion!,
                style: TextStyle(
                  color: WessexColors.darkGrape.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Estadísticas de asistencia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WessexColors.mistyRoseGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: WessexColors.deepRoyalBlue, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Estadísticas de Asistencia',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: WessexColors.leafGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${estadisticas.porcentajeAsistencia.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: WessexColors.leafGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEstadistica('Total', estadisticas.totalAlumnos, WessexColors.darkGrape),
                      _buildEstadistica('Presentes', estadisticas.presentes, WessexColors.leafGreen),
                      _buildEstadistica('Ausentes', estadisticas.ausentes, WessexColors.crimsonAlert),
                      _buildEstadistica('Tardanzas', estadisticas.tardanzas, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Botón ver detalles
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _verDetallesSesion(sesion),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Ver Detalles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.deepRoyalBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadistica(String label, int valor, Color color) {
    return Column(
      children: [
        Text(
          valor.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }

  void _verDetallesSesion(SesionEntrenamiento sesion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalle de Asistencia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                        Text(
                          sesion.nombre,
                          style: TextStyle(
                            color: WessexColors.darkGrape.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: WessexColors.darkGrape),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Lista de asistencias
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sesion.registros.length,
                itemBuilder: (context, index) {
                  final registro = sesion.registros[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: registro.estado.color.withOpacity(0.1),
                        child: Icon(
                          registro.estado.icono,
                          color: registro.estado.color,
                        ),
                      ),
                      title: Text(registro.nombreAlumno),
                      subtitle: Text('RUT: ${registro.rutAlumno}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: registro.estado.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          registro.estado.nombre,
                          style: TextStyle(
                            color: registro.estado.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: WessexColors.darkGrape),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Filtro por categoría
              Text(
                'Categoría',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: WessexColors.darkGrape,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Todas las categorías'),
                items: _categorias.map((categoria) =>
                  DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  ),
                ).toList(),
                onChanged: (value) {
                  setModalState(() {
                    _categoriaSeleccionada = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Filtros de fecha
              Text(
                'Rango de Fechas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: WessexColors.darkGrape,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _seleccionarFecha(true);
                        setModalState(() {});
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(_fechaInicio != null 
                          ? _formatearFecha(_fechaInicio!)
                          : 'Fecha inicio'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _seleccionarFecha(false);
                        setModalState(() {});
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(_fechaFin != null 
                          ? _formatearFecha(_fechaFin!)
                          : 'Fecha fin'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          _categoriaSeleccionada = null;
                          _fechaInicio = null;
                          _fechaFin = null;
                        });
                      },
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _aplicarFiltros();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.deepRoyalBlue,
                      ),
                      child: const Text('Aplicar', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),

              // Espacio adicional para el teclado
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  String _formatearFechaHora(DateTime fecha) {
    return '${_formatearFecha(fecha)} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: WessexColors.crimsonAlert,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}