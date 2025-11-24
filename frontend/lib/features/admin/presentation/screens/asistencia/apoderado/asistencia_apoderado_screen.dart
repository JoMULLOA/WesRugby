import 'package:flutter/material.dart';
import 'package:wesrugby/data/models/asistencia_model.dart';
import 'package:wesrugby/data/services/asistencia_service.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

class AsistenciaApoderadoScreen extends StatefulWidget {
  const AsistenciaApoderadoScreen({super.key});

  @override
  State<AsistenciaApoderadoScreen> createState() =>
      _AsistenciaApoderadoScreenState();
}

class _AsistenciaApoderadoScreenState extends State<AsistenciaApoderadoScreen> {
  final EstudianteService _estudianteService = EstudianteService();

  List<SesionEntrenamiento> _todasSesiones = [];
  List<Map<String, dynamic>> _hijos = [];
  String? _hijoSeleccionado; // RUT del hijo seleccionado
  bool _cargando = true;

  // Filtros
  int? _mesSeleccionado;
  int? _anioSeleccionado;

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
      // Cargar todos los hijos del apoderado
      final hijos = await _estudianteService.getMisEstudiantes();
      
      // Cargar TODAS las sesiones (necesario para ver registros de los hijos)
      final sesiones = await AsistenciaService.obtenerHistorialSesiones(
        todasLasSesiones: true,
      );

      print('📊 DEBUG Apoderado - Hijos cargados: ${hijos.length}');
      print('📊 DEBUG Apoderado - Sesiones totales: ${sesiones.length}');
      
      if (hijos.isNotEmpty) {
        print('📊 DEBUG Apoderado - RUTs hijos RAW:');
        for (var hijo in hijos) {
          final rutRaw = hijo['rut']?.toString() ?? '';
          final rutNormalizado = _normalizarRut(rutRaw);
          print('  - Nombre: ${hijo['nombre']}');
          print('    RAW: "$rutRaw" (length: ${rutRaw.length})');
          print('    NORMALIZADO: "$rutNormalizado" (length: ${rutNormalizado.length})');
        }
      }
      
      if (sesiones.isNotEmpty) {
        final totalRegistros = sesiones.fold(0, (sum, s) => sum + s.registros.length);
        print('📊 DEBUG Apoderado - Total registros en todas las sesiones: $totalRegistros');
        
        // Mostrar todos los RUTs únicos en los registros
        final rutsEnRegistros = <String>{};
        for (var sesion in sesiones) {
          for (var registro in sesion.registros) {
            rutsEnRegistros.add(registro.rutAlumno);
          }
        }
        print('📊 DEBUG Apoderado - RUTs únicos en registros (${rutsEnRegistros.length}):');
        for (var rut in rutsEnRegistros.take(10)) {
          final rutNormalizado = _normalizarRut(rut);
          print('  - RAW: "$rut" (length: ${rut.length})');
          print('    NORMALIZADO: "$rutNormalizado" (length: ${rutNormalizado.length})');
        }
        if (rutsEnRegistros.length > 10) {
          print('  ... y ${rutsEnRegistros.length - 10} más');
        }
      }

      setState(() {
        _hijos = hijos;
        _todasSesiones = sesiones;
        
        // Si solo tiene un hijo, seleccionarlo automáticamente
        if (_hijos.length == 1 && _hijos.first['rut'] != null) {
          _hijoSeleccionado = _hijos.first['rut']?.toString();
          print('✅ Hijo único seleccionado automáticamente: $_hijoSeleccionado');
        }
      });
    } catch (e) {
      print('❌ Error al cargar datos apoderado: $e');
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

  List<SesionEntrenamiento> _getSesionesFiltradas() {
    if (_hijoSeleccionado == null) {
      print('⚠️ No hay hijo seleccionado');
      return [];
    }

    // Normalizar el RUT del hijo seleccionado (quitar puntos y guión)
    final rutHijoNormalizado = _normalizarRut(_hijoSeleccionado!);
    
    print('🔍 DEBUG FILTRADO - Iniciando búsqueda');
    print('🔍 RUT buscado RAW: "$_hijoSeleccionado"');
    print('🔍 RUT buscado NORMALIZADO: "$rutHijoNormalizado"');
    print('🔍 Total de sesiones disponibles: ${_todasSesiones.length}');

    // Filtrar por hijo
    var sesionesEncontradas = 0;
    var sesiones = _todasSesiones.where((sesion) {
      print('\n🔍 Revisando sesión: ${sesion.nombre} (${sesion.registros.length} registros)');
      
      final tieneRegistro = sesion.registros.any((registro) {
        final rutRegistroNormalizado = _normalizarRut(registro.rutAlumno);
        final coincide = rutRegistroNormalizado == rutHijoNormalizado;
        
        print('  • Comparando: "${registro.rutAlumno}" -> "$rutRegistroNormalizado" | Coincide: $coincide');
        
        if (coincide) {
          sesionesEncontradas++;
          print('  ✅ ¡COINCIDENCIA! Alumno: ${registro.nombreAlumno}');
        }
        return coincide;
      });
      
      return tieneRegistro;
    }).toList();

    print('\n🎯 RESULTADO: $sesionesEncontradas sesiones encontradas para el hijo');

    // Filtrar por mes y año
    if (_mesSeleccionado != null && _anioSeleccionado != null) {
      sesiones = sesiones.where((sesion) {
        return sesion.fechaInicio.month == _mesSeleccionado && 
               sesion.fechaInicio.year == _anioSeleccionado;
      }).toList();
      print('🔍 Después de filtro mes/año: ${sesiones.length}');
    }

    return sesiones;
  }

  /// Normaliza un RUT quitando puntos, guiones y espacios, y convierte a minúsculas
  String _normalizarRut(String rut) {
    return rut.replaceAll('.', '').replaceAll('-', '').replaceAll(' ', '').toLowerCase();
  }

  Map<String, int> _calcularEstadisticas() {
    final sesiones = _getSesionesFiltradas();
    int presentes = 0;
    int ausentes = 0;
    int justificados = 0;

    final rutHijoNormalizado = _hijoSeleccionado != null ? _normalizarRut(_hijoSeleccionado!) : '';

    for (var sesion in sesiones) {
      // Buscar el registro del hijo en esta sesión
      final registro = sesion.registros.cast<RegistroAsistencia?>().firstWhere(
        (r) => r != null && _normalizarRut(r.rutAlumno) == rutHijoNormalizado,
        orElse: () => null,
      );

      if (registro != null) {
        switch (registro.estado) {
          case EstadoAsistencia.presente:
            presentes++;
            break;
          case EstadoAsistencia.ausente:
            ausentes++;
            break;
          case EstadoAsistencia.justificado:
            justificados++;
            break;
          case EstadoAsistencia.tardanza:
            presentes++; // Tardanza cuenta como presente
            break;
          case EstadoAsistencia.sinRegistrar:
            // No se cuenta en ninguna categoría
            break;
        }
      }
    }

    return {
      'presentes': presentes,
      'ausentes': ausentes,
      'justificados': justificados,
      'total': sesiones.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;
    final isTablet = screenSize.width > 600;

    final sesionesFiltradas = _getSesionesFiltradas();
    final estadisticas = _calcularEstadisticas();
    final porcentajeAsistencia = estadisticas['total']! > 0
        ? (estadisticas['presentes']! / estadisticas['total']!) * 100
        : 0.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: WessexAppBar(
        title: 'Asistencia de mis Hijos',
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: WessexColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: WessexBackground(
        child: SafeArea(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _hijos.isEmpty
                  ? _buildNoDataState()
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selector de hijo (solo si tiene más de 1)
                          if (_hijos.length > 1) ...[
                            WessexCard(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Seleccionar Hijo/a',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: WessexColors.darkGrape,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: _hijoSeleccionado,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    hint: const Text('Seleccione un alumno'),
                                    items: _hijos.map((hijo) {
                                      return DropdownMenuItem<String>(
                                        value: hijo['rut']?.toString(),
                                        child: Text(hijo['nombre']?.toString() ?? 'Sin nombre'),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _hijoSeleccionado = value;
                                        // Resetear filtros al cambiar de hijo
                                        _mesSeleccionado = null;
                                        _anioSeleccionado = null;
                                      });
                                      print('👤 Hijo seleccionado cambiado a: $value');
                                      // Forzar recalcular estadísticas
                                      final sesiones = _getSesionesFiltradas();
                                      print('📊 Sesiones encontradas para $_hijoSeleccionado: ${sesiones.length}');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Si ya tiene hijo seleccionado, mostrar contenido
                          if (_hijoSeleccionado != null) ...[
                            // Header con nombre del hijo seleccionado
                            WessexCard(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 32,
                                      color: WessexColors.deepRoyalBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _hijos.firstWhere(
                                            (h) => h['rut']?.toString() == _hijoSeleccionado,
                                            orElse: () => {'nombre': 'Alumno'},
                                          )['nombre']?.toString() ?? 'Alumno',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: WessexColors.darkGrape,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'RUT: $_hijoSeleccionado',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: WessexColors.darkGrape.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Filtros de mes y año
                            WessexCard(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filtrar por Fecha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: WessexColors.darkGrape,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          value: _mesSeleccionado,
                                          decoration: InputDecoration(
                                            labelText: 'Mes',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                          ),
                                          items: [
                                            const DropdownMenuItem(value: null, child: Text('Todos')),
                                            ...List.generate(12, (index) {
                                              final mes = index + 1;
                                              final nombres = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                                                             'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
                                              return DropdownMenuItem(
                                                value: mes,
                                                child: Text(nombres[index]),
                                              );
                                            }),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _mesSeleccionado = value;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          value: _anioSeleccionado,
                                          decoration: InputDecoration(
                                            labelText: 'Año',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                          ),
                                          items: [
                                            const DropdownMenuItem(value: null, child: Text('Todos')),
                                            ...List.generate(5, (index) {
                                              final anio = DateTime.now().year - index;
                                              return DropdownMenuItem(
                                                value: anio,
                                                child: Text(anio.toString()),
                                              );
                                            }),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _anioSeleccionado = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Resumen de asistencia
                            Text(
                              'Resumen',
                              style: TextStyle(
                                fontSize: isDesktop ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                            const SizedBox(height: 16),

                            WessexCard(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                children: [
                                  // Porcentaje grande
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: porcentajeAsistencia >= 80
                                          ? WessexColors.leafGreen
                                          : porcentajeAsistencia >= 60
                                              ? Colors.orange
                                              : WessexColors.crimsonAlert,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${porcentajeAsistencia.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: WessexColors.white,
                                            ),
                                          ),
                                          Text(
                                            'Asistencia',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: WessexColors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Estadísticas
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatColumn(
                                        'Presentes',
                                        estadisticas['presentes'].toString(),
                                        WessexColors.leafGreen,
                                      ),
                                      _buildStatColumn(
                                        'Ausentes',
                                        estadisticas['ausentes'].toString(),
                                        WessexColors.crimsonAlert,
                                      ),
                                      _buildStatColumn(
                                        'Justificados',
                                        estadisticas['justificados'].toString(),
                                        WessexColors.deepRoyalBlue,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Lista de sesiones
                            Text(
                              'Historial (${sesionesFiltradas.length} sesiones)',
                              style: TextStyle(
                                fontSize: isDesktop ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (sesionesFiltradas.isEmpty)
                              WessexCard(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 64,
                                          color: WessexColors.darkGrape.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay sesiones registradas',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: WessexColors.darkGrape,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...sesionesFiltradas.map((sesion) {
                                // Buscar el registro del hijo usando RUT normalizado
                                final rutHijoNormalizado = _normalizarRut(_hijoSeleccionado!);
                                final registro = sesion.registros.cast<RegistroAsistencia?>().firstWhere(
                                  (r) => r != null && _normalizarRut(r.rutAlumno) == rutHijoNormalizado,
                                  orElse: () => null,
                                );

                                // Si no se encuentra el registro, no debería pasar (por el filtro previo)
                                // pero manejamos el caso por seguridad
                                if (registro == null) {
                                  print('⚠️ ADVERTENCIA: Sesión ${sesion.nombre} sin registro para $_hijoSeleccionado');
                                  return const SizedBox.shrink();
                                }

                                return WessexCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
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
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${sesion.fechaInicio.day}/${sesion.fechaInicio.month}/${sesion.fechaInicio.year} • ${sesion.categoria}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: WessexColors.darkGrape.withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getEstadoColor(registro.estado).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getEstadoColor(registro.estado),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getEstadoIcon(registro.estado),
                                                  size: 16,
                                                  color: _getEstadoColor(registro.estado),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _getEstadoTexto(registro.estado),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getEstadoColor(registro.estado),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (registro.observaciones != null &&
                                          registro.observaciones!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                size: 16,
                                                color: WessexColors.deepRoyalBlue,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  registro.observaciones!,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: WessexColors.deepRoyalBlue,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                          ] else if (_hijos.length == 1)
                            // Si tiene un solo hijo pero aún no se seleccionó automáticamente
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            // Si tiene múltiples hijos y no ha seleccionado ninguno
                            WessexCard(
                              margin: const EdgeInsets.only(top: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.touch_app,
                                      size: 64,
                                      color: WessexColors.deepRoyalBlue,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Selecciona un hijo/a',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: WessexColors.darkGrape,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Usa el selector de arriba para ver la asistencia',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: WessexColors.darkGrape.withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: WessexCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: WessexColors.darkGrape.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontró información del alumno',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: WessexColors.darkGrape,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor contacte con la administración',
                style: TextStyle(
                  fontSize: 14,
                  color: WessexColors.darkGrape.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: WessexColors.darkGrape.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Color _getEstadoColor(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return WessexColors.leafGreen;
      case EstadoAsistencia.ausente:
        return WessexColors.crimsonAlert;
      case EstadoAsistencia.justificado:
        return WessexColors.deepRoyalBlue;
      case EstadoAsistencia.tardanza:
        return Colors.orange;
      case EstadoAsistencia.sinRegistrar:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return Icons.check_circle;
      case EstadoAsistencia.ausente:
        return Icons.cancel;
      case EstadoAsistencia.justificado:
        return Icons.assignment_turned_in;
      case EstadoAsistencia.tardanza:
        return Icons.schedule;
      case EstadoAsistencia.sinRegistrar:
        return Icons.help_outline;
    }
  }

  String _getEstadoTexto(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return 'Presente';
      case EstadoAsistencia.ausente:
        return 'Ausente';
      case EstadoAsistencia.justificado:
        return 'Justificado';
      case EstadoAsistencia.tardanza:
        return 'Tardanza';
      case EstadoAsistencia.sinRegistrar:
        return 'Sin Registrar';
    }
  }
}
