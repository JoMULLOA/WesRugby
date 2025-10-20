import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import '../widgets/wessex_widgets.dart';
import '../config/colors.dart';
import '../services/api_service.dart';
import '../models/noticia_model.dart';
import '../models/auspiciador_model.dart';
import '../models/merchandising_model.dart';

class GestionInformacionPublicaScreen extends StatefulWidget {
  const GestionInformacionPublicaScreen({super.key});

  @override
  State<GestionInformacionPublicaScreen> createState() => _GestionInformacionPublicaScreenState();
}

class _GestionInformacionPublicaScreenState extends State<GestionInformacionPublicaScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Gestión de Información Pública'),
        backgroundColor: WessexColors.midnightNavy,
        foregroundColor: WessexColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WessexColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: WessexColors.white,
          indicatorWeight: 3,
          labelColor: WessexColors.white,
          unselectedLabelColor: WessexColors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(icon: Icon(Icons.article), text: 'Noticias'),
            Tab(icon: Icon(Icons.business), text: 'Auspiciadores'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Merchandising'),
          ],
        ),
      ),
      body: WessexBackground(
        child: TabBarView(
          controller: _tabController,
          children: const [
            _NoticiasTab(),
            _AuspiciadoresTab(),
            _MerchandisingTab(),
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
        final List<dynamic> noticiasData = response.data is Map 
            ? (response.data['data'] as List? ?? [])
            : (response.data is List ? response.data as List : []);
        
        print('🔍 DEBUG _loadNoticias - Noticias count: ${noticiasData.length}');
        
        setState(() {
          _noticias = noticiasData
              .map((json) => NoticiaModel.fromJson(json))
              .toList();
        });
        
        print('✅ DEBUG _loadNoticias - _noticias final count: ${_noticias.length}');
      } else {
        print('❌ DEBUG _loadNoticias - Response not successful or data is null');
      }
    } catch (e) {
      print('❌ DEBUG _loadNoticias - Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar noticias: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Noticias',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.white,
                  ),
                ),
                WessexButton(
                  onPressed: () => _showCreateDialog(),
                  text: 'Nueva Noticia',
                  icon: Icons.add,
                  backgroundColor: WessexColors.crimsonAlert,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: WessexColors.white))
                : _noticias.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay noticias registradas\nAgrega la primera noticia para comenzar',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: WessexColors.white, fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _noticias.length,
                        itemBuilder: (context, index) => _buildNoticiaCard(_noticias[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticiaCard(NoticiaModel noticia) {
    return WessexCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildEstadoChip(noticia.estado),
                    if (noticia.destacada) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: WessexColors.goldenYellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'DESTACADA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: WessexColors.deepNavyBlue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(noticia.destacada ? Icons.star : Icons.star_border),
                      onPressed: () => _toggleDestacada(noticia),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(noticia),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmDelete(noticia),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Imagen de la noticia
            if (noticia.imagen.isNotEmpty && !noticia.imagen.contains('placeholder'))
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(noticia.imagen),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(
              noticia.titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(noticia.descripcion),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: estado == 'publicada' ? WessexColors.leafGreen : WessexColors.ashGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        estado.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WessexColors.white),
      ),
    );
  }

  Future<void> _toggleDestacada(NoticiaModel noticia) async {
    try {
      final response = await ApiService.patch('/noticias/${noticia.id}/destacada', {});
      if (response.success) _loadNoticias();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(NoticiaModel noticia) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar "${noticia.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.delete('/noticias/${noticia.id}');
        if (response.success) _loadNoticias();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showCreateDialog() => _showNoticiaDialog();
  void _showEditDialog(NoticiaModel noticia) => _showNoticiaDialog(noticia: noticia);

  void _showNoticiaDialog({NoticiaModel? noticia}) {
    showDialog(
      context: context,
      builder: (context) => _NoticiaDialog(
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
      _imagenUrl = widget.noticia!.imagen.isNotEmpty ? widget.noticia!.imagen : null;
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
        final uploadResponse = await _uploadImage(_imagenBytes!, _imagenNombre!);
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
        'fechaPublicacion': DateTime.now().toIso8601String().split('T')[0], // Solo la fecha YYYY-MM-DD
      };

      ApiResponse response;
      if (widget.noticia != null) {
        response = await ApiService.put('/noticias/${widget.noticia!.id}', noticiaData);
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
              content: Text(widget.noticia != null 
                  ? 'Noticia actualizada exitosamente'
                  : 'Noticia creada exitosamente'),
            ),
          );
        }
        Navigator.pop(context);
      } else {
        print('❌ Error guardando noticia. Status: ${response.statusCode}, Message: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.message ?? 'Error desconocido'}')),
          );
        }
      }
    } catch (e) {
      print('❌ Exception en _guardar noticia: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
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
      print('🔍 DEBUG _uploadImage - Datos: filename=$fileName, mimeType=$mimeType, dataSize=${base64Image.length}');
      
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
            final fullUrl = '${ApiService.baseUrl.replaceAll('/api', '')}$imageUrl';
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
        final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
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
          const SnackBar(content: Text('Funcionalidad disponible solo en web por ahora')),
        );
      }
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: ${e.toString()}')),
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
                decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
                validator: (value) => value?.trim().isEmpty == true ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                maxLines: 4,
                validator: (value) => value?.trim().isEmpty == true ? 'La descripción es obligatoria' : null,
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
                            color: _imagenBytes != null 
                              ? WessexColors.leafGreen 
                              : WessexColors.darkGrape.withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: _imagenBytes != null 
                            ? WessexColors.leafGreen.withOpacity(0.05)
                            : Colors.transparent,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _imagenBytes != null ? Icons.check_circle : Icons.cloud_upload,
                              color: _imagenBytes != null 
                                ? WessexColors.leafGreen 
                                : WessexColors.darkGrape.withOpacity(0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _imagenNombre ?? 'Toca para seleccionar imagen',
                              style: TextStyle(
                                color: _imagenBytes != null 
                                  ? WessexColors.leafGreen 
                                  : WessexColors.darkGrape.withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: _imagenBytes != null 
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
                                    color: WessexColors.leafGreen.withOpacity(0.3),
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
                                    Icon(Icons.error, color: WessexColors.crimsonAlert),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
        final List<dynamic> auspiciadoresData = response.data is Map 
            ? (response.data['data'] as List? ?? [])
            : (response.data is List ? response.data as List : []);
        
        setState(() {
          _auspiciadores = auspiciadoresData
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
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Auspiciadores',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.deepNavyBlue,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Auspiciador'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.deepRoyalBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _auspiciadores.isEmpty
                    ? const Center(
                        child: Text('No hay auspiciadores registrados'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _auspiciadores.length,
                        itemBuilder: (context, index) {
                          final auspiciador = _auspiciadores[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen del auspiciador
                                if (auspiciador.imagen.isNotEmpty && !auspiciador.imagen.contains('placeholder'))
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      image: DecorationImage(
                                        image: NetworkImage(auspiciador.imagen),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                // Información del auspiciador
                                ListTile(
                                  leading: auspiciador.imagen.isEmpty || auspiciador.imagen.contains('placeholder')
                                      ? const Icon(Icons.business, size: 40)
                                      : null,
                                  title: Text(
                                    auspiciador.titulo,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(auspiciador.enlace ?? 'Sin enlace'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showEditDialog(auspiciador),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteAuspiciador(auspiciador.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAuspiciador(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este auspiciador?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
              const SnackBar(content: Text('Auspiciador eliminado exitosamente')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  void _showCreateDialog() => _showAuspiciadorDialog();
  void _showEditDialog(AuspiciadorModel auspiciador) => _showAuspiciadorDialog(auspiciador: auspiciador);

  void _showAuspiciadorDialog({AuspiciadorModel? auspiciador}) {
    showDialog(
      context: context,
      builder: (context) => _AuspiciadorDialog(
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

  const _AuspiciadorDialog({
    this.auspiciador,
    required this.onSaved,
  });

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
      print('🔍 DEBUG _uploadImage Auspiciador - Iniciando subida de imagen: $fileName');
      
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
      
      print('🔍 DEBUG _uploadImage Auspiciador - Enviando POST a /upload/imagen');
      
      final response = await ApiService.post('/upload/imagen', uploadData);
      
      print('🔍 DEBUG _uploadImage Auspiciador - Response success: ${response.success}');
      
      if (response.success && response.data != null) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          final dataMap = responseData['data'] as Map<String, dynamic>;
          final imageUrl = dataMap['url'] as String?;
          if (imageUrl != null) {
            // Convertir URL relativa a absoluta
            final fullUrl = '${ApiService.baseUrl.replaceAll('/api', '')}$imageUrl';
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
        final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
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
          const SnackBar(content: Text('Funcionalidad disponible solo en web por ahora')),
        );
      }
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: ${e.toString()}')),
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      String imagenUrl = widget.auspiciador?.imagen ?? 'https://via.placeholder.com/200x200?text=Logo';
      
      // Si hay una imagen seleccionada, subirla primero
      if (_imagenBytes != null && _imagenNombre != null) {
        print('🔍 DEBUG - Subiendo imagen auspiciador: $_imagenNombre');
        final uploadResponse = await _uploadImage(_imagenBytes!, _imagenNombre!);
        if (uploadResponse != null) {
          imagenUrl = uploadResponse;
          print('✅ DEBUG - Imagen auspiciador subida exitosamente: $imagenUrl');
        } else {
          print('❌ DEBUG - Error subiendo imagen auspiciador, usando placeholder');
        }
      }

      final auspiciadorData = {
        'titulo': _tituloController.text.trim(),
        'imagen': imagenUrl,
        'enlace': _enlaceController.text.isEmpty ? null : _enlaceController.text.trim(),
        'estado': 'activo', // Usar 'activo' en lugar de 'publicado'
        // No agregamos orden, el backend usará el valor por defecto (0)
      };

      ApiResponse response;
      if (widget.auspiciador != null) {
        response = await ApiService.put('/auspiciadores/${widget.auspiciador!.id}', auspiciadorData);
      } else {
        response = await ApiService.post('/auspiciadores', auspiciadorData);
      }

      if (response.success) {
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.auspiciador != null 
                  ? 'Auspiciador actualizado exitosamente'
                  : 'Auspiciador creado exitosamente'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.auspiciador != null ? 'Editar Auspiciador' : 'Nuevo Auspiciador'),
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
                          color: _imagenBytes != null 
                            ? WessexColors.leafGreen 
                            : WessexColors.darkGrape.withOpacity(0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: _imagenBytes != null 
                          ? WessexColors.leafGreen.withOpacity(0.05)
                          : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _imagenBytes != null ? Icons.check_circle : Icons.cloud_upload,
                            color: _imagenBytes != null 
                              ? WessexColors.leafGreen 
                              : WessexColors.darkGrape.withOpacity(0.5),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _imagenNombre ?? 'Toca para seleccionar logo',
                            style: TextStyle(
                              color: _imagenBytes != null 
                                ? WessexColors.leafGreen 
                                : WessexColors.darkGrape.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight: _imagenBytes != null 
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
                                  color: WessexColors.leafGreen.withOpacity(0.3),
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
                                  Icon(Icons.error, color: WessexColors.crimsonAlert),
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
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
        final List<dynamic> productosData = response.data is Map 
            ? (response.data['data'] as List? ?? [])
            : (response.data is List ? response.data as List : []);
        
        print('🔍 DEBUG _loadProductos - Productos count: ${productosData.length}');
        
        setState(() {
          _productos = productosData.map((json) {
            try {
              print('🔍 DEBUG _loadProductos - Parseando producto: ${json['titulo']}, precio: ${json['precio']} (${json['precio'].runtimeType})');
              return MerchandisingModel.fromJson(json);
            } catch (e) {
              print('❌ ERROR _loadProductos - Error parseando producto ${json['titulo']}: $e');
              rethrow;
            }
          }).toList();
        });
        
        print('✅ DEBUG _loadProductos - _productos final count: ${_productos.length}');
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
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Merchandising',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: WessexColors.deepNavyBlue,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WessexColors.deepRoyalBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _productos.isEmpty
                    ? const Center(
                        child: Text('No hay productos registrados'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _productos.length,
                        itemBuilder: (context, index) {
                          final producto = _productos[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen del producto
                                if (producto.imagen.isNotEmpty && !producto.imagen.contains('placeholder'))
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      image: DecorationImage(
                                        image: NetworkImage(producto.imagen),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                // Información del producto
                                ListTile(
                                  leading: producto.imagen.isEmpty || producto.imagen.contains('placeholder')
                                      ? const Icon(Icons.shopping_bag, size: 40)
                                      : null,
                                  title: Text(
                                    producto.titulo,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (producto.descripcion?.isNotEmpty == true)
                                        Text(producto.descripcion!),
                                      Text(
                                        '\$${producto.precio.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showEditDialog(producto),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteProducto(producto.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProducto(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este producto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  void _showCreateDialog() => _showMerchandisingDialog();
  void _showEditDialog(MerchandisingModel producto) => _showMerchandisingDialog(producto: producto);

  void _showMerchandisingDialog({MerchandisingModel? producto}) {
    showDialog(
      context: context,
      builder: (context) => _MerchandisingDialog(
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

  const _MerchandisingDialog({
    this.producto,
    required this.onSaved,
  });

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
      print('🔍 DEBUG _uploadImage Merchandising - Iniciando subida de imagen: $fileName');
      
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
      
      print('🔍 DEBUG _uploadImage Merchandising - Enviando POST a /upload/imagen');
      
      final response = await ApiService.post('/upload/imagen', uploadData);
      
      print('🔍 DEBUG _uploadImage Merchandising - Response success: ${response.success}');
      
      if (response.success && response.data != null) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          final dataMap = responseData['data'] as Map<String, dynamic>;
          final imageUrl = dataMap['url'] as String?;
          if (imageUrl != null) {
            // Convertir URL relativa a absoluta
            final fullUrl = '${ApiService.baseUrl.replaceAll('/api', '')}$imageUrl';
            print('✅ DEBUG _uploadImage Merchandising - URL completa: $fullUrl');
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
        final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
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
          const SnackBar(content: Text('Funcionalidad disponible solo en web por ahora')),
        );
      }
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: ${e.toString()}')),
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final precio = double.tryParse(_precioController.text);
      
      String imagenUrl = widget.producto?.imagen ?? 'https://via.placeholder.com/300x300?text=Producto';
      
      // Si hay una imagen seleccionada, subirla primero
      if (_imagenBytes != null && _imagenNombre != null) {
        print('🔍 DEBUG - Subiendo imagen merchandising: $_imagenNombre');
        final uploadResponse = await _uploadImage(_imagenBytes!, _imagenNombre!);
        if (uploadResponse != null) {
          imagenUrl = uploadResponse;
          print('✅ DEBUG - Imagen merchandising subida exitosamente: $imagenUrl');
        } else {
          print('❌ DEBUG - Error subiendo imagen merchandising, usando placeholder');
        }
      }
      
      final productoData = {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.isEmpty ? null : _descripcionController.text.trim(),
        'precio': precio,
        'imagen': imagenUrl,
        'estado': 'activo', // Usar 'activo' en lugar de 'publicado'
        // No agregamos orden, el backend usará el valor por defecto (0)
      };

      ApiResponse response;
      if (widget.producto != null) {
        response = await ApiService.put('/merchandising/${widget.producto!.id}', productoData);
      } else {
        response = await ApiService.post('/merchandising', productoData);
      }

      if (response.success) {
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.producto != null 
                  ? 'Producto actualizado exitosamente'
                  : 'Producto creado exitosamente'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.producto != null ? 'Editar Producto' : 'Nuevo Producto'),
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
                          color: _imagenBytes != null 
                            ? WessexColors.leafGreen 
                            : WessexColors.darkGrape.withOpacity(0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: _imagenBytes != null 
                          ? WessexColors.leafGreen.withOpacity(0.05)
                          : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _imagenBytes != null ? Icons.check_circle : Icons.cloud_upload,
                            color: _imagenBytes != null 
                              ? WessexColors.leafGreen 
                              : WessexColors.darkGrape.withOpacity(0.5),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _imagenNombre ?? 'Toca para seleccionar imagen',
                            style: TextStyle(
                              color: _imagenBytes != null 
                                ? WessexColors.leafGreen 
                                : WessexColors.darkGrape.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight: _imagenBytes != null 
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
                                  color: WessexColors.leafGreen.withOpacity(0.3),
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
                                  Icon(Icons.error, color: WessexColors.crimsonAlert),
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
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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