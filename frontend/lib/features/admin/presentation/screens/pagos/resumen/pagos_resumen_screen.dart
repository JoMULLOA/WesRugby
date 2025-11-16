import 'package:flutter/material.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
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
  const PagosResumenScreen({super.key});

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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: WessexAppBar(
        title: 'Resumen de Pagos',
        elevation: 2,
      ),
      body: WessexBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                ),
        ),
      ),
    );
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
      child: Column(
        children: [
          // Primera fila (5 meses)
          Row(
            children: _meses.take(5).map((mes) {
              final valor = _obtenerValorMes(meses, mes);
              final color = _colorEstado(valor);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: Container(
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
                        Text(
                          _mesTitulo(mes),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.darkGrape,
                          ),
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
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
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
                        Text(
                          _mesTitulo(mes),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.darkGrape,
                          ),
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
