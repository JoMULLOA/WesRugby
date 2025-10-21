import 'package:flutter/material.dart';
import 'package:wesrugby/data/models/asistencia_model.dart';
import 'package:wesrugby/data/services/asistencia_service.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

class GestionAsistenciaScreen extends StatefulWidget {
  const GestionAsistenciaScreen({super.key});

  @override
  State<GestionAsistenciaScreen> createState() =>
      _GestionAsistenciaScreenState();
}

class _GestionAsistenciaScreenState extends State<GestionAsistenciaScreen>
    with TickerProviderStateMixin {
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
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);
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
      final alumnos = await AsistenciaService.obtenerAlumnos(
        categoria: categoria,
      );
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(title: 'Gestión de Asistencia', elevation: 2),
      body: WessexBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child:
                !_sesionIniciada
                    ? _buildConfiguracionSesion(isDesktop, isTablet)
                    : _buildGestionAsistencia(isDesktop, isTablet),
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguracionSesion(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const WessexSectionTitle(
            title: 'Nueva Sesión de Entrenamiento',
            subtitle: 'Configure los detalles de la sesión',
            titleColor: WessexColors.white,
          ),
          const SizedBox(height: 32),

          // Formulario de configuración
          WessexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información de la Sesión',
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                    fontWeight: FontWeight.bold,
                    color: WessexColors.darkGrape,
                  ),
                ),
                const SizedBox(height: 20),

                // Nombre de la sesión
                _buildInputField(
                  label: 'Nombre de la Sesión',
                  hint: 'Ej: Entrenamiento Juvenil - Técnica',
                  controller: _nombreSesionController,
                  icon: Icons.sports_rugby,
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),
                const SizedBox(height: 16),

                // Descripción
                _buildInputField(
                  label: 'Descripción (Opcional)',
                  hint: 'Descripción de los objetivos del entrenamiento',
                  controller: _descripcionController,
                  icon: Icons.description,
                  maxLines: 3,
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),
                const SizedBox(height: 16),

                // Selector de categoría
                Text(
                  'Categoría',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                    fontWeight: FontWeight.w600,
                    color: WessexColors.darkGrape,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _categoriaSeleccionada,
                  decoration: InputDecoration(
                    hintText: 'Seleccione una categoría',
                    prefixIcon: Icon(
                      Icons.category,
                      color: WessexColors.deepRoyalBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: WessexColors.maximumGrayMint,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: WessexColors.deepRoyalBlue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: WessexColors.mistyRoseGray,
                  ),
                  items:
                      _categorias.map((categoria) {
                        return DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria),
                        );
                      }).toList(),
                  onChanged: (valor) {
                    setState(() {
                      _categoriaSeleccionada = valor;
                    });
                    if (valor != null) {
                      _cargarAlumnos(valor);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Botón para iniciar sesión
                SizedBox(
                  width: double.infinity,
                  child: WessexButton(
                    text: 'Iniciar Sesión de Asistencia',
                    icon: Icons.play_arrow,
                    backgroundColor: WessexColors.leafGreen,
                    onPressed: _puedeIniciarSesion() ? _iniciarSesion : null,
                    isLoading: _cargandoAlumnos,
                  ),
                ),
              ],
            ),
          ),

          // Información adicional
          if (_categoriaSeleccionada != null && _alumnos.isNotEmpty) ...[
            const SizedBox(height: 24),
            WessexCard(
              backgroundColor: WessexColors.leafGreen.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: WessexColors.leafGreen,
                    size: isDesktop ? 24 : (isTablet ? 22 : 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Listo para iniciar',
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                            fontWeight: FontWeight.bold,
                            color: WessexColors.leafGreen,
                          ),
                        ),
                        Text(
                          '${_alumnos.length} alumnos cargados en $_categoriaSeleccionada',
                          style: TextStyle(
                            fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                            color: WessexColors.darkGrape.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDesktop,
    required bool isTablet,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
            fontWeight: FontWeight.w600,
            color: WessexColors.darkGrape,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: WessexColors.deepRoyalBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: WessexColors.maximumGrayMint),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: WessexColors.deepRoyalBlue,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: WessexColors.mistyRoseGray,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isDesktop ? 16 : 14,
            ),
          ),
          style: TextStyle(
            fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
            color: WessexColors.darkGrape,
          ),
        ),
      ],
    );
  }

  Widget _buildGestionAsistencia(bool isDesktop, bool isTablet) {
    final alumnosFiltrados =
        _alumnos.where((alumno) {
          return alumno.nombreCompleto.toLowerCase().contains(
            _filtroNombre.toLowerCase(),
          );
        }).toList();

    return Column(
      children: [
        // Header fijo con estadísticas
        Container(
          padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
          child: Column(
            children: [
              const WessexSectionTitle(
                title: 'Toma de Asistencia',
                subtitle: 'Marcar presente/ausente para cada alumno',
                titleColor: WessexColors.white,
              ),
              const SizedBox(height: 20),

              // Estadísticas en tiempo real
              WessexCard(
                child: Row(
                  children: [
                    _buildEstadistica(
                      'Presentes',
                      _contarEstado(EstadoAsistencia.presente).toString(),
                      WessexColors.leafGreen,
                      Icons.check_circle,
                      isDesktop,
                      isTablet,
                    ),
                    const SizedBox(width: 16),
                    _buildEstadistica(
                      'Ausentes',
                      _contarEstado(EstadoAsistencia.ausente).toString(),
                      WessexColors.crimsonAlert,
                      Icons.cancel,
                      isDesktop,
                      isTablet,
                    ),
                    const SizedBox(width: 16),
                    _buildEstadistica(
                      'Sin Marcar',
                      _contarEstado(EstadoAsistencia.sinRegistrar).toString(),
                      WessexColors.maximumGrayMint,
                      Icons.radio_button_unchecked,
                      isDesktop,
                      isTablet,
                    ),
                  ],
                ),
              ),

              // Filtro de búsqueda
              const SizedBox(height: 16),
              WessexCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: TextField(
                  controller: _filtroController,
                  decoration: InputDecoration(
                    hintText: 'Buscar alumno...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: WessexColors.deepRoyalBlue,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (valor) {
                    setState(() {
                      _filtroNombre = valor;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // Lista de alumnos
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : (isTablet ? 20 : 16),
            ),
            itemCount: alumnosFiltrados.length,
            itemBuilder: (context, index) {
              final alumno = alumnosFiltrados[index];
              final registro = _registrosAsistencia[alumno.rut]!;

              return _buildAlumnoCard(alumno, registro, isDesktop, isTablet);
            },
          ),
        ),

        // Botones de acción fijos
        Container(
          padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
          child: Row(
            children: [
              Expanded(
                child: WessexButton(
                  text: 'Finalizar Sesión',
                  icon: Icons.save,
                  backgroundColor: WessexColors.deepRoyalBlue,
                  onPressed: _finalizarSesion,
                ),
              ),
              const SizedBox(width: 12),
              WessexButton(
                text: 'Cancelar',
                icon: Icons.cancel,
                backgroundColor: WessexColors.crimsonAlert,
                onPressed: _cancelarSesion,
                width: isDesktop ? 140 : (isTablet ? 120 : 100),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstadistica(
    String label,
    String valor,
    Color color,
    IconData icon,
    bool isDesktop,
    bool isTablet,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: isDesktop ? 32 : (isTablet ? 28 : 24)),
          SizedBox(height: isDesktop ? 8 : 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
              color: WessexColors.darkGrape.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlumnoCard(
    Alumno alumno,
    RegistroAsistencia registro,
    bool isDesktop,
    bool isTablet,
  ) {
    return WessexCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar del alumno
          CircleAvatar(
            radius: isDesktop ? 24 : (isTablet ? 22 : 20),
            backgroundColor: WessexColors.deepRoyalBlue,
            child: Text(
              alumno.nombreCompleto.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: WessexColors.white,
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Información del alumno
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alumno.nombreCompleto,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                    fontWeight: FontWeight.bold,
                    color: WessexColors.darkGrape,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RUT: ${alumno.rut}',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                    color: WessexColors.darkGrape.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Botones de estado
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEstadoButton(
                Icons.check_circle,
                WessexColors.leafGreen,
                registro.estado == EstadoAsistencia.presente,
                () => _cambiarEstado(alumno.rut, EstadoAsistencia.presente),
                isDesktop,
                isTablet,
              ),
              const SizedBox(width: 8),
              _buildEstadoButton(
                Icons.cancel,
                WessexColors.crimsonAlert,
                registro.estado == EstadoAsistencia.ausente,
                () => _cambiarEstado(alumno.rut, EstadoAsistencia.ausente),
                isDesktop,
                isTablet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoButton(
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onPressed,
    bool isDesktop,
    bool isTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: isSelected ? 0 : 1),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isSelected ? WessexColors.white : color,
          size: isDesktop ? 24 : (isTablet ? 22 : 20),
        ),
        padding: EdgeInsets.all(isDesktop ? 12 : (isTablet ? 10 : 8)),
        constraints: BoxConstraints(
          minWidth: isDesktop ? 48 : (isTablet ? 44 : 40),
          minHeight: isDesktop ? 48 : (isTablet ? 44 : 40),
        ),
      ),
    );
  }

  bool _puedeIniciarSesion() {
    return _nombreSesionController.text.isNotEmpty &&
        _categoriaSeleccionada != null &&
        _alumnos.isNotEmpty;
  }

  void _iniciarSesion() {
    if (!_puedeIniciarSesion()) return;

    setState(() {
      _sesionActual = SesionEntrenamiento(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreSesionController.text,
        descripcion:
            _descripcionController.text.isEmpty
                ? null
                : _descripcionController.text,
        categoria: _categoriaSeleccionada!,
        fechaInicio: DateTime.now(),
        entrenadorRut: 'trainer001', // TODO: Obtener del usuario autenticado
        entrenadorNombre:
            'Entrenador Wessex', // TODO: Obtener del usuario autenticado
        registros: _registrosAsistencia.values.toList(),
      );
      _sesionIniciada = true;
    });

    _mostrarExito('Sesión de asistencia iniciada correctamente');
  }

  void _cambiarEstado(String rutAlumno, EstadoAsistencia nuevoEstado) {
    setState(() {
      _registrosAsistencia[rutAlumno] = _registrosAsistencia[rutAlumno]!
          .copyWith(estado: nuevoEstado);
    });
  }

  int _contarEstado(EstadoAsistencia estado) {
    return _registrosAsistencia.values
        .where((registro) => registro.estado == estado)
        .length;
  }

  Future<void> _finalizarSesion() async {
    if (_sesionActual == null) return;

    // Validar que todos los alumnos tengan estado asignado
    final sinRegistrar = _contarEstado(EstadoAsistencia.sinRegistrar);
    if (sinRegistrar > 0) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Confirmar Finalización'),
              content: Text(
                'Hay $sinRegistrar alumno(s) sin marcar. ¿Desea continuar?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continuar'),
                ),
              ],
            ),
      );

      if (confirmar != true) return;
    }

    try {
      // TODO: Guardar la sesión completa en el servicio
      await AsistenciaService.finalizarSesion(_sesionActual!.id);

      _mostrarExito('Sesión guardada correctamente');

      // Regresar al dashboard
      Navigator.pop(context);
    } catch (e) {
      _mostrarError('Error al guardar la sesión: $e');
    }
  }

  void _cancelarSesion() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancelar Sesión'),
            content: const Text(
              '¿Está seguro que desea cancelar? Se perderán todos los datos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context); // Regresar al dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.crimsonAlert,
                ),
                child: const Text('Sí, Cancelar'),
              ),
            ],
          ),
    );
  }
}
