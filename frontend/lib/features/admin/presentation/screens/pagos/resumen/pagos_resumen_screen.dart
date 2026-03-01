import 'package:flutter/material.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/data/services/notificacion_service.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:wesrugby/data/services/pagos_service.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:wesrugby/core/utils/html.dart' as html;
import 'package:wesrugby/core/utils/platform_view_registry.dart';

// Función para ordenar categorías alfanuméricamente (M6, M8, M10, M12, etc.)
int _ordenarCategoriasAlfanumericamente(String a, String b) {
  // Extraer números de las categorías (ej: M6 -> 6, M10 -> 10)
  final regExp = RegExp(r'\d+');
  final matchA = regExp.firstMatch(a);
  final matchB = regExp.firstMatch(b);
  
  if (matchA != null && matchB != null) {
    final numA = int.tryParse(matchA.group(0)!) ?? 0;
    final numB = int.tryParse(matchB.group(0)!) ?? 0;
    if (numA != numB) {
      return numA.compareTo(numB);
    }
  }
  
  // Si no hay números o son iguales, ordenar alfabéticamente
  return a.toLowerCase().compareTo(b.toLowerCase());
}

class PagosResumenScreen extends StatefulWidget {
  final bool canSendNotifications;

  const PagosResumenScreen({
    super.key,
    this.canSendNotifications = true,
  });

  @override
  State<PagosResumenScreen> createState() => _PagosResumenScreenState();
}

class _PagosResumenScreenState extends State<PagosResumenScreen> {
  final EstudianteService _estudianteService = EstudianteService();

  final List<String> _meses = const [
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// Mapeo de nombre de mes (clave interna) a número de mes con cero a la izquierda.
  /// Usado para construir el código YYYY-MM al buscar comprobantes.
  static const Map<String, String> _mesNumero = {
    'marzo': '03',
    'abril': '04',
    'mayo': '05',
    'junio': '06',
    'julio': '07',
    'agosto': '08',
    'septiembre': '09',
    'octubre': '10',
    'noviembre': '11',
    'diciembre': '12',
  };

  List<Map<String, dynamic>> _todosEstudiantes = [];
  List<Map<String, dynamic>> _estudiantesFiltrados = [];
  List<String> _cursosDisponibles = ['Todos'];
  List<String> _categoriasDisponibles = ['Todas'];

  String _cursoSeleccionado = 'Todos';
  String _categoriaSeleccionada = 'Todas';
  bool _soloPendientes = false;
  bool _isLoading = true;
  
  // Filtro de búsqueda por nombre
  String _textoBusqueda = '';
  final TextEditingController _searchController = TextEditingController();

  // Paginación
  int _currentPage = 0;
  final int _estudiantesPerPage = 6;

  // Estados de expansión para cada estudiante
  final Map<String, bool> _pagosExpandidos = {};
  final Map<String, bool> _equipamientoExpandido = {};
  
  // Año seleccionado por cada estudiante (RUT -> año)
  final Map<String, int> _aniosPorEstudiante = {};

  @override
  void initState() {
    super.initState();
    _estudianteService.addListener(_recargarDesdeServicio);
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _estudianteService.removeListener(_recargarDesdeServicio);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _estudianteService.refreshStudentsFromAPI();
      _recargarDesdeServicio();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estudiantes: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _recargarDesdeServicio() {
    final estudiantes = _estudianteService.getAllStudents();
    final cursos =
        <String>{}..addAll(
          estudiantes
              .map((e) => (e['curso']?.toString().trim() ?? ''))
              .where((value) => value.isNotEmpty),
        );
    final categorias =
        <String>{}..addAll(
          estudiantes
              .map(
                (e) => (e['categoria']?.toString().trim().toUpperCase() ?? ''),
              )
              .where((value) => value.isNotEmpty),
        );

    setState(() {
      _todosEstudiantes = estudiantes;
      _cursosDisponibles = ['Todos', ...cursos.toList()..sort()];
      _categoriasDisponibles = ['Todas', ...categorias.toList()..sort(_ordenarCategoriasAlfanumericamente)];
      _estudiantesFiltrados = _aplicarFiltros(estudiantes);
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _aplicarFiltros(
    List<Map<String, dynamic>> origen,
  ) {
    return origen.where((estudiante) {
      // Filtro de búsqueda por nombre
      if (_textoBusqueda.isNotEmpty) {
        final nombre = estudiante['nombre']?.toString().toLowerCase() ?? '';
        if (!nombre.contains(_textoBusqueda.toLowerCase())) {
          return false;
        }
      }

      if (_cursoSeleccionado != 'Todos') {
        final curso = estudiante['curso']?.toString().toLowerCase() ?? '';
        if (curso != _cursoSeleccionado.toLowerCase()) {
          return false;
        }
      }

      if (_categoriaSeleccionada != 'Todas') {
        final categoria =
            estudiante['categoria']?.toString().toLowerCase() ?? '';
        if (categoria != _categoriaSeleccionada.toLowerCase()) {
          return false;
        }
      }

      if (_soloPendientes && !_tienePagosPendientes(estudiante)) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _tienePagosPendientes(Map<String, dynamic> estudiante) {
    final currentYear = DateTime.now().year;
    final pagos = (estudiante['pagos'] as Map<String, dynamic>?) ?? const {};
    final pagosPorAnio = (estudiante['pagosPorAnio'] as Map<String, dynamic>?) ?? {};

    // Obtener pagos del año actual: legacy para 2025, pagosPorAnio para otros años
    final Map<String, dynamic> pagosActuales = currentYear == 2025
        ? pagos
        : (pagosPorAnio[currentYear.toString()] as Map<String, dynamic>?) ?? {};

    if (_esPendiente(pagosActuales['matricula'])) {
      return true;
    }
    final meses = (pagosActuales['meses'] as Map<String, dynamic>?) ?? const {};
    for (final mes in _meses) {
      if (_esPendiente(_obtenerValorMes(meses, mes))) {
        return true;
      }
    }
    if (_esPendiente(pagosActuales['totalAnio'])) {
      return true;
    }
    return false;
  }

  bool _esPendiente(dynamic valor) {
    final texto = valor?.toString().trim().toLowerCase() ?? '';
    if (texto.isEmpty) return true;
    if (texto.contains('no') ||
        texto.contains('pend') ||
        texto.contains('deuda')) {
      return true;
    }
    if (texto.contains('sin')) {
      return true;
    }
    return false;
  }

  bool _esPagado(dynamic valor) {
    final texto = valor?.toString().trim().toLowerCase() ?? '';
    if (texto.isEmpty) return false;
    if (texto.contains('si') || texto.contains('sí') || texto.contains('pag')) {
      return true;
    }
    if (texto.contains('al dia') || texto.contains('al día')) {
      return true;
    }
    return false;
  }

  String _obtenerValorMes(Map<String, dynamic> meses, String mes) {
    if (meses.containsKey(mes)) {
      return _formatearValor(meses[mes]);
    }
    final claveCoincidente = meses.keys.firstWhere(
      (key) => key.toString().toLowerCase() == mes,
      orElse: () => mes,
    );
    return _formatearValor(meses[claveCoincidente]);
  }

  String _mesTitulo(String mes) {
    if (mes.isEmpty) return mes;
    return mes[0].toUpperCase() + mes.substring(1);
  }

  int get _totalPendientes =>
      _estudiantesFiltrados.where(_tienePagosPendientes).length;

  int get _totalMatriculaAlDia {
    final currentYear = DateTime.now().year;
    return _estudiantesFiltrados.where((estudiante) {
      final pagos = (estudiante['pagos'] as Map<String, dynamic>?) ?? {};
      final pagosPorAnio = (estudiante['pagosPorAnio'] as Map<String, dynamic>?) ?? {};
      final matricula = currentYear == 2025
          ? pagos['matricula']
          : (pagosPorAnio[currentYear.toString()] as Map<String, dynamic>?)?['matricula'];
      return _esPagado(matricula);
    }).length;
  }

  void _onCursoChanged(String? value) {
    setState(() {
      _cursoSeleccionado = value ?? 'Todos';
      _estudiantesFiltrados = _aplicarFiltros(_todosEstudiantes);
      _currentPage = 0;
    });
  }

  void _onCategoriaChanged(String? value) {
    setState(() {
      _categoriaSeleccionada = value ?? 'Todas';
      _estudiantesFiltrados = _aplicarFiltros(_todosEstudiantes);
      _currentPage = 0;
    });
  }

  void _onPendientesChanged(bool value) {
    setState(() {
      _soloPendientes = value;
      _estudiantesFiltrados = _aplicarFiltros(_todosEstudiantes);
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.canSendNotifications ? 2 : 1,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: WessexAppBar(
          title: 'Resumen de Pagos',
          elevation: 2,
          bottom: TabBar(
            indicatorColor: WessexColors.goldenYellow,
            labelColor: WessexColors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(text: 'Resumen'),
              if (widget.canSendNotifications) const Tab(text: 'Notificaciones'),
            ],
          ),
        ),
        body: WessexBackground(
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _buildResumenTab(),
                      if (widget.canSendNotifications) _buildNotificacionesTab(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumenTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResumenGeneral(),
          const SizedBox(height: 24),
          _buildFiltros(),
          const SizedBox(height: 24),
          if (_estudiantesFiltrados.isEmpty)
            _buildEmptyState()
          else
            _buildEstudiantesPaginados(),
        ],
      ),
    );
  }

  // Variables para la pestaña de notificaciones
  String _notificacionCategoria = 'Pagos'; // Pagos, Equipamiento
  String _notificacionSubcategoria = 'Matrícula'; // Matrícula, Mensualidad (solo si es Pagos)
  String _notificacionMes = 'marzo'; // Solo si es Mensualidad
  int _notificacionAnio = DateTime.now().year; // Año de la deuda (2025-2030)
  bool _enviandoNotificaciones = false;

  Widget _buildNotificacionesTab() {
    // Filtrar estudiantes deudores según selección
    List<Map<String, dynamic>> deudores = [];
    
    if (_notificacionCategoria == 'Pagos') {
      if (_notificacionSubcategoria == 'Matrícula') {
        deudores = _todosEstudiantes.where((e) {
          final pagos = (e['pagos'] as Map<String, dynamic>?) ?? {};
          final pagosPorAnio = (e['pagosPorAnio'] as Map<String, dynamic>?) ?? {};
          final matricula = _notificacionAnio == 2025
              ? pagos['matricula']
              : (pagosPorAnio[_notificacionAnio.toString()] as Map<String, dynamic>?)?['matricula'];
          return _esPendiente(matricula);
        }).toList();
      } else {
        // Mensualidad
        deudores = _todosEstudiantes.where((e) {
          final pagos = (e['pagos'] as Map<String, dynamic>?) ?? {};
          final pagosPorAnio = (e['pagosPorAnio'] as Map<String, dynamic>?) ?? {};
          final Map<String, dynamic> meses;
          if (_notificacionAnio == 2025) {
            meses = (pagos['meses'] as Map<String, dynamic>?) ?? {};
          } else {
            final pagosAnio = (pagosPorAnio[_notificacionAnio.toString()] as Map<String, dynamic>?) ?? {};
            meses = (pagosAnio['meses'] as Map<String, dynamic>?) ?? {};
          }
          return _esPendiente(_obtenerValorMes(meses, _notificacionMes));
        }).toList();
      }
    } else {
      // Equipamiento (cualquiera que aparezca en el cuadro)
      deudores = _todosEstudiantes.where((e) {
        final equipamiento = (e['equipamiento'] as Map<String, dynamic>?) ?? {};
        return equipamiento.isNotEmpty;
      }).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WessexCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurar Notificación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.darkGrape,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Selector de Categoría
                DropdownButtonFormField<String>(
                  value: _notificacionCategoria,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Pagos', 'Equipamiento'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() {
                    _notificacionCategoria = val!;
                    if (val == 'Equipamiento') {
                      _notificacionSubcategoria = ''; // No aplica
                    } else {
                      _notificacionSubcategoria = 'Matrícula';
                    }
                  }),
                ),
                const SizedBox(height: 16),

                // Selector de Subcategoría (Solo Pagos)
                if (_notificacionCategoria == 'Pagos') ...[
                  DropdownButtonFormField<String>(
                    value: _notificacionSubcategoria,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Pago',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Matrícula', 'Mensualidad'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _notificacionSubcategoria = val!),
                  ),
                  const SizedBox(height: 16),
                ],

                // Selector de Mes (Solo Mensualidad)
                if (_notificacionCategoria == 'Pagos' && _notificacionSubcategoria == 'Mensualidad') ...[
                  DropdownButtonFormField<String>(
                    value: _notificacionMes,
                    decoration: InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _meses.map((e) => DropdownMenuItem(value: e, child: Text(_mesTitulo(e)))).toList(),
                    onChanged: (val) => setState(() => _notificacionMes = val!),
                  ),
                  const SizedBox(height: 16),
                ],

                // Selector de Año (Para Pagos: Matrícula y Mensualidad)
                if (_notificacionCategoria == 'Pagos') ...[
                  DropdownButtonFormField<int>(
                    value: _notificacionAnio,
                    decoration: InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: List.generate(6, (index) => 2025 + index)
                        .map((year) => DropdownMenuItem(value: year, child: Text('$year')))
                        .toList(),
                    onChanged: (val) => setState(() => _notificacionAnio = val!),
                  ),
                  const SizedBox(height: 16),
                ],

                const Divider(),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destinatarios: ${deudores.length}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                          Text(
                            'Se enviará notificación a todos los apoderados de la lista.',
                            style: TextStyle(
                              fontSize: 12,
                              color: WessexColors.darkGrape.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: deudores.isEmpty || _enviandoNotificaciones 
                          ? null 
                          : () => _enviarNotificacionesMasivas(deudores),
                      icon: _enviandoNotificaciones 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: const Text('Enviar Notificación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WessexColors.crimsonAlert,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          if (deudores.isNotEmpty)
            Column(
              children: deudores.map((estudiante) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WessexCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: WessexColors.deepRoyalBlue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              estudiante['nombre'] ?? 'Sin nombre',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                            Text(
                              'Apoderado: ${estudiante['nombreResponsable'] ?? 'No asignado'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: WessexColors.darkGrape.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_notificacionCategoria == 'Pagos')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: WessexColors.crimsonAlert.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Debe ${_notificacionSubcategoria == 'Mensualidad' ? '${_mesTitulo(_notificacionMes)} $_notificacionAnio' : 'Matrícula $_notificacionAnio'}',

                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: WessexColors.crimsonAlert,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )).toList(),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No hay destinatarios para los filtros seleccionados.'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _enviarNotificacionesMasivas(List<Map<String, dynamic>> deudores) async {
    setState(() => _enviandoNotificaciones = true);

    try {
      // Recopilar RUTs de apoderados (usando RUT estudiante como proxy si no hay rut apoderado explícito, 
      // pero idealmente debería ser el rut del usuario apoderado. 
      // Asumiremos que el backend puede resolver el usuario apoderado a partir del estudiante o que el estudiante tiene el dato.
      // En este sistema parece que el estudiante tiene 'rut' y 'nombreResponsable'. 
      // Necesitamos el RUT del USUARIO apoderado. 
      // Revisando estudiante_service.dart, no veo explícitamente el rut del apoderado usuario, solo 'rut' del estudiante.
      // Sin embargo, en la lógica de notificaciones, se usa 'rutReceptor'.
      // Si el apoderado es el usuario, necesitamos su RUT.
      // Voy a asumir que el sistema usa el RUT del estudiante para buscar al apoderado o que el apoderado tiene el mismo RUT (poco probable)
      // O que enviaremos al RUT del estudiante y el backend lo redirige? No, el backend busca User por rut.
      // Revisando `EstudianteService`, no hay campo `rutApoderado`.
      // Pero hay `correoApoderadoGenerado`. 
      // Si no tengo el RUT del apoderado, no puedo enviar la notificación directa a él si el sistema se basa en RUT.
      // VOY A ASUMIR que el RUT del estudiante es la clave para encontrar al apoderado O que enviaremos al RUT del estudiante 
      // y el apoderado ve las notificaciones de sus estudiantes.
      // PERO el requerimiento dice "Debe llegarle al apoderado".
      // En `notificacion.service.js` backend: `const receptor = await userRepository.findOne({ where: { rut: rutReceptor } });`
      // Esto busca en la tabla User. Los apoderados son Users.
      // Necesito los RUTs de los apoderados.
      // En `tesorera_dashboard.dart` no se ve cómo obtenerlos.
      // En `gestion_usuarios_screen.dart` (no visto) podría estar.
      // Por ahora, usaré el RUT del estudiante como destinatario, asumiendo que el apoderado tiene ese RUT asociado o es el mismo.
      // OJO: Si el apoderado tiene su propio RUT, esto fallará si no coincide.
      // REVISIÓN RÁPIDA: `EstudianteService` tiene `rut` (del estudiante).
      // Si el apoderado se loguea, usa SU rut.
      // Existe una relación? `Apoderado` tiene `pupilos`.
      // Si envío la notificación al RUT del estudiante, el apoderado NO la verá si el backend busca por `rutReceptor == user.rut`.
      // SOLUCIÓN: El backend debería buscar los apoderados de estos estudiantes.
      // O el frontend debería tener el rut del apoderado.
      // Como no puedo cambiar todo el modelo de datos ahora, voy a enviar la notificación con un campo `datos: { rutEstudiante: ... }`
      // Y en el backend o frontend manejarlo.
      // PERO `crearNotificacionMasiva` toma `destinatarios` (lista de RUTs).
      // Si paso RUTs de estudiantes, y no son usuarios, fallará la validación de usuario existente en backend.
      // VALIDACIÓN: `const receptor = await userRepository.findOne({ where: { rut: rutReceptor } });`
      // Esto confirma que el destinatario DEBE ser un usuario registrado.
      // Los estudiantes NO suelen ser usuarios.
      // Los apoderados SI.
      // ¿Dónde está el RUT del apoderado en el objeto estudiante?
      // `estudiante['rut']` es del estudiante.
      // `estudiante['nombreResponsable']` es nombre.
      // NO VEO EL RUT DEL APODERADO.
      // Esto es un problema.
      // Sin embargo, veo `correoApoderadoGenerado`.
      // Tal vez el RUT del apoderado es el mismo del estudiante en este sistema simplificado?
      // O tal vez no se está cargando.
      // Voy a asumir por ahora que debo usar el RUT del estudiante y si falla, tendré que investigar más.
      // ESPERA: En `EstudianteService` -> `_adaptEstudianteFromBackend`:
      // No hay rut de apoderado.
      // PERO, si el apoderado se creó al importar, debe tener un RUT.
      // Si no tengo el RUT del apoderado, no puedo notificarle.
      // Voy a agregar un TODO y usar el RUT del estudiante como placeholder, 
      // pero lo más probable es que necesite el RUT del apoderado.
      // Si el sistema usa el RUT del estudiante como ID de usuario para el apoderado (común en sistemas escolares simples), funcionará.
      
      final destinatarios = deudores
          .map((e) => e['rutResponsable']?.toString())
          .where((rut) => rut != null && rut.isNotEmpty)
          .cast<String>()
          .toList();

      if (destinatarios.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontraron RUTs de apoderados válidos para los estudiantes seleccionados.'),
              backgroundColor: WessexColors.crimsonAlert,
            ),
          );
        }
        return;
      }
      
      String titulo = 'Aviso de Cobro';
      String mensaje = '';
      String tipo = 'cobro';
      Map<String, dynamic> datos = {};

      if (_notificacionCategoria == 'Pagos') {
        if (_notificacionSubcategoria == 'Matrícula') {
          mensaje = 'Estimado apoderado, le recordamos que tiene pendiente el pago de la Matrícula $_notificacionAnio.';
          datos = {'tipoDeuda': 'matricula', 'anio': _notificacionAnio};
        } else {
          mensaje = 'Estimado apoderado, le recordamos que tiene pendiente el pago de la mensualidad de ${_mesTitulo(_notificacionMes)} $_notificacionAnio.';
          datos = {'tipoDeuda': 'mes', 'mes': _notificacionMes, 'anio': _notificacionAnio};
        }
      } else {
        mensaje = 'Estimado apoderado, le recordamos regularizar su situación de equipamiento.';
        datos = {'tipoDeuda': 'equipamiento'};
      }

      final resultado = await NotificacionService.enviarNotificacionMasiva(
        destinatarios: destinatarios,
        titulo: titulo,
        mensaje: mensaje,
        tipo: tipo,
        datos: datos,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message']),
            backgroundColor: resultado['success'] ? WessexColors.leafGreen : WessexColors.crimsonAlert,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar notificaciones: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviandoNotificaciones = false);
      }
    }
  }

  Widget _buildEstudiantesPaginados() {
    final totalPages = (_estudiantesFiltrados.length / _estudiantesPerPage).ceil();
    final startIndex = _currentPage * _estudiantesPerPage;
    final endIndex = (startIndex + _estudiantesPerPage).clamp(0, _estudiantesFiltrados.length);
    final estudiantesPaginados = _estudiantesFiltrados.sublist(startIndex, endIndex);

    return Column(
      children: [
        ...estudiantesPaginados.map(_buildTarjetaEstudiante).toList(),
        if (totalPages > 1) ...[
          const SizedBox(height: 24),
          _buildPaginacionControls(totalPages),
        ],
      ],
    );
  }

  Widget _buildPaginacionControls(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0
              ? () => setState(() => _currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left),
          color: WessexColors.deepRoyalBlue,
        ),
        const SizedBox(width: 16),
        ...List.generate(totalPages, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildPageButton(index, totalPages),
          );
        }),
        const SizedBox(width: 16),
        IconButton(
          onPressed: _currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
          icon: const Icon(Icons.chevron_right),
          color: WessexColors.deepRoyalBlue,
        ),
      ],
    );
  }

  Widget _buildPageButton(int pageIndex, int totalPages) {
    final isActive = pageIndex == _currentPage;
    return InkWell(
      onTap: () => setState(() => _currentPage = pageIndex),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? WessexColors.deepRoyalBlue : Colors.transparent,
          border: Border.all(
            color: WessexColors.deepRoyalBlue,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '${pageIndex + 1}',
          style: TextStyle(
            color: isActive ? Colors.white : WessexColors.deepRoyalBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildResumenGeneral() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth > 1000
                ? 3
                : constraints.maxWidth > 600
                ? 2
                : 1;
        final tarjetas = [
          _buildResumenCard(
            titulo: 'Estudiantes',
            valor: _estudiantesFiltrados.length.toString(),
            icono: Icons.people,
            color: WessexColors.deepRoyalBlue,
            detalle: '${_todosEstudiantes.length} registrados en total',
          ),
          _buildResumenCard(
            titulo: 'Pagos pendientes',
            valor: _totalPendientes.toString(),
            icono: Icons.error_outline,
            color: WessexColors.crimsonAlert,
            detalle:
                _soloPendientes
                    ? 'Mostrando únicamente pendientes'
                    : 'Activa el filtro para ver solo pendientes',
          ),
          _buildResumenCard(
            titulo: 'Matrícula al día',
            valor: _totalMatriculaAlDia.toString(),
            icono: Icons.verified_user,
            color: WessexColors.leafGreen,
            detalle: 'Pagos de matrícula marcados como pagados',
          ),
        ];

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio:
              crossAxisCount == 1
                  ? 3.4
                  : crossAxisCount == 2
                  ? 2.6
                  : 3.4,
          children: tarjetas,
        );
      },
    );
  }

  Widget _buildResumenCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
    required String detalle,
  }) {
    return LayoutBuilder( // 🔹 Detecta el espacio disponible
      builder: (context, constraints) {
        return WessexCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox( // 🔹 Ajusta automáticamente el tamaño del contenido
                  fit: BoxFit.scaleDown, // 🔹 Evita overflow horizontal y vertical
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // 🔹 Ajusta al contenido
                    children: [
                      Text(
                        valor,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: WessexColors.darkGrape.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detalle,
                        style: TextStyle(
                          fontSize: 13,
                          color: WessexColors.darkGrape.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildFiltros() {
    return WessexCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WessexColors.darkGrape,
            ),
          ),
          const SizedBox(height: 16),
          
          // Campo de búsqueda por nombre
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar por nombre',
              hintText: 'Escribe el nombre del estudiante...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _textoBusqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _textoBusqueda = '';
                          _estudiantesFiltrados = _aplicarFiltros(_todosEstudiantes);
                          _currentPage = 0;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (valor) {
              setState(() {
                _textoBusqueda = valor;
                _estudiantesFiltrados = _aplicarFiltros(_todosEstudiantes);
                _currentPage = 0;
              });
            },
          ),
          const SizedBox(height: 16),
          
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: _buildCursoDropdown()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCategoriaDropdown()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildCursoDropdown(),
                  const SizedBox(height: 16),
                  _buildCategoriaDropdown(),
                ],
              );
            },
          ),
          SwitchListTile.adaptive(
            value: _soloPendientes,
            onChanged: _onPendientesChanged,
            activeColor: WessexColors.crimsonAlert,
            title: const Text('Mostrar solo estudiantes con pagos pendientes'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  DropdownButtonFormField<String> _buildCursoDropdown() {
    return DropdownButtonFormField<String>(
      value: _cursoSeleccionado,
      onChanged: _onCursoChanged,
      decoration: InputDecoration(
        labelText: 'Curso',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items:
          _cursosDisponibles
              .map(
                (curso) => DropdownMenuItem(value: curso, child: Text(curso)),
              )
              .toList(),
    );
  }

  DropdownButtonFormField<String> _buildCategoriaDropdown() {
    return DropdownButtonFormField<String>(
      value: _categoriaSeleccionada,
      onChanged: _onCategoriaChanged,
      decoration: InputDecoration(
        labelText: 'Categoría',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items:
          _categoriasDisponibles
              .map(
                (categoria) =>
                    DropdownMenuItem(value: categoria, child: Text(categoria)),
              )
              .toList(),
    );
  }

  // ─── Detalle de comprobante por mes / matrícula (solo años > 2025) ─────────

  Future<void> _mostrarDetalleVoucher({
    required String estudianteRut,
    required String nombreEstudiante,
    required int anio,
    String? mes, // null = Matrícula; non-null = clave de mes, ej: 'julio'
  }) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      List<Map<String, dynamic>> comprobantes = [];

      // Traer TODOS los comprobantes del estudiante sin filtrar por mes en el backend.
      // El backend filtra por estudianteRut incluyendo pagos donde aparece en
      // estudiantesRuts (JSONB). El filtrado por mes/tipo se hace aquí.
      final response = await PagosService.obtenerComprobantes(
        estudianteRut: estudianteRut,
        limite: 100,
      );

      if (response.success && response.data != null) {
        // El backend envuelve con handleSuccess → { success, message, data: { comprobantes: [...] } }
        // ApiService almacena el body completo en response.data, así que hay que bajar un nivel.
        final inner = (response.data is Map && response.data['data'] != null)
            ? response.data['data']
            : response.data;
        final raw = (inner is Map)
            ? (inner['comprobantes'] ?? inner)
            : inner;
        if (raw is List) {
          final todos = raw.cast<Map<String, dynamic>>();

          if (mes != null) {
            // MENSUALIDAD: buscar comprobantes que incluyan este mes en cualquier campo
            final mesNum = _mesNumero[mes];
            if (mesNum == null) {
              if (mounted) Navigator.pop(context);
              return;
            }
            final mesCode = '$anio-$mesNum'; // ej: "2026-07"

            comprobantes = todos.where((c) {
              // 1. Campo mesCorrespondiente directo
              if ((c['mesCorrespondiente'] ?? '').toString() == mesCode) {
                return true;
              }
              // 2. Array mesesCorrespondientes (pagos agrupados)
              final mesesArr = c['mesesCorrespondientes'];
              if (mesesArr is List && mesesArr.contains(mesCode)) return true;
              // 3. detallesPago[rut].meses contiene mesCode
              final detalles = c['detallesPago'];
              if (detalles is Map) {
                for (final detalle in detalles.values) {
                  if (detalle is Map) {
                    final mesesDetalle = detalle['meses'];
                    if (mesesDetalle is List && mesesDetalle.contains(mesCode)) {
                      return true;
                    }
                  }
                }
              }
              return false;
            }).toList();
          } else {
            // MATRÍCULA: buscar comprobantes tipo 'matricula' del año correcto
            comprobantes = todos.where((c) {
              final tipo = (c['tipoPago'] ?? '').toString().toLowerCase();
              if (tipo != 'matricula') return false;
              // Verificar año
              final anioC = c['anioMatricula'];
              if (anioC != null) return anioC.toString() == anio.toString();
              // Fallback: año en fechaPago
              return (c['fechaPago'] ?? '').toString().startsWith(anio.toString());
            }).toList();
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // cerrar loading

      final titulo = mes != null
          ? '${_mesTitulo(mes)} $anio — $nombreEstudiante'
          : 'Matrícula $anio — $nombreEstudiante';

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 520),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
                const Divider(),
                if (comprobantes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: WessexColors.maximumGrayMint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontró ningún comprobante para este período.',
                            style: TextStyle(
                              color: WessexColors.darkGrape.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: comprobantes.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (_, i) =>
                          _buildComprobanteItem(ctx, comprobantes[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar el comprobante: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  Widget _buildComprobanteItem(
    BuildContext ctx,
    Map<String, dynamic> c,
  ) {
    final estado = (c['estado'] ?? 'pendiente').toString();
    final archivoUrl =
        (c['archivoUrl'] ?? c['rutaComprobante'] ?? '').toString();

    Color estadoColor;
    switch (estado.toLowerCase()) {
      case 'validado':
        estadoColor = WessexColors.leafGreen;
        break;
      case 'rechazado':
        estadoColor = WessexColors.crimsonAlert;
        break;
      case 'observado':
        estadoColor = WessexColors.deepRoyalBlue;
        break;
      default:
        estadoColor = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _infoChip(
              Icons.tag,
              'N° ${(c['numeroComprobante'] ?? 'S/N')}',
              WessexColors.darkGrape,
            ),
            _infoChip(
              Icons.payment,
              PagosService.formatearMetodoPago(
                (c['metodoPago'] ?? '').toString(),
              ),
              WessexColors.deepRoyalBlue,
            ),
            _infoChip(
              Icons.attach_money,
              '\$${c['montoTotal']?.toString() ?? ''}',
              WessexColors.leafGreen,
            ),
            _infoChip(
              Icons.calendar_today,
              (c['fechaPago'] ?? '').toString(),
              WessexColors.darkGrape,
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: estadoColor.withOpacity(0.4)),
              ),
              child: Text(
                estado.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: estadoColor,
                ),
              ),
            ),
          ],
        ),
        if ((c['observacionesTesorera'] ?? '').toString().isNotEmpty) ...[  
          const SizedBox(height: 8),
          Text(
            'Obs. Tesorera: ${c['observacionesTesorera']}',
            style: TextStyle(
              fontSize: 12,
              color: WessexColors.darkGrape.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (archivoUrl.isNotEmpty) ...[  
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _mostrarVisorVoucher(
              ctx: ctx,
              url: archivoUrl,
              tipoArchivo: (c['tipoArchivo'] ?? '').toString(),
              nombreArchivo: (c['nombreArchivoOriginal'] ?? 'voucher').toString(),
              numeroComprobante: (c['numeroComprobante'] ?? '').toString(),
            ),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('Ver Voucher'),
            style: OutlinedButton.styleFrom(
              foregroundColor: WessexColors.deepRoyalBlue,
              side: const BorderSide(color: WessexColors.deepRoyalBlue),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: WessexColors.darkGrape),
        ),
      ],
    );
  }

  void _mostrarVisorVoucher({
    required BuildContext ctx,
    required String url,
    String tipoArchivo = '',
    String nombreArchivo = 'voucher',
    String numeroComprobante = '',
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => _VoucherViewerDialog(
        url: url,
        tipoArchivo: tipoArchivo,
        nombreArchivo: nombreArchivo,
        numeroComprobante: numeroComprobante,
      ),
    );
  }

  /// Construye la celda de un mes dentro del grid de pagos.
  /// Si [onTap] no es null, la celda es presionable (cursor pointer + ripple).
  Widget _buildMesCelda({
    required String mes,
    required String valor,
    required Color color,
    VoidCallback? onTap,
  }) {
    Widget cell = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  _mesTitulo(mes),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.darkGrape,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.search,
                  size: 13,
                  color: WessexColors.deepRoyalBlue.withOpacity(0.6),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: WessexColors.darkGrape,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      cell = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: cell),
      );
    }
    return cell;
  }

  Widget _buildTarjetaEstudiante(Map<String, dynamic> estudiante) {
    final pagos = (estudiante['pagos'] as Map<String, dynamic>?) ?? const {};
    final pagosMeses = (pagos['meses'] as Map<String, dynamic>?) ?? const {};
    final equipamiento =
        (estudiante['equipamiento'] as Map<String, dynamic>?) ?? const {};
    
    // Usar RUT como clave única para el estado de expansión
    final rutKey = estudiante['rut']?.toString() ?? estudiante['nombre']?.toString() ?? '';
    final pagosExpanded = _pagosExpandidos[rutKey] ?? false;
    final equipamientoExpanded = _equipamientoExpandido[rutKey] ?? false;
    
    // Obtener año seleccionado para este estudiante (por defecto: año actual)
    final anioEstudiante = _aniosPorEstudiante[rutKey] ?? DateTime.now().year;
    
    // Obtener pagos por año (nueva estructura)
    final pagosPorAnio = (estudiante['pagosPorAnio'] as Map<String, dynamic>?) ?? {};
    final pagosDelAnio = (pagosPorAnio[anioEstudiante.toString()] as Map<String, dynamic>?) ?? {};
    
    // Si el año es 2025, usar datos del Excel (estructura legacy), sino usar pagosPorAnio
    final matricula = anioEstudiante == 2025
        ? _formatearValor(pagos['matricula'])
        : _formatearValor(pagosDelAnio['matricula']);
    final mesesAMostrar = anioEstudiante == 2025
        ? pagosMeses
        : (pagosDelAnio['meses'] as Map<String, dynamic>?) ?? {};

    // Calcular total del año: suma de matrícula + todos los meses pagados
    final String totalAnio;
    if (anioEstudiante == 2025) {
      totalAnio = _formatearValor(pagos['totalAnio']);
    } else {
      double total = 0.0;
      bool hayDatos = false;
      // Sumar matrícula
      final matriculaRaw = pagosDelAnio['matricula'];
      if (matriculaRaw != null) {
        final v = double.tryParse(matriculaRaw.toString());
        if (v != null && v > 0) { total += v; hayDatos = true; }
      }
      // Sumar meses
      for (final val in mesesAMostrar.values) {
        final v = double.tryParse(val?.toString() ?? '');
        if (v != null && v > 0) { total += v; hayDatos = true; }
      }
      totalAnio = hayDatos ? total.toStringAsFixed(0) : 'Sin información';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: WessexCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estudiante['nombre'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RUT: ${estudiante['rut'] ?? 'Sin RUT'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: WessexColors.darkGrape.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildEtiquetaDetalle('Curso', estudiante['curso']),
                          _buildEtiquetaDetalle(
                            'Categoría',
                            estudiante['categoria'],
                          ),
                          _buildEtiquetaDetalle(
                            'Responsable',
                            estudiante['nombreResponsable'],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (estudiante['correoApoderadoGenerado'] != null &&
                    estudiante['correoApoderadoGenerado'].toString().isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.alternate_email, size: 18),
                    label: Text(estudiante['correoApoderadoGenerado']),
                    backgroundColor: WessexColors.deepRoyalBlue.withOpacity(
                      0.1,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Botones en horizontal
            Row(
              children: [
                // Botón de Pagos
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _pagosExpandidos[rutKey] = !pagosExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: WessexColors.deepRoyalBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: WessexColors.deepRoyalBlue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.payments,
                            color: WessexColors.deepRoyalBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pagos',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.deepRoyalBlue,
                              ),
                            ),
                          ),
                          Icon(
                            pagosExpanded ? Icons.expand_less : Icons.expand_more,
                            color: WessexColors.deepRoyalBlue,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Espaciado entre botones
                if (equipamiento.isNotEmpty) const SizedBox(width: 12),
                
                // Botón de Equipamiento
                if (equipamiento.isNotEmpty)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _equipamientoExpandido[rutKey] = !equipamientoExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: WessexColors.leafGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: WessexColors.leafGreen.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sports_rugby,
                              color: WessexColors.leafGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Equipamiento',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: WessexColors.leafGreen,
                                ),
                              ),
                            ),
                            Icon(
                              equipamientoExpanded ? Icons.expand_less : Icons.expand_more,
                              color: WessexColors.leafGreen,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Contenido de Pagos (desplegable)
            if (pagosExpanded) ...[
              const SizedBox(height: 16),
              
              // Selector de año individual
              DropdownButtonFormField<int>(
                value: _aniosPorEstudiante[rutKey] ?? DateTime.now().year,
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() {
                      _aniosPorEstudiante[rutKey] = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Año',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(Icons.calendar_today, color: WessexColors.deepRoyalBlue),
                ),
                items: List.generate(6, (index) => 2025 + index)
                    .map((year) => DropdownMenuItem(value: year, child: Text('$year')))
                    .toList(),
              ),
              
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  anioEstudiante > 2025 && matricula != 'Sin información'
                    ? MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _mostrarDetalleVoucher(
                            estudianteRut: rutKey,
                            nombreEstudiante:
                                estudiante['nombre']?.toString() ?? '',
                            anio: anioEstudiante,
                          ),
                          child: _buildPagoEstatusChip('Matrícula', matricula),
                        ),
                      )
                    : _buildPagoEstatusChip('Matrícula', matricula),
                  _buildPagoEstatusChip('Total año', totalAnio),
                ],
              ),
              const SizedBox(height: 16),
              _buildMesesGrid(
                mesesAMostrar,
                anioEstudiante,
                estudianteRut: rutKey,
                nombreEstudiante: estudiante['nombre']?.toString() ?? '',
              ),
            ],
            
            // Contenido de Equipamiento (desplegable)
            if (equipamientoExpanded) ...[
              const SizedBox(height: 16),
              _buildEquipamientoResumen(equipamiento),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEtiquetaDetalle(String titulo, dynamic valor) {
    final texto = _formatearValor(valor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: WessexColors.maximumGrayMint.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$titulo: $texto',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: WessexColors.darkGrape.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildPagoEstatusChip(String titulo, String valor) {
    final color = _colorEstado(valor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: WessexColors.darkGrape,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: WessexColors.darkGrape,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMesesGrid(
    Map<String, dynamic> meses,
    int anioSeleccionado, {
    String estudianteRut = '',
    String nombreEstudiante = '',
  }) {
    // Los meses son presionables a partir del año 2026
    final esTappable = anioSeleccionado > 2025;

    return WessexCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Primera fila (5 meses)
          Row(
            children: _meses.take(5).map((mes) {
              final valor = _obtenerValorMes(meses, mes);
              final color = _colorEstado(valor);
              final tieneDatos = valor != 'Sin información';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: _buildMesCelda(
                    mes: mes,
                    valor: valor,
                    color: color,
                    onTap: esTappable && tieneDatos
                        ? () => _mostrarDetalleVoucher(
                              estudianteRut: estudianteRut,
                              nombreEstudiante: nombreEstudiante,
                              anio: anioSeleccionado,
                              mes: mes,
                            )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          // Segunda fila (5 meses)
          Row(
            children: _meses.skip(5).map((mes) {
              final valor = _obtenerValorMes(meses, mes);
              final color = _colorEstado(valor);
              final tieneDatos = valor != 'Sin información';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildMesCelda(
                    mes: mes,
                    valor: valor,
                    color: color,
                    onTap: esTappable && tieneDatos
                        ? () => _mostrarDetalleVoucher(
                              estudianteRut: estudianteRut,
                              nombreEstudiante: nombreEstudiante,
                              anio: anioSeleccionado,
                              mes: mes,
                            )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipamientoResumen(Map<String, dynamic> equipamiento) {
    final items = <String, dynamic>{
      'Polerón': equipamiento['poleron'],
      'Calcetas': equipamiento['calcetas'],
      'Protector Bucal': equipamiento['protectorBucal'],
      'Uniforme': equipamiento['uniforme'],
      'Añadido': equipamiento['anadido'],
    };

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          items.entries.map((entry) {
            final valor = _formatearValor(entry.value);
            final color = _colorEstado(valor);
            return Chip(
              label: Text('${entry.key}: $valor'),
              backgroundColor: color.withOpacity(0.12),
              shape: StadiumBorder(
                side: BorderSide(color: color.withOpacity(0.4)),
              ),
            );
          }).toList(),
    );
  }

  Color _colorEstado(String valor) {
    final texto = valor.toLowerCase();
    if (_esPendiente(texto)) {
      return WessexColors.crimsonAlert;
    }
    if (_esPagado(texto)) {
      return WessexColors.leafGreen;
    }
    return WessexColors.maximumGrayMint;
  }

  String _formatearValor(dynamic valor) {
    if (valor == null) return 'Sin información';
    final texto = valor.toString().trim();
    if (texto.isEmpty) return 'Sin información';
    if (texto.toLowerCase() == 'n/a' || texto.toLowerCase() == 'null') {
      return 'Sin información';
    }
    // Si es un número, mostrar sin decimales innecesarios (ej: "20000.0" → "20000")
    final numero = double.tryParse(texto);
    if (numero != null) {
      return numero == numero.truncateToDouble()
          ? numero.toInt().toString()
          : texto;
    }
    return texto;
  }

  Widget _buildEmptyState() {
    return WessexCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wallet_outlined,
            size: 48,
            color: WessexColors.maximumGrayMint,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay registros para los filtros seleccionados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: WessexColors.darkGrape,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta los filtros o verifica que los datos de pagos estén cargados correctamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: WessexColors.darkGrape.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Visualizador de voucher inline (imagen con zoom o PDF en iframe)
// ─────────────────────────────────────────────────────────────

class _VoucherViewerDialog extends StatefulWidget {
  final String url;
  final String tipoArchivo;
  final String nombreArchivo;
  final String numeroComprobante;

  const _VoucherViewerDialog({
    required this.url,
    required this.tipoArchivo,
    required this.nombreArchivo,
    required this.numeroComprobante,
  });

  @override
  State<_VoucherViewerDialog> createState() => _VoucherViewerDialogState();
}

class _VoucherViewerDialogState extends State<_VoucherViewerDialog> {
  late final String _viewId;
  bool _imageError = false;

  bool get _esPdf {
    final tipo = widget.tipoArchivo.toLowerCase();
    if (tipo.contains('pdf')) return true;
    return widget.url.toLowerCase().endsWith('.pdf');
  }

  bool get _esImagen {
    final tipo = widget.tipoArchivo.toLowerCase();
    if (tipo.startsWith('image/')) return true;
    final url = widget.url.toLowerCase();
    return url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.gif') ||
        url.endsWith('.webp');
  }

  @override
  void initState() {
    super.initState();
    _viewId = 'voucher-${DateTime.now().millisecondsSinceEpoch}';
    if (kIsWeb && _esPdf) {
      registerViewFactory(_viewId, (int id) {
        // ignore: avoid_web_libraries_in_flutter
        final iframe = html.IFrameElement()
          ..src = widget.url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true;
        return iframe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: size.width * 0.9,
        height: size.height * 0.9,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // ── Barra superior ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF16213E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.numeroComprobante.isNotEmpty
                              ? 'Comprobante N° ${widget.numeroComprobante}'
                              : 'Visor de voucher',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (widget.nombreArchivo.isNotEmpty)
                          Text(
                            widget.nombreArchivo,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Fallback: abrir en nueva pestaña
                  TextButton.icon(
                    onPressed: () {
                      if (kIsWeb) html.window.open(widget.url, '_blank');
                    },
                    icon: const Icon(Icons.open_in_new,
                        size: 14, color: Colors.white54),
                    label: const Text('Nueva pestaña',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Cerrar',
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            // ── Contenido ──
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // PDF: iframe nativo del navegador
    if (_esPdf && kIsWeb) {
      return HtmlElementView(viewType: _viewId);
    }
    // Imagen: con zoom interactivo
    if (_esImagen) {
      return Container(
        color: const Color(0xFF0F3460),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Center(
            child: _imageError
                ? _fallbackWidget()
                : Image.network(
                    widget.url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _imageError = true);
                      });
                      return _fallbackWidget();
                    },
                  ),
          ),
        ),
      );
    }
    // Tipo desconocido
    return _fallbackWidget();
  }

  Widget _fallbackWidget() {
    return Container(
      color: const Color(0xFF0F3460),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined,
                color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No se puede previsualizar este archivo',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                if (kIsWeb) html.window.open(widget.url, '_blank');
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Abrir en nueva pestaña'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WessexColors.deepRoyalBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
