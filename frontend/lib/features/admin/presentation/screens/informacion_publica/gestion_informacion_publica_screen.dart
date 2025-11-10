import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:wesrugby/shared/widgets/layout/wessex_widgets.dart';
import 'package:wesrugby/core/config/colors.dart';
import 'package:wesrugby/data/services/api_service.dart';
import 'package:wesrugby/data/models/noticia_model.dart';
import 'package:wesrugby/data/models/auspiciador_model.dart';
import 'package:wesrugby/data/models/merchandising_model.dart';

class GestionInformacionPublicaScreen extends StatefulWidget {
  const GestionInformacionPublicaScreen({super.key});

  @override
  State<GestionInformacionPublicaScreen> createState() =>
      _GestionInformacionPublicaScreenState();
}

class _GestionInformacionPublicaScreenState
    extends State<GestionInformacionPublicaScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WessexColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.public, color: WessexColors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Información Pública',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.white,
                  ),
                ),
                Text(
                  'Gestión de contenido visible al público',
                  style: TextStyle(
                    fontSize: 12,
                    color: WessexColors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: WessexColors.crestPrimaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WessexColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isDesktop ? 60 : 50),
          child: Container(
            color: WessexColors.leafGreen,
            child: TabBar(
              controller: _tabController,
              indicatorColor: WessexColors.goldenYellow,
              indicatorWeight: 4,
              labelColor: WessexColors.white,
              unselectedLabelColor: WessexColors.white.withOpacity(0.6),
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 16 : 14,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.article),
                  text: 'Noticias',
                  height: isDesktop ? 60 : 50,
                ),
                Tab(
                  icon: const Icon(Icons.business),
                  text: 'Auspiciadores',
                  height: isDesktop ? 60 : 50,
                ),
                Tab(
                  icon: const Icon(Icons.shopping_bag),
                  text: 'Merchandising',
                  height: isDesktop ? 60 : 50,
                ),
                Tab(
                  icon: const Icon(Icons.info),
                  text: 'Info del Club',
                  height: isDesktop ? 60 : 50,
                ),
              ],
            ),
          ),
        ),
      ),
      body: WessexBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _NoticiasTab(),
            _AuspiciadoresTab(),
            _MerchandisingTab(),
            _InformacionClubTab(),
          ],
        ),
      ),
    );
  }
}

class _NoticiasTab extends StatefulWidget {
  const _NoticiasTab();

  @override
  State<_NoticiasTab> createState() => _NoticiasTabState();
}

class _NoticiasTabState extends State<_NoticiasTab> {
  List<NoticiaModel> _noticias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNoticias();
  }

  Future<void> _loadNoticias() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/noticias');
      print('🔍 DEBUG _loadNoticias - Success: ${response.success}');
      print('🔍 DEBUG _loadNoticias - Data type: ${response.data.runtimeType}');
      print('🔍 DEBUG _loadNoticias - Data: ${response.data}');

      if (response.success && response.data != null) {
        // El backend devuelve {success: true, message: "...", data: [...]}
        final List<dynamic> noticiasData =
            response.data is Map
                ? (response.data['data'] as List? ?? [])
                : (response.data is List ? response.data as List : []);

        print(
          '🔍 DEBUG _loadNoticias - Noticias count: ${noticiasData.length}',
        );

        setState(() {
          _noticias =
              noticiasData.map((json) => NoticiaModel.fromJson(json)).toList();
        });

        print(
          '✅ DEBUG _loadNoticias - _noticias final count: ${_noticias.length}',
        );
      } else {
        print(
          '❌ DEBUG _loadNoticias - Response not successful or data is null',
        );
      }
    } catch (e) {
      print('❌ DEBUG _loadNoticias - Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar noticias: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
    
    return SafeArea(
      child: Column(
        children: [
          // Header mejorado con estadísticas
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WessexColors.deepRoyalBlue,
                  WessexColors.midnightNavy,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: WessexColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.article,
                                  color: WessexColors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Gestión de Noticias',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: WessexColors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_noticias.length} noticias publicadas',
                            style: TextStyle(
                              fontSize: 14,
                              color: WessexColors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    WessexButton(
                      onPressed: () => _showCreateDialog(),
                      text: isDesktop ? 'Nueva Noticia' : 'Crear',
                      icon: Icons.add_circle,
                      backgroundColor: WessexColors.crimsonAlert,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 16,
                        vertical: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: WessexColors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cargando noticias...',
                            style: TextStyle(
                              color: WessexColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _noticias.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 80,
                            color: WessexColors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay noticias registradas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: WessexColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega la primera noticia para comenzar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: WessexColors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _noticias.length,
                      itemBuilder:
                          (context, index) =>
                              _buildNoticiaCard(_noticias[index], isDesktop, isTablet),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticiaCard(NoticiaModel noticia, bool isDesktop, bool isTablet) {
    return WessexCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen destacada
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(
                      noticia.imagen.isNotEmpty && !noticia.imagen.contains('placeholder')
                          ? noticia.imagen
                          : 'https://via.placeholder.com/400x200/090976/FFFFFF?text=Sin+Imagen',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Overlay oscuro para mejor legibilidad
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Badges superiores
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    _buildEstadoChip(noticia.estado),
                    if (noticia.destacada) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: WessexColors.goldenYellow,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: WessexColors.deepNavyBlue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'DESTACADA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.deepNavyBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // Contenido de la tarjeta
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    noticia.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.darkGrape,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Descripción
                  Expanded(
                    child: Text(
                      noticia.descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        color: WessexColors.darkGrape.withOpacity(0.7),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Acciones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(
                        icon: noticia.destacada ? Icons.star : Icons.star_border,
                        color: noticia.destacada ? WessexColors.goldenYellow : Colors.grey,
                        onTap: () => _toggleDestacada(noticia),
                        tooltip: 'Destacar',
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.edit,
                        color: WessexColors.deepRoyalBlue,
                        onTap: () => _showEditDialog(noticia),
                        tooltip: 'Editar',
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete,
                        color: WessexColors.crimsonAlert,
                        onTap: () => _confirmDelete(noticia),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    final bool isPublicada = estado == 'publicada';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPublicada ? WessexColors.leafGreen : WessexColors.ashGray,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublicada ? Icons.check_circle : Icons.schedule,
            size: 14,
            color: WessexColors.white,
          ),
          const SizedBox(width: 4),
          Text(
            estado.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: WessexColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDestacada(NoticiaModel noticia) async {
    try {
      final response = await ApiService.patch(
        '/noticias/${noticia.id}/destacada',
        {},
      );
      if (response.success) _loadNoticias();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmDelete(NoticiaModel noticia) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text('¿Eliminar "${noticia.titulo}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.delete('/noticias/${noticia.id}');
        if (response.success) _loadNoticias();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showCreateDialog() => _showNoticiaDialog();
  void _showEditDialog(NoticiaModel noticia) =>
      _showNoticiaDialog(noticia: noticia);

  void _showNoticiaDialog({NoticiaModel? noticia}) {
    showDialog(
      context: context,
      builder:
          (context) => _NoticiaDialog(
            noticia: noticia,
            onSaved: () {
              _loadNoticias();
            },
          ),
    );
  }
}

class _NoticiaDialog extends StatefulWidget {
  final NoticiaModel? noticia;
  final VoidCallback onSaved;

  const _NoticiaDialog({this.noticia, required this.onSaved});

  @override
  State<_NoticiaDialog> createState() => _NoticiaDialogState();
}

class _NoticiaDialogState extends State<_NoticiaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  bool _isLoading = false;
  String? _imagenUrl;
  String? _imagenNombre;
  Uint8List? _imagenBytes;

  @override
  void initState() {
    super.initState();
    if (widget.noticia != null) {
      _tituloController.text = widget.noticia!.titulo;
      _descripcionController.text = widget.noticia!.descripcion;
      _imagenUrl =
          widget.noticia!.imagen.isNotEmpty ? widget.noticia!.imagen : null;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imagenUrl = _imagenUrl ?? 'https://via.placeholder.com/400x200';

      // Si hay una imagen seleccionada, subirla primero
      if (_imagenBytes != null && _imagenNombre != null) {
        print('🔍 DEBUG - Subiendo imagen: $_imagenNombre');
        final uploadResponse = await _uploadImage(
          _imagenBytes!,
          _imagenNombre!,
        );
        if (uploadResponse != null) {
          imagenUrl = uploadResponse;
          print('✅ DEBUG - Imagen subida exitosamente: $imagenUrl');
        } else {
          print('❌ DEBUG - Error subiendo imagen, usando placeholder');
        }
      }

      final noticiaData = {
        'titulo': _tituloController.text,
        'descripcion': _descripcionController.text,
        'imagen': imagenUrl,
        'estado': 'publicada',
        'fechaPublicacion':
            DateTime.now().toIso8601String().split(
              'T',
            )[0], // Solo la fecha YYYY-MM-DD
      };

      ApiResponse response;
      if (widget.noticia != null) {
        response = await ApiService.put(
          '/noticias/${widget.noticia!.id}',
          noticiaData,
        );
      } else {
        // No agregamos orden, el backend usará el valor por defecto (0)
        response = await ApiService.post('/noticias', noticiaData);
      }

      if (response.success) {
        print('✅ Noticia guardada exitosamente. Response: ${response.data}');
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.noticia != null
                    ? 'Noticia actualizada exitosamente'
                    : 'Noticia creada exitosamente',
              ),
            ),
          );
        }
        Navigator.pop(context);
      } else {
        print(
          '❌ Error guardando noticia. Status: ${response.statusCode}, Message: ${response.message}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${response.message ?? 'Error desconocido'}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Exception en _guardar noticia: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      print('🔍 DEBUG _uploadImage - Iniciando subida de imagen: $fileName');

      // Convertir bytes a base64
      final base64Image = base64Encode(imageBytes);

      // Determinar MIME type basado en la extensión
      final extension = fileName.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // por defecto
      }

      // Preparar datos para el backend
      final uploadData = {
        'filename': fileName,
        'fileData': base64Image,
        'mimeType': mimeType,
      };

      print('🔍 DEBUG _uploadImage - Enviando POST a /upload/imagen');
      print(
        '🔍 DEBUG _uploadImage - Datos: filename=$fileName, mimeType=$mimeType, dataSize=${base64Image.length}',
      );

      final response = await ApiService.post('/upload/imagen', uploadData);

      print('🔍 DEBUG _uploadImage - Response success: ${response.success}');
      print('🔍 DEBUG _uploadImage - Response data: ${response.data}');

      if (response.success && response.data != null) {
        // El backend devuelve { success: true, data: { url: "...", filename: "..." } }
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          final dataMap = responseData['data'] as Map<String, dynamic>;
          final imageUrl = dataMap['url'] as String?;
          if (imageUrl != null) {
            // Convertir URL relativa a absoluta
            final fullUrl =
                '${ApiService.baseUrl.replaceAll('/api', '')}$imageUrl';
            print('✅ DEBUG _uploadImage - URL completa: $fullUrl');
            return fullUrl;
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ ERROR _uploadImage - Exception: $e');
      return null;
    }
  }

  Future<void> _pickImageFile() async {
    try {
      if (kIsWeb) {
        // Para Web: usar html input file como en vouchers
        final html.FileUploadInputElement uploadInput =
            html.FileUploadInputElement();
        uploadInput.accept = 'image/*';
        uploadInput.click();

        uploadInput.onChange.listen((event) async {
          final files = uploadInput.files;
          if (files!.isNotEmpty) {
            final file = files[0];
            final reader = html.FileReader();

            reader.readAsArrayBuffer(file);
            reader.onLoadEnd.listen((event) {
              setState(() {
                _imagenBytes = reader.result as Uint8List;
                _imagenNombre = file.name;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Imagen seleccionada: ${file.name}'),
                  backgroundColor: WessexColors.leafGreen,
                ),
              );
            });
          }
        });
      } else {
        // Para móvil: implementación básica
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidad disponible solo en web por ahora'),
          ),
        );
      }
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar archivo: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.noticia == null ? 'Crear Noticia' : 'Editar Noticia'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value?.trim().isEmpty == true
                            ? 'El título es obligatorio'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator:
                    (value) =>
                        value?.trim().isEmpty == true
                            ? 'La descripción es obligatoria'
                            : null,
              ),
              const SizedBox(height: 16),

              // Sección de imagen
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Imagen', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),

                    // Botón de seleccionar archivo como vouchers
                    InkWell(
                      onTap: _pickImageFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                _imagenBytes != null
                                    ? WessexColors.leafGreen
                                    : WessexColors.darkGrape.withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color:
                              _imagenBytes != null
                                  ? WessexColors.leafGreen.withOpacity(0.05)
                                  : Colors.transparent,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _imagenBytes != null
                                  ? Icons.check_circle
                                  : Icons.cloud_upload,
                              color:
                                  _imagenBytes != null
                                      ? WessexColors.leafGreen
                                      : WessexColors.darkGrape.withOpacity(0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _imagenNombre ?? 'Toca para seleccionar imagen',
                              style: TextStyle(
                                color:
                                    _imagenBytes != null
                                        ? WessexColors.leafGreen
                                        : WessexColors.darkGrape.withOpacity(
                                          0.7,
                                        ),
                                fontSize: 16,
                                fontWeight:
                                    _imagenBytes != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_imagenBytes == null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Formatos permitidos: PNG, JPG, JPEG',
                                style: TextStyle(
                                  color: WessexColors.darkGrape.withOpacity(
                                    0.6,
                                  ),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (_imagenBytes != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: WessexColors.leafGreen.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: WessexColors.leafGreen.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: WessexColors.leafGreen,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _imagenNombre!,
                                        style: TextStyle(
                                          color: WessexColors.darkGrape,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Preview de la imagen
                    if (_imagenBytes != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: WessexColors.leafGreen),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _imagenBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error,
                                      color: WessexColors.crimsonAlert,
                                    ),
                                    Text('Error al cargar imagen'),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.noticia == null ? 'Crear' : 'Actualizar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}

// Tab de Auspiciadores
class _AuspiciadoresTab extends StatefulWidget {
  const _AuspiciadoresTab();

  @override
  State<_AuspiciadoresTab> createState() => _AuspiciadoresTabState();
}

class _AuspiciadoresTabState extends State<_AuspiciadoresTab> {
  List<AuspiciadorModel> _auspiciadores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuspiciadores();
  }

  Future<void> _loadAuspiciadores() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/auspiciadores');
      if (response.success && response.data != null) {
        // El backend devuelve {success: true, message: "...", data: [...]}
        final List<dynamic> auspiciadoresData =
            response.data is Map
                ? (response.data['data'] as List? ?? [])
                : (response.data is List ? response.data as List : []);

        setState(() {
          _auspiciadores =
              auspiciadoresData
                  .map((json) => AuspiciadorModel.fromJson(json))
                  .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar auspiciadores: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
    
    return SafeArea(
      child: Column(
        children: [
          // Header mejorado
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WessexColors.deepRoyalBlue,
                  WessexColors.midnightNavy,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: WessexColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.business,
                                  color: WessexColors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Gestión de Auspiciadores',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: WessexColors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_auspiciadores.length} auspiciadores activos',
                            style: TextStyle(
                              fontSize: 14,
                              color: WessexColors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    WessexButton(
                      onPressed: _showCreateDialog,
                      text: isDesktop ? 'Nuevo Auspiciador' : 'Crear',
                      icon: Icons.add_circle,
                      backgroundColor: WessexColors.crimsonAlert,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 16,
                        vertical: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: WessexColors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cargando auspiciadores...',
                            style: TextStyle(
                              color: WessexColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _auspiciadores.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 80,
                            color: WessexColors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay auspiciadores registrados',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: WessexColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega el primer auspiciador para comenzar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: WessexColors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: _auspiciadores.length,
                      itemBuilder: (context, index) => _buildAuspiciadorCard(
                        _auspiciadores[index],
                        isDesktop,
                        isTablet,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuspiciadorCard(
    AuspiciadorModel auspiciador,
    bool isDesktop,
    bool isTablet,
  ) {
    return WessexCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del auspiciador
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              color: Colors.white,
              image: DecorationImage(
                image: NetworkImage(
                  auspiciador.imagen.isNotEmpty && !auspiciador.imagen.contains('placeholder')
                      ? auspiciador.imagen
                      : 'https://via.placeholder.com/400x200/FFFFFF/090976?text=Logo',
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Contenido de la tarjeta
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    auspiciador.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.darkGrape,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Enlace
                  if (auspiciador.enlace != null && auspiciador.enlace!.isNotEmpty)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 14,
                            color: WessexColors.deepRoyalBlue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              auspiciador.enlace!,
                              style: TextStyle(
                                fontSize: 12,
                                color: WessexColors.deepRoyalBlue,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        'Sin enlace web',
                        style: TextStyle(
                          fontSize: 12,
                          color: WessexColors.darkGrape.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Acciones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildAuspiciadorActionButton(
                        icon: Icons.edit,
                        color: WessexColors.deepRoyalBlue,
                        onTap: () => _showEditDialog(auspiciador),
                        tooltip: 'Editar',
                      ),
                      const SizedBox(width: 8),
                      _buildAuspiciadorActionButton(
                        icon: Icons.delete,
                        color: WessexColors.crimsonAlert,
                        onTap: () => _deleteAuspiciador(auspiciador.id),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuspiciadorActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAuspiciador(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text(
              '¿Estás seguro de que quieres eliminar este auspiciador?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.delete('/auspiciadores/$id');
        if (response.success) {
          await _loadAuspiciadores();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Auspiciador eliminado exitosamente'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  void _showCreateDialog() => _showAuspiciadorDialog();
  void _showEditDialog(AuspiciadorModel auspiciador) =>
      _showAuspiciadorDialog(auspiciador: auspiciador);

  void _showAuspiciadorDialog({AuspiciadorModel? auspiciador}) {
    showDialog(
      context: context,
      builder:
          (context) => _AuspiciadorDialog(
            auspiciador: auspiciador,
            onSaved: () {
              _loadAuspiciadores();
            },
          ),
    );
  }
}

class _AuspiciadorDialog extends StatefulWidget {
  final AuspiciadorModel? auspiciador;
  final VoidCallback onSaved;

  const _AuspiciadorDialog({this.auspiciador, required this.onSaved});

  @override
  State<_AuspiciadorDialog> createState() => _AuspiciadorDialogState();
}

class _AuspiciadorDialogState extends State<_AuspiciadorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _enlaceController = TextEditingController();

  String? _imagenNombre;
  Uint8List? _imagenBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.auspiciador != null) {
      _tituloController.text = widget.auspiciador!.titulo;
      _enlaceController.text = widget.auspiciador!.enlace ?? '';
    }
  }

  Future<String?> _uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      print(
        '🔍 DEBUG _uploadImage Auspiciador - Iniciando subida de imagen: $fileName',
      );

      // Convertir bytes a base64
      final base64Image = base64Encode(imageBytes);

      // Determinar MIME type basado en la extensión
      final extension = fileName.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // por defecto
      }

      // Preparar datos para el backend
      final uploadData = {
        'filename': fileName,
        'fileData': base64Image,
        'mimeType': mimeType,
      };

      print(
        '🔍 DEBUG _uploadImage Auspiciador - Enviando POST a /upload/imagen',
      );

      final response = await ApiService.post('/upload/imagen', uploadData);

      print(
        '🔍 DEBUG _uploadImage Auspiciador - Response success: ${response.success}',
      );

      if (response.success && response.data != null) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          final dataMap = responseData['data'] as Map<String, dynamic>;
          final imageUrl = dataMap['url'] as String?;
          if (imageUrl != null) {
            // Convertir URL relativa a absoluta
            final fullUrl =
                '${ApiService.baseUrl.replaceAll('/api', '')}$imageUrl';
            print('✅ DEBUG _uploadImage Auspiciador - URL completa: $fullUrl');
            return fullUrl;
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ ERROR _uploadImage Auspiciador - Exception: $e');
      return null;
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      if (kIsWeb) {
        // Para Web: usar html input file como en vouchers
        final html.FileUploadInputElement uploadInput =
            html.FileUploadInputElement();
        uploadInput.accept = 'image/*';
        uploadInput.click();

        uploadInput.onChange.listen((event) async {
          final files = uploadInput.files;
          if (files!.isNotEmpty) {
            final file = files[0];
            final reader = html.FileReader();

            reader.readAsArrayBuffer(file);
            reader.onLoadEnd.listen((event) {
              setState(() {
                _imagenBytes = reader.result as Uint8List;
                _imagenNombre = file.name;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Imagen seleccionada: ${file.name}'),
                  backgroundColor: WessexColors.leafGreen,
                ),
              );
            });
          }
        });
      } else {
        // Para móvil: implementación básica
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidad disponible solo en web por ahora'),
          ),
        );
      }
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar archivo: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imagenUrl =
          widget.auspiciador?.imagen ??
          'https://via.placeholder.com/200x200?text=Logo';

      // Si hay una imagen seleccionada, subirla primero
      if (_imagenBytes != null && _imagenNombre != null) {
        print('🔍 DEBUG - Subiendo imagen auspiciador: $_imagenNombre');
        final uploadResponse = await _uploadImage(
          _imagenBytes!,
          _imagenNombre!,
        );
        if (uploadResponse != null) {
          imagenUrl = uploadResponse;
          print('✅ DEBUG - Imagen auspiciador subida exitosamente: $imagenUrl');
        } else {
          print(
            '❌ DEBUG - Error subiendo imagen auspiciador, usando placeholder',
          );
        }
      }

      final auspiciadorData = {
        'titulo': _tituloController.text.trim(),
        'imagen': imagenUrl,
        'enlace':
            _enlaceController.text.isEmpty
                ? null
                : _enlaceController.text.trim(),
        'estado': 'activo', // Usar 'activo' en lugar de 'publicado'
        // No agregamos orden, el backend usará el valor por defecto (0)
      };

      ApiResponse response;
      if (widget.auspiciador != null) {
        response = await ApiService.put(
          '/auspiciadores/${widget.auspiciador!.id}',
          auspiciadorData,
        );
      } else {
        response = await ApiService.post('/auspiciadores', auspiciadorData);
      }

      if (response.success) {
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.auspiciador != null
                    ? 'Auspiciador actualizado exitosamente'
                    : 'Auspiciador creado exitosamente',
              ),
            ),
          );
        }
        Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.auspiciador != null ? 'Editar Auspiciador' : 'Nuevo Auspiciador',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Auspiciador *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selección de imagen
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Logo del Auspiciador'),
                  const SizedBox(height: 8),

                  // Botón de seleccionar archivo como vouchers
                  InkWell(
                    onTap: _seleccionarImagen,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _imagenBytes != null
                                  ? WessexColors.leafGreen
                                  : WessexColors.darkGrape.withOpacity(0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color:
                            _imagenBytes != null
                                ? WessexColors.leafGreen.withOpacity(0.05)
                                : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _imagenBytes != null
                                ? Icons.check_circle
                                : Icons.cloud_upload,
                            color:
                                _imagenBytes != null
                                    ? WessexColors.leafGreen
                                    : WessexColors.darkGrape.withOpacity(0.5),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _imagenNombre ?? 'Toca para seleccionar logo',
                            style: TextStyle(
                              color:
                                  _imagenBytes != null
                                      ? WessexColors.leafGreen
                                      : WessexColors.darkGrape.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight:
                                  _imagenBytes != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_imagenBytes == null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Formatos permitidos: PNG, JPG, JPEG',
                              style: TextStyle(
                                color: WessexColors.darkGrape.withOpacity(0.6),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (_imagenBytes != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: WessexColors.leafGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: WessexColors.leafGreen.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: WessexColors.leafGreen,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _imagenNombre!,
                                      style: TextStyle(
                                        color: WessexColors.darkGrape,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Preview de la imagen
                  if (_imagenBytes != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: WessexColors.leafGreen),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _imagenBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: WessexColors.crimsonAlert,
                                  ),
                                  Text('Error al cargar imagen'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _enlaceController,
                decoration: const InputDecoration(
                  labelText: 'Sitio Web (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: WessexColors.deepRoyalBlue,
            foregroundColor: Colors.white,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(widget.auspiciador != null ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _enlaceController.dispose();
    super.dispose();
  }
}

// Tab de Merchandising
class _MerchandisingTab extends StatefulWidget {
  const _MerchandisingTab();

  @override
  State<_MerchandisingTab> createState() => _MerchandisingTabState();
}

class _MerchandisingTabState extends State<_MerchandisingTab> {
  List<MerchandisingModel> _productos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 DEBUG _loadProductos - Cargando merchandising');
      final response = await ApiService.get('/merchandising');
      print('🔍 DEBUG _loadProductos - Response success: ${response.success}');

      if (response.success && response.data != null) {
        // El backend devuelve {success: true, message: "...", data: [...]}
        final List<dynamic> productosData =
            response.data is Map
                ? (response.data['data'] as List? ?? [])
                : (response.data is List ? response.data as List : []);

        print(
          '🔍 DEBUG _loadProductos - Productos count: ${productosData.length}',
        );

        setState(() {
          _productos =
              productosData.map((json) {
                try {
                  print(
                    '🔍 DEBUG _loadProductos - Parseando producto: ${json['titulo']}, precio: ${json['precio']} (${json['precio'].runtimeType})',
                  );
                  return MerchandisingModel.fromJson(json);
                } catch (e) {
                  print(
                    '❌ ERROR _loadProductos - Error parseando producto ${json['titulo']}: $e',
                  );
                  rethrow;
                }
              }).toList();
        });

        print(
          '✅ DEBUG _loadProductos - _productos final count: ${_productos.length}',
        );
      }
    } catch (e) {
      print('❌ ERROR _loadProductos - Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar productos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
    
    return SafeArea(
      child: Column(
        children: [
          // Header mejorado
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WessexColors.deepRoyalBlue,
                  WessexColors.midnightNavy,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: WessexColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: WessexColors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Gestión de Merchandising',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: WessexColors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_productos.length} productos en tienda',
                            style: TextStyle(
                              fontSize: 14,
                              color: WessexColors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    WessexButton(
                      onPressed: _showCreateDialog,
                      text: isDesktop ? 'Nuevo Producto' : 'Crear',
                      icon: Icons.add_circle,
                      backgroundColor: WessexColors.crimsonAlert,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 16,
                        vertical: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: WessexColors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cargando productos...',
                            style: TextStyle(
                              color: WessexColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _productos.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 80,
                            color: WessexColors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay productos registrados',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: WessexColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega el primer producto para comenzar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: WessexColors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _productos.length,
                      itemBuilder: (context, index) => _buildProductoCard(
                        _productos[index],
                        isDesktop,
                        isTablet,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(
    MerchandisingModel producto,
    bool isDesktop,
    bool isTablet,
  ) {
    return WessexCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(
                      producto.imagen.isNotEmpty && !producto.imagen.contains('placeholder')
                          ? producto.imagen
                          : 'https://via.placeholder.com/400x400/090976/FFFFFF?text=Producto',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Badge de precio
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: WessexColors.leafGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '\$${producto.precio.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: WessexColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Contenido de la tarjeta
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    producto.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: WessexColors.darkGrape,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Descripción
                  if (producto.descripcion != null && producto.descripcion!.isNotEmpty)
                    Expanded(
                      child: Text(
                        producto.descripcion!,
                        style: TextStyle(
                          fontSize: 13,
                          color: WessexColors.darkGrape.withOpacity(0.7),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        'Sin descripción',
                        style: TextStyle(
                          fontSize: 13,
                          color: WessexColors.darkGrape.withOpacity(0.4),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Acciones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildProductoActionButton(
                        icon: Icons.edit,
                        color: WessexColors.deepRoyalBlue,
                        onTap: () => _showEditDialog(producto),
                        tooltip: 'Editar',
                      ),
                      const SizedBox(width: 8),
                      _buildProductoActionButton(
                        icon: Icons.delete,
                        color: WessexColors.crimsonAlert,
                        onTap: () => _deleteProducto(producto.id),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProducto(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text(
              '¿Estás seguro de que quieres eliminar este producto?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.delete('/merchandising/$id');
        if (response.success) {
          await _loadProductos();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Producto eliminado exitosamente')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  void _showCreateDialog() => _showMerchandisingDialog();
  void _showEditDialog(MerchandisingModel producto) =>
      _showMerchandisingDialog(producto: producto);

  void _showMerchandisingDialog({MerchandisingModel? producto}) {
    showDialog(
      context: context,
      builder:
          (context) => _MerchandisingDialog(
            producto: producto,
            onSaved: () {
              _loadProductos();
            },
          ),
    );
  }
}

class _MerchandisingDialog extends StatefulWidget {
  final MerchandisingModel? producto;
  final VoidCallback onSaved;

  const _MerchandisingDialog({this.producto, required this.onSaved});

  @override
  State<_MerchandisingDialog> createState() => _MerchandisingDialogState();
}

class _MerchandisingDialogState extends State<_MerchandisingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();

  String? _imagenNombre;
  Uint8List? _imagenBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.producto != null) {
      _tituloController.text = widget.producto!.titulo;
      _descripcionController.text = widget.producto!.descripcion ?? '';
      _precioController.text = widget.producto!.precio.toString();
    }
  }

  Future<String?> _uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      print(
        '🔍 DEBUG _uploadImage Merchandising - Iniciando subida de imagen: $fileName',
      );

      // Convertir bytes a base64
      final base64Image = base64Encode(imageBytes);

      // Determinar MIME type basado en la extensión
      final extension = fileName.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // por defecto
      }

      // Preparar datos para el backend
      final uploadData = {
        'filename': fileName,
        'fileData': base64Image,
        'mimeType': mimeType,
      };

      print(
        '🔍 DEBUG _uploadImage Merchandising - Enviando POST a /upload/imagen',
      );

      final response = await ApiService.post('/upload/imagen', uploadData);

      print(
        '🔍 DEBUG _uploadImage Merchandising - Response success: ${response.success}',
      );

      if (response.success && response.data != null) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          final dataMap = responseData['data'] as Map<String, dynamic>;
          final imageUrl = dataMap['url'] as String?;
          if (imageUrl != null) {
            // Convertir URL relativa a absoluta
            final fullUrl =
                '${ApiService.baseUrl.replaceAll('/api', '')}$imageUrl';
            print(
              '✅ DEBUG _uploadImage Merchandising - URL completa: $fullUrl',
            );
            return fullUrl;
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ ERROR _uploadImage Merchandising - Exception: $e');
      return null;
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      if (kIsWeb) {
        // Para Web: usar html input file como en vouchers
        final html.FileUploadInputElement uploadInput =
            html.FileUploadInputElement();
        uploadInput.accept = 'image/*';
        uploadInput.click();

        uploadInput.onChange.listen((event) async {
          final files = uploadInput.files;
          if (files!.isNotEmpty) {
            final file = files[0];
            final reader = html.FileReader();

            reader.readAsArrayBuffer(file);
            reader.onLoadEnd.listen((event) {
              setState(() {
                _imagenBytes = reader.result as Uint8List;
                _imagenNombre = file.name;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Imagen seleccionada: ${file.name}'),
                  backgroundColor: WessexColors.leafGreen,
                ),
              );
            });
          }
        });
      } else {
        // Para móvil: implementación básica
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidad disponible solo en web por ahora'),
          ),
        );
      }
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar archivo: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final precio = double.tryParse(_precioController.text);

      String imagenUrl =
          widget.producto?.imagen ??
          'https://via.placeholder.com/300x300?text=Producto';

      // Si hay una imagen seleccionada, subirla primero
      if (_imagenBytes != null && _imagenNombre != null) {
        print('🔍 DEBUG - Subiendo imagen merchandising: $_imagenNombre');
        final uploadResponse = await _uploadImage(
          _imagenBytes!,
          _imagenNombre!,
        );
        if (uploadResponse != null) {
          imagenUrl = uploadResponse;
          print(
            '✅ DEBUG - Imagen merchandising subida exitosamente: $imagenUrl',
          );
        } else {
          print(
            '❌ DEBUG - Error subiendo imagen merchandising, usando placeholder',
          );
        }
      }

      final productoData = {
        'titulo': _tituloController.text.trim(),
        'descripcion':
            _descripcionController.text.isEmpty
                ? null
                : _descripcionController.text.trim(),
        'precio': precio,
        'imagen': imagenUrl,
        'estado': 'activo', // Usar 'activo' en lugar de 'publicado'
        // No agregamos orden, el backend usará el valor por defecto (0)
      };

      ApiResponse response;
      if (widget.producto != null) {
        response = await ApiService.put(
          '/merchandising/${widget.producto!.id}',
          productoData,
        );
      } else {
        response = await ApiService.post('/merchandising', productoData);
      }

      if (response.success) {
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.producto != null
                    ? 'Producto actualizado exitosamente'
                    : 'Producto creado exitosamente',
              ),
            ),
          );
        }
        Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.producto != null ? 'Editar Producto' : 'Nuevo Producto',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio *',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El precio es obligatorio';
                  }
                  final precio = double.tryParse(value);
                  if (precio == null || precio < 0) {
                    return 'Ingresa un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selección de imagen
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Imagen del Producto'),
                  const SizedBox(height: 8),

                  // Botón de seleccionar archivo como vouchers
                  InkWell(
                    onTap: _seleccionarImagen,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _imagenBytes != null
                                  ? WessexColors.leafGreen
                                  : WessexColors.darkGrape.withOpacity(0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color:
                            _imagenBytes != null
                                ? WessexColors.leafGreen.withOpacity(0.05)
                                : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _imagenBytes != null
                                ? Icons.check_circle
                                : Icons.cloud_upload,
                            color:
                                _imagenBytes != null
                                    ? WessexColors.leafGreen
                                    : WessexColors.darkGrape.withOpacity(0.5),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _imagenNombre ?? 'Toca para seleccionar imagen',
                            style: TextStyle(
                              color:
                                  _imagenBytes != null
                                      ? WessexColors.leafGreen
                                      : WessexColors.darkGrape.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight:
                                  _imagenBytes != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_imagenBytes == null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Formatos permitidos: PNG, JPG, JPEG',
                              style: TextStyle(
                                color: WessexColors.darkGrape.withOpacity(0.6),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (_imagenBytes != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: WessexColors.leafGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: WessexColors.leafGreen.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: WessexColors.leafGreen,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _imagenNombre!,
                                      style: TextStyle(
                                        color: WessexColors.darkGrape,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Preview de la imagen
                  if (_imagenBytes != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: WessexColors.leafGreen),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _imagenBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: WessexColors.crimsonAlert,
                                  ),
                                  Text('Error al cargar imagen'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: WessexColors.deepRoyalBlue,
            foregroundColor: Colors.white,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(widget.producto != null ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }
}

// Tab de Información del Club
class _InformacionClubTab extends StatefulWidget {
  const _InformacionClubTab();

  @override
  State<_InformacionClubTab> createState() => _InformacionClubTabState();
}

class _InformacionClubTabState extends State<_InformacionClubTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Controladores de texto
  final _nombreController = TextEditingController();
  final _misionController = TextEditingController();
  final _visionController = TextEditingController();
  final _historiaController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarInformacion();
  }

  Future<void> _cargarInformacion() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/club/informacion');
      print('📥 DEBUG _cargarInformacion - Response: ${response.success}, data: ${response.data}');
      
      if (response.success && response.data != null) {
        // El backend devuelve: { status: "success", message: "...", data: {...} }
        final data = response.data is Map && response.data.containsKey('data') 
            ? response.data['data'] 
            : response.data;
        
        print('📝 DEBUG _cargarInformacion - Extracted data: $data');
        
        if (data != null && data is Map) {
          setState(() {
            _nombreController.text = data['nombre'] ?? 'Wessex Rugby Club';
            _misionController.text = data['mision'] ?? '';
            _visionController.text = data['vision'] ?? '';
            _historiaController.text = data['historia'] ?? '';
            _direccionController.text = data['direccion'] ?? '';
            _telefonoController.text = data['telefono'] ?? '';
            _emailController.text = data['email'] ?? '';
            _facebookController.text = data['facebook'] ?? '';
            _instagramController.text = data['instagram'] ?? '';
            _twitterController.text = data['twitter'] ?? '';
            _websiteController.text = data['website'] ?? '';
          });
          print('✅ DEBUG _cargarInformacion - Datos cargados exitosamente');
        }
      } else {
        print('⚠️ DEBUG _cargarInformacion - Response no exitoso o sin data');
        // Solo cargar valores por defecto si los controladores están vacíos
        if (_nombreController.text.isEmpty) {
          setState(() {
            _nombreController.text = 'Wessex Rugby Club';
          });
        }
      }
    } catch (e) {
      print('❌ ERROR _cargarInformacion - Exception: $e');
      // Solo establecer valores por defecto si los campos están vacíos
      if (_nombreController.text.isEmpty) {
        setState(() {
          _nombreController.text = 'Wessex Rugby Club';
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _guardarInformacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'nombre': _nombreController.text.trim(),
        'mision': _misionController.text.trim(),
        'vision': _visionController.text.trim(),
        'historia': _historiaController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'email': _emailController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'twitter': _twitterController.text.trim(),
        'website': _websiteController.text.trim(),
      };

      final response = await ApiService.post('/club/informacion', data);
      if (response.success) {
        // Recargar los datos actualizados del servidor
        await _cargarInformacion();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Información guardada exitosamente'),
              backgroundColor: WessexColors.leafGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.message ?? "No se pudo guardar"}'),
              backgroundColor: WessexColors.crimsonAlert,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: WessexColors.crimsonAlert,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WessexColors.deepRoyalBlue,
                  WessexColors.midnightNavy,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: WessexColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info,
                          color: WessexColors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información del Club',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: WessexColors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gestiona los datos públicos del club',
                              style: TextStyle(
                                fontSize: 14,
                                color: WessexColors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                WessexButton(
                  onPressed: _isSaving ? null : _guardarInformacion,
                  text: isDesktop ? 'Guardar Cambios' : 'Guardar',
                  icon: Icons.save,
                  backgroundColor: WessexColors.leafGreen,
                  isLoading: _isSaving,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: 14,
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: WessexColors.white,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Cargando información...',
                          style: TextStyle(
                            color: WessexColors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Información General
                          _buildSectionCard(
                            title: 'Información General',
                            icon: Icons.business,
                            color: WessexColors.deepRoyalBlue,
                            children: [
                              _buildTextField(
                                controller: _nombreController,
                                label: 'Nombre del Club',
                                icon: Icons.sports_rugby,
                                validator: (value) =>
                                    value?.isEmpty == true
                                        ? 'El nombre es obligatorio'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _misionController,
                                label: 'Misión',
                                icon: Icons.flag,
                                maxLines: 4,
                                hint: 'Describe la misión del club...',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _visionController,
                                label: 'Visión',
                                icon: Icons.visibility,
                                maxLines: 4,
                                hint: 'Describe la visión del club...',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _historiaController,
                                label: 'Historia',
                                icon: Icons.history_edu,
                                maxLines: 6,
                                hint: 'Cuenta la historia del club...',
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),

                          // Información de Contacto
                          _buildSectionCard(
                            title: 'Datos de Contacto',
                            icon: Icons.contact_mail,
                            color: WessexColors.leafGreen,
                            children: [
                              _buildTextField(
                                controller: _direccionController,
                                label: 'Dirección',
                                icon: Icons.location_on,
                                hint: 'Dirección física del club',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _telefonoController,
                                label: 'Teléfono',
                                icon: Icons.phone,
                                hint: '+56 9 1234 5678',
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email,
                                hint: 'contacto@wessexrugby.cl',
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Redes Sociales
                          _buildSectionCard(
                            title: 'Redes Sociales y Web',
                            icon: Icons.share,
                            color: WessexColors.goldenYellow,
                            children: [
                              _buildTextField(
                                controller: _websiteController,
                                label: 'Sitio Web',
                                icon: Icons.language,
                                hint: 'https://www.wessexrugby.cl',
                                keyboardType: TextInputType.url,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _facebookController,
                                label: 'Facebook',
                                icon: Icons.facebook,
                                hint: 'https://facebook.com/wessexrugby',
                                keyboardType: TextInputType.url,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _instagramController,
                                label: 'Instagram',
                                icon: Icons.camera_alt,
                                hint: '@wessexrugby',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _twitterController,
                                label: 'Twitter / X',
                                icon: Icons.chat,
                                hint: '@wessexrugby',
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return WessexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: WessexColors.darkGrape,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: WessexColors.deepRoyalBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: WessexColors.deepRoyalBlue,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _misionController.dispose();
    _visionController.dispose();
    _historiaController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _websiteController.dispose();
    super.dispose();
  }
}
