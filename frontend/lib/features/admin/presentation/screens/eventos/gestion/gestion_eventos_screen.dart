import 'package:universal_html/html.dart' as html;

import 'package:flutter/material.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/features/admin/presentation/screens/eventos/tipos/admin_tipos_evento_screen.dart';
import 'package:wesrugby/features/admin/presentation/screens/eventos/gestion/widgets/event_multimedia_dialog.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
// Versión 2.0 - Con gestión de categorías mejorada

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

class GestionEventosScreen extends StatefulWidget {
  @override
  _GestionEventosScreenState createState() => _GestionEventosScreenState();
}

class _GestionEventosScreenState extends State<GestionEventosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _eventos = [];
  bool _isLoading = false;
  List<String> _categorias = ['M6', 'M8', 'M10', 'M12'];

  // Variables para filtros
  final TextEditingController _filtroNombreController = TextEditingController();
  DateTime? _filtroFechaInicio;
  DateTime? _filtroFechaFin;

  // Función para convertir hora UTC a hora de Chile (UTC-3)
  String _convertirUTCaChile(String horaUTC) {
    if (horaUTC.isEmpty) return horaUTC;

    try {
      // Parsear la hora en formato HH:mm
      final partes = horaUTC.split(':');
      if (partes.length != 2) return horaUTC;

      int horas = int.parse(partes[0]);
      int minutos = int.parse(partes[1]);

      // Restar 3 horas para convertir de UTC a Chile (UTC-3)
      horas -= 3;

      // Manejar el caso donde las horas se vuelven negativas
      if (horas < 0) {
        horas += 24;
      }

      // Formatear de vuelta a HH:mm
      return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
    } catch (e) {
      // Si hay error en el parseo, devolver la hora original
      return horaUTC;
    }
  }

  // Función para convertir DateTime UTC a hora local de Chile (UTC-3)
  DateTime _convertirFechaUTCaChile(DateTime fechaUTC) {
    // Restar 3 horas para convertir de UTC a Chile (UTC-3)
    return fechaUTC.toLocal();
  }


  DateTime? _parseFechaLocal(dynamic rawDate) {
    if (rawDate == null) return null;
    try {
      final parsedDate =
          rawDate is DateTime ? rawDate : DateTime.parse(rawDate.toString());
      return parsedDate.toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatearFechaCorta(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  String _generarNombreArchivoCsv(String titulo) {
    final normalized = titulo
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '${normalized.isEmpty ? 'participaciones' : normalized}_$stamp.csv';
  }

  Future<void> _descargarParticipacionesCsvArchivo({
    required dynamic eventoId,
    required String titulo,
    List<String>? categorias,
  }) async {
    final bytes = await ApiService.descargarParticipacionesCsv(
      eventoId,
      categorias: categorias,
    );
    final fileName = _generarNombreArchivoCsv(titulo);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarEventos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filtroNombreController.dispose();
    super.dispose();
  }

  Future<void> _cargarEventos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.obtenerEventosDeportivos();
      print('DEBUG: Respuesta completa del backend: $response'); // Debug
      setState(() {
        // El backend ahora devuelve directamente la lista de eventos
        final data = response['data'];
        print('DEBUG: Tipo de data: ${data.runtimeType}'); // Debug
        print('DEBUG: Data recibida: $data'); // Debug

        _eventos = data is List ? List<dynamic>.from(data) : [];
        print('DEBUG: Total eventos cargados: ${_eventos.length}'); // Debug
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error completo al cargar eventos: $e'); // Debug
      print('DEBUG: Tipo de error: ${e.runtimeType}'); // Debug
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar eventos: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  void _mostrarParticipaciones(Map<String, dynamic> evento) async {
    try {
      final response = await ApiService.obtenerParticipacionesEvento(
        evento['id'],
      );
      final datos = response['data'] as Map<String, dynamic>;
      final List<dynamic> estadisticasIniciales = List<dynamic>.from(
        datos['estadisticasPorRama'] ?? [],
      );
      final List<dynamic> resumenInicial = List<dynamic>.from(
        datos['resumenCategorias'] ?? [],
      );
      final List<String> categoriasDisponibles = List<String>.from(
        (datos['categoriasDisponibles'] as List<dynamic>? ?? []).map(
          (categoria) => categoria.toString(),
        ),
      )..sort(_ordenarCategoriasAlfanumericamente);
      final int totalGeneralInicial = datos['totalGeneral'] ?? 0;
      final int totalRamasInicial =
          datos['totalRamas'] ?? estadisticasIniciales.length;

      showDialog(
        context: context,
        builder: (dialogContext) {
          bool isFiltering = false;
          bool isExportingCsv = false;
          List<dynamic> estadisticasVisibles = List<dynamic>.from(
            estadisticasIniciales,
          );
          List<dynamic> resumenVisible = List<dynamic>.from(resumenInicial);
          int totalVisible = totalGeneralInicial;
          int ramasVisibles = totalRamasInicial;
          Set<String> categoriasSeleccionadas =
              categoriasDisponibles.isEmpty
                  ? <String>{}
                  : categoriasDisponibles.toSet();

          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> aplicarFiltro(Set<String> nuevasCategorias) async {
                setDialogState(() {
                  isFiltering = true;
                });

                try {
                  final filtroResponse =
                      await ApiService.obtenerParticipacionesEvento(
                        evento['id'],
                        categorias:
                            (nuevasCategorias.isEmpty ||
                                    nuevasCategorias.length ==
                                        categoriasDisponibles.length)
                                ? null
                                : nuevasCategorias.toList(),
                      );
                  final filtroDatos =
                      filtroResponse['data'] as Map<String, dynamic>;

                  setDialogState(() {
                    categoriasSeleccionadas =
                        nuevasCategorias.isEmpty
                            ? categoriasDisponibles.toSet()
                            : nuevasCategorias;
                    estadisticasVisibles = List<dynamic>.from(
                      filtroDatos['estadisticasPorRama'] ?? [],
                    );
                    resumenVisible = List<dynamic>.from(
                      filtroDatos['resumenCategorias'] ?? [],
                    );
                    totalVisible = filtroDatos['totalGeneral'] ?? 0;
                    ramasVisibles =
                        filtroDatos['totalRamas'] ??
                        estadisticasVisibles.length;
                    isFiltering = false;
                  });
                } catch (error) {
                  setDialogState(() {
                    isFiltering = false;
                  });

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Error al filtrar participaciones: $error'),
                      backgroundColor: WessexColors.crimsonAlert,
                    ),
                  );
                }
              }

              Future<void> descargarCsv() async {
                if (isExportingCsv) return;
                setDialogState(() {
                  isExportingCsv = true;
                });

                try {
                  final categoriasParaCsv =
                      categoriasDisponibles.isEmpty ||
                              categoriasSeleccionadas.length ==
                                  categoriasDisponibles.length
                          ? null
                          : categoriasSeleccionadas.toList();

                  await _descargarParticipacionesCsvArchivo(
                    eventoId: evento['id'],
                    titulo: evento['titulo'] ?? evento['nombre'] ?? 'evento',
                    categorias: categoriasParaCsv,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('CSV de participaciones generado'),
                      ),
                    );
                  }
                } catch (error) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Error al descargar CSV: $error'),
                      backgroundColor: WessexColors.crimsonAlert,
                    ),
                  );
                } finally {
                  setDialogState(() {
                    isExportingCsv = false;
                  });
                }
              }

              final bool todasSeleccionadas =
                  categoriasSeleccionadas.length ==
                  categoriasDisponibles.length;

              final List<Widget> chips = <Widget>[];

              if (categoriasDisponibles.isNotEmpty) {
                chips.add(
                  FilterChip(
                    label: const Text('Todas'),
                    selected: todasSeleccionadas,
                    onSelected: (_) {
                      aplicarFiltro(categoriasDisponibles.toSet());
                    },
                    selectedColor: WessexColors.darkGrape.withOpacity(0.2),
                    checkmarkColor: WessexColors.darkGrape,
                  ),
                );

                chips.addAll(
                  (categoriasDisponibles..sort(_ordenarCategoriasAlfanumericamente)).map((categoria) {
                    final bool estaSeleccionada = categoriasSeleccionadas
                        .contains(categoria);
                    return FilterChip(
                      label: Text(categoria.toUpperCase()),
                      selected: estaSeleccionada,
                      onSelected: (selected) {
                        final updated = Set<String>.from(
                          categoriasSeleccionadas,
                        );
                        if (selected) {
                          updated.add(categoria);
                        } else {
                          updated.remove(categoria);
                        }

                        if (updated.isEmpty) {
                          updated.addAll(categoriasDisponibles);
                        }

                        aplicarFiltro(updated);
                      },
                      selectedColor: WessexColors.leafGreen.withOpacity(0.2),
                      checkmarkColor: WessexColors.leafGreen,
                    );
                  }),
                );
              }

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 800,
                  height: 600,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Participaciones - ${evento['titulo'] ?? evento['nombre'] ?? 'Evento sin título'}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: WessexColors.leafGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: WessexColors.leafGreen,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.group,
                              color: WessexColors.leafGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total: $totalVisible niños participantes',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.leafGreen,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$ramasVisibles ramas deportivas',
                              style: const TextStyle(
                                fontSize: 14,
                                color: WessexColors.darkGrape,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: descargarCsv,
                              icon: isExportingCsv
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          WessexColors.deepRoyalBlue,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.table_view,
                                      color: WessexColors.deepRoyalBlue,
                                    ),
                              label: Text(
                                isExportingCsv
                                    ? 'Generando...'
                                    : 'Descargar CSV',
                                style: const TextStyle(
                                  color: WessexColors.deepRoyalBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (categoriasDisponibles.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: WessexColors.darkGrape.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: WessexColors.darkGrape.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Filtrar por categorías:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: WessexColors.darkGrape,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(spacing: 6, runSpacing: 4, children: chips),
                              if (isFiltering)
                                const Padding(
                                  padding: EdgeInsets.only(top: 12.0),
                                  child: LinearProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                      if (resumenVisible.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                resumenVisible.map((item) {
                                  final categoria =
                                      item['categoria']?.toString() ?? 'N/A';
                                  final total = item['totalNinos'] ?? 0;
                                  final ramas = item['ramasParticipantes'] ?? 0;
                                  return Chip(
                                    avatar: CircleAvatar(
                                      backgroundColor:
                                          WessexColors.deepRoyalBlue,
                                      child: Text(
                                        categoria.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    label: Text(
                                      '$categoria · $total niños · $ramas ramas',
                                      style: const TextStyle(
                                        color: WessexColors.darkGrape,
                                      ),
                                    ),
                                    backgroundColor: WessexColors
                                        .maximumGrayMint
                                        .withOpacity(0.4),
                                  );
                                }).toList(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            estadisticasVisibles.isEmpty
                                ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: WessexColors.darkGrape,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No hay participaciones registradas',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: WessexColors.darkGrape,
                                      ),
                                    ),
                                  ],
                                )
                                : ListView.builder(
                                  itemCount: estadisticasVisibles.length,
                                  itemBuilder:
                                      (context, index) => _buildRamaCard(
                                        estadisticasVisibles[index]
                                            as Map<String, dynamic>,
                                      ),
                                ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WessexColors.darkGrape,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar participaciones: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  void _mostrarMultimediaEvento(Map<String, dynamic> evento) {
    final String eventoId = evento['id']?.toString() ?? '';
    if (eventoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar el evento para multimedia.'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
      return;
    }

    final titulo = evento['titulo'] ?? evento['nombre'] ?? 'Evento';

    showDialog(
      context: context,
      builder:
          (_) => EventMultimediaDialog(
            eventoId: eventoId,
            tituloEvento: titulo,
            scaffoldContext: context,
            isDirectiva: true,
            canUploadPrivate: true,
            canUploadShared: true,
          ),
    );
  }

  Widget _buildRamaCard(Map<String, dynamic> ramaData) {
    final nombreRama = ramaData['nombreRama'] ?? 'Rama sin nombre';
    final totalRama = ramaData['totalRama'] ?? 0;
    final totalPorCategoria =
        ramaData['totalPorCategoria'] as Map<String, dynamic>;
    final participaciones = ramaData['participaciones'] as List;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: WessexColors.darkGrape,
          child: Text(
            nombreRama.substring(0, 1).toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          nombreRama,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: WessexColors.darkGrape,
          ),
        ),
        subtitle: Text(
          'Total: $totalRama niños en ${totalPorCategoria.length} categorías',
          style: TextStyle(fontSize: 14, color: WessexColors.midnightNavy),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribución por categorías:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: WessexColors.darkGrape,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      totalPorCategoria.entries
                          .map(
                            (entry) => Chip(
                              label: Text(
                                '${entry.key.toString().toUpperCase()}: ${entry.value}',
                                style: TextStyle(fontSize: 12),
                              ),
                              backgroundColor: WessexColors.leafGreen
                                  .withOpacity(0.2),
                              side: BorderSide(
                                color: WessexColors.leafGreen,
                                width: 1,
                              ),
                            ),
                          )
                          .toList(),
                ),
                SizedBox(height: 12),

                Text(
                  'Detalle de participaciones:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: WessexColors.darkGrape,
                  ),
                ),
                SizedBox(height: 8),
                ...participaciones
                    .map(
                      (participacion) => Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WessexColors.lightGray.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: WessexColors.darkGrape.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  participacion['categoria']
                                      .toString()
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: WessexColors.darkGrape,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '${participacion['cantidadNinos']} niños',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: WessexColors.leafGreen,
                                  ),
                                ),
                              ],
                            ),
                            if (participacion['listaInvitados'] != null &&
                                participacion['listaInvitados']
                                    .toString()
                                    .isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                'Invitados: ${participacion['listaInvitados']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: WessexColors.midnightNavy.withOpacity(
                                    0.8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Función para editar un evento
  void _editarEvento(Map<String, dynamic> evento) {
    print(
      'DEBUG: Función _editarEvento llamada para evento: ${evento['titulo'] ?? evento['nombre']}',
    );
    final _tituloController = TextEditingController(
      text: evento['titulo'] ?? evento['nombre'] ?? '',
    );
    final _descripcionController = TextEditingController(
      text: evento['descripcion'] ?? '',
    );
    final _lugarController = TextEditingController(text: evento['lugar'] ?? '');
    DateTime? _fechaSeleccionada = _parseFechaLocal(evento['fechaInicio']);
    TimeOfDay? _horaSeleccionada =
        _fechaSeleccionada != null ? TimeOfDay.fromDateTime(_fechaSeleccionada) : null;

    if (_fechaSeleccionada == null) {
      _fechaSeleccionada = DateTime.now();
      _horaSeleccionada = TimeOfDay.now();
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 600,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    padding: EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Editar Evento',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: WessexColors.darkGrape,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Título
                          Text(
                            'Título del evento *',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _tituloController,
                            decoration: InputDecoration(
                              hintText: 'Ej: Partido vs Club XYZ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Descripción
                          Text(
                            'Descripción',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _descripcionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Descripción del evento',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Lugar
                          Text(
                            'Lugar *',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: WessexColors.darkGrape,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _lugarController,
                            decoration: InputDecoration(
                              hintText: 'Ej: Cancha Principal',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Fecha y Hora
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: WessexColors.darkGrape,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final fecha = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _fechaSeleccionada ??
                                              DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(
                                            Duration(days: 365),
                                          ),
                                        );
                                        if (fecha != null) {
                                          setDialogState(() {
                                            _fechaSeleccionada = fecha;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              color: WessexColors.darkGrape,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              _fechaSeleccionada != null
                                                  ? '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}'
                                                  : 'Seleccionar fecha',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hora *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: WessexColors.darkGrape,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final hora = await showTimePicker(
                                          context: context,
                                          initialTime:
                                              _horaSeleccionada ??
                                              TimeOfDay.now(),
                                        );
                                        if (hora != null) {
                                          setDialogState(() {
                                            _horaSeleccionada = hora;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              color: WessexColors.darkGrape,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              _horaSeleccionada != null
                                                  ? '${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaSeleccionada!.minute.toString().padLeft(2, '0')}'
                                                  : 'Seleccionar hora',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),

                          // Botones
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: WessexColors.darkGrape,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  await _guardarEdicionEvento(
                                    evento,
                                    _tituloController.text,
                                    _descripcionController.text,
                                    _lugarController.text,
                                    _fechaSeleccionada,
                                    _horaSeleccionada,
                                  );
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WessexColors.leafGreen,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Guardar Cambios'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  // Función para guardar la edición de un evento
  Future<void> _guardarEdicionEvento(
    Map<String, dynamic> evento,
    String titulo,
    String descripcion,
    String lugar,
    DateTime? fecha,
    TimeOfDay? hora,
  ) async {
    if (titulo.isEmpty || lugar.isEmpty || fecha == null || hora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, completa todos los campos obligatorios'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
      return;
    }

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  WessexColors.leafGreen,
                ),
              ),
            ),
      );

      // Construir fecha completa
      final fechaCompleta = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );

      // Determinar si es evento deportivo o regular
      final eventoId = evento['id'];
      bool esEventoDeportivo = eventoId is String && eventoId.contains('-');

      if (esEventoDeportivo) {
        // Actualizar evento deportivo
        await ApiService.actualizarEventoDeportivo(eventoId, {
          'titulo': titulo,
          'descripcion': descripcion,
          'lugar': lugar,
          'fechaInicio': fechaCompleta.toIso8601String(),
        });
      } else {
        // Actualizar evento regular
        await ApiService.actualizarEvento(int.parse(eventoId.toString()), {
          'nombre': titulo,
          'descripcion': descripcion,
          'fecha': fechaCompleta.toIso8601String(),
        });
      }

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evento actualizado exitosamente'),
          backgroundColor: WessexColors.leafGreen,
        ),
      );

      // Recargar eventos
      await _cargarEventos();
    } catch (e) {
      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar evento: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  // Función para eliminar un evento
  void _eliminarEvento(Map<String, dynamic> evento) {
    print(
      'DEBUG: Función _eliminarEvento llamada para evento: ${evento['titulo'] ?? evento['nombre']}',
    );
    final fechaEventoLocal = _parseFechaLocal(evento['fechaInicio']);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Eliminar Evento',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: WessexColors.crimsonAlert,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estás seguro de que deseas eliminar este evento?',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WessexColors.crimsonAlert.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: WessexColors.crimsonAlert.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evento['titulo'] ?? evento['nombre'] ?? 'Sin título',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                        ),
                      ),
                      if (fechaEventoLocal != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Fecha: ${_formatearFechaCorta(fechaEventoLocal)}',
                          style: TextStyle(color: WessexColors.midnightNavy),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Esta acción no se puede deshacer.',
                  style: TextStyle(
                    fontSize: 14,
                    color: WessexColors.crimsonAlert,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: WessexColors.darkGrape),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _confirmarEliminacion(evento);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WessexColors.crimsonAlert,
                  foregroundColor: Colors.white,
                ),
                child: Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  // Función para confirmar y ejecutar la eliminación
  Future<void> _confirmarEliminacion(Map<String, dynamic> evento) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  WessexColors.leafGreen,
                ),
              ),
            ),
      );

      // Determinar si es evento deportivo o regular basado en el ID
      final eventoId = evento['id'];
      bool esEventoDeportivo = eventoId is String && eventoId.contains('-');

      if (esEventoDeportivo) {
        // Es un evento deportivo (UUID)
        await ApiService.eliminarEventoDeportivo(eventoId);
      } else {
        // Es un evento regular (int)
        await ApiService.eliminarEvento(int.parse(eventoId.toString()));
      }

      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evento eliminado exitosamente'),
          backgroundColor: WessexColors.leafGreen,
        ),
      );

      // Recargar eventos
      await _cargarEventos();
    } catch (e) {
      // Cerrar indicador de carga
      Navigator.pop(context);

      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar evento: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    }
  }

  // Función para obtener el número de ramas deportivas participantes
  Future<int> _obtenerNumeroParticipantes(dynamic eventoId) async {
    try {
      final response = await ApiService.obtenerParticipacionesEvento(eventoId);
      final datos = response['data'];
      final estadisticasPorRama = datos['estadisticasPorRama'] as List;
      return estadisticasPorRama.length;
    } catch (e) {
      return 0;
    }
  }

  // Función para seleccionar fecha en los filtros
  Future<void> _seleccionarFecha(bool esFechaInicio) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: WessexColors.darkGrape,
              onPrimary: Colors.white,
              onSurface: WessexColors.darkGrape,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esFechaInicio) {
          _filtroFechaInicio = fechaSeleccionada;
        } else {
          _filtroFechaFin = fechaSeleccionada;
        }
      });
    }
  }

  // Función para limpiar filtros
  void _limpiarFiltros() {
    setState(() {
      _filtroNombreController.clear();
      _filtroFechaInicio = null;
      _filtroFechaFin = null;
    });
  }

  void _mostrarGestionCategorias() {
    final _nuevaCategoriaController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width:
                        MediaQuery.of(context).size.width > 600
                            ? 500
                            : MediaQuery.of(context).size.width * 0.9,
                    height:
                        MediaQuery.of(context).size.height > 700
                            ? 600
                            : MediaQuery.of(context).size.height * 0.8,
                    constraints: BoxConstraints(
                      maxWidth: 600,
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                      minHeight: 400,
                    ),
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width > 600 ? 24 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Gestionar Categorías',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: WessexColors.darkGrape,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        Text(
                          'Categorías disponibles:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                        SizedBox(height: 12),

                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.all(8),
                              itemCount: _categorias.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: WessexColors.leafGreen,
                                      child: Text(
                                        _categorias[index]
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      _categorias[index].toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: WessexColors.darkGrape,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: WessexColors.crimsonAlert,
                                      ),
                                      onPressed: () {
                                        setDialogState(() {
                                          _categorias.removeAt(index);
                                        });
                                        setState(
                                          () {},
                                        ); // Actualizar el estado principal
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 16),
                        Text(
                          'Agregar nueva categoría:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                        SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nuevaCategoriaController,
                                decoration: InputDecoration(
                                  hintText: 'M14, M16, etc.',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: WessexColors.leafGreen,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final nuevaCategoria =
                                    _nuevaCategoriaController.text
                                        .trim()
                                        .toLowerCase();
                                if (nuevaCategoria.isNotEmpty &&
                                    !_categorias.contains(nuevaCategoria)) {
                                  setDialogState(() {
                                    _categorias.add(nuevaCategoria);
                                    _categorias
                                        .sort(_ordenarCategoriasAlfanumericamente); // Ordenar alfanuméricamente
                                  });
                                  setState(
                                    () {},
                                  ); // Actualizar el estado principal
                                  _nuevaCategoriaController.clear();
                                } else if (_categorias.contains(
                                  nuevaCategoria,
                                )) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Esta categoría ya existe'),
                                      backgroundColor:
                                          WessexColors.crimsonAlert,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WessexColors.leafGreen,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Agregar'),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WessexColors.darkGrape,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Cerrar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Future<void> _mostrarDialogoCrearEvento() async {
    // Mostrar indicador de carga mientras se obtienen los tipos
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Cargar tipos de evento
    List<Map<String, dynamic>> tiposEvento = [];
    try {
      print('DEBUG: Intentando cargar tipos de evento...');
      tiposEvento = await ApiService.obtenerTiposEvento();
      print('DEBUG: Tipos de evento cargados: ${tiposEvento.length}');
      for (var tipo in tiposEvento) {
        print(
          'DEBUG: - ${tipo['nombre']} (${tipo['esDeportivo'] ? 'Deportivo' : 'No deportivo'}) - ID: ${tipo['id']}',
        );
      }
    } catch (e) {
      print('ERROR: Error al cargar tipos de evento: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      // Usar tipos por defecto en caso de error
      tiposEvento = [
        {'id': 'default', 'nombre': 'Entrenamiento', 'esDeportivo': true},
      ];
    }

    // Cerrar el indicador de carga
    Navigator.of(context).pop();

    if (tiposEvento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar los tipos de evento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Variables del formulario
    final _formKey = GlobalKey<FormState>();
    final _tituloController = TextEditingController();
    final _descripcionController = TextEditingController();
    final _lugarController = TextEditingController();
    DateTime? _fechaSeleccionada;
    List<String> _categoriasSeleccionadas = [];
    String? _tipoEventoId = tiposEvento.first['id'];
    bool _tipoEsDeportivo = tiposEvento.first['esDeportivo'] ?? true;
    TimeOfDay? _horaInicio;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width:
                        MediaQuery.of(context).size.width > 600
                            ? 500
                            : MediaQuery.of(context).size.width * 0.9,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                      maxWidth: 600,
                    ),
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width > 600 ? 24 : 16,
                    ),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Crear Nuevo Evento',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: WessexColors.darkGrape,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(Icons.close),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            TextFormField(
                              controller: _tituloController,
                              decoration: InputDecoration(
                                labelText: 'Título del evento *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: WessexColors.leafGreen,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa el título del evento';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: _tipoEventoId,
                              decoration: InputDecoration(
                                labelText: 'Tipo de evento *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: WessexColors.leafGreen,
                                  ),
                                ),
                              ),
                              items:
                                  tiposEvento.map((tipo) {
                                    return DropdownMenuItem<String>(
                                      value: tipo['id'] as String,
                                      child: Text(tipo['nombre'] as String),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  _tipoEventoId = value;
                                  // Encontrar si el tipo seleccionado es deportivo
                                  final tipoSeleccionado = tiposEvento
                                      .firstWhere(
                                        (tipo) => tipo['id'] == value,
                                        orElse: () => {'esDeportivo': true},
                                      );
                                  _tipoEsDeportivo =
                                      tipoSeleccionado['esDeportivo'] ?? true;
                                  // Limpiar categorías si no es deportivo
                                  if (!_tipoEsDeportivo) {
                                    _categoriasSeleccionadas.clear();
                                  }
                                });
                              },
                            ),
                            SizedBox(height: 16),

                            // Solo mostrar categorías si el tipo es deportivo
                            if (_tipoEsDeportivo) ...[
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        'Categorías disponibles:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: WessexColors.darkGrape,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height >
                                                    600
                                                ? 300
                                                : 250,
                                        minHeight: 60,
                                      ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children:
                                              (_categorias..sort(_ordenarCategoriasAlfanumericamente))
                                                  .map(
                                                    (
                                                      categoria,
                                                    ) => CheckboxListTile(
                                                      title: Text(
                                                        categoria.toUpperCase(),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      value:
                                                          _categoriasSeleccionadas
                                                              .contains(
                                                                categoria,
                                                              ),
                                                      activeColor:
                                                          WessexColors
                                                              .leafGreen,
                                                      onChanged: (bool? value) {
                                                        setDialogState(() {
                                                          if (value == true) {
                                                            _categoriasSeleccionadas
                                                                .add(categoria);
                                                          } else {
                                                            _categoriasSeleccionadas
                                                                .remove(
                                                                  categoria,
                                                                );
                                                          }
                                                        });
                                                      },
                                                      dense: true,
                                                      controlAffinity:
                                                          ListTileControlAffinity
                                                              .leading,
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        'Seleccionadas: ${_categoriasSeleccionadas.length > 0 ? _categoriasSeleccionadas.map((c) => c.toUpperCase()).join(', ') : 'Ninguna'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            SizedBox(height: 16),

                            TextFormField(
                              controller: _descripcionController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Descripción',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: WessexColors.leafGreen,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),

                            TextFormField(
                              controller: _lugarController,
                              decoration: InputDecoration(
                                labelText: 'Lugar *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: WessexColors.leafGreen,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa el lugar del evento';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Solo hora de inicio
                            InkWell(
                              onTap: () async {
                                final hora = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: WessexColors.darkGrape,
                                          onPrimary: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (hora != null) {
                                  // Validar que no sea una hora pasada si es el día de hoy
                                  if (_fechaSeleccionada != null) {
                                    final fechaCompleta = DateTime(
                                      _fechaSeleccionada!.year,
                                      _fechaSeleccionada!.month,
                                      _fechaSeleccionada!.day,
                                      hora.hour,
                                      hora.minute,
                                    );

                                    final fechaHoy = DateTime.now();
                                    final esHoy =
                                        _fechaSeleccionada!.year ==
                                            fechaHoy.year &&
                                        _fechaSeleccionada!.month ==
                                            fechaHoy.month &&
                                        _fechaSeleccionada!.day == fechaHoy.day;

                                    if (esHoy &&
                                        fechaCompleta.isBefore(fechaHoy)) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'No puedes seleccionar una hora pasada para el día de hoy',
                                          ),
                                          backgroundColor:
                                              WessexColors.crimsonAlert,
                                        ),
                                      );
                                      return;
                                    }
                                  }

                                  setDialogState(() {
                                    _horaInicio = hora;
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: WessexColors.darkGrape,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      _horaInicio == null
                                          ? 'Hora de inicio *'
                                          : _horaInicio!.format(context),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            _horaInicio == null
                                                ? Colors.grey[600]
                                                : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16),

                            InkWell(
                              onTap: () async {
                                final fecha = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(
                                    Duration(days: 1),
                                  ),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    Duration(days: 365),
                                  ),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: WessexColors.darkGrape,
                                          onPrimary: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (fecha != null) {
                                  // Validar que no sea una fecha pasada
                                  final fechaHoy = DateTime.now();
                                  final fechaSinHora = DateTime(
                                    fecha.year,
                                    fecha.month,
                                    fecha.day,
                                  );
                                  final hoySinHora = DateTime(
                                    fechaHoy.year,
                                    fechaHoy.month,
                                    fechaHoy.day,
                                  );

                                  if (fechaSinHora.isBefore(hoySinHora)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'No puedes seleccionar una fecha pasada',
                                        ),
                                        backgroundColor:
                                            WessexColors.crimsonAlert,
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() {
                                    _fechaSeleccionada = fecha;
                                    // Si se cambia la fecha, revalidar la hora
                                    if (_horaInicio != null) {
                                      final fechaCompleta = DateTime(
                                        fecha.year,
                                        fecha.month,
                                        fecha.day,
                                        _horaInicio!.hour,
                                        _horaInicio!.minute,
                                      );

                                      final esHoy =
                                          fecha.year == fechaHoy.year &&
                                          fecha.month == fechaHoy.month &&
                                          fecha.day == fechaHoy.day;

                                      if (esHoy &&
                                          fechaCompleta.isBefore(fechaHoy)) {
                                        _horaInicio =
                                            null; // Resetear hora si ya no es válida
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Se reinició la hora porque ya no es válida para la fecha seleccionada',
                                            ),
                                            backgroundColor:
                                                WessexColors.darkGrape,
                                          ),
                                        );
                                      }
                                    }
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: WessexColors.darkGrape,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      _fechaSeleccionada == null
                                          ? 'Seleccionar fecha del evento *'
                                          : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            _fechaSeleccionada == null
                                                ? Colors.grey[600]
                                                : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_fechaSeleccionada == null) ...[
                              SizedBox(height: 8),
                              Text(
                                'Por favor selecciona la fecha del evento',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],

                            SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: WessexColors.darkGrape,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate() &&
                                        _fechaSeleccionada != null) {
                                      // Validación adicional para hora de inicio requerida
                                      if (_horaInicio == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Por favor selecciona la hora de inicio',
                                            ),
                                            backgroundColor:
                                                WessexColors.crimsonAlert,
                                          ),
                                        );
                                        return;
                                      }

                                      await _crearEventoDeportivo(
                                        _tituloController.text.trim(),
                                        _descripcionController.text.trim(),
                                        _lugarController.text.trim(),
                                        _tipoEventoId!,
                                        _categoriasSeleccionadas,
                                        _fechaSeleccionada!,
                                        _horaInicio!,
                                      );
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WessexColors.leafGreen,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Crear Evento'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  Future<void> _crearEventoDeportivo(
    String titulo,
    String descripcion,
    String lugar,
    String tipoEventoId,
    List<String> categorias,
    DateTime fecha,
    TimeOfDay horaInicio,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Construir fechaInicio con hora
      DateTime fechaInicio = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        horaInicio.hour,
        horaInicio.minute,
      );

      final eventoData = {
        'titulo': titulo,
        'descripcion': descripcion.isEmpty ? null : descripcion,
        'tipoEventoId': tipoEventoId,
        'categoria': categorias.isNotEmpty ? categorias.join(',') : null,
        'categorias': categorias, // Enviamos también como array
        'fechaInicio': fechaInicio.toIso8601String(),
        'horaInicio':
            '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
        'lugar': lugar,
        'estado': 'programado',
        'inscripcionRequerida': false,
        'notificarParticipantes': true,
      };

      await ApiService.crearEventoDeportivo(eventoData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evento creado exitosamente'),
          backgroundColor: WessexColors.leafGreen,
        ),
      );

      // Recargar la lista de eventos
      await _cargarEventos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear evento: $e'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gestión de eventos con menú de categorías y formulario mejorado - v2.0
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: WessexAppBar(
        title: 'Gestión de Eventos',
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [Tab(text: 'Eventos Activos'), Tab(text: 'Eventos Pasados')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoCrearEvento,
        backgroundColor: WessexColors.leafGreen,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Crear nuevo evento',
      ),
      body: WessexBackground(
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: WessexColors.deepRoyalBlue,
                  ),
                )
              : Column(
                  children: [
                    // Filtros de búsqueda
                    Container(
                      margin: EdgeInsets.all(24),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Filtro por nombre
                          TextField(
                            controller: _filtroNombreController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre de evento...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: WessexColors.darkGrape,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        SizedBox(height: 12),
                          // Filtros por fecha y botones de gestión responsive
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmallScreen = constraints.maxWidth < 600;

                              if (isSmallScreen) {
                                return Column(
                                  children: [
                                    // Filtros por fecha (Stacked)
                                    GestureDetector(
                                      onTap: () => _seleccionarFecha(true),
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: WessexColors.darkGrape.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              color: WessexColors.darkGrape,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              _filtroFechaInicio != null
                                                  ? 'Desde: ${_filtroFechaInicio!.day}/${_filtroFechaInicio!.month}/${_filtroFechaInicio!.year}'
                                                  : 'Fecha desde',
                                              style: TextStyle(
                                                color: _filtroFechaInicio != null
                                                    ? WessexColors.darkGrape
                                                    : WessexColors.midnightNavy.withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () => _seleccionarFecha(false),
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: WessexColors.darkGrape.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              color: WessexColors.darkGrape,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              _filtroFechaFin != null
                                                  ? 'Hasta: ${_filtroFechaFin!.day}/${_filtroFechaFin!.month}/${_filtroFechaFin!.year}'
                                                  : 'Fecha hasta',
                                              style: TextStyle(
                                                color: _filtroFechaFin != null
                                                    ? WessexColors.darkGrape
                                                    : WessexColors.midnightNavy.withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    // Botón limpiar filtros (Full width)
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _limpiarFiltros,
                                        icon: Icon(
                                          Icons.clear,
                                          color: WessexColors.crimsonAlert,
                                        ),
                                        label: Text(
                                          'Limpiar filtros',
                                          style: TextStyle(color: WessexColors.crimsonAlert),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: WessexColors.crimsonAlert),
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    // Botones de gestión (Stacked)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _mostrarGestionCategorias,
                                        icon: Icon(Icons.category),
                                        label: Text('Gestionar Categorías'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: WessexColors.deepRoyalBlue,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AdminTiposEventoScreen(),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.event_note),
                                        label: Text('Tipos de Evento'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: WessexColors.leafGreen,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => _seleccionarFecha(true),
                                            child: Container(
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: WessexColors.darkGrape.withOpacity(0.3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    color: WessexColors.darkGrape,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    _filtroFechaInicio != null
                                                        ? 'Desde: ${_filtroFechaInicio!.day}/${_filtroFechaInicio!.month}/${_filtroFechaInicio!.year}'
                                                        : 'Fecha desde',
                                                    style: TextStyle(
                                                      color: _filtroFechaInicio != null
                                                          ? WessexColors.darkGrape
                                                          : WessexColors.midnightNavy.withOpacity(0.6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => _seleccionarFecha(false),
                                            child: Container(
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: WessexColors.darkGrape.withOpacity(0.3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    color: WessexColors.darkGrape,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    _filtroFechaFin != null
                                                        ? 'Hasta: ${_filtroFechaFin!.day}/${_filtroFechaFin!.month}/${_filtroFechaFin!.year}'
                                                        : 'Fecha hasta',
                                                    style: TextStyle(
                                                      color: _filtroFechaFin != null
                                                          ? WessexColors.darkGrape
                                                          : WessexColors.midnightNavy.withOpacity(0.6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        IconButton(
                                          onPressed: _limpiarFiltros,
                                          icon: Icon(
                                            Icons.clear,
                                            color: WessexColors.crimsonAlert,
                                          ),
                                          tooltip: 'Limpiar filtros',
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _mostrarGestionCategorias,
                                            icon: Icon(Icons.category),
                                            label: Text('Gestionar Categorías'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: WessexColors.deepRoyalBlue,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => AdminTiposEventoScreen(),
                                                ),
                                              );
                                            },
                                            icon: Icon(Icons.event_note),
                                            label: Text('Tipos de Evento'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: WessexColors.leafGreen,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  // TabBarView con eventos filtrados
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEventosActivos(),
                        _buildEventosPasados(),
                      ],
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildEventosActivos() {
    final eventosActivos =
        _eventos.where((evento) {
          final fechaEvento = _parseFechaLocal(evento['fechaInicio']);
          if (fechaEvento == null) return false;
          bool esActivo = fechaEvento.isAfter(DateTime.now());

          if (!esActivo) return false;

          // Aplicar filtro por nombre
          if (_filtroNombreController.text.isNotEmpty) {
            final nombre =
                (evento['titulo'] ?? evento['nombre'] ?? '')
                    .toString()
                    .toLowerCase();
            final filtroNombre = _filtroNombreController.text.toLowerCase();
            if (!nombre.contains(filtroNombre)) return false;
          }

          // Aplicar filtro por fecha de inicio
          if (_filtroFechaInicio != null) {
            if (fechaEvento.isBefore(_filtroFechaInicio!)) return false;
          }

          // Aplicar filtro por fecha de fin
          if (_filtroFechaFin != null) {
            if (fechaEvento.isAfter(_filtroFechaFin!.add(Duration(days: 1))))
              return false;
          }

          return true;
        }).toList()
          ..sort((a, b) {
            final fechaA = _parseFechaLocal(a['fechaInicio']);
            final fechaB = _parseFechaLocal(b['fechaInicio']);
            if (fechaA == null && fechaB == null) return 0;
            if (fechaA == null) return 1;
            if (fechaB == null) return -1;
            return fechaA.compareTo(fechaB); // Eventos futuros: mŽs prœximos primero
          });

    if (eventosActivos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event,
              size: 64,
              color: WessexColors.darkGrape.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No hay eventos activos',
              style: TextStyle(fontSize: 18, color: WessexColors.darkGrape),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: eventosActivos.length,
      itemBuilder: (context, index) {
        return _buildEventoCard(eventosActivos[index]);
      },
    );
  }

  Widget _buildEventosPasados() {
    final eventosPasados =
        _eventos.where((evento) {
          final fechaEvento = _parseFechaLocal(evento['fechaInicio']);
          if (fechaEvento == null) return false;
          bool esPasado = fechaEvento.isBefore(DateTime.now());

          if (!esPasado) return false;

          // Aplicar filtro por nombre
          if (_filtroNombreController.text.isNotEmpty) {
            final nombre =
                (evento['titulo'] ?? evento['nombre'] ?? '')
                    .toString()
                    .toLowerCase();
            final filtroNombre = _filtroNombreController.text.toLowerCase();
            if (!nombre.contains(filtroNombre)) return false;
          }

          // Aplicar filtro por fecha de inicio
          if (_filtroFechaInicio != null) {
            if (fechaEvento.isBefore(_filtroFechaInicio!)) return false;
          }

          // Aplicar filtro por fecha de fin
          if (_filtroFechaFin != null) {
            if (fechaEvento.isAfter(_filtroFechaFin!.add(Duration(days: 1))))
              return false;
          }

          return true;
        }).toList()
          ..sort((a, b) {
            final fechaA = _parseFechaLocal(a['fechaInicio']);
            final fechaB = _parseFechaLocal(b['fechaInicio']);
            if (fechaA == null && fechaB == null) return 0;
            if (fechaA == null) return 1;
            if (fechaB == null) return -1;
            return fechaB.compareTo(fechaA); // Ordenar de mŽs reciente a mŽs antiguo
          });

    if (eventosPasados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: WessexColors.darkGrape.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No hay eventos pasados',
              style: TextStyle(fontSize: 18, color: WessexColors.darkGrape),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: eventosPasados.length,
      itemBuilder: (context, index) {
        return _buildEventoCard(eventosPasados[index]);
      },
    );
  }

  Widget _buildEventoCard(Map<String, dynamic> evento) {
    final fechaEvento = _parseFechaLocal(evento['fechaInicio']);
    final esEventoPasado =
        fechaEvento?.isBefore(DateTime.now()) ?? false;
    final estado = evento['estado'] ?? 'programado';
    final tipoEventoObj = evento['tipoEvento'];
    final tipoEvento =
        tipoEventoObj != null
            ? (tipoEventoObj is Map<String, dynamic>
                ? tipoEventoObj['nombre'] ?? 'evento'
                : tipoEventoObj.toString())
            : 'evento';
    final categoria = evento['categoria'];

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    evento['titulo'] ?? 'Sin título',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        esEventoPasado
                            ? WessexColors.crimsonAlert.withOpacity(0.1)
                            : WessexColors.leafGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          esEventoPasado
                              ? WessexColors.crimsonAlert
                              : WessexColors.leafGreen,
                    ),
                  ),
                  child: Text(
                    estado.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          esEventoPasado
                              ? WessexColors.crimsonAlert
                              : WessexColors.leafGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Tipo de evento y categorías
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: WessexColors.darkGrape.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tipoEvento.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                ),
                // Mostrar múltiples categorías
                if (categoria != null && categoria.toString().isNotEmpty)
                  ...categoria
                      .toString()
                      .split(',')
                      .map(
                        (cat) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: WessexColors.leafGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            cat.trim().toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: WessexColors.leafGreen,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              ],
            ),

            if (evento['descripcion'] != null &&
                evento['descripcion'].isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                evento['descripcion'],
                style: TextStyle(
                  fontSize: 14,
                  color: WessexColors.midnightNavy,
                ),
              ),
            ],

            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: WessexColors.darkGrape,
                ),
                SizedBox(width: 4),
                Text(
                  fechaEvento != null
                      ? _formatearFechaCorta(fechaEvento)
                      : 'Fecha no disponible',
                  style: TextStyle(fontSize: 14, color: WessexColors.darkGrape),
                ),
                // Mostrar hora de inicio si está disponible
                if (evento['horaInicio'] != null) ...[
                  SizedBox(width: 8),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: WessexColors.darkGrape,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _convertirUTCaChile(evento['horaInicio']),
                    style: TextStyle(
                      fontSize: 14,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                ] else if (fechaEvento != null &&
                    (fechaEvento.hour != 0 || fechaEvento.minute != 0)) ...[
                  // Fallback para fechas con hora integrada - convertir de UTC a Chile
                  SizedBox(width: 8),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: WessexColors.darkGrape,
                  ),
                  SizedBox(width: 4),
                  Text(
                    () {
                      final fechaChile = _convertirFechaUTCaChile(fechaEvento!);
                      return '${fechaChile.hour.toString().padLeft(2, '0')}:${fechaChile.minute.toString().padLeft(2, '0')}';
                    }(),
                    style: TextStyle(
                      fontSize: 14,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                ],
                SizedBox(width: 16),
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: WessexColors.darkGrape,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    evento['lugar'] ?? 'Sin ubicación',
                    style: TextStyle(
                      fontSize: 14,
                      color: WessexColors.darkGrape,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (!esEventoPasado) ...[
                      TextButton.icon(
                        onPressed: () {
                          _editarEvento(evento);
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: WessexColors.darkGrape,
                          size: 18,
                        ),
                        label: const Text(
                          'Editar',
                          style: TextStyle(color: WessexColors.darkGrape),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          _eliminarEvento(evento);
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: WessexColors.crimsonAlert,
                          size: 18,
                        ),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(color: WessexColors.crimsonAlert),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (esEventoPasado)
                      TextButton.icon(
                        onPressed: () => _mostrarMultimediaEvento(evento),
                        icon: const Icon(
                          Icons.photo_library,
                          color: WessexColors.deepRoyalBlue,
                        ),
                        label: const Text(
                          'Multimedia',
                          style: TextStyle(color: WessexColors.deepRoyalBlue),
                        ),
                      ),
                  ],
                ),
                FutureBuilder<int>(
                  future: _obtenerNumeroParticipantes(evento['id']),
                  builder: (context, snapshot) {
                    final numParticipantes = snapshot.data ?? 0;
                    return TextButton.icon(
                      onPressed: () => _mostrarParticipaciones(evento),
                      icon: Stack(
                        children: [
                          Icon(Icons.people, color: WessexColors.leafGreen),
                          if (numParticipantes > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: WessexColors.crimsonAlert,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$numParticipantes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: Text(
                        numParticipantes > 0
                            ? 'Ver Participaciones ($numParticipantes ramas)'
                            : 'Ver Participaciones',
                        style: TextStyle(color: WessexColors.leafGreen),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
