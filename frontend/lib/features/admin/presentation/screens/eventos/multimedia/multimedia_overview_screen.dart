import 'package:flutter/material.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/features/admin/presentation/screens/eventos/gestion/widgets/event_multimedia_dialog.dart';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';

class MultimediaOverviewScreen extends StatefulWidget {
  const MultimediaOverviewScreen({super.key});

  @override
  State<MultimediaOverviewScreen> createState() =>
      _MultimediaOverviewScreenState();
}

class _MultimediaOverviewScreenState extends State<MultimediaOverviewScreen> {
  final TextEditingController _eventoController = TextEditingController();
  final TextEditingController _rutController = TextEditingController();

  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String _rolSeleccionado = 'todos';
  String _visibilidadSeleccionada = 'todas';

  bool _cargando = true;
  List<dynamic> _multimedia = [];
  List<dynamic> _eventos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _cargando = true;
    });
    await Future.wait([_cargarEventos(), _cargarMultimedia()]);
    if (mounted) {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _cargarEventos() async {
    try {
      final response = await ApiService.obtenerEventosDeportivos();
      final data = response['data'] as List<dynamic>? ?? [];

      final ahora = DateTime.now();
      final eventosPasados =
          data.where((evento) {
            final fechaInicio = evento['fechaInicio'];
            if (fechaInicio == null) return false;
            final fecha = DateTime.tryParse(fechaInicio.toString());
            if (fecha == null) return false;
            return fecha.isBefore(ahora);
          }).toList();

      if (mounted) {
        setState(() {
          _eventos = eventosPasados;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar eventos: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    }
  }

  Future<void> _cargarMultimedia() async {
    setState(() => _cargando = true);
    try {
      final response = await ApiService.obtenerMultimediaGlobalDirectiva(
        evento:
            _eventoController.text.trim().isEmpty
                ? null
                : _eventoController.text.trim(),
        fechaDesde:
            _fechaDesde != null
                ? _fechaDesde!.toIso8601String().split('T').first
                : null,
        fechaHasta:
            _fechaHasta != null
                ? _fechaHasta!.toIso8601String().split('T').first
                : null,
        rol:
            _rolSeleccionado == 'todos'
                ? null
                : (_rolSeleccionado == 'directiva'
                    ? 'directiva'
                    : 'RamaExterna'),
        visibilidad:
            _visibilidadSeleccionada == 'todas'
                ? null
                : (_visibilidadSeleccionada == 'privada'
                    ? 'privada'
                    : 'compartida'),
        rut:
            _rutController.text.trim().isEmpty
                ? null
                : _rutController.text.trim(),
      );

      final data = response['data'] as List<dynamic>? ?? [];
      setState(() {
        _multimedia = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar multimedia: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _seleccionarFecha({required bool desde}) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          desde
              ? (_fechaDesde ?? DateTime.now())
              : (_fechaHasta ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: WessexColors.deepRoyalBlue,
                onPrimary: Colors.white,
                onSurface: WessexColors.darkGrape,
              ),
            ),
            child: child!,
          ),
    );

    if (selectedDate != null) {
      setState(() {
        if (desde) {
          _fechaDesde = selectedDate;
        } else {
          _fechaHasta = selectedDate;
        }
      });
    }
  }

  Future<void> _mostrarDialogoAgregar() async {
    if (_eventos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay eventos pasados disponibles para asociar.'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
      return;
    }

    String? eventoSeleccionado = _eventos.first['id']?.toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Seleccionar evento'),
          content: DropdownButtonFormField<String>(
            value: eventoSeleccionado,
            items:
                _eventos
                    .map(
                      (evento) => DropdownMenuItem<String>(
                        value: evento['id']?.toString(),
                        child: Text(
                          (evento['titulo'] ?? evento['nombre'] ?? 'Evento')
                              .toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (value) => eventoSeleccionado = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (eventoSeleccionado != null) {
                  _abrirDialogoMultimedia(eventoSeleccionado!);
                }
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _abrirDialogoMultimedia(String eventoId) async {
    final evento = _eventos.firstWhere(
      (item) => item['id'].toString() == eventoId,
      orElse: () => {},
    );
    final titulo = evento['titulo'] ?? evento['nombre'] ?? 'Evento';

    await showDialog(
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
    await _cargarMultimedia();
  }

  @override
  void dispose() {
    _eventoController.dispose();
    _rutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WessexAppBar(title: 'Multimedia de Eventos', elevation: 2),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoAgregar,
        backgroundColor: WessexColors.deepRoyalBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Agregar multimedia'),
      ),
      body: WessexBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.darkGrape,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 260,
                              child: TextField(
                                controller: _eventoController,
                                decoration: const InputDecoration(
                                  labelText: 'Evento / título',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 200,
                              child: TextField(
                                controller: _rutController,
                                decoration: const InputDecoration(
                                  labelText: 'RUT rama',
                                  prefixIcon: Icon(Icons.badge),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: _buildFechaField(
                                label: 'Fecha desde',
                                fecha: _fechaDesde,
                                onTap: () => _seleccionarFecha(desde: true),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: _buildFechaField(
                                label: 'Fecha hasta',
                                fecha: _fechaHasta,
                                onTap: () => _seleccionarFecha(desde: false),
                              ),
                            ),
                            SizedBox(
                              width: 220,
                              child: DropdownButtonFormField<String>(
                                value: _rolSeleccionado,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'todos',
                                    child: Text('Todos los roles'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'directiva',
                                    child: Text('Solo directiva'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'rama',
                                    child: Text('Solo ramas externas'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _rolSeleccionado = value);
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Rol',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 240,
                              child: DropdownButtonFormField<String>(
                                value: _visibilidadSeleccionada,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'todas',
                                    child: Text('Todas las visibilidades'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'compartida',
                                    child: Text('Compartidas con ramas'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'privada',
                                    child: Text('Solo directiva'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(
                                      () => _visibilidadSeleccionada = value,
                                    );
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Visibilidad',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _cargarMultimedia,
                              icon: const Icon(Icons.filter_alt),
                              label: const Text('Aplicar filtros'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WessexColors.deepRoyalBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _eventoController.clear();
                                  _rutController.clear();
                                  _fechaDesde = null;
                                  _fechaHasta = null;
                                  _rolSeleccionado = 'todos';
                                  _visibilidadSeleccionada = 'todas';
                                });
                                _cargarMultimedia();
                              },
                              child: const Text('Limpiar filtros'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    _cargando
                        ? const Center(child: CircularProgressIndicator())
                        : _multimedia.isEmpty
                        ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            margin: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_outlined,
                                  size: 80,
                                  color: WessexColors.darkGrape,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No se encontraron imágenes con los filtros seleccionados.',
                                  style: TextStyle(
                                    color: WessexColors.darkGrape,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Intenta ajustar los filtros o agregar nueva multimedia.',
                                  style: TextStyle(
                                    color: WessexColors.midnightNavy.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                        : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.68,
                              ),
                          itemCount: _multimedia.length,
                          itemBuilder: (context, index) {
                            final media =
                                _multimedia[index] as Map<String, dynamic>;
                            return _buildMediaCard(media);
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFechaField({
    required String label,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    final value =
        fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : '';
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.date_range),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value.isEmpty ? 'Seleccionar fecha' : value,
          style: TextStyle(
            color:
                value.isEmpty
                    ? WessexColors.midnightNavy.withOpacity(0.5)
                    : WessexColors.darkGrape,
          ),
        ),
      ),
    );
  }

  Future<void> _eliminarMultimedia(Map<String, dynamic> media) async {
    final eventoId =
        (media['eventoDeportivoId'] ?? media['eventoId'])?.toString();
    final mediaId = media['id']?.toString();

    if (eventoId == null || mediaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo identificar la imagen'),
          backgroundColor: WessexColors.crimsonAlert,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta imagen? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WessexColors.crimsonAlert,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.eliminarMultimediaEvento(
        eventoId: eventoId,
        mediaId: mediaId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen eliminada exitosamente'),
            backgroundColor: WessexColors.leafGreen,
          ),
        );
        await _cargarMultimedia();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar imagen: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    }
  }

  Widget _buildMediaCard(Map<String, dynamic> media) {
    final tituloEvento = media['tituloEvento'] ?? 'Evento';
    final uploader = media['uploadedByNombre'] ?? media['uploadedByRut'] ?? '';
    final rol = media['uploadedByRol'] ?? '';
    final isPrivate = media['isPrivate'] == true;
    final fecha =
        media['createdAt'] != null
            ? DateTime.tryParse(media['createdAt'].toString())
            : null;
    final fechaTexto =
        fecha != null
            ? '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}'
            : '';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    InkWell(
                      onTap: () {
                        final eventoId =
                            (media['eventoDeportivoId'] ?? media['eventoId'])
                                ?.toString();
                        if (eventoId != null) {
                          _abrirDialogoMultimedia(eventoId);
                        }
                      },
                      child: Ink.image(
                        image: NetworkImage(media['url']),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => _eliminarMultimedia(media),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: constraints.maxWidth,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tituloEvento.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: WessexColors.darkGrape,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        uploader.toString(),
                        style: TextStyle(
                          color: WessexColors.midnightNavy.withOpacity(0.7),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: constraints.maxWidth - 16,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPrivate ? Icons.lock : Icons.groups,
                              size: 12,
                              color:
                                  isPrivate
                                      ? WessexColors.midnightNavy
                                      : WessexColors.leafGreen,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                isPrivate ? 'Solo directiva' : 'Compartido',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isPrivate
                                          ? WessexColors.midnightNavy
                                          : WessexColors.leafGreen,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (fechaTexto.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        SizedBox(
                          width: constraints.maxWidth - 16,
                          child: Text(
                            fechaTexto,
                            style: TextStyle(
                              fontSize: 9,
                              color: WessexColors.midnightNavy.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      SizedBox(
                        width: constraints.maxWidth - 16,
                        child: Text(
                          rol.toString(),
                          style: TextStyle(
                            fontSize: 9,
                            color: WessexColors.midnightNavy.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
