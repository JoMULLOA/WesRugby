import 'package:flutter/material.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/data/services/notificacion_service.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

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
    final pagos = (estudiante['pagos'] as Map<String, dynamic>?) ?? const {};
    if (_esPendiente(pagos['matricula'])) {
      return true;
    }
    final meses = (pagos['meses'] as Map<String, dynamic>?) ?? const {};
    for (final mes in _meses) {
      if (_esPendiente(_obtenerValorMes(meses, mes))) {
        return true;
      }
    }
    if (_esPendiente(pagos['totalAnio'])) {
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

  int get _totalMatriculaAlDia =>
      _estudiantesFiltrados
          .where(
            (estudiante) => _esPagado(
              ((estudiante['pagos'] ?? const {}) as Map)['matricula'],
            ),
          )
          .length;

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
  bool _enviandoNotificaciones = false;

  Widget _buildNotificacionesTab() {
    // Filtrar estudiantes deudores según selección
    List<Map<String, dynamic>> deudores = [];
    
    if (_notificacionCategoria == 'Pagos') {
      if (_notificacionSubcategoria == 'Matrícula') {
        deudores = _todosEstudiantes.where((e) {
          final pagos = (e['pagos'] as Map<String, dynamic>?) ?? {};
          return _esPendiente(pagos['matricula']);
        }).toList();
      } else {
        // Mensualidad
        deudores = _todosEstudiantes.where((e) {
          final pagos = (e['pagos'] as Map<String, dynamic>?) ?? {};
          final meses = (pagos['meses'] as Map<String, dynamic>?) ?? {};
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
                            'Debe ${_notificacionSubcategoria == 'Mensualidad' ? _mesTitulo(_notificacionMes) : 'Matrícula'}',
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
          mensaje = 'Estimado apoderado, le recordamos que tiene pendiente el pago de la Matrícula.';
          datos = {'tipoDeuda': 'matricula'};
        } else {
          mensaje = 'Estimado apoderado, le recordamos que tiene pendiente el pago de la mensualidad de ${_mesTitulo(_notificacionMes)}.';
          datos = {'tipoDeuda': 'mes', 'mes': _notificacionMes};
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
    // Lógica para mostrar solo algunas páginas (Smart Pagination)
    List<Widget> pageButtons = [];
    
    // Función helper para agregar botón
    void addButton(int page) {
      pageButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildPageButton(page, totalPages),
        ),
      );
    }
    
    // Función helper para agregar elipsis
    void addEllipsis() {
      pageButtons.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: WessexColors.deepRoyalBlue)),
        ),
      );
    }

    if (totalPages <= 5) {
      // Si son pocas páginas, mostrar todas
      for (int i = 0; i < totalPages; i++) {
        addButton(i);
      }
    } else {
      // Siempre mostrar primera página
      addButton(0);
      
      // Calcular rango alrededor de la página actual
      int start = _currentPage - 1;
      int end = _currentPage + 1;
      
      // Ajustar si está cerca del inicio
      if (start <= 1) {
        start = 1;
        end = 3;
      }
      
      // Ajustar si está cerca del final
      if (end >= totalPages - 2) {
        end = totalPages - 2;
        start = totalPages - 4;
        if (start < 1) start = 1;
      }
      
      // Agregar elipsis inicial
      if (start > 1) {
        addEllipsis();
      }
      
      // Agregar páginas del rango medio
      for (int i = start; i <= end; i++) {
        if (i < totalPages - 1) { // Evitar duplicar la última
           addButton(i);
        }
      }
      
      // Agregar elipsis final
      if (end < totalPages - 2) {
        addEllipsis();
      }
      
      // Siempre mostrar última página
      addButton(totalPages - 1);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: WessexColors.deepRoyalBlue,
          ),
          const SizedBox(width: 8),
          ...pageButtons,
          const SizedBox(width: 8),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: WessexColors.deepRoyalBlue,
          ),
        ],
      ),
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

  Widget _buildTarjetaEstudiante(Map<String, dynamic> estudiante) {
    final pagos = (estudiante['pagos'] as Map<String, dynamic>?) ?? const {};
    final pagosMeses = (pagos['meses'] as Map<String, dynamic>?) ?? const {};
    final equipamiento =
        (estudiante['equipamiento'] as Map<String, dynamic>?) ?? const {};
    final matricula = _formatearValor(pagos['matricula']);
    final totalAnio = _formatearValor(pagos['totalAnio']);
    
    // Usar RUT como clave única para el estado de expansión
    final rutKey = estudiante['rut']?.toString() ?? estudiante['nombre']?.toString() ?? '';
    final pagosExpanded = _pagosExpandidos[rutKey] ?? false;
    final equipamientoExpanded = _equipamientoExpandido[rutKey] ?? false;


    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: WessexCard(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 500;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Info + Email
                if (isSmall)
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       _buildEstudianteInfo(estudiante),
                       const SizedBox(height: 12),
                       if (estudiante['correoApoderadoGenerado'] != null &&
                           estudiante['correoApoderadoGenerado'].toString().isNotEmpty)
                         Chip(
                           avatar: const Icon(Icons.alternate_email, size: 18),
                           label: Text(estudiante['correoApoderadoGenerado']),
                           backgroundColor: WessexColors.deepRoyalBlue.withOpacity(0.1),
                         ),
                     ],
                   )
                else
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Expanded(child: _buildEstudianteInfo(estudiante)),
                       if (estudiante['correoApoderadoGenerado'] != null &&
                           estudiante['correoApoderadoGenerado'].toString().isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(left: 12),
                           child: Chip(
                             avatar: const Icon(Icons.alternate_email, size: 18),
                             label: Text(estudiante['correoApoderadoGenerado']),
                             backgroundColor: WessexColors.deepRoyalBlue.withOpacity(0.1),
                           ),
                         ),
                     ],
                   ),
                
                const SizedBox(height: 20),
                
                // Botones en horizontal o vertical
                if (isSmall)
                  Column(
                    children: [
                      _buildBotonDesplegable(
                        icon: Icons.payments,
                        label: 'Pagos',
                        color: WessexColors.deepRoyalBlue,
                        isExpanded: pagosExpanded,
                        onTap: () {
                          setState(() {
                            _pagosExpandidos[rutKey] = !pagosExpanded;
                          });
                        },
                      ),
                      if (equipamiento.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildBotonDesplegable(
                          icon: Icons.sports_rugby,
                          label: 'Equipamiento',
                          color: WessexColors.leafGreen,
                          isExpanded: equipamientoExpanded,
                          onTap: () {
                            setState(() {
                              _equipamientoExpandido[rutKey] = !equipamientoExpanded;
                            });
                          },
                        ),
                      ],
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _buildBotonDesplegable(
                          icon: Icons.payments,
                          label: 'Pagos',
                          color: WessexColors.deepRoyalBlue,
                          isExpanded: pagosExpanded,
                          onTap: () {
                            setState(() {
                              _pagosExpandidos[rutKey] = !pagosExpanded;
                            });
                          },
                        ),
                      ),
                      if (equipamiento.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildBotonDesplegable(
                            icon: Icons.sports_rugby,
                            label: 'Equipamiento',
                            color: WessexColors.leafGreen,
                            isExpanded: equipamientoExpanded,
                            onTap: () {
                              setState(() {
                                _equipamientoExpandido[rutKey] = !equipamientoExpanded;
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                
                // Contenido de Pagos (desplegable)
                if (pagosExpanded) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildPagoEstatusChip('Matrícula', matricula),
                      _buildPagoEstatusChip('Total año', totalAnio),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMesesGrid(pagosMeses),
                ],
                
                // Contenido de Equipamiento (desplegable)
                if (equipamientoExpanded) ...[
                  const SizedBox(height: 16),
                  _buildEquipamientoResumen(equipamiento),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEstudianteInfo(Map<String, dynamic> estudiante) {
    return Column(
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
    );
  }

  Widget _buildBotonDesplegable({
    required IconData icon,
    required String label,
    required Color color,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: color,
              size: 20,
            ),
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

  Widget _buildMesesGrid(Map<String, dynamic> meses) {
    return WessexCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;
          final crossAxisCount = isSmall ? 2 : 5;
          final childAspectRatio = isSmall ? 2.5 : 1.2;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _meses.length,
            itemBuilder: (context, index) {
              final mes = _meses[index];
              final valor = _obtenerValorMes(meses, mes);
              final color = _colorEstado(valor);
              
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _mesTitulo(mes),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: WessexColors.darkGrape,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valor,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: WessexColors.darkGrape,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
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
