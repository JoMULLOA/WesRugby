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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                WessexColors.deepRoyalBlue.withOpacity(0.9),
                WessexColors.darkGrape.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WessexColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isDesktop ? 60 : 50),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WessexColors.deepRoyalBlue.withOpacity(0.9),
                  WessexColors.darkGrape.withOpacity(0.9),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
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
                  icon: const Icon(Icons.sports),
                  text: 'Entrenadores',
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
          children: const [
            _NoticiasTab(),
            _AuspiciadoresTab(),
            _MerchandisingTab(),
            _EntrenadoresTab(),
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

// Tab de Entrenadores
class _EntrenadoresTab extends StatelessWidget {
  const _EntrenadoresTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: WessexColors.deepRoyalBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sports,
                        color: WessexColors.deepRoyalBlue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión de Entrenadores',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: WessexColors.deepNavyBlue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Administra la información pública de los entrenadores del club',
                            style: TextStyle(
                              fontSize: 14,
                              color: WessexColors.charcoalGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildEntrenadoresContent(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntrenadoresContent(BuildContext context) {
    // Importar la pantalla de gestión de entrenadores
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const _EntrenadoresManagementWidget(),
        );
      },
    );
  }
}

// Widget interno para la gestión de entrenadores
class _EntrenadoresManagementWidget extends StatefulWidget {
  const _EntrenadoresManagementWidget();

  @override
  State<_EntrenadoresManagementWidget> createState() =>
      _EntrenadoresManagementWidgetState();
}

class _EntrenadoresManagementWidgetState
    extends State<_EntrenadoresManagementWidget> {
  List<Map<String, dynamic>> _entrenadores = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarEntrenadores();
  }

  Future<void> _cargarEntrenadores() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/entrenadores/gestion');
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data is Map
            ? (response.data['data'] as List? ?? [])
            : (response.data is List ? response.data : []);

        setState(() {
          _entrenadores = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      _mostrarError('Error al cargar entrenadores: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: WessexColors.crimsonAlert,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: WessexColors.leafGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entrenadores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports, size: 64, color: WessexColors.ashGray),
            const SizedBox(height: 16),
            const Text(
              'No hay entrenadores registrados',
              style: TextStyle(
                fontSize: 16,
                color: WessexColors.charcoalGray,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _entrenadores.length,
      itemBuilder: (context, index) {
        return _buildEntrenadorCard(_entrenadores[index]);
      },
    );
  }

  Widget _buildEntrenadorCard(Map<String, dynamic> entrenador) {
    final bool tienePerfil = entrenador['tienePerfil'] == true;
    final Map<String, dynamic>? perfil = entrenador['perfilPublico'];
    final bool visible = perfil?['visible'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: WessexColors.deepRoyalBlue,
          child: Text(
            (entrenador['nombreCompleto'] ?? 'N')[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(entrenador['nombreCompleto'] ?? 'Sin nombre'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entrenador['email'] ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tienePerfil
                        ? WessexColors.leafGreen.withOpacity(0.1)
                        : WessexColors.ashGray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tienePerfil ? 'CON PERFIL' : 'SIN PERFIL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tienePerfil
                          ? WessexColors.leafGreen
                          : WessexColors.ashGray,
                    ),
                  ),
                ),
                if (tienePerfil) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: visible
                          ? WessexColors.deepRoyalBlue.withOpacity(0.1)
                          : WessexColors.crimsonAlert.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      visible ? 'VISIBLE' : 'OCULTO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: visible
                            ? WessexColors.deepRoyalBlue
                            : WessexColors.crimsonAlert,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tienePerfil)
              IconButton(
                icon: Icon(
                  visible ? Icons.visibility_off : Icons.visibility,
                  color: WessexColors.deepRoyalBlue,
                ),
                onPressed: () => _toggleVisibilidad(perfil!),
                tooltip: visible ? 'Ocultar' : 'Mostrar',
              ),
            IconButton(
              icon: Icon(
                tienePerfil ? Icons.edit : Icons.add,
                color: WessexColors.leafGreen,
              ),
              onPressed: () => _editarPerfil(entrenador),
              tooltip: tienePerfil ? 'Editar' : 'Crear Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleVisibilidad(Map<String, dynamic> perfil) async {
    try {
      final int id = perfil['id'];
      final bool visible = perfil['visible'] ?? false;

      final response = await ApiService.patch(
        '/entrenadores/$id/visibilidad',
        {'visible': !visible},
      );

      if (response.success) {
        _mostrarExito('Visibilidad actualizada');
        _cargarEntrenadores();
      } else {
        _mostrarError('Error al cambiar visibilidad');
      }
    } catch (e) {
      _mostrarError('Error: $e');
    }
  }

  void _editarPerfil(Map<String, dynamic> entrenador) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FormularioEntrenadorDialog(
          entrenador: entrenador,
          perfilExistente: entrenador['perfilPublico'],
          onGuardado: () {
            _cargarEntrenadores();
            _mostrarExito('Perfil actualizado correctamente');
          },
        ),
      ),
    );
  }
}

// Formulario para editar perfil de entrenador
class _FormularioEntrenadorDialog extends StatefulWidget {
  final Map<String, dynamic> entrenador;
  final Map<String, dynamic>? perfilExistente;
  final VoidCallback onGuardado;

  const _FormularioEntrenadorDialog({
    required this.entrenador,
    this.perfilExistente,
    required this.onGuardado,
  });

  @override
  State<_FormularioEntrenadorDialog> createState() =>
      _FormularioEntrenadorDialogState();
}

class _FormularioEntrenadorDialogState
    extends State<_FormularioEntrenadorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _especialidadController;
  late TextEditingController _aniosExperienciaController;
  late TextEditingController _certificacionesController;
  late TextEditingController _logrosController;
  late TextEditingController _biografiaController;
  late TextEditingController _categoriasController;
  bool _visible = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final perfil = widget.perfilExistente;

    _tituloController = TextEditingController(text: perfil?['titulo'] ?? '');
    _especialidadController =
        TextEditingController(text: perfil?['especialidad'] ?? '');
    _aniosExperienciaController = TextEditingController(
      text: perfil?['aniosExperiencia']?.toString() ?? '',
    );
    _certificacionesController =
        TextEditingController(text: perfil?['certificaciones'] ?? '');
    _logrosController = TextEditingController(text: perfil?['logros'] ?? '');
    _biografiaController =
        TextEditingController(text: perfil?['biografia'] ?? '');
    _categoriasController =
        TextEditingController(text: perfil?['categorias'] ?? '');
    _visible = perfil?['visible'] ?? true;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _especialidadController.dispose();
    _aniosExperienciaController.dispose();
    _certificacionesController.dispose();
    _logrosController.dispose();
    _biografiaController.dispose();
    _categoriasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.perfilExistente == null ? 'Crear Perfil Público' : 'Editar Perfil Público',
        ),
        backgroundColor: WessexColors.deepRoyalBlue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info del entrenador
            Card(
              color: WessexColors.deepRoyalBlue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entrenador',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: WessexColors.charcoalGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.entrenador['nombreCompleto'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: WessexColors.deepNavyBlue,
                      ),
                    ),
                    Text(
                      widget.entrenador['email'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: WessexColors.charcoalGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _tituloController,
              label: 'Título Profesional',
              hint: 'Ej: Entrenador Nivel 1 World Rugby',
              icon: Icons.workspace_premium,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _especialidadController,
              label: 'Especialidad',
              hint: 'Ej: Entrenamiento Físico y Técnico',
              icon: Icons.sports_kabaddi,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _aniosExperienciaController,
              label: 'Años de Experiencia',
              hint: 'Ej: 10',
              icon: Icons.timer,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _categoriasController,
              label: 'Categorías que Entrena',
              hint: 'Ej: sub-8, sub-10, sub-12',
              icon: Icons.groups,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _biografiaController,
              label: 'Biografía',
              hint: 'Describe la trayectoria y experiencia del entrenador...',
              icon: Icons.person,
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _logrosController,
              label: 'Logros Destacados',
              hint: 'Enumera los logros más importantes...',
              icon: Icons.emoji_events,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _certificacionesController,
              label: 'Certificaciones',
              hint: 'Lista certificaciones y cursos relevantes...',
              icon: Icons.school,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            Card(
              child: SwitchListTile(
                title: const Text('Visible públicamente'),
                subtitle: const Text(
                  'El perfil será visible en la página pública de entrenadores',
                ),
                value: _visible,
                onChanged: (value) => setState(() => _visible = value),
                activeColor: WessexColors.leafGreen,
                secondary: Icon(
                  _visible ? Icons.visibility : Icons.visibility_off,
                  color: _visible ? WessexColors.leafGreen : WessexColors.ashGray,
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _guardando ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.leafGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final data = {
        'userRut': widget.entrenador['rut'],
        'titulo': _tituloController.text.trim(),
        'especialidad': _especialidadController.text.trim(),
        'aniosExperiencia': int.tryParse(_aniosExperienciaController.text),
        'certificaciones': _certificacionesController.text.trim(),
        'logros': _logrosController.text.trim(),
        'biografia': _biografiaController.text.trim(),
        'categorias': _categoriasController.text.trim(),
        'visible': _visible,
      };

      final response = widget.perfilExistente == null
          ? await ApiService.post('/entrenadores', data)
          : await ApiService.put(
              '/entrenadores/${widget.perfilExistente!['id']}',
              data,
            );

      if (response.success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onGuardado();
        }
      } else {
        throw Exception(response.message ?? 'Error al guardar');
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
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }
}
