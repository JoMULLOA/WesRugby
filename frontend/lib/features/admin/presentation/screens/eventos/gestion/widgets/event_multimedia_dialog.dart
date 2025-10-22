import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';

class EventMultimediaDialog extends StatefulWidget {
  final String eventoId;
  final String tituloEvento;
  final bool isDirectiva;
  final bool canUploadPrivate;
  final bool canUploadShared;
  final BuildContext scaffoldContext;

  const EventMultimediaDialog({
    super.key,
    required this.eventoId,
    required this.tituloEvento,
    required this.scaffoldContext,
    this.isDirectiva = false,
    this.canUploadPrivate = false,
    this.canUploadShared = false,
  });

  @override
  State<EventMultimediaDialog> createState() => _EventMultimediaDialogState();
}

class _EventMultimediaDialogState extends State<EventMultimediaDialog> {
  bool _loading = true;
  bool _uploading = false;
  String? _errorMessage;
  List<dynamic> _mediaPrivada = [];
  List<dynamic> _mediaCompartida = [];

  @override
  void initState() {
    super.initState();
    _cargarMultimedia();
  }

  Future<void> _cargarMultimedia() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> response;
      if (widget.isDirectiva) {
        response = await ApiService.obtenerMultimediaEventoDirectiva(
          widget.eventoId,
        );
        final data = response['data'] as List<dynamic>? ?? [];
        _mediaPrivada =
            data.where((item) => (item['isPrivate'] ?? false) == true).toList();
        _mediaCompartida =
            data
                .where((item) => (item['isPrivate'] ?? false) == false)
                .toList();
      } else {
        response = await ApiService.obtenerMultimediaEventoCompartido(
          widget.eventoId,
        );
        _mediaCompartida = response['data'] as List<dynamic>? ?? [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _uploading = false;
        });
      }
    }
  }

  Future<void> _seleccionarYSubirImagenes({required bool esPrivado}) async {
    if (!_puedeSubir(esPrivado: esPrivado)) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() {
      _uploading = true;
      _errorMessage = null;
    });

    int exitosas = 0;
    int fallidas = 0;

    for (final file in result.files) {
      try {
        final bytes = await _obtenerBytes(file);
        final mimeType = _inferMimeType(file.extension);

        if (mimeType == null) {
          fallidas++;
          continue;
        }

        if (widget.isDirectiva) {
          await ApiService.subirMultimediaEventoDirectiva(
            eventoId: widget.eventoId,
            bytes: bytes,
            fileName: file.name,
            mimeType: mimeType,
            esPrivado: esPrivado,
          );
        } else {
          await ApiService.subirMultimediaEventoRama(
            eventoId: widget.eventoId,
            bytes: bytes,
            fileName: file.name,
            mimeType: mimeType,
          );
        }

        exitosas++;
      } catch (e) {
        fallidas++;
        debugPrint('Error subiendo imagen ${file.name}: $e');
      }
    }

    if (mounted) {
      if (exitosas > 0) {
        ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
          SnackBar(
            content: Text(
              exitosas == 1
                  ? 'Imagen subida correctamente.'
                  : '$exitosas imágenes subidas correctamente.',
            ),
            backgroundColor: WessexColors.leafGreen,
          ),
        );
      }

      if (fallidas > 0) {
        ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
          SnackBar(
            content: Text(
              fallidas == 1
                  ? 'Una imagen no pudo subirse. Verifica el formato.'
                  : '$fallidas imágenes no pudieron subirse.',
            ),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    }

    await _cargarMultimedia();
  }

  bool _puedeSubir({required bool esPrivado}) {
    if (esPrivado && !widget.canUploadPrivate) return false;
    if (!esPrivado && !widget.canUploadShared) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.photo_library, color: WessexColors.deepRoyalBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Multimedia - ${widget.tituloEvento}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: WessexColors.darkGrape,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_uploading)
                        const LinearProgressIndicator(
                          minHeight: 4,
                          color: WessexColors.deepRoyalBlue,
                        ),
                      if (widget.canUploadPrivate || widget.canUploadShared)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (widget.canUploadShared)
                                ElevatedButton.icon(
                                  onPressed:
                                      _uploading
                                          ? null
                                          : () => _seleccionarYSubirImagenes(
                                            esPrivado: false,
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WessexColors.leafGreen,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.cloud_upload),
                                  label: const Text('Compartir con ramas'),
                                ),
                              if (widget.canUploadPrivate)
                                ElevatedButton.icon(
                                  onPressed:
                                      _uploading
                                          ? null
                                          : () => _seleccionarYSubirImagenes(
                                            esPrivado: true,
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WessexColors.deepRoyalBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.lock),
                                  label: const Text('Solo para directiva'),
                                ),
                            ],
                          ),
                        ),
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: WessexColors.crimsonAlert.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: WessexColors.crimsonAlert,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: WessexColors.crimsonAlert,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: WessexColors.crimsonAlert,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.isDirectiva)
                        _buildSection(
                          titulo:
                              'Contenido compartido con ramas participantes',
                          media: _mediaCompartida,
                          vacioMensaje:
                              'Aún no se han compartido imágenes con las ramas.',
                        ),
                      if (widget.isDirectiva)
                        _buildSection(
                          titulo: 'Solo visible para directiva',
                          media: _mediaPrivada,
                          vacioMensaje:
                              'No hay imágenes privadas para este evento.',
                          badgeColor: WessexColors.darkGrape,
                        ),
                      if (!widget.isDirectiva)
                        _buildSection(
                          titulo: 'Imágenes compartidas del evento',
                          media: _mediaCompartida,
                          vacioMensaje:
                              'Aún no hay imágenes compartidas para este evento.',
                        ),
                    ],
                  ),
                ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String titulo,
    required List<dynamic> media,
    required String vacioMensaje,
    Color badgeColor = WessexColors.leafGreen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${media.length})',
                style: TextStyle(
                  color: WessexColors.midnightNavy.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (media.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WessexColors.maximumGrayMint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: WessexColors.midnightNavy.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vacioMensaje,
                      style: TextStyle(
                        color: WessexColors.midnightNavy.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: media.map((item) => _buildMediaCard(item)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(Map<String, dynamic> media) {
    final uploader = media['uploadedByNombre'] ?? media['uploadedByRut'] ?? '';
    final rol = media['uploadedByRol'] ?? '';
    final fecha =
        media['createdAt'] != null
            ? DateTime.tryParse(media['createdAt'].toString())
            : null;
    final fechaTexto =
        fecha != null
            ? '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}'
            : '';

    return SizedBox(
      width: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: InkWell(
                onTap: () => _mostrarImagenCompleta(media['url']),
                child: Ink.image(
                  image: NetworkImage(media['url']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uploader.isEmpty ? 'Sin registro' : uploader,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: WessexColors.darkGrape,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rol,
                    style: TextStyle(
                      fontSize: 12,
                      color: WessexColors.midnightNavy.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (fechaTexto.isNotEmpty)
                    Text(
                      fechaTexto,
                      style: TextStyle(
                        fontSize: 11,
                        color: WessexColors.midnightNavy.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarImagenCompleta(String url) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(24),
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
    );
  }

  Future<Uint8List> _obtenerBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }

    final stream = file.readStream;
    if (stream != null) {
      final completer = Completer<Uint8List>();
      final chunks = <int>[];

      stream.listen(
        (data) => chunks.addAll(data),
        onDone: () => completer.complete(Uint8List.fromList(chunks)),
        onError: (error) => completer.completeError(error),
        cancelOnError: true,
      );

      return completer.future;
    }

    throw Exception('No fue posible leer el archivo seleccionado.');
  }

  String? _inferMimeType(String? extension) {
    if (extension == null) return null;
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }
}
