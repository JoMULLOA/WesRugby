import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/justificante_service.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:intl/intl.dart';
import 'package:wesrugby/features/admin/presentation/screens/asistencia/tomar/tomar_asistencia_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/asistencia/historial/historial_asistencia_screen_wessex.dart';

class JustificadosActivosScreen extends StatefulWidget {
  const JustificadosActivosScreen({super.key});

  @override
  State<JustificadosActivosScreen> createState() => _JustificadosActivosScreenState();
}

class _JustificadosActivosScreenState extends State<JustificadosActivosScreen> {
  final JustificanteService _justificanteService = JustificanteService();
  final EstudianteService _estudianteService = EstudianteService();

  // Estado de carga
  bool _isLoading = false;

  // Datos
  List<Map<String, dynamic>> _todosEstudiantes = [];
  List<String> _categoriasDisponibles = [];
  Map<String, List<Map<String, dynamic>>> _justificadosPorEstudiante = {};

  // Filtros
  String? _categoriaSeleccionada;
  DateTime _fechaDesde = DateTime.now();
  DateTime _fechaHasta = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEstudiantes();
  }

  Future<void> _loadEstudiantes() async {
    try {
      setState(() => _isLoading = true);

      final estudiantes = await _estudianteService.getAllStudentsFromAPI();

      // Extraer categorías únicas
      final categoriasSet = <String>{};
      for (var estudiante in estudiantes) {
        final categoria = estudiante['categoria'];
        if (categoria != null && categoria.toString().isNotEmpty) {
          categoriasSet.add(categoria.toString());
        }
      }

      setState(() {
        _todosEstudiantes = estudiantes;
        _categoriasDisponibles = categoriasSet.toList()..sort();
        _isLoading = false;
      });

      // Cargar justificantes para hoy
      await _cargarJustificantes();
    } catch (e) {
      setState(() => _isLoading = false);
      if (kDebugMode) {
        print('Error cargando estudiantes: $e');
      }
      _showErrorSnackBar('Error al cargar datos');
    }
  }

  Future<void> _cargarJustificantes() async {
    try {
      setState(() => _isLoading = true);

      // Filtrar estudiantes por categoría si está seleccionada
      final estudiantesFiltrados = _categoriaSeleccionada == null
          ? _todosEstudiantes
          : _todosEstudiantes
              .where((e) => e['categoria'] == _categoriaSeleccionada)
              .toList();

      if (estudiantesFiltrados.isEmpty) {
        setState(() {
          _justificadosPorEstudiante = {};
          _isLoading = false;
        });
        return;
      }

      // Obtener RUTs
      final ruts = estudiantesFiltrados.map((e) => e['rut'].toString()).toList();

      // Consultar justificantes para el rango de fechas
      final justificadosMap = <String, List<Map<String, dynamic>>>{};

      // Iterar por cada día del rango
      final diasRango = _fechaHasta.difference(_fechaDesde).inDays + 1;
      for (int i = 0; i < diasRango; i++) {
        final fechaActual = _fechaDesde.add(Duration(days: i));
        final fechaISO = DateFormat('yyyy-MM-dd').format(fechaActual);

        final justificadosDia = await _justificanteService.obtenerJustificadosPorFecha(fechaISO, ruts);

        // Agregar al mapa consolidado
        justificadosDia.forEach((rut, justificantes) {
          if (!justificadosMap.containsKey(rut)) {
            justificadosMap[rut] = [];
          }
          // Evitar duplicados por ID
          for (var j in justificantes) {
            final id = j['id'];
            if (!justificadosMap[rut]!.any((existing) => existing['id'] == id)) {
              justificadosMap[rut]!.add(j);
            }
          }
        });
      }

      setState(() {
        _justificadosPorEstudiante = justificadosMap;
        _isLoading = false;
      });

      if (kDebugMode) {
        print('📋 Justificados cargados: ${justificadosMap.keys.length} estudiantes');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (kDebugMode) {
        print('Error cargando justificantes: $e');
      }
      _showErrorSnackBar('Error al cargar justificantes');
    }
  }

  List<Map<String, dynamic>> _getEstudiantesConJustificantes() {
    return _todosEstudiantes.where((estudiante) {
      final rut = estudiante['rut'].toString();
      return _justificadosPorEstudiante.containsKey(rut) &&
          _justificadosPorEstudiante[rut]!.isNotEmpty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Alumnos Justificados',
        elevation: 2,
      ),
      body: WessexBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Botones de acceso rápido
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: WessexCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TomarAsistenciaScreen(),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.how_to_reg, size: 18, color: WessexColors.deepRoyalBlue),
                                label: Text(
                                  'Tomar Asistencia',
                                  style: TextStyle(fontSize: 13, color: WessexColors.deepRoyalBlue),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: WessexColors.deepRoyalBlue),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HistorialAsistenciaScreen(),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.history, size: 18, color: WessexColors.primaryAction),
                                label: Text(
                                  'Ver Historial',
                                  style: TextStyle(fontSize: 13, color: WessexColors.primaryAction),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: WessexColors.primaryAction),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Filtros
                    _buildFiltros(),
                    const SizedBox(height: 16),
                    // Lista de justificados
                    Expanded(child: _buildListaJustificados()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WessexColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WessexColors.deepRoyalBlue,
            ),
          ),
          const SizedBox(height: 16),
          
          // Filtro de categoría
          DropdownButtonFormField<String>(
            value: _categoriaSeleccionada,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Todas las categorías'),
              ),
              ..._categoriasDisponibles.map((categoria) {
                return DropdownMenuItem<String>(
                  value: categoria,
                  child: Text(categoria),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _categoriaSeleccionada = value;
              });
              _cargarJustificantes();
            },
          ),
          const SizedBox(height: 12),

          // Rango de fechas
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: _fechaDesde,
                      firstDate: DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (fecha != null) {
                      setState(() {
                        _fechaDesde = fecha;
                        if (_fechaDesde.isAfter(_fechaHasta)) {
                          _fechaHasta = _fechaDesde;
                        }
                      });
                      _cargarJustificantes();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Desde',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd/MM/yyyy').format(_fechaDesde)),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: _fechaHasta,
                      firstDate: _fechaDesde,
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (fecha != null) {
                      setState(() => _fechaHasta = fecha);
                      _cargarJustificantes();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Hasta',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd/MM/yyyy').format(_fechaHasta)),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaJustificados() {
    final estudiantesJustificados = _getEstudiantesConJustificantes();

    if (estudiantesJustificados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay estudiantes justificados en este período',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: estudiantesJustificados.length,
      itemBuilder: (context, index) {
        final estudiante = estudiantesJustificados[index];
        final rut = estudiante['rut'].toString();
        final justificantes = _justificadosPorEstudiante[rut] ?? [];

        return _buildEstudianteCard(estudiante, justificantes);
      },
    );
  }

  Widget _buildEstudianteCard(
    Map<String, dynamic> estudiante,
    List<Map<String, dynamic>> justificantes,
  ) {
    final nombre = estudiante['nombre']?.toString() ?? 'Sin nombre';
    final categoria = estudiante['categoria']?.toString() ?? 'Sin categoría';
    final rut = estudiante['rut']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: WessexColors.deepRoyalBlue.withOpacity(0.1),
          child: const Icon(Icons.person, color: WessexColors.deepRoyalBlue),
        ),
        title: Text(
          nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: WessexColors.leafGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    categoria,
                    style: const TextStyle(
                      fontSize: 12,
                      color: WessexColors.leafGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rut,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${justificantes.length} justificante${justificantes.length != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          ...justificantes.map((justificante) => _buildJustificanteItem(justificante)),
        ],
      ),
    );
  }

  Widget _buildJustificanteItem(Map<String, dynamic> justificante) {
    final tipo = justificante['tipo']?.toString() ?? 'Sin tipo';
    final motivo = justificante['motivo']?.toString() ?? 'Sin motivo';
    final fechaInicio = justificante['fechaInicio']?.toString() ?? '';
    final fechaFin = justificante['fechaFin']?.toString() ?? '';

    final inicioFormatted = fechaInicio.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaInicio))
        : '-';
    final finFormatted = fechaFin.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaFin))
        : inicioFormatted;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTipoColor(tipo).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tipo,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getTipoColor(tipo),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.event_available,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '$inicioFormatted - $finFormatted',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Motivo:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            motivo,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'enfermedad':
      case 'certificado médico':
        return WessexColors.crimsonAlert;
      case 'viaje':
        return WessexColors.accentAction; // Azul cielo para viaje
      case 'familiar':
        return WessexColors.deepRoyalBlue;
      case 'otro':
      default:
        return Colors.grey;
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WessexColors.crimsonAlert,
      ),
    );
  }
}
