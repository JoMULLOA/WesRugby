import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/estudiante_service.dart';
import 'package:wesrugby/data/services/pagos_service.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:wesrugby/core/utils/html.dart' as html;
import 'package:wesrugby/core/utils/platform_view_registry.dart';

/// Pantalla de resumen de pagos para el apoderado.
/// Muestra el estado de pagos de los hijos del apoderado autenticado.
/// Usa el endpoint /estudiantes/mis-estudiantes que retorna datos completos.
class PagosApoderadoResumenScreen extends StatefulWidget {
  const PagosApoderadoResumenScreen({super.key});

  @override
  State<PagosApoderadoResumenScreen> createState() =>
      _PagosApoderadoResumenScreenState();
}

class _PagosApoderadoResumenScreenState
    extends State<PagosApoderadoResumenScreen> {
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

  /// Mapeo de nombre de mes (clave interna) → número con cero a la izquierda.
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

  List<Map<String, dynamic>> _misEstudiantes = [];
  bool _isLoading = true;
  String? _errorMsg;

  // Estado de expansión por RUT
  final Map<String, bool> _pagosExpandidos = {};
  final Map<String, bool> _equipamientoExpandido = {};

  // Año seleccionado por estudiante (RUT → año)
  final Map<String, int> _aniosPorEstudiante = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ─────────────── Carga de datos ───────────────

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final lista = await _estudianteService.getMisEstudiantes();
      if (mounted) {
        setState(() {
          _misEstudiantes = lista;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'No se pudo cargar la información: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ─────────────── Helpers ───────────────

  bool _esPendiente(dynamic valor) {
    final texto = valor?.toString().trim().toLowerCase() ?? '';
    if (texto.isEmpty) return true;
    if (texto.contains('no') ||
        texto.contains('pend') ||
        texto.contains('deuda')) return true;
    if (texto.contains('sin')) return true;
    return false;
  }

  bool _esPagado(dynamic valor) {
    final texto = valor?.toString().trim().toLowerCase() ?? '';
    if (texto.isEmpty) return false;
    if (texto.contains('si') ||
        texto.contains('sí') ||
        texto.contains('pag')) return true;
    if (texto.contains('al dia') || texto.contains('al día')) return true;
    return false;
  }

  String _obtenerValorMes(Map<String, dynamic> meses, String mes) {
    if (meses.containsKey(mes)) return _formatearValor(meses[mes]);
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

  String _formatearValor(dynamic valor) {
    if (valor == null) return 'Sin información';
    final texto = valor.toString().trim();
    if (texto.isEmpty) return 'Sin información';
    if (texto.toLowerCase() == 'n/a' || texto.toLowerCase() == 'null') {
      return 'Sin información';
    }
    final numero = double.tryParse(texto);
    if (numero != null) {
      return numero == numero.truncateToDouble()
          ? numero.toInt().toString()
          : texto;
    }
    return texto;
  }

  Color _colorEstado(String valor) {
    final texto = valor.toLowerCase();
    if (_esPendiente(texto)) return WessexColors.crimsonAlert;
    if (_esPagado(texto)) return WessexColors.leafGreen;
    return WessexColors.maximumGrayMint;
  }

  bool _tienePagosPendientes(Map<String, dynamic> estudiante) {
    final anioActual = DateTime.now().year;
    final pagos = (estudiante['pagos'] as Map<String, dynamic>?) ?? {};
    final pagosPorAnio =
        (estudiante['pagosPorAnio'] as Map<String, dynamic>?) ?? {};

    final pagosActuales = anioActual == 2025
        ? pagos
        : (pagosPorAnio[anioActual.toString()] as Map<String, dynamic>?) ?? {};

    final matricula = pagosActuales['matricula'];
    if (_esPendiente(matricula)) return true;

    final meses = (pagosActuales['meses'] as Map<String, dynamic>?) ?? {};
    for (final mes in _meses) {
      if (_esPendiente(_obtenerValorMes(meses, mes))) return true;
    }
    if (_esPendiente(pagosActuales['totalAnio'])) return true;
    return false;
  }

  // ─────────────── Build principal ───────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WessexColors.crestIvory,
      appBar: WessexAppBar(
        title: 'Estado de Pagos',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? _buildError()
              : _misEstudiantes.isEmpty
                  ? _buildSinHijos()
                  : _buildContenido(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: WessexCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: WessexColors.crimsonAlert),
              const SizedBox(height: 16),
              Text(
                _errorMsg ?? 'Error desconocido',
                textAlign: TextAlign.center,
                style: TextStyle(color: WessexColors.darkGrape),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.deepRoyalBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSinHijos() {
    return Center(
      child: WessexCard(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 56, color: WessexColors.maximumGrayMint),
            const SizedBox(height: 16),
            Text(
              'No se encontraron estudiantes asociados a tu cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: WessexColors.darkGrape,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    final totalHijos = _misEstudiantes.length;
    final conPendientes =
        _misEstudiantes.where(_tienePagosPendientes).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Resumen rápido ──
          _buildResumenRapido(totalHijos, conPendientes),
          const SizedBox(height: 24),

          // ── Tarjetas por estudiante ──
          ...List.generate(_misEstudiantes.length, (i) {
            return _buildTarjetaEstudiante(_misEstudiantes[i]);
          }),
        ],
      ),
    );
  }

  Widget _buildResumenRapido(int totalHijos, int conPendientes) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.people,
            label: 'Mis hijos',
            valor: '$totalHijos',
            color: WessexColors.deepRoyalBlue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.warning_amber_rounded,
            label: 'Con pagos pendientes',
            valor: '$conPendientes',
            color: conPendientes > 0
                ? WessexColors.crimsonAlert
                : WessexColors.leafGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String valor,
    required Color color,
  }) {
    return WessexCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: WessexColors.darkGrape.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── Tarjeta por estudiante ───────────────

  Widget _buildTarjetaEstudiante(Map<String, dynamic> estudiante) {
    final pagos = (estudiante['pagos'] as Map<String, dynamic>?) ?? const {};
    final equipamiento =
        (estudiante['equipamiento'] as Map<String, dynamic>?) ?? const {};

    final rutKey =
        estudiante['rut']?.toString() ?? estudiante['nombre']?.toString() ?? '';
    final pagosExpanded = _pagosExpandidos[rutKey] ?? false;
    final equipamientoExpanded = _equipamientoExpandido[rutKey] ?? false;

    final anioEstudiante =
        _aniosPorEstudiante[rutKey] ?? DateTime.now().year;
    final pagosPorAnio =
        (estudiante['pagosPorAnio'] as Map<String, dynamic>?) ?? {};
    final pagosDelAnio =
        (pagosPorAnio[anioEstudiante.toString()] as Map<String, dynamic>?) ??
            {};

    final matricula = anioEstudiante == 2025
        ? _formatearValor(pagos['matricula'])
        : _formatearValor(pagosDelAnio['matricula']);
    final mesesAMostrar = anioEstudiante == 2025
        ? (pagos['meses'] as Map<String, dynamic>?) ?? {}
        : (pagosDelAnio['meses'] as Map<String, dynamic>?) ?? {};

    final String totalAnio;
    if (anioEstudiante == 2025) {
      totalAnio = _formatearValor(pagos['totalAnio']);
    } else {
      double total = 0.0;
      bool hayDatos = false;
      final matriculaRaw = pagosDelAnio['matricula'];
      if (matriculaRaw != null) {
        final v = double.tryParse(matriculaRaw.toString());
        if (v != null && v > 0) {
          total += v;
          hayDatos = true;
        }
      }
      for (final val in mesesAMostrar.values) {
        final v = double.tryParse(val?.toString() ?? '');
        if (v != null && v > 0) {
          total += v;
          hayDatos = true;
        }
      }
      totalAnio =
          hayDatos ? total.toStringAsFixed(0) : 'Sin información';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: WessexCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera del estudiante ──
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
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _buildEtiquetaDetalle('Curso', estudiante['curso']),
                          _buildEtiquetaDetalle(
                              'Categoría', estudiante['categoria']),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Botones de expansión ──
            Row(
              children: [
                // Pagos
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() {
                      _pagosExpandidos[rutKey] = !pagosExpanded;
                    }),
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
                          Icon(Icons.payments,
                              color: WessexColors.deepRoyalBlue, size: 20),
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
                            pagosExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: WessexColors.deepRoyalBlue,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Equipamiento (solo si existe)
                if (equipamiento.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() {
                        _equipamientoExpandido[rutKey] =
                            !equipamientoExpanded;
                      }),
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
                            Icon(Icons.sports_rugby,
                                color: WessexColors.leafGreen, size: 20),
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
                              equipamientoExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: WessexColors.leafGreen,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // ── Contenido: Pagos ──
            if (pagosExpanded) ...[
              const SizedBox(height: 16),

              // Selector de año
              DropdownButtonFormField<int>(
                value: anioEstudiante,
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() => _aniosPorEstudiante[rutKey] = value);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Año',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.calendar_today,
                      color: WessexColors.deepRoyalBlue),
                ),
                items: List.generate(6, (i) => 2025 + i)
                    .map((y) =>
                        DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Chips matrícula y total
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

            // ── Contenido: Equipamiento ──
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
      children: items.entries.map((entry) {
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

  // ─────────────── Visor de vouchers ───────────────

  Future<void> _mostrarDetalleVoucher({
    required String estudianteRut,
    required String nombreEstudiante,
    required int anio,
    String? mes,
  }) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      List<Map<String, dynamic>> comprobantes = [];

      final response = await PagosService.obtenerComprobantes(
        estudianteRut: estudianteRut,
        limite: 100,
      );

      if (response.success && response.data != null) {
        final inner =
            (response.data is Map && response.data['data'] != null)
                ? response.data['data']
                : response.data;
        final raw =
            (inner is Map) ? (inner['comprobantes'] ?? inner) : inner;
        if (raw is List) {
          final todos = raw.cast<Map<String, dynamic>>();

          if (mes != null) {
            final mesNum = _mesNumero[mes];
            if (mesNum == null) {
              if (mounted) Navigator.pop(context);
              return;
            }
            final mesCode = '$anio-$mesNum';

            comprobantes = todos.where((c) {
              if ((c['mesCorrespondiente'] ?? '').toString() == mesCode) {
                return true;
              }
              final mesesArr = c['mesesCorrespondientes'];
              if (mesesArr is List && mesesArr.contains(mesCode)) return true;
              final detalles = c['detallesPago'];
              if (detalles is Map) {
                for (final detalle in detalles.values) {
                  if (detalle is Map) {
                    final mesesDetalle = detalle['meses'];
                    if (mesesDetalle is List &&
                        mesesDetalle.contains(mesCode)) {
                      return true;
                    }
                  }
                }
              }
              return false;
            }).toList();
          } else {
            // Matrícula
            comprobantes = todos.where((c) {
              final tipo =
                  (c['tipoPago'] ?? '').toString().toLowerCase();
              if (tipo != 'matricula') return false;
              final anioC = c['anioMatricula'];
              if (anioC != null) return anioC.toString() == anio.toString();
              return (c['fechaPago'] ?? '')
                  .toString()
                  .startsWith(anio.toString());
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              color:
                                  WessexColors.darkGrape.withOpacity(0.7),
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
                      separatorBuilder: (_, __) =>
                          const Divider(height: 24),
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

  Widget _buildComprobanteItem(BuildContext ctx, Map<String, dynamic> c) {
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
                  (c['metodoPago'] ?? '').toString()),
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
              nombreArchivo:
                  (c['nombreArchivoOriginal'] ?? 'voucher').toString(),
              numeroComprobante:
                  (c['numeroComprobante'] ?? '').toString(),
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
        Text(text,
            style: TextStyle(fontSize: 12, color: WessexColors.darkGrape)),
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
    _viewId = 'voucher-apoderado-${DateTime.now().millisecondsSinceEpoch}';
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF16213E),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long,
                      color: Colors.white70, size: 18),
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
                  TextButton.icon(
                    onPressed: () {
                      if (kIsWeb) html.window.open(widget.url, '_blank');
                    },
                    icon: const Icon(Icons.open_in_new,
                        size: 14, color: Colors.white54),
                    label: const Text('Nueva pestaña',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12)),
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
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_esPdf && kIsWeb) {
      return HtmlElementView(viewType: _viewId);
    }
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
