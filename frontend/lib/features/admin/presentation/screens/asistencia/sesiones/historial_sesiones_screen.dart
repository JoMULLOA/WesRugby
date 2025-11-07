import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/asistencia_service.dart';

class HistorialSesionesScreen extends StatefulWidget {
  const HistorialSesionesScreen({super.key});

  @override
  State<HistorialSesionesScreen> createState() =>
      _HistorialSesionesScreenState();
}

class _HistorialSesionesScreenState extends State<HistorialSesionesScreen> {
  final AsistenciaService _asistenciaService = AsistenciaService();

  // Estado de carga
  bool _isLoadingSesiones = true;

  // Datos
  List<Map<String, dynamic>> _sesiones = [];
  Map<int, Map<String, dynamic>> _detallesSesiones = {};

  // Filtros
  String? _cursoFiltro;
  List<String> _cursosDisponibles = [];

  @override
  void initState() {
    super.initState();
    _loadSesiones();
  }

  Future<void> _loadSesiones() async {
    try {
      setState(() {
        _isLoadingSesiones = true;
      });

      final sesiones = await _asistenciaService.getMisSesiones();

      // Extraer cursos únicos para filtros
      final cursosSet = <String>{};
      for (var sesion in sesiones) {
        if (sesion['curso'] != null) {
          cursosSet.add(sesion['curso'].toString());
        }
      }

      setState(() {
        _sesiones = sesiones;
        _cursosDisponibles = cursosSet.toList()..sort();
        _isLoadingSesiones = false;
      });

      if (kDebugMode) {
        print('📋 Sesiones cargadas: ${sesiones.length}');
      }
    } catch (e) {
      setState(() {
        _isLoadingSesiones = false;
      });
      if (kDebugMode) {
        print('Error al cargar sesiones: $e');
      }
      _showErrorSnackBar('Error al cargar las sesiones');
    }
  }

  Future<void> _loadDetalleSesion(int sesionId) async {
    if (_detallesSesiones.containsKey(sesionId)) {
      return; // Ya está cargado
    }

    try {
      final detalle = await _asistenciaService.getDetalleSesion(sesionId);
      setState(() {
        _detallesSesiones[sesionId] = detalle;
      });

      if (kDebugMode) {
        print('📊 Detalles cargados para sesión $sesionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar detalle de sesión $sesionId: $e');
      }
      _showErrorSnackBar('Error al cargar detalles de la sesión');
    }
  }

  List<Map<String, dynamic>> _getSesionesFiltradas() {
    if (_cursoFiltro == null) return _sesiones;

    return _sesiones
        .where((sesion) => sesion['curso'] == _cursoFiltro)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(title: 'Historial de Sesiones', elevation: 2),
      body: WessexBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header informativo
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.history,
                          color: WessexColors.deepRoyalBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Historial de Asistencias',
                              style: TextStyle(
                                color: WessexColors.darkGrape,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Consulta las sesiones de asistencia registradas',
                              style: TextStyle(
                                color: WessexColors.darkGrape.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Filtros
                WessexCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtros',
                        style: TextStyle(
                          color: WessexColors.darkGrape,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _cursoFiltro,
                              decoration: InputDecoration(
                                labelText: 'Categoría',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.class_,
                                  color: WessexColors.crimsonAlert,
                                ),
                              ),
                              isExpanded: true,
                              hint: const Text('Todos las categorías'),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Todos las categorías'),
                                ),
                                ..._cursosDisponibles
                                    .map(
                                      (curso) => DropdownMenuItem<String>(
                                        value: curso,
                                        child: Text(curso),
                                      ),
                                    )
                                    .toList(),
                              ],
                              onChanged:
                                  (value) =>
                                      setState(() => _cursoFiltro = value),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _loadSesiones,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WessexColors.leafGreen,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            icon: Icon(
                              Icons.refresh,
                              color: WessexColors.white,
                              size: 20,
                            ),
                            label: Text(
                              'Actualizar',
                              style: TextStyle(color: WessexColors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Estadísticas rápidas
                if (!_isLoadingSesiones) ...[
                  WessexCard(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Sesiones',
                            '${_getSesionesFiltradas().length}',
                            Icons.assignment,
                            WessexColors.deepRoyalBlue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Categorías Activas',
                            '${_cursosDisponibles.length}',
                            Icons.school,
                            WessexColors.leafGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Lista de sesiones
                if (_isLoadingSesiones)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: WessexColors.deepRoyalBlue,
                      ),
                    ),
                  )
                else if (_getSesionesFiltradas().isEmpty)
                  WessexCard(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: WessexColors.darkGrape.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay sesiones registradas',
                            style: TextStyle(
                              color: WessexColors.darkGrape.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _cursoFiltro != null
                                ? 'No hay sesiones para la categoría $_cursoFiltro'
                                : 'Toma tu primera asistencia para verla aquí',
                            style: TextStyle(
                              color: WessexColors.darkGrape.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._getSesionesFiltradas()
                      .map((sesion) => _buildSesionCard(sesion))
                      .toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: WessexColors.darkGrape.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSesionCard(Map<String, dynamic> sesion) {
    final sesionId = sesion['id'] as int;
    final detalle = _detallesSesiones[sesionId];

    return WessexCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sesión
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sesion['nombre'] ?? 'Sesión sin nombre',
                      style: TextStyle(
                        color: WessexColors.darkGrape,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: WessexColors.deepRoyalBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatearFecha(sesion['fecha']),
                          style: TextStyle(
                            color: WessexColors.deepRoyalBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.class_,
                          size: 16,
                          color: WessexColors.leafGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sesion['curso'] ?? 'Sin curso',
                          style: TextStyle(
                            color: WessexColors.leafGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (detalle == null) {
                    _loadDetalleSesion(sesionId);
                  } else {
                    setState(() {
                      _detallesSesiones.remove(sesionId);
                    });
                  }
                },
                icon: Icon(
                  detalle == null ? Icons.expand_more : Icons.expand_less,
                  color: WessexColors.darkGrape,
                ),
              ),
            ],
          ),

          // Descripción si existe
          if (sesion['descripcion'] != null &&
              sesion['descripcion'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              sesion['descripcion'],
              style: TextStyle(
                color: WessexColors.darkGrape.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],

          // Detalles expandibles
          if (detalle != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetalleAsistencia(detalle),
          ],
        ],
      ),
    );
  }

  Widget _buildDetalleAsistencia(Map<String, dynamic> detalle) {
    final registros = detalle['registros'] as List<dynamic>? ?? [];

    // Calcular estadísticas
    int presentes = registros.where((r) => r['estado'] == 'presente').length;
    int ausentes = registros.where((r) => r['estado'] == 'ausente').length;
    int justificados =
        registros.where((r) => r['estado'] == 'justificado').length;
    int total = registros.length;

    double porcentajeAsistencia = total > 0 ? (presentes / total) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estadísticas
        Row(
          children: [
            Expanded(
              child: _buildMiniStat(
                'Presentes',
                presentes.toString(),
                WessexColors.leafGreen,
              ),
            ),
            Expanded(
              child: _buildMiniStat(
                'Ausentes',
                ausentes.toString(),
                WessexColors.crimsonAlert,
              ),
            ),
            Expanded(
              child: _buildMiniStat(
                'Justificados',
                justificados.toString(),
                WessexColors.deepRoyalBlue,
              ),
            ),
            Expanded(
              child: _buildMiniStat(
                '% Asistencia',
                '${porcentajeAsistencia.toStringAsFixed(1)}%',
                WessexColors.darkGrape,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Lista de estudiantes
        Text(
          'Estudiantes (${registros.length})',
          style: TextStyle(
            color: WessexColors.darkGrape,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ...registros.map<Widget>((registro) {
          final estado = registro['estado'] as String;
          final color = _getColorByEstado(estado);
          final icon = _getIconByEstado(estado);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(width: 4, color: color)),
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    registro['nombreEstudiante'] ??
                        'Estudiante ${registro['rutEstudiante']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  _getLabelByEstado(estado),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: WessexColors.darkGrape.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatearFecha(dynamic fecha) {
    try {
      DateTime dt;
      if (fecha is String) {
        dt = DateTime.parse(fecha);
      } else if (fecha is DateTime) {
        dt = fecha;
      } else {
        return 'Fecha inválida';
      }

      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  Color _getColorByEstado(String estado) {
    switch (estado) {
      case 'presente':
        return WessexColors.leafGreen;
      case 'ausente':
        return WessexColors.crimsonAlert;
      case 'justificado':
        return WessexColors.deepRoyalBlue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconByEstado(String estado) {
    switch (estado) {
      case 'presente':
        return Icons.check_circle;
      case 'ausente':
        return Icons.cancel;
      case 'justificado':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  String _getLabelByEstado(String estado) {
    switch (estado) {
      case 'presente':
        return 'Presente';
      case 'ausente':
        return 'Ausente';
      case 'justificado':
        return 'Justificado';
      default:
        return 'Desconocido';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WessexColors.crimsonAlert,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
