import 'package:flutter/material.dart';
import 'package:wesrugby/data/models/asistencia_model.dart';
import 'package:wesrugby/data/services/asistencia_service.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

class EstadisticasAsistenciaScreen extends StatefulWidget {
  const EstadisticasAsistenciaScreen({super.key});

  @override
  State<EstadisticasAsistenciaScreen> createState() =>
      _EstadisticasAsistenciaScreenState();
}

class _EstadisticasAsistenciaScreenState
    extends State<EstadisticasAsistenciaScreen> {
  List<SesionEntrenamiento> _sesiones = [];
  List<String> _categorias = [];
  String? _categoriaFiltro;
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
      final categorias = await AsistenciaService.obtenerCategorias();
      // Para estadísticas, siempre queremos ver TODAS las sesiones (directiva)
      final sesiones = await AsistenciaService.obtenerHistorialSesiones(
        todasLasSesiones: true,
      );

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

  Map<String, dynamic> _calcularEstadisticasGenerales() {
    final sesionesFiltradas = _categoriaFiltro == null
        ? _sesiones
        : _sesiones.where((s) => s.categoria == _categoriaFiltro).toList();

    if (sesionesFiltradas.isEmpty) {
      return {
        'totalSesiones': 0,
        'totalPresentes': 0,
        'totalAusentes': 0,
        'totalJustificados': 0,
        'totalAlumnos': 0,
        'promedioAsistencia': 0.0,
        'categorias': <String, Map<String, dynamic>>{},
        'tendencia': <Map<String, dynamic>>[],
      };
    }

    int totalPresentes = 0;
    int totalAusentes = 0;
    int totalJustificados = 0;
    int totalRegistros = 0;
    Set<String> alumnosUnicos = {};

    // Estadísticas por categoría
    Map<String, Map<String, int>> estatsPorCategoria = {};

    // Tendencia por sesión (últimas 10)
    List<Map<String, dynamic>> tendencia = [];

    for (var sesion in sesionesFiltradas.reversed.take(10)) {
      totalPresentes += sesion.estadisticas.presentes;
      totalAusentes += sesion.estadisticas.ausentes;
      totalJustificados += sesion.estadisticas.justificados;
      totalRegistros += sesion.estadisticas.totalAlumnos;

      // Alumnos únicos
      for (var registro in sesion.registros) {
        alumnosUnicos.add(registro.rutAlumno);
      }

      // Por categoría
      if (!estatsPorCategoria.containsKey(sesion.categoria)) {
        estatsPorCategoria[sesion.categoria] = {
          'presentes': 0,
          'ausentes': 0,
          'justificados': 0,
          'total': 0,
        };
      }
      estatsPorCategoria[sesion.categoria]!['presentes'] =
          (estatsPorCategoria[sesion.categoria]!['presentes'] ?? 0) +
              sesion.estadisticas.presentes;
      estatsPorCategoria[sesion.categoria]!['ausentes'] =
          (estatsPorCategoria[sesion.categoria]!['ausentes'] ?? 0) +
              sesion.estadisticas.ausentes;
      estatsPorCategoria[sesion.categoria]!['justificados'] =
          (estatsPorCategoria[sesion.categoria]!['justificados'] ?? 0) +
              sesion.estadisticas.justificados;
      estatsPorCategoria[sesion.categoria]!['total'] =
          (estatsPorCategoria[sesion.categoria]!['total'] ?? 0) +
              sesion.estadisticas.totalAlumnos;

      // Tendencia
      tendencia.add({
        'fecha': sesion.fechaInicio,
        'porcentaje': sesion.estadisticas.porcentajeAsistencia,
        'nombre': sesion.nombre,
      });
    }

    final promedioAsistencia =
        totalRegistros > 0 ? (totalPresentes / totalRegistros) * 100 : 0.0;

    return {
      'totalSesiones': sesionesFiltradas.length,
      'totalPresentes': totalPresentes,
      'totalAusentes': totalAusentes,
      'totalJustificados': totalJustificados,
      'totalAlumnos': alumnosUnicos.length,
      'promedioAsistencia': promedioAsistencia,
      'categorias': estatsPorCategoria,
      'tendencia': tendencia.reversed.toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;
    final isTablet = screenSize.width > 600;

    final estadisticas = _calcularEstadisticasGenerales();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: WessexAppBar(
        title: 'Estadísticas de Asistencia',
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: WessexColors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: WessexBackground(
        child: SafeArea(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filtro de categoría
                      WessexCard(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filtrar por Categoría',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text('Todas'),
                                  selected: _categoriaFiltro == null,
                                  onSelected: (selected) {
                                    setState(() {
                                      _categoriaFiltro = null;
                                    });
                                  },
                                  selectedColor: WessexColors.deepRoyalBlue,
                                  labelStyle: TextStyle(
                                    color: _categoriaFiltro == null
                                        ? WessexColors.white
                                        : WessexColors.darkGrape,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                ..._categorias.map(
                                  (categoria) => ChoiceChip(
                                    label: Text(categoria),
                                    selected: _categoriaFiltro == categoria,
                                    onSelected: (selected) {
                                      setState(() {
                                        _categoriaFiltro =
                                            selected ? categoria : null;
                                      });
                                    },
                                    selectedColor: WessexColors.deepRoyalBlue,
                                    labelStyle: TextStyle(
                                      color: _categoriaFiltro == categoria
                                          ? WessexColors.white
                                          : WessexColors.darkGrape,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Resumen General
                      Text(
                        'Resumen General',
                        style: TextStyle(
                          fontSize: isDesktop ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: WessexColors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 2),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: isDesktop ? 1.5 : (isTablet ? 1.5 : 1.0),
                        children: [
                          _buildStatCard(
                            'Sesiones',
                            estadisticas['totalSesiones'].toString(),
                            Icons.event,
                            WessexColors.deepRoyalBlue,
                          ),
                          _buildStatCard(
                            'Alumnos',
                            estadisticas['totalAlumnos'].toString(),
                            Icons.people,
                            WessexColors.darkGrape,
                          ),
                          _buildStatCard(
                            'Presentes',
                            estadisticas['totalPresentes'].toString(),
                            Icons.check_circle,
                            WessexColors.leafGreen,
                          ),
                          _buildStatCard(
                            'Ausentes',
                            estadisticas['totalAusentes'].toString(),
                            Icons.cancel,
                            WessexColors.crimsonAlert,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Promedio de Asistencia
                      WessexCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Promedio de Asistencia',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: estadisticas['promedioAsistencia'] >= 80
                                      ? WessexColors.leafGreen
                                      : estadisticas['promedioAsistencia'] >= 60
                                          ? Colors.orange
                                          : WessexColors.crimsonAlert,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${estadisticas['promedioAsistencia'].toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: WessexColors.white,
                                        ),
                                      ),
                                      Text(
                                        'Asistencia',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: WessexColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Estadísticas por Categoría
                      if (estadisticas['categorias'] != null &&
                          (estadisticas['categorias'] as Map).isNotEmpty) ...[
                        Text(
                          'Por Categoría',
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(estadisticas['categorias'] as Map<String, Map<String, int>>)
                            .entries
                            .map(
                              (entry) => WessexCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: WessexColors.darkGrape,
                                          ),
                                        ),
                                        Text(
                                          '${((entry.value['presentes']! / entry.value['total']!) * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: WessexColors.leafGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildMiniStat(
                                          'Presentes',
                                          entry.value['presentes'].toString(),
                                          WessexColors.leafGreen,
                                        ),
                                        _buildMiniStat(
                                          'Ausentes',
                                          entry.value['ausentes'].toString(),
                                          WessexColors.crimsonAlert,
                                        ),
                                        _buildMiniStat(
                                          'Justificados',
                                          entry.value['justificados'].toString(),
                                          WessexColors.deepRoyalBlue,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        const SizedBox(height: 24),
                      ],

                      // Tendencia
                      if (estadisticas['tendencia'] != null &&
                          (estadisticas['tendencia'] as List).isNotEmpty) ...[
                        Text(
                          'Tendencia de Asistencia (Últimas 10 sesiones)',
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        WessexCard(
                          child: Column(
                            children: (estadisticas['tendencia'] as List)
                                .map((sesion) {
                              final fecha = sesion['fecha'] as DateTime;
                              final porcentaje = sesion['porcentaje'] as double;
                              final nombre = sesion['nombre'] as String;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        '${fecha.day}/${fecha.month}/${fecha.year}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: WessexColors.darkGrape,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nombre,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: WessexColors.darkGrape,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: porcentaje / 100,
                                              backgroundColor: Colors.grey.shade200,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                porcentaje >= 80
                                                    ? WessexColors.leafGreen
                                                    : porcentaje >= 60
                                                        ? Colors.orange
                                                        : WessexColors.crimsonAlert,
                                              ),
                                              minHeight: 8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        '${porcentaje.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: porcentaje >= 80
                                              ? WessexColors.leafGreen
                                              : porcentaje >= 60
                                                  ? Colors.orange
                                                  : WessexColors.crimsonAlert,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return WessexCard(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: WessexColors.darkGrape.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: WessexColors.darkGrape.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
