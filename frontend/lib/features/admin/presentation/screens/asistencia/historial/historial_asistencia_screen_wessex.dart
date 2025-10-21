import 'package:flutter/material.dart';
import 'package:wesrugby/data/models/asistencia_model.dart';
import 'package:wesrugby/data/services/asistencia_service.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

class HistorialAsistenciaScreen extends StatefulWidget {
  const HistorialAsistenciaScreen({super.key});

  @override
  State<HistorialAsistenciaScreen> createState() =>
      _HistorialAsistenciaScreenState();
}

class _HistorialAsistenciaScreenState extends State<HistorialAsistenciaScreen> {
  List<SesionEntrenamiento> _sesiones = [];
  List<String> _categorias = [];
  String? _categoriaSeleccionada;
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const WessexAppBar(
        title: 'Historial de Asistencia',
        elevation: 2,
      ),
      body: WessexBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header con filtros
              Container(
                padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WessexSectionTitle(
                      title: 'Historial de Sesiones',
                      subtitle:
                          'Consultar registros de entrenamientos anteriores',
                      titleColor: WessexColors.white,
                    ),
                    const SizedBox(height: 20),

                    // Filtros
                    WessexCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filtros',
                            style: TextStyle(
                              fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                              fontWeight: FontWeight.bold,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Selector de categoría
                          DropdownButtonFormField<String>(
                            value: _categoriaSeleccionada,
                            decoration: InputDecoration(
                              labelText: 'Categoría',
                              prefixIcon: Icon(
                                Icons.category,
                                color: WessexColors.deepRoyalBlue,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: WessexColors.mistyRoseGray,
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todas las categorías'),
                              ),
                              ..._categorias.map((categoria) {
                                return DropdownMenuItem(
                                  value: categoria,
                                  child: Text(categoria),
                                );
                              }),
                            ],
                            onChanged: (valor) {
                              setState(() {
                                _categoriaSeleccionada = valor;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Botón de refrescar
                          SizedBox(
                            width: double.infinity,
                            child: WessexButton(
                              text: 'Actualizar',
                              icon: Icons.refresh,
                              backgroundColor: WessexColors.deepRoyalBlue,
                              onPressed: _cargarDatos,
                              isLoading: _cargando,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de sesiones
              Expanded(
                child:
                    _cargando
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: WessexColors.white,
                          ),
                        )
                        : _sesiones.isEmpty
                        ? _buildEmptyState(isDesktop, isTablet)
                        : _buildListaSesiones(isDesktop, isTablet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDesktop, bool isTablet) {
    return Center(
      child: WessexCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: isDesktop ? 80 : (isTablet ? 64 : 48),
              color: WessexColors.darkGrape.withOpacity(0.5),
            ),
            SizedBox(height: isDesktop ? 24 : (isTablet ? 20 : 16)),
            Text(
              'No hay sesiones registradas',
              style: TextStyle(
                fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                fontWeight: FontWeight.bold,
                color: WessexColors.darkGrape,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las sesiones de asistencia aparecerán aquí\ncuando se completen entrenamientos.',
              style: TextStyle(
                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                color: WessexColors.darkGrape.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaSesiones(bool isDesktop, bool isTablet) {
    final sesionesFiltradas = _filtrarSesiones();

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : (isTablet ? 20 : 16),
      ),
      itemCount: sesionesFiltradas.length,
      itemBuilder: (context, index) {
        final sesion = sesionesFiltradas[index];
        return _buildSesionCard(sesion, isDesktop, isTablet);
      },
    );
  }

  Widget _buildSesionCard(
    SesionEntrenamiento sesion,
    bool isDesktop,
    bool isTablet,
  ) {
    final estadisticas = sesion.estadisticas;
    final fechaFormateada = _formatearFecha(sesion.fechaInicio);

    return WessexCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _mostrarDetallesSesion(sesion),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 16 : 14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la sesión
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      isDesktop ? 12 : (isTablet ? 10 : 8),
                    ),
                    decoration: BoxDecoration(
                      color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sports_rugby,
                      color: WessexColors.deepRoyalBlue,
                      size: isDesktop ? 24 : (isTablet ? 22 : 20),
                    ),
                  ),
                  SizedBox(width: isDesktop ? 16 : (isTablet ? 14 : 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sesion.nombre,
                          style: TextStyle(
                            fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                            fontWeight: FontWeight.bold,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sesion.categoria} • $fechaFormateada',
                          style: TextStyle(
                            fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                            color: WessexColors.darkGrape.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: WessexColors.darkGrape.withOpacity(0.5),
                    size: isDesktop ? 24 : (isTablet ? 22 : 20),
                  ),
                ],
              ),

              SizedBox(height: isDesktop ? 20 : (isTablet ? 16 : 14)),

              // Estadísticas
              Row(
                children: [
                  _buildEstadisticaMini(
                    'Total',
                    estadisticas.totalAlumnos.toString(),
                    WessexColors.darkGrape,
                    isDesktop,
                    isTablet,
                  ),
                  const SizedBox(width: 16),
                  _buildEstadisticaMini(
                    'Presentes',
                    estadisticas.presentes.toString(),
                    WessexColors.leafGreen,
                    isDesktop,
                    isTablet,
                  ),
                  const SizedBox(width: 16),
                  _buildEstadisticaMini(
                    'Ausentes',
                    estadisticas.ausentes.toString(),
                    WessexColors.crimsonAlert,
                    isDesktop,
                    isTablet,
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : (isTablet ? 10 : 8),
                      vertical: isDesktop ? 6 : (isTablet ? 5 : 4),
                    ),
                    decoration: BoxDecoration(
                      color:
                          estadisticas.porcentajeAsistencia >= 80
                              ? WessexColors.leafGreen
                              : estadisticas.porcentajeAsistencia >= 60
                              ? WessexColors.crimsonAlert
                              : WessexColors.crimsonAlert,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${estadisticas.porcentajeAsistencia.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: WessexColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadisticaMini(
    String label,
    String valor,
    Color color,
    bool isDesktop,
    bool isTablet,
  ) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 12 : (isTablet ? 11 : 10),
            color: WessexColors.darkGrape.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  List<SesionEntrenamiento> _filtrarSesiones() {
    var sesionesFiltradas = _sesiones.toList();

    if (_categoriaSeleccionada != null) {
      sesionesFiltradas =
          sesionesFiltradas
              .where((sesion) => sesion.categoria == _categoriaSeleccionada)
              .toList();
    }

    // Ordenar por fecha más reciente primero
    sesionesFiltradas.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));

    return sesionesFiltradas;
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return '${fecha.day} de ${meses[fecha.month - 1]} ${fecha.year}';
  }

  void _mostrarDetallesSesion(SesionEntrenamiento sesion) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;
    final isTablet = screenSize.width > 600;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : (isTablet ? 500 : double.infinity),
                maxHeight: screenSize.height * 0.8,
              ),
              child: WessexCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header del diálogo
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Detalles de la Sesión',
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                              fontWeight: FontWeight.bold,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: WessexColors.darkGrape.withOpacity(0.7),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Información de la sesión
                    _buildInfoRow(
                      'Nombre:',
                      sesion.nombre,
                      isDesktop,
                      isTablet,
                    ),
                    _buildInfoRow(
                      'Categoría:',
                      sesion.categoria,
                      isDesktop,
                      isTablet,
                    ),
                    _buildInfoRow(
                      'Fecha:',
                      _formatearFecha(sesion.fechaInicio),
                      isDesktop,
                      isTablet,
                    ),
                    _buildInfoRow(
                      'Entrenador:',
                      sesion.entrenadorNombre,
                      isDesktop,
                      isTablet,
                    ),
                    if (sesion.descripcion != null &&
                        sesion.descripcion!.isNotEmpty)
                      _buildInfoRow(
                        'Descripción:',
                        sesion.descripcion!,
                        isDesktop,
                        isTablet,
                      ),

                    const SizedBox(height: 20),

                    // Estadísticas detalladas
                    Text(
                      'Estadísticas',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                        fontWeight: FontWeight.bold,
                        color: WessexColors.darkGrape,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: WessexColors.mistyRoseGray.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildEstadisticaDetalle(
                                'Total',
                                sesion.estadisticas.totalAlumnos.toString(),
                                WessexColors.darkGrape,
                                isDesktop,
                                isTablet,
                              ),
                              _buildEstadisticaDetalle(
                                'Presentes',
                                sesion.estadisticas.presentes.toString(),
                                WessexColors.leafGreen,
                                isDesktop,
                                isTablet,
                              ),
                              _buildEstadisticaDetalle(
                                'Ausentes',
                                sesion.estadisticas.ausentes.toString(),
                                WessexColors.crimsonAlert,
                                isDesktop,
                                isTablet,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 20 : (isTablet ? 16 : 14),
                              vertical: isDesktop ? 12 : (isTablet ? 10 : 8),
                            ),
                            decoration: BoxDecoration(
                              color: WessexColors.deepRoyalBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Asistencia: ${sesion.estadisticas.porcentajeAsistencia.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: WessexColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botón de cerrar
                    SizedBox(
                      width: double.infinity,
                      child: WessexButton(
                        text: 'Cerrar',
                        backgroundColor: WessexColors.deepRoyalBlue,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String valor,
    bool isDesktop,
    bool isTablet,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isDesktop ? 120 : (isTablet ? 100 : 80),
            child: Text(
              label,
              style: TextStyle(
                fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                fontWeight: FontWeight.w600,
                color: WessexColors.darkGrape.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                color: WessexColors.darkGrape,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaDetalle(
    String label,
    String valor,
    Color color,
    bool isDesktop,
    bool isTablet,
  ) {
    return Column(
      children: [
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
        ),
      ],
    );
  }
}
