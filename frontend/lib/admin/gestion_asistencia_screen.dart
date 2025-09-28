import 'package:flutter/material.dart';
import '../models/asistencia_model.dart';
import '../services/asistencia_service.dart';
import '../config/colors.dart';

class GestionAsistenciaScreen extends StatefulWidget {
  const GestionAsistenciaScreen({super.key});

  @override
  State<GestionAsistenciaScreen> createState() => _GestionAsistenciaScreenState();
}

class _GestionAsistenciaScreenState extends State<GestionAsistenciaScreen> with TickerProviderStateMixin {
  // Controllers de animaciones
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Estado de la sesión
  SesionEntrenamiento? _sesionActual;
  List<Alumno> _alumnos = [];
  List<String> _categorias = [];
  Map<String, RegistroAsistencia> _registrosAsistencia = {};
  
  // Estado de la UI
  bool _cargandoAlumnos = false;
  bool _sesionIniciada = false;
  String? _categoriaSeleccionada;
  String _filtroNombre = '';
  
  // Controllers para formularios
  final _nombreSesionController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _filtroController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _cargarCategorias();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nombreSesionController.dispose();
    _descripcionController.dispose();
    _filtroController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await AsistenciaService.obtenerCategorias();
      setState(() {
        _categorias = categorias;
      });
    } catch (e) {
      _mostrarError('Error al cargar categorías: $e');
    }
  }

  Future<void> _cargarAlumnos(String categoria) async {
    setState(() {
      _cargandoAlumnos = true;
    });

    try {
      final alumnos = await AsistenciaService.obtenerAlumnos(categoria: categoria);
      setState(() {
        _alumnos = alumnos;
        _registrosAsistencia.clear();
        
        // Inicializar registros de asistencia
        for (final alumno in alumnos) {
          _registrosAsistencia[alumno.rut] = RegistroAsistencia(
            rutAlumno: alumno.rut,
            nombreAlumno: alumno.nombreCompleto,
            estado: EstadoAsistencia.sinRegistrar,
            fechaHora: DateTime.now(),
          );
        }
      });
    } catch (e) {
      _mostrarError('Error al cargar alumnos: $e');
    } finally {
      setState(() {
        _cargandoAlumnos = false;
      });
    }
  }

  Future<void> _iniciarSesion() async {
    if (_nombreSesionController.text.isEmpty || _categoriaSeleccionada == null) {
      _mostrarError('Completa todos los campos obligatorios');
      return;
    }

    try {
      final sesion = await AsistenciaService.iniciarSesion(
        nombre: _nombreSesionController.text,
        categoria: _categoriaSeleccionada!,
        descripcion: _descripcionController.text.isNotEmpty ? _descripcionController.text : null,
        entrenadorRut: '11111111-1', // TODO: Obtener del usuario autenticado
        entrenadorNombre: 'Entrenador', // TODO: Obtener del usuario autenticado
      );

      setState(() {
        _sesionActual = sesion;
        _sesionIniciada = true;
      });

      await _cargarAlumnos(_categoriaSeleccionada!);
      _mostrarExito('Sesión iniciada correctamente');
    } catch (e) {
      _mostrarError('Error al iniciar sesión: $e');
    }
  }

  Future<void> _cambiarEstadoAsistencia(String rutAlumno, EstadoAsistencia nuevoEstado) async {
    final registro = _registrosAsistencia[rutAlumno];
    if (registro == null || _sesionActual == null) return;

    if (nuevoEstado == EstadoAsistencia.justificado) {
      await _mostrarDialogoJustificacion(rutAlumno, nuevoEstado);
      return;
    }

    final registroActualizado = registro.copyWith(estado: nuevoEstado);
    
    if (_sesionIniciada) {
      final exito = await AsistenciaService.registrarAsistencia(
        sesionId: _sesionActual!.id,
        rutAlumno: rutAlumno,
        nombreAlumno: registro.nombreAlumno,
        estado: nuevoEstado,
      );

      if (exito) {
        setState(() {
          _registrosAsistencia[rutAlumno] = registroActualizado;
        });
      } else {
        _mostrarError('Error al registrar asistencia');
      }
    } else {
      setState(() {
        _registrosAsistencia[rutAlumno] = registroActualizado;
      });
    }
  }

  Future<void> _mostrarDialogoJustificacion(String rutAlumno, EstadoAsistencia estado) async {
    final justificacionController = TextEditingController();
    
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Justificación',
          style: TextStyle(
            color: WessexColors.darkGrape,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingrese la justificación para ${_registrosAsistencia[rutAlumno]?.nombreAlumno}:',
              style: TextStyle(color: WessexColors.darkGrape),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: justificacionController,
              decoration: InputDecoration(
                hintText: 'Motivo de la justificación...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: WessexColors.deepRoyalBlue),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: WessexColors.darkGrape)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, justificacionController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: WessexColors.deepRoyalBlue,
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (resultado != null && resultado.isNotEmpty) {
      final registro = _registrosAsistencia[rutAlumno];
      if (registro != null) {
        final registroActualizado = registro.copyWith(
          estado: estado,
          justificacion: resultado,
        );

        if (_sesionIniciada && _sesionActual != null) {
          final exito = await AsistenciaService.registrarAsistencia(
            sesionId: _sesionActual!.id,
            rutAlumno: rutAlumno,
            nombreAlumno: registro.nombreAlumno,
            estado: estado,
            justificacion: resultado,
          );

          if (exito) {
            setState(() {
              _registrosAsistencia[rutAlumno] = registroActualizado;
            });
          } else {
            _mostrarError('Error al registrar justificación');
          }
        } else {
          setState(() {
            _registrosAsistencia[rutAlumno] = registroActualizado;
          });
        }
      }
    }
  }

  Future<void> _finalizarSesion() async {
    if (_sesionActual == null) return;

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Finalizar Sesión',
          style: TextStyle(
            color: WessexColors.darkGrape,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('¿Estás seguro de que deseas finalizar la sesión? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: WessexColors.darkGrape)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WessexColors.crimsonAlert,
            ),
            child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      final exito = await AsistenciaService.finalizarSesion(_sesionActual!.id);
      
      if (exito) {
        _mostrarExito('Sesión finalizada correctamente');
        Navigator.pop(context);
      } else {
        _mostrarError('Error al finalizar la sesión');
      }
    }
  }

  List<Alumno> get _alumnosFiltrados {
    if (_filtroNombre.isEmpty) return _alumnos;
    
    return _alumnos.where((alumno) =>
      alumno.nombreCompleto.toLowerCase().contains(_filtroNombre.toLowerCase()) ||
      alumno.rut.contains(_filtroNombre)
    ).toList();
  }

  EstadisticasAsistencia get _estadisticas {
    final registros = _registrosAsistencia.values.toList();
    final total = registros.length;
    
    if (total == 0) {
      return EstadisticasAsistencia(
        totalAlumnos: 0,
        presentes: 0,
        ausentes: 0,
        tardanzas: 0,
        justificados: 0,
        porcentajeAsistencia: 0.0,
      );
    }

    final presentes = registros.where((r) => r.estado == EstadoAsistencia.presente).length;
    final ausentes = registros.where((r) => r.estado == EstadoAsistencia.ausente).length;
    final tardanzas = registros.where((r) => r.estado == EstadoAsistencia.tardanza).length;
    final justificados = registros.where((r) => r.estado == EstadoAsistencia.justificado).length;
    
    final porcentaje = total > 0 ? ((presentes + tardanzas) / total) * 100 : 0.0;

    return EstadisticasAsistencia(
      totalAlumnos: total,
      presentes: presentes,
      ausentes: ausentes,
      tardanzas: tardanzas,
      justificados: justificados,
      porcentajeAsistencia: porcentaje,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WessexColors.mistyRoseGray,
      appBar: AppBar(
        title: const Text(
          'Gestión de Asistencia',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WessexColors.midnightNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        actions: [
          if (_sesionIniciada)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.white),
              onPressed: _finalizarSesion,
              tooltip: 'Finalizar Sesión',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: !_sesionIniciada ? _buildConfiguracionSesion() : _buildTomaAsistencia(),
      ),
    );
  }

  Widget _buildConfiguracionSesion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [WessexColors.midnightNavy, WessexColors.deepRoyalBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: WessexColors.darkGrape.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.how_to_reg,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nueva Sesión de Entrenamiento',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configura los parámetros para iniciar la toma de asistencia',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Formulario de configuración
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración de Sesión',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre de sesión
                  TextField(
                    controller: _nombreSesionController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Sesión *',
                      hintText: 'Ej: Entrenamiento Técnico',
                      prefixIcon: Icon(Icons.title, color: WessexColors.deepRoyalBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: WessexColors.deepRoyalBlue),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Selector de categoría
                  DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Categoría *',
                      prefixIcon: Icon(Icons.category, color: WessexColors.deepRoyalBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: WessexColors.deepRoyalBlue),
                      ),
                    ),
                    items: _categorias.map((categoria) =>
                      DropdownMenuItem(
                        value: categoria,
                        child: Text(categoria),
                      ),
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoriaSeleccionada = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Descripción opcional
                  TextField(
                    controller: _descripcionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción (Opcional)',
                      hintText: 'Detalles adicionales de la sesión...',
                      prefixIcon: Icon(Icons.description, color: WessexColors.deepRoyalBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: WessexColors.deepRoyalBlue),
                      ),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // Botón iniciar sesión
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _iniciarSesion,
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text(
                        'Iniciar Sesión de Asistencia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.leafGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTomaAsistencia() {
    final estadisticas = _estadisticas;
    
    return Column(
      children: [
        // Panel de estadísticas
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: WessexColors.darkGrape.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: WessexColors.deepRoyalBlue),
                  const SizedBox(width: 8),
                  Text(
                    _sesionActual?.nombre ?? 'Sesión',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: WessexColors.leafGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${estadisticas.porcentajeAsistencia.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: WessexColors.leafGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildEstadisticaChip('Total', estadisticas.totalAlumnos.toString(), WessexColors.darkGrape),
                  const SizedBox(width: 8),
                  _buildEstadisticaChip('Presentes', estadisticas.presentes.toString(), WessexColors.leafGreen),
                  const SizedBox(width: 8),
                  _buildEstadisticaChip('Ausentes', estadisticas.ausentes.toString(), WessexColors.crimsonAlert),
                ],
              ),
            ],
          ),
        ),

        // Barra de filtro
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _filtroController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o RUT...',
              prefixIcon: Icon(Icons.search, color: WessexColors.deepRoyalBlue),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _filtroNombre = value;
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // Lista de alumnos
        Expanded(
          child: _cargandoAlumnos
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _alumnosFiltrados.length,
                  itemBuilder: (context, index) {
                    final alumno = _alumnosFiltrados[index];
                    final registro = _registrosAsistencia[alumno.rut];
                    return _buildAlumnoCard(alumno, registro);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEstadisticaChip(String label, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlumnoCard(Alumno alumno, RegistroAsistencia? registro) {
    final estado = registro?.estado ?? EstadoAsistencia.sinRegistrar;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: estado.color.withOpacity(0.1),
                  child: Icon(
                    estado.icono,
                    color: estado.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alumno.nombreCompleto,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                      Text(
                        'RUT: ${alumno.rut}',
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
                    color: estado.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estado.nombre,
                    style: TextStyle(
                      color: estado.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBotonEstado(
                    'Presente',
                    Icons.check_circle,
                    WessexColors.leafGreen,
                    () => _cambiarEstadoAsistencia(alumno.rut, EstadoAsistencia.presente),
                    estado == EstadoAsistencia.presente,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBotonEstado(
                    'Ausente',
                    Icons.cancel,
                    WessexColors.crimsonAlert,
                    () => _cambiarEstadoAsistencia(alumno.rut, EstadoAsistencia.ausente),
                    estado == EstadoAsistencia.ausente,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBotonEstado(
                    'Tardanza',
                    Icons.access_time,
                    Colors.orange,
                    () => _cambiarEstadoAsistencia(alumno.rut, EstadoAsistencia.tardanza),
                    estado == EstadoAsistencia.tardanza,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBotonEstado(
                    'Justificado',
                    Icons.info,
                    WessexColors.deepRoyalBlue,
                    () => _cambiarEstadoAsistencia(alumno.rut, EstadoAsistencia.justificado),
                    estado == EstadoAsistencia.justificado,
                  ),
                ),
              ],
            ),
            if (registro?.justificacion != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Justificación: ${registro!.justificacion}',
                  style: TextStyle(
                    color: WessexColors.deepRoyalBlue,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBotonEstado(String texto, IconData icono, Color color, VoidCallback onPressed, bool seleccionado) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icono,
        size: 16,
        color: seleccionado ? Colors.white : color,
      ),
      label: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: seleccionado ? Colors.white : color,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: seleccionado ? color : Colors.white,
        foregroundColor: seleccionado ? Colors.white : color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        elevation: seleccionado ? 2 : 0,
      ),
    );
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

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: WessexColors.leafGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}